import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/documentation_record.dart';
import '../models/photo_item.dart';

class PdfGeneratorService {
  /// Menghasilkan file PDF standar A4 resmi sesuai format SPJ
  /// [photosPerPage]: Jumlah maksimal foto per lembar A4 (1, 2, atau 4)
  static Future<Uint8List> generateSpjPdf(
    DocumentationRecord record, {
    int photosPerPage = 4,
  }) async {
    final pdf = pw.Document();

    // Baca byte seluruh foto terlebih dahulu
    final List<Map<String, dynamic>> photoDataList = [];
    for (final photo in record.photos) {
      final file = File(photo.filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        photoDataList.add({
          'item': photo,
          'image': pw.MemoryImage(bytes),
        });
      }
    }

    // Bagi foto ke dalam halaman sesuai kuota foto per halaman (default: 4 foto per lembar A4)
    final List<List<Map<String, dynamic>>> pagesData = [];
    for (int i = 0; i < photoDataList.length; i += photosPerPage) {
      pagesData.add(
        photoDataList.sublist(
          i,
          i + photosPerPage > photoDataList.length
              ? photoDataList.length
              : i + photosPerPage,
        ),
      );
    }

    // Jika belum ada foto sama sekali, buat 1 halaman judul
    if (pagesData.isEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          build: (context) {
            return pw.Center(
              child: pw.Text(
                record.title.toUpperCase(),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
        ),
      );
    }

    for (int pageIdx = 0; pageIdx < pagesData.length; pageIdx++) {
      final currentPhotos = pagesData[pageIdx];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.only(
            left: 28,
            right: 28,
            top: 32,
            bottom: 24,
          ),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Judul Dokumen di bagian atas lembar A4
                if (pageIdx == 0) ...[
                  pw.Text(
                    record.title.toUpperCase(),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      lineSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 14),
                ] else ...[
                  pw.Text(
                    '${record.title.toUpperCase()} (Lanjutan)',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                ],

                // Tampilan Foto (Besar atau Grid 2x2)
                pw.Expanded(
                  child: _buildLayout(currentPhotos, photosPerPage),
                ),

                // Nomor Halaman di sudut bawah
                pw.Align(
                  alignment: pw.Alignment.bottomRight,
                  child: pw.Text(
                    'Halaman ${pageIdx + 1} dari ${pagesData.length}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return await pdf.save();
  }

  /// Membangun susunan foto agar proporsional dan mengisi lembar A4 secara rapi
  static pw.Widget _buildLayout(
      List<Map<String, dynamic>> photos, int targetPerPage) {
    // Kasus 1: Hanya 1 Foto di Halaman (Ukuran Besar & Proporsional Mengisi A4)
    if (photos.length == 1 && targetPerPage == 1) {
      return pw.Center(
        child: _buildPhotoCell(
          photos[0]['item'],
          photos[0]['image'],
          maxHeight: 520,
          maxWidth: 500,
        ),
      );
    }

    // Kasus 2: 2 Foto vertikal (jika dipilih mode 2 foto per halaman)
    if (photos.length <= 2 && targetPerPage == 2) {
      return pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: photos.map((data) {
          return _buildPhotoCell(
            data['item'],
            data['image'],
            maxHeight: 290,
            maxWidth: 480,
          );
        }).toList(),
      );
    }

    // Kasus 3: Jika hanya 1 foto tapi dalam mode 4 foto (tetap buat cukup besar dan rapi)
    if (photos.length == 1) {
      return pw.Center(
        child: _buildPhotoCell(
          photos[0]['item'],
          photos[0]['image'],
          maxHeight: 460,
          maxWidth: 480,
        ),
      );
    }

    // Kasus 4: Jika ada 2 foto dalam mode 4 foto (Tampilkan bersebelahan rapi atau vertikal)
    if (photos.length == 2) {
      return pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Expanded(
                child: _buildPhotoCell(
                  photos[0]['item'],
                  photos[0]['image'],
                  maxHeight: 260,
                  maxWidth: 245,
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: _buildPhotoCell(
                  photos[1]['item'],
                  photos[1]['image'],
                  maxHeight: 260,
                  maxWidth: 245,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Kasus 5: 3 atau 4 Foto per Lembar (Grid 2x2 - 2 Kolom x 2 Baris)
    final row1 = photos.sublist(0, 2);
    final row2 = photos.sublist(2, photos.length);

    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        // Baris 1: Foto 1 & Foto 2
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _buildPhotoCell(
                row1[0]['item'],
                row1[0]['image'],
                maxHeight: 235,
                maxWidth: 245,
              ),
            ),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: _buildPhotoCell(
                row1[1]['item'],
                row1[1]['image'],
                maxHeight: 235,
                maxWidth: 245,
              ),
            ),
          ],
        ),

        // Baris 2: Foto 3 & Foto 4 (jika ada)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _buildPhotoCell(
                row2[0]['item'],
                row2[0]['image'],
                maxHeight: 235,
                maxWidth: 245,
              ),
            ),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: row2.length > 1
                  ? _buildPhotoCell(
                      row2[1]['item'],
                      row2[1]['image'],
                      maxHeight: 235,
                      maxWidth: 245,
                    )
                  : pw.Container(),
            ),
          ],
        ),
      ],
    );
  }

  /// Membuat kotak bingkai foto dengan keterangan di bawahnya
  static pw.Widget _buildPhotoCell(
    PhotoItem item,
    pw.MemoryImage image, {
    required double maxHeight,
    required double maxWidth,
  }) {
    final String captionText = item.caption.isNotEmpty
        ? item.caption
        : (item.stage != null && item.stage!.isNotEmpty
            ? 'Foto ${item.stage}'
            : 'Dokumentasi');

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Bingkai Foto
        pw.Container(
          constraints: pw.BoxConstraints(
            maxHeight: maxHeight,
            maxWidth: maxWidth,
          ),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColors.grey400,
              width: 0.8,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Image(
            image,
            fit: pw.BoxFit.contain,
          ),
        ),
        pw.SizedBox(height: 5),
        // Keterangan di bawah foto
        pw.Text(
          captionText,
          textAlign: pw.TextAlign.center,
          maxLines: 2,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Membuka dialog pratinjau cetak langsung (Print ke printer fisik via Wi-Fi/Bluetooth)
  static Future<void> printDocument(
    DocumentationRecord record, {
    int photosPerPage = 4,
  }) async {
    final pdfBytes = await generateSpjPdf(record, photosPerPage: photosPerPage);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: '${record.title}.pdf',
    );
  }

  /// Bagikan file PDF ke WhatsApp atau aplikasi lain
  static Future<void> sharePdf(
    DocumentationRecord record, {
    int photosPerPage = 4,
  }) async {
    final pdfBytes = await generateSpjPdf(record, photosPerPage: photosPerPage);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${_sanitizeFilename(record.title)}.pdf',
    );
  }

  static String _sanitizeFilename(String text) {
    return text.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}
