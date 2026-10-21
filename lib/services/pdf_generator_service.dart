import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/documentation_record.dart';
import '../models/photo_item.dart';

class PdfGeneratorService {
  /// Menghasilkan file PDF standar A4 resmi sesuai format SPJ
  /// Mendukung susunan maksimal 4 foto per lembar (Grid 2x2) agar hemat kertas
  static Future<Uint8List> generateSpjPdf(
    DocumentationRecord record, {
    int photosPerPage = 4,
  }) async {
    final pdf = pw.Document();

    // Baca byte seluruh foto yang valid
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

    // Kelompokkan foto ke halaman (default maksimal 4 foto per lembar A4)
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

    // Jika belum ada foto, buat 1 halaman judul
    if (pagesData.isEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 40),
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
            top: 28,
            bottom: 24,
          ),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Judul Dokumen di atas lembar A4
                if (pageIdx == 0) ...[
                  pw.Text(
                    record.title.toUpperCase(),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      lineSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 12),
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

                // Area Foto Utama yang Memenuhi Lembar A4 Secara Efisien
                pw.Expanded(
                  child: _buildAdaptivePhotosLayout(currentPhotos, photosPerPage),
                ),

                // Penanda halaman halus di pojok bawah
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Align(
                    alignment: pw.Alignment.bottomRight,
                    child: pw.Text(
                      'Halaman ${pageIdx + 1} dari ${pagesData.length}',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: PdfColors.grey500,
                      ),
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

  /// Membangun susunan foto agar proporsional, besar, dan memenuhi kertas tanpa boros ruang
  static pw.Widget _buildAdaptivePhotosLayout(
    List<Map<String, dynamic>> photos,
    int targetPerPage,
  ) {
    // -------------------------------------------------------------
    // KASUS 1: Hanya 1 Foto di Lembar Ini
    // Foto tampil besar dan gagah memenuhi lembar A4 (seperti contoh pengguna)
    // -------------------------------------------------------------
    if (photos.length == 1) {
      return pw.Center(
        child: _buildPhotoBox(
          photos[0]['item'],
          photos[0]['image'],
          width: 500,
          height: 640,
          fit: pw.BoxFit.contain,
        ),
      );
    }

    // -------------------------------------------------------------
    // KASUS 2: Mode 2 Foto per Lembar
    // 2 foto vertikal berukuran besar
    // -------------------------------------------------------------
    if (photos.length == 2 && targetPerPage == 2) {
      return pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          pw.Expanded(
            child: _buildPhotoBox(
              photos[0]['item'],
              photos[0]['image'],
              width: 500,
              height: 320,
              fit: pw.BoxFit.contain,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Expanded(
            child: _buildPhotoBox(
              photos[1]['item'],
              photos[1]['image'],
              width: 500,
              height: 320,
              fit: pw.BoxFit.contain,
            ),
          ),
        ],
      );
    }

    // -------------------------------------------------------------
    // KASUS 3: Ada 2 Foto dalam Mode 4 Foto (Tampilkan Berdampingan Rapi)
    // -------------------------------------------------------------
    if (photos.length == 2) {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: _buildPhotoBox(
              photos[0]['item'],
              photos[0]['image'],
              width: 255,
              height: 480,
              fit: pw.BoxFit.contain,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: _buildPhotoBox(
              photos[1]['item'],
              photos[1]['image'],
              width: 255,
              height: 480,
              fit: pw.BoxFit.contain,
            ),
          ),
        ],
      );
    }

    // -------------------------------------------------------------
    // KASUS 4: 3 atau 4 Foto per Lembar (Grid 2x2 Persis Seperti Gambar 2 Pengguna)
    // Baris 1: Foto 1 & 2
    // Baris 2: Foto 3 & 4
    // Mengisi ~85% ruang kertas A4 tanpa menyia-nyiakan kertas!
    // -------------------------------------------------------------
    final row1 = photos.sublist(0, 2);
    final row2 = photos.sublist(2, photos.length);

    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Baris Pertama (Foto 1 & 2)
        pw.Expanded(
          child: pw.Row(
            children: [
              pw.Expanded(
                child: _buildPhotoBox(
                  row1[0]['item'],
                  row1[0]['image'],
                  width: 260,
                  height: 340,
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildPhotoBox(
                  row1[1]['item'],
                  row1[1]['image'],
                  width: 260,
                  height: 340,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),

        // Baris Kedua (Foto 3 & 4)
        pw.Expanded(
          child: pw.Row(
            children: [
              pw.Expanded(
                child: _buildPhotoBox(
                  row2[0]['item'],
                  row2[0]['image'],
                  width: 260,
                  height: 340,
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: row2.length > 1
                    ? _buildPhotoBox(
                        row2[1]['item'],
                        row2[1]['image'],
                        width: 260,
                        height: 340,
                        fit: pw.BoxFit.contain,
                      )
                    : pw.Container(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Membuat elemen wadah foto beserta keterangan opsionalnya
  static pw.Widget _buildPhotoBox(
    PhotoItem item,
    pw.MemoryImage image, {
    required double width,
    required double height,
    required pw.BoxFit fit,
  }) {
    final bool hasCustomCaption = item.caption.trim().isNotEmpty &&
        !item.caption.toLowerCase().startsWith('dokumentasi ');

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          constraints: pw.BoxConstraints(
            maxWidth: width,
            maxHeight: hasCustomCaption ? height - 18 : height,
          ),
          child: pw.Image(
            image,
            fit: fit,
          ),
        ),
        if (hasCustomCaption) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            item.caption,
            textAlign: pw.TextAlign.center,
            maxLines: 2,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
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
