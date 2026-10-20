import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_settings.dart';
import '../models/documentation_record.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import 'create_documentation_screen.dart';
import 'preview_export_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DocumentationRecord> _records = [];
  AppSettings _settings = AppSettings();
  bool _isLoading = true;
  String _activeFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final settings = await StorageService.loadSettings();
    final records = await StorageService.loadRecords();
    setState(() {
      _settings = settings;
      _records = records;
      _isLoading = false;
    });
  }

  List<DocumentationRecord> get _filteredRecords {
    if (_activeFilter == 'Semua') return _records;
    return _records.where((r) => r.category == _activeFilter).toList();
  }

  Future<void> _deleteRecord(DocumentationRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dokumentasi?'),
        content: Text('Apakah Anda yakin ingin menghapus "${record.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.deleteRecord(record.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokumentasi SPJ Desa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan & Watermark',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadData();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Buat SPJ Baru'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateDocumentationScreen(),
            ),
          );
          _loadData();
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Banner Header Desa
                  Card(
                    color: AppTheme.primaryColor,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance,
                                size: 36, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pemerintah Desa ${_settings.villageName}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tahun Anggaran ${_settings.defaultYear} • Format Kertas A4',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Kategori
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Semua',
                        'Pengadaan Barang',
                        'Pembangunan Fisik',
                        'Kegiatan Umum',
                      ].map((filter) {
                        final isSelected = _activeFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (_) {
                              setState(() => _activeFilter = filter);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Daftar Dokumentasi SPJ
                  if (_filteredRecords.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 60, horizontal: 20),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum Ada Dokumentasi SPJ',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tekan tombol "+ Buat SPJ Baru" di bawah untuk mulai memfoto dan membuat dokumen PDF & Word.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._filteredRecords.map((record) {
                      final firstPhoto = record.photos.isNotEmpty &&
                              File(record.photos.first.filePath).existsSync()
                          ? File(record.photos.first.filePath)
                          : null;

                      final formattedDate = DateFormat('dd MMM yyyy, HH:mm')
                          .format(record.createdAt);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PreviewExportScreen(record: record),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Thumbnail Foto Pertama
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 75,
                                    height: 75,
                                    color: Colors.grey.shade200,
                                    child: firstPhoto != null
                                        ? Image.file(firstPhoto,
                                            fit: BoxFit.cover)
                                        : const Icon(Icons.description,
                                            color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Detail Informasi
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Badge Kategori
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryColor
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          record.category,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.secondaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        record.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$formattedDate • ${record.photos.length} Foto',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Aksi Menu Titik Tiga
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert,
                                      color: Colors.grey),
                                  onSelected: (val) async {
                                    if (val == 'preview') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PreviewExportScreen(
                                              record: record),
                                        ),
                                      );
                                    } else if (val == 'edit') {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CreateDocumentationScreen(
                                                  initialRecord: record),
                                        ),
                                      );
                                      _loadData();
                                    } else if (val == 'delete') {
                                      _deleteRecord(record);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'preview',
                                      child: Row(
                                        children: [
                                          Icon(Icons.print,
                                              size: 18, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Ekspor / Cetak'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit,
                                              size: 18, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('Ubah Data / Foto'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete,
                                              size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Hapus'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 80), // Padding untuk FloatingActionButton
                ],
              ),
            ),
    );
  }
}
