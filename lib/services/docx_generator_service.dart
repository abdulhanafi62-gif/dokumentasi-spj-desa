import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/documentation_record.dart';

class DocxGeneratorService {
  /// Menghasilkan file Microsoft Word (.docx) berstandar OpenXML A4
  static Future<File> generateSpjDocx(DocumentationRecord record) async {
    final archive = Archive();

    // 1. [Content_Types].xml
    final contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="jpeg" ContentType="image/jpeg"/>
  <Default Extension="jpg" ContentType="image/jpeg"/>
  <Default Extension="png" ContentType="image/png"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';
    _addStringToArchive(archive, '[Content_Types].xml', contentTypesXml);

    // 2. _rels/.rels
    final rootRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    _addStringToArchive(archive, '_rels/.rels', rootRelsXml);

    // 3. Susun relasi gambar di word/_rels/document.xml.rels & salin byte gambar
    final relsBuffer = StringBuffer();
    relsBuffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    relsBuffer.writeln('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');

    final bodyBuffer = StringBuffer();

    // Judul Dokumen (Huruf Kapital, Tebal, Posisi Tengah)
    bodyBuffer.writeln('''
<w:p>
  <w:pPr>
    <w:jc w:val="center"/>
    <w:spacing w:before="0" w:after="360"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/>
      <w:b/>
      <w:sz w:val="30"/>
    </w:rPr>
    <w:t>${_escapeXml(record.title.toUpperCase())}</w:t>
  </w:r>
</w:p>''');

    int relIdCounter = 1;
    for (int i = 0; i < record.photos.length; i++) {
      final photo = record.photos[i];
      final photoFile = File(photo.filePath);

      if (await photoFile.exists()) {
        final photoBytes = await photoFile.readAsBytes();
        final imageExtension = photo.filePath.endsWith('.png') ? 'png' : 'jpg';
        final mediaFileName = 'image$relIdCounter.$imageExtension';

        // Tambahkan relasi
        final rId = 'rId$relIdCounter';
        relsBuffer.writeln(
            '<Relationship Id="$rId" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/$mediaFileName"/>');

        // Masukkan file gambar ke dalam zip: word/media/imageX.jpg
        _addBytesToArchive(archive, 'word/media/$mediaFileName', photoBytes);

        // Teks keterangan di bawah foto
        final captionText = photo.caption.isNotEmpty
            ? photo.caption
            : (photo.stage != null && photo.stage!.isNotEmpty
                ? 'Foto ${photo.stage}'
                : 'Foto ${i + 1}');

        // Tambahkan XML Drawing Gambar & Paragraf Keterangan
        // Ukuran 15cm x 11cm dihitung dalam satuan EMU (1cm = 360,000 EMUs)
        const int emuWidth = 5400000;
        const int emuHeight = 4050000;

        bodyBuffer.writeln('''
<w:p>
  <w:pPr>
    <w:jc w:val="center"/>
    <w:spacing w:before="120" w:after="120"/>
  </w:pPr>
  <w:r>
    <w:drawing>
      <wp:inline distT="0" distB="0" distL="0" distR="0" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">
        <wp:extent cx="$emuWidth" cy="$emuHeight"/>
        <wp:effectExtent l="0" t="0" r="0" b="0"/>
        <wp:docPr id="$relIdCounter" name="Foto $relIdCounter"/>
        <wp:cNvGraphicFramePr>
          <a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/>
        </wp:cNvGraphicFramePr>
        <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
          <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
            <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
              <pic:nvPicPr>
                <pic:cNvPr id="$relIdCounter" name="Image $relIdCounter"/>
                <pic:cNvPicPr/>
              </pic:nvPicPr>
              <pic:blipFill>
                <a:blip r:embed="$rId" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>
                <a:stretch><a:fillRect/></a:stretch>
              </pic:blipFill>
              <pic:spPr>
                <a:xfrm><a:off x="0" y="0"/><a:ext cx="$emuWidth" cy="$emuHeight"/></a:xfrm>
                <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
              </pic:spPr>
            </pic:pic>
          </a:graphicData>
        </a:graphic>
      </wp:inline>
    </w:drawing>
  </w:r>
</w:p>
<w:p>
  <w:pPr>
    <w:jc w:val="center"/>
    <w:spacing w:before="60" w:after="300"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/>
      <w:i/>
      <w:sz w:val="22"/>
    </w:rPr>
    <w:t>${_escapeXml(captionText)}</w:t>
  </w:r>
</w:p>''');

        // Jika setiap 2 foto, tambahkan pemisah halaman (Page Break) agar rapi di A4
        if ((i + 1) % 2 == 0 && (i + 1) < record.photos.length) {
          bodyBuffer.writeln('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
        }

        relIdCounter++;
      }
    }

    relsBuffer.writeln('</Relationships>');
    _addStringToArchive(archive, 'word/_rels/document.xml.rels', relsBuffer.toString());

    // 4. word/document.xml (Ukuran A4: 11906 x 16838 twips)
    final documentXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
    ${bodyBuffer.toString()}
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>''';
    _addStringToArchive(archive, 'word/document.xml', documentXml);

    // Encode seluruh zip menjadi file .docx
    final zipEncoder = ZipEncoder();
    final encodedBytes = zipEncoder.encode(archive);

    final outputDir = await getApplicationDocumentsDirectory();
    final cleanFileName = _sanitizeFilename(record.title);
    final docxFile = File('${outputDir.path}/$cleanFileName.docx');
    await docxFile.writeAsBytes(encodedBytes!);

    return docxFile;
  }

  /// Bagikan file Word ke WhatsApp, email, atau drive
  static Future<void> shareDocx(DocumentationRecord record) async {
    final docxFile = await generateSpjDocx(record);
    await Share.shareXFiles(
      [XFile(docxFile.path)],
      text: 'Dokumentasi SPJ Word: ${record.title}',
    );
  }

  static void _addStringToArchive(Archive archive, String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  static void _addBytesToArchive(Archive archive, String path, List<int> bytes) {
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _sanitizeFilename(String text) {
    return text.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}
