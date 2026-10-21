import 'dart:io';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/documentation_record.dart';
import '../services/docx_generator_service.dart';
import '../services/pdf_generator_service.dart';
import '../services/storage_service.dart';
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
  int _photosPerPage = 4; // Default 4 foto per lembar (Grid 2x2)

  @override
  void initState() {
    super.initState();
    _loadDefaultLayout();
  }

  Future<void> _loadDefaultLayout() async {
    final settings = await StorageService.loadSettings();
    setState(() {
      _photosPerPage = settings.photosPerPage;
    });
  }

  Future<void> _handlePrintPdf() async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Menyiapkan pratinjau cetak PDF...';
    });
    try {
      await PdfGeneratorService.printDocument(
        widget.record,
        photosPerPage: _photosPerPage,
      );
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
      await PdfGeneratorService.sharePdf(
        widget.record,
        photosPerPage: _photosPerPage,
      );
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
      await DocxGeneratorService.shareDocx(
        widget.record,
        photosPerPage: _photosPerPage,
      );
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
              // Card Pengaturan Susunan Lembar (1, 2, atau 4 Foto)
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.grid_view, color: AppTheme.primaryColor),
                          SizedBox(width: 8),
                          Text(
                            'Tata Letak Foto per Lembar A4:',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('4 Foto (Grid 2x2)'),
                            selected: _photosPerPage == 4,
                            selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _photosPerPage == 4
                                  ? AppTheme.primaryColor
                                  : Colors.black87,
                              fontWeight: _photosPerPage == 4
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (_) =>
                                setState(() => _photosPerPage = 4),
                          ),
                          ChoiceChip(
                            label: const Text('2 Foto (Besar)'),
                            selected: _photosPerPage == 2,
                            selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _photosPerPage == 2
                                  ? AppTheme.primaryColor
                                  : Colors.black87,
                              fontWeight: _photosPerPage == 2
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (_) =>
                                setState(() => _photosPerPage = 2),
                          ),
                          ChoiceChip(
                            label: const Text('1 Foto (Penuh)'),
                            selected: _photosPerPage == 1,
                            selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _photosPerPage == 1
                                  ? AppTheme.primaryColor
                                  : Colors.black87,
                              fontWeight: _photosPerPage == 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (_) =>
                                setState(() => _photosPerPage = 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _photosPerPage == 4
                            ? '✨ Pilihan ideal untuk Pengadaan ATK & banyak barang: 4 foto rapi dalam 1 lembar A4.'
                            : (_photosPerPage == 2
                                ? '✨ Cocok untuk pembangunan fisik: foto terlihat besar dan jelas.'
                                : '✨ 1 lembar penuh untuk 1 foto ukuran maksimal.'),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Banner Tombol Ekspor Cepat
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Format Output:',
                        style: TextStyle(
                          fontSize: 15,
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
                                backgroundColor: const Color(0xFF185ABD),
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
              ),
              const SizedBox(height: 16),

              // Simulasi Lembar Kertas A4
              Card(
                elevation: 3,
                child: Container(
                  padding: const EdgeInsets.all(20),
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Daftar Foto & Caption (Simulasi Sesuai Pilihan Grid)
                      if (widget.record.photos.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            'Belum ada foto yang ditambahkan.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else if (_photosPerPage == 4 && widget.record.photos.length > 1)
                        // Tampilan Grid 2 Kolom untuk mode 4 Foto
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: widget.record.photos.length,
                          itemBuilder: (ctx, idx) {
                            final photo = widget.record.photos[idx];
                            final file = File(photo.filePath);
                            return Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: file.existsSync()
                                          ? Image.file(file, fit: BoxFit.cover)
                                          : const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  photo.caption.isNotEmpty
                                      ? photo.caption
                                      : (photo.stage != null && photo.stage!.isNotEmpty
                                          ? 'Foto ${photo.stage}'
                                          : 'Foto #${idx + 1}'),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                      else
                        // Tampilan Vertikal Besar (1 atau 2 foto)
                        ...widget.record.photos.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final photo = entry.value;
                          final file = File(photo.filePath);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxHeight: _photosPerPage == 1 ? 400 : 280,
                                      maxWidth: double.infinity,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                        width: 1,
                                      ),
                                    ),
                                    child: file.existsSync()
                                        ? Image.file(file, fit: BoxFit.contain)
                                        : const Center(
                                            child: Icon(Icons.broken_image,
                                                size: 60, color: Colors.grey),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 6),
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
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                      const Divider(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kategori: ${widget.record.category}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'Standar: A4 (${_photosPerPage} Foto/Lembar)',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
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
