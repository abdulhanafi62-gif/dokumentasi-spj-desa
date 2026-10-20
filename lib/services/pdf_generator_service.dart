import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/documentation_record.dart';
import '../models/photo_item.dart';

class PdfGeneratorService {
  /// Menghasilkan file PDF standar A4 resmi sesuai format SPJ
  static Future<Uint8List> generateSpjPdf(
      DocumentationRecord record) async {
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

    // Bagi foto menjadi 2 foto per halaman agar proporsi di kertas A4 rapi & tidak kekecilan
    const int photosPerPage = 2;
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

    // Jika belum ada foto, buat 1 halaman kosong bertuliskan judul
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
            left: 36,
            right: 36,
            top: 36,
            bottom: 30,
          ),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Judul Dokumen (hanya di halaman pertama atau selalu di atas halaman)
                if (pageIdx == 0) ...[
                  pw.Text(
                    record.title.toUpperCase(),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 16),
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
                  pw.SizedBox(height: 12),
                ],

                // Foto-foto untuk halaman ini
                pw.Expanded(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: currentPhotos.map((data) {
                      final PhotoItem item = data['item'];
                      final pw.MemoryImage image = data['image'];

                      // Teks keterangan di bawah foto
                      final String captionText = item.caption.isNotEmpty
                          ? item.caption
                          : (item.stage != null && item.stage!.isNotEmpty
                              ? 'Foto ${item.stage}'
                              : 'Dokumentasi Kegiatan');

                      return pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 12),
                        child: pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            // Frame Foto
                            pw.Container(
                              constraints: const pw.BoxConstraints(
                                maxHeight: 270,
                                maxWidth: 480,
                              ),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(
                                  color: PdfColors.grey400,
                                  width: 0.8,
                                ),
                              ),
                              child: pw.Image(
                                image,
                                fit: pw.BoxFit.contain,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            // Keterangan di bawah foto
                            pw.Text(
                              captionText,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
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

  /// Membuka dialog pratinjau cetak langsung (Print ke printer fisik via Wi-Fi/Bluetooth)
  static Future<void> printDocument(DocumentationRecord record) async {
    final pdfBytes = await generateSpjPdf(record);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: '${record.title}.pdf',
    );
  }

  /// Bagikan file PDF ke WhatsApp atau aplikasi lain
  static Future<void> sharePdf(DocumentationRecord record) async {
    final pdfBytes = await generateSpjPdf(record);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${_sanitizeFilename(record.title)}.pdf',
    );
  }

  static String _sanitizeFilename(String text) {
    return text.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}
