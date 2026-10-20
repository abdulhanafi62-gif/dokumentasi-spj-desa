import 'dart:io';
import 'package:flutter/material.dart';
import '../models/documentation_record.dart';
import '../services/docx_generator_service.dart';
import '../services/pdf_generator_service.dart';
import '../utils/app_theme.dart';

class PreviewExportScreen extends StatefulWidget {
  final DocumentationRecord record;

  const PreviewExportScreen({super.key, required this.record});

  @override
  State<PreviewExportScreen> createState() => _PreviewExportScreenState();
}

class _PreviewExportScreenState extends State<PreviewExportScreen> {
  bool _isProcessing = false;
  String _processingMessage = '';

  Future<void> _handlePrintPdf() async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Menyiapkan pratinjau cetak PDF...';
    });
    try {
      await PdfGeneratorService.printDocument(widget.record);
    } catch (e) {
      _showError('Gagal mencetak PDF: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleSharePdf() async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Menghasilkan file PDF A4...';
    });
    try {
      await PdfGeneratorService.sharePdf(widget.record);
    } catch (e) {
      _showError('Gagal membagikan PDF: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleShareDocx() async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Menghasilkan file Microsoft Word (.docx)...';
    });
    try {
      await DocxGeneratorService.shareDocx(widget.record);
    } catch (e) {
      _showError('Gagal membagikan file Word: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pratinjau & Ekspor Dokumen'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Banner Tombol Ekspor Cepat
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Pilih Format Output:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Tombol PDF
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.picture_as_pdf, size: 20),
                            label: const Text('Kirim PDF'),
                            onPressed: _isProcessing ? null : _handleSharePdf,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Tombol Word DOCX
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF185ABD), // Warna khas Word
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.description, size: 20),
                            label: const Text('Kirim Word'),
                            onPressed: _isProcessing ? null : _handleShareDocx,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Tombol Cetak / Print Langsung
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.print, size: 20),
                      label: const Text('Cetak Langsung (Print Preview)'),
                      onPressed: _isProcessing ? null : _handlePrintPdf,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Simulasi Lembar Kertas A4
              Card(
                elevation: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Judul Dokumen di Lembar A4
                      Text(
                        widget.record.title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Daftar Foto & Caption
                      if (widget.record.photos.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            'Belum ada foto yang ditambahkan.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...widget.record.photos.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final photo = entry.value;
                          final file = File(photo.filePath);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              children: [
                                // Foto
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 280,
                                      maxWidth: double.infinity,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                        width: 1,
                                      ),
                                    ),
                                    child: file.existsSync()
                                        ? Image.file(
                                            file,
                                            fit: BoxFit.contain,
                                          )
                                        : const Center(
                                            child: Icon(Icons.broken_image,
                                                size: 60, color: Colors.grey),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Keterangan di bawah foto
                                Text(
                                  photo.caption.isNotEmpty
                                      ? photo.caption
                                      : (photo.stage != null &&
                                              photo.stage!.isNotEmpty
                                          ? 'Foto ${photo.stage}'
                                          : 'Foto Dokumentasi ${idx + 1}'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kategori: ${widget.record.category}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const Text(
                            'Standar Kertas: A4',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Loading Overlay
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _processingMessage,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
