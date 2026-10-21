import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/documentation_record.dart';

class DocxGeneratorService {
  /// Menghasilkan file Microsoft Word (.docx) berstandar OpenXML A4
  /// Mendukung susunan Grid 2x2 (maksimal 4 foto per halaman)
  static Future<File> generateSpjDocx(
    DocumentationRecord record, {
    int photosPerPage = 4,
  }) async {
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
    <w:spacing w:before="0" w:after="300"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/>
      <w:b/>
      <w:sz w:val="28"/>
    </w:rPr>
    <w:t>${_escapeXml(record.title.toUpperCase())}</w:t>
  </w:r>
</w:p>''');

    // Filter foto yang valid ada di HP
    final List<Map<String, dynamic>> validPhotos = [];
    int relIdCounter = 1;
    for (int i = 0; i < record.photos.length; i++) {
      final photo = record.photos[i];
      final file = File(photo.filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final ext = photo.filePath.endsWith('.png') ? 'png' : 'jpg';
        final mediaFileName = 'image$relIdCounter.$ext';
        final rId = 'rId$relIdCounter';

        relsBuffer.writeln(
            '<Relationship Id="$rId" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/$mediaFileName"/>');
        _addBytesToArchive(archive, 'word/media/$mediaFileName', bytes);

        validPhotos.add({
          'item': photo,
          'rId': rId,
          'id': relIdCounter,
        });
        relIdCounter++;
      }
    }

    // Kelompokkan foto ke halaman (default: 4 foto per halaman)
    for (int pageStart = 0; pageStart < validPhotos.length; pageStart += photosPerPage) {
      final pagePhotos = validPhotos.sublist(
        pageStart,
        pageStart + photosPerPage > validPhotos.length
            ? validPhotos.length
            : pageStart + photosPerPage,
      );

      // Jika halaman 2 ke atas, buat sub-judul lanjutan
      if (pageStart > 0) {
        bodyBuffer.writeln('''
<w:p>
  <w:pPr>
    <w:jc w:val="center"/>
    <w:spacing w:before="100" w:after="240"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/>
      <w:b/>
      <w:sz w:val="24"/>
    </w:rPr>
    <w:t>${_escapeXml(record.title.toUpperCase())} (Lanjutan)</w:t>
  </w:r>
</w:p>''');
      }

      // Susun layout tabel 2 kolom untuk Grid 2x2 (Maksimal 4 foto per lembar)
      if (photosPerPage == 4 && pagePhotos.length > 2) {
        // Grid 2x2 menggunakan Table Word tanpa border
        bodyBuffer.writeln('''
<w:tbl>
  <w:tblPr>
    <w:tblW w:w="9200" w:type="dxa"/>
    <w:jc w:val="center"/>
    <w:tblBorders>
      <w:top w:val="none"/><w:left w:val="none"/><w:bottom w:val="none"/><w:right w:val="none"/>
      <w:insideH w:val="none"/><w:insideV w:val="none"/>
    </w:tblBorders>
  </w:tblPr>''');

        for (int r = 0; r < pagePhotos.length; r += 2) {
          bodyBuffer.writeln('<w:tr>');
          for (int c = 0; c < 2; c++) {
            final pIdx = r + c;
            bodyBuffer.writeln('<w:tc><w:tcPr><w:tcW w:w="4600" w:type="dxa"/></w:tcPr>');
            if (pIdx < pagePhotos.length) {
              final pData = pagePhotos[pIdx];
              bodyBuffer.writeln(_buildDocxPhotoXml(pData['rId'], pData['id'], pData['item'], widthEmu: 2900000, heightEmu: 2200000));
            } else {
              bodyBuffer.writeln('<w:p/>');
            }
            bodyBuffer.writeln('</w:tc>');
          }
          bodyBuffer.writeln('</w:tr>');
        }
        bodyBuffer.writeln('</w:tbl>');
      } else {
        // 1 atau 2 Foto: Tampilkan vertikal besar
        final int wEmu = pagePhotos.length == 1 ? 5200000 : 4500000;
        final int hEmu = pagePhotos.length == 1 ? 3900000 : 3100000;

        for (final pData in pagePhotos) {
          bodyBuffer.writeln(_buildDocxPhotoXml(pData['rId'], pData['id'], pData['item'], widthEmu: wEmu, heightEmu: hEmu));
        }
      }

      // Jika masih ada halaman berikutnya, tambahkan Page Break
      if (pageStart + photosPerPage < validPhotos.length) {
        bodyBuffer.writeln('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
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

    // Encode ke file .docx
    final zipEncoder = ZipEncoder();
    final encodedBytes = zipEncoder.encode(archive);

    final outputDir = await getApplicationDocumentsDirectory();
    final cleanFileName = _sanitizeFilename(record.title);
    final docxFile = File('${outputDir.path}/$cleanFileName.docx');
    await docxFile.writeAsBytes(encodedBytes!);

    return docxFile;
  }

  static String _buildDocxPhotoXml(
    String rId,
    int id,
    dynamic item, {
    required int widthEmu,
    required int heightEmu,
  }) {
    final captionText = (item.caption != null && (item.caption as String).isNotEmpty)
        ? item.caption as String
        : (item.stage != null && (item.stage as String).isNotEmpty
            ? 'Foto ${item.stage}'
            : 'Dokumentasi');

    return '''
<w:p>
  <w:pPr>
    <w:jc w:val="center"/>
    <w:spacing w:before="60" w:after="40"/>
  </w:pPr>
  <w:r>
    <w:drawing>
      <wp:inline distT="0" distB="0" distL="0" distR="0" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">
        <wp:extent cx="$widthEmu" cy="$heightEmu"/>
        <wp:effectExtent l="0" t="0" r="0" b="0"/>
        <wp:docPr id="$id" name="Foto $id"/>
        <wp:cNvGraphicFramePr>
          <a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/>
        </wp:cNvGraphicFramePr>
        <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
          <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
            <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
              <pic:nvPicPr>
                <pic:cNvPr id="$id" name="Image $id"/>
                <pic:cNvPicPr/>
              </pic:nvPicPr>
              <pic:blipFill>
                <a:blip r:embed="$rId" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>
                <a:stretch><a:fillRect/></a:stretch>
              </pic:blipFill>
              <pic:spPr>
                <a:xfrm><a:off x="0" y="0"/><a:ext cx="$widthEmu" cy="$heightEmu"/></a:xfrm>
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
    <w:spacing w:before="40" w:after="160"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/>
      <w:b/>
      <w:sz w:val="20"/>
    </w:rPr>
    <w:t>${_escapeXml(captionText)}</w:t>
  </w:r>
</w:p>''';
  }

  /// Bagikan file Word ke WhatsApp, email, atau drive
  static Future<void> shareDocx(
    DocumentationRecord record, {
    int photosPerPage = 4,
  }) async {
    final docxFile = await generateSpjDocx(record, photosPerPage: photosPerPage);
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
