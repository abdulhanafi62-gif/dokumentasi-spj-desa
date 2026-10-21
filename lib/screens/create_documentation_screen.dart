import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/app_settings.dart';
import '../models/documentation_record.dart';
import '../models/photo_item.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/watermark_service.dart';
import '../utils/app_theme.dart';
import 'preview_export_screen.dart';

class CreateDocumentationScreen extends StatefulWidget {
  final DocumentationRecord? initialRecord;

  const CreateDocumentationScreen({super.key, this.initialRecord});

  @override
  State<CreateDocumentationScreen> createState() =>
      _CreateDocumentationScreenState();
}

class _CreateDocumentationScreenState extends State<CreateDocumentationScreen> {
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  late AppSettings _settings;
  bool _isLoading = true;
  bool _isProcessingImage = false;

  String _selectedCategory = 'Pengadaan Barang';
  final TextEditingController _itemOrActivityCtrl = TextEditingController();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _yearCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();

  List<PhotoItem> _photos = [];

  final List<String> _categories = [
    'Pengadaan Barang',
    'Pembangunan Fisik',
    'Kegiatan Umum',
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _settings = await StorageService.loadSettings();

    if (widget.initialRecord != null) {
      final r = widget.initialRecord!;
      _selectedCategory = r.category;
      _itemOrActivityCtrl.text = r.activityName;
      _titleCtrl.text = r.title;
      _yearCtrl.text = r.year;
      _locationCtrl.text = r.location;
      _photos = List.from(r.photos);
    } else {
      _yearCtrl.text = _settings.defaultYear;
      _locationCtrl.text = 'Kantor Desa ${_settings.villageName}';
      _updateDefaultTitle();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _updateDefaultTitle() {
    final activity = _itemOrActivityCtrl.text.trim();
    final year = _yearCtrl.text.trim();
    final village = _settings.villageName;

    if (_selectedCategory == 'Pengadaan Barang') {
      final itemName = activity.isNotEmpty ? activity : 'Printer';
      _titleCtrl.text =
          'Dokumentasi Pengadaan $itemName Kantor Desa $village Tahun $year'
              .trim();
    } else if (_selectedCategory == 'Pembangunan Fisik') {
      final projectName =
          activity.isNotEmpty ? activity : 'Rabat Beton RT 01';
      _titleCtrl.text =
          'Dokumentasi Pembangunan $projectName Desa $village Tahun $year'
              .trim();
    } else {
      final act = activity.isNotEmpty ? activity : 'Kegiatan Desa';
      _titleCtrl.text =
          'Dokumentasi $act Desa $village Tahun $year'.trim();
    }
  }

  Future<void> _pickImage(ImageSource source, {String? stageLabel}) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 92,
      );
      if (picked == null) return;

      setState(() => _isProcessingImage = true);

      // Ambil koordinat GPS jika watermark aktif
      double? lat;
      double? lng;
      if (_settings.watermarkEnabled && _settings.watermarkShowLocation) {
        final position = await LocationService.getCurrentLocation();
        if (position != null) {
          lat = position.latitude;
          lng = position.longitude;
        }
      }

      // Beri watermark jika setting aktif
      final processedFile = await WatermarkService.applyWatermarkIfNeeded(
        originalFile: File(picked.path),
        settings: _settings,
        activityTitle: _titleCtrl.text.trim(),
        latitude: lat,
        longitude: lng,
      );

      final newPhoto = PhotoItem(
        id: _uuid.v4(),
        filePath: processedFile.path,
        caption: stageLabel != null ? 'Titik $stageLabel' : '',
        stage: stageLabel,
        timestamp: DateTime.now(),
        latitude: lat,
        longitude: lng,
      );

      setState(() {
        if (stageLabel != null) {
          final existingIdx = _photos.indexWhere((p) => p.stage == stageLabel);
          if (existingIdx >= 0) {
            _photos[existingIdx] = newPhoto;
          } else {
            _photos.add(newPhoto);
          }
        } else {
          _photos.add(newPhoto);
        }
        _isProcessingImage = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e')),
        );
      }
    }
  }

  void _showImageSourcePicker({String? stageLabel}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                title: const Text('Ambil dari Kamera HP (Langsung)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera, stageLabel: stageLabel);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.secondaryColor),
                title: const Text('Pilih dari Galeri Foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery, stageLabel: stageLabel);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAndPreview() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan judul dokumentasi!')),
      );
      return;
    }

    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap tambahkan minimal 1 foto kegiatan!')),
      );
      return;
    }

    final record = DocumentationRecord(
      id: widget.initialRecord?.id ?? _uuid.v4(),
      title: title,
      category: _selectedCategory,
      activityName: _itemOrActivityCtrl.text.trim(),
      year: _yearCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      createdAt: widget.initialRecord?.createdAt ?? DateTime.now(),
      photos: _photos,
    );

    // Simpan ke memori lokal HP
    await StorageService.saveRecord(record);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewExportScreen(record: record),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialRecord != null
            ? 'Edit Dokumentasi SPJ'
            : 'Buat Dokumentasi Baru'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Card Form Kategori & Data Utama
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jenis Kegiatan SPJ:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor.withOpacity(0.18),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedCategory = cat;
                                _updateDefaultTitle();
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(height: 24),
                    TextField(
                      controller: _itemOrActivityCtrl,
                      decoration: InputDecoration(
                        labelText: _selectedCategory == 'Pengadaan Barang'
                            ? 'Nama Barang yang Dibeli'
                            : 'Nama Proyek / Kegiatan',
                        hintText: _selectedCategory == 'Pengadaan Barang'
                            ? 'Contoh: Printer Kantor Desa'
                            : 'Contoh: Pembangunan Jalan Usaha Tani',
                      ),
                      onChanged: (_) => _updateDefaultTitle(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Judul Lengkap Dokumen (Di Atas Kertas A4)',
                        helperText:
                            'Judul ini akan dicetak di bagian paling atas lembar A4.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _yearCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Tahun Anggaran',
                            ),
                            onChanged: (_) => _updateDefaultTitle(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _locationCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Lokasi Kegiatan',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
              const SizedBox(height: 16),

              // Bagian Pengambilan Foto
              if (_selectedCategory == 'Pembangunan Fisik')
                _buildPhysicalProjectStages()
              else
                _buildGeneralPhotoList(),

              const SizedBox(height: 24),

              // Tombol Simpan & Pratinjau
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Simpan & Lihat Hasil Dokumen (PDF/Word)'),
                onPressed: _saveAndPreview,
              ),
              const SizedBox(height: 30),
            ],
          ),

          if (_isProcessingImage)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(AppTheme.primaryColor),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Memproses foto & watermark...',
                          style: TextStyle(fontWeight: FontWeight.w600),
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

  /// Tampilan khusus pembangunan fisik bertahap: 0%, 50%, 100%, Serah Terima
  Widget _buildPhysicalProjectStages() {
    final stages = [
      {'label': 'Titik 0%', 'desc': 'Kondisi awal sebelum proyek dimulai'},
      {'label': 'Titik 50%', 'desc': 'Proses pengerjaan fisik berlangsung'},
      {'label': 'Titik 100%', 'desc': 'Pekerjaan fisik telah selesai'},
      {'label': 'Serah Terima', 'desc': 'Serah terima / papan prasasti proyek'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dokumentasi Bertahap Pembangunan Fisik:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            ...stages.map((stage) {
              final stageName = stage['label']!;
              final desc = stage['desc']!;
              final existingPhoto = _photos.firstWhere(
                (p) => p.stage == stageName,
                orElse: () => PhotoItem(
                  id: '',
                  filePath: '',
                  caption: '',
                  timestamp: DateTime.now(),
                ),
              );

              final bool hasPhoto = existingPhoto.filePath.isNotEmpty &&
                  File(existingPhoto.filePath).existsSync();

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    // Kotak Foto
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: hasPhoto
                            ? Image.file(
                                File(existingPhoto.filePath),
                                fit: BoxFit.cover,
                              )
                            : Icon(Icons.camera_alt,
                                size: 36, color: Colors.grey.shade500),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Keterangan
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stageName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            desc,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: AppTheme.primaryColor,
                            ),
                            icon: Icon(
                                hasPhoto ? Icons.edit : Icons.add_a_photo,
                                size: 16),
                            label: Text(hasPhoto ? 'Ubah Foto' : 'Ambil Foto'),
                            onPressed: () => _showImageSourcePicker(
                                stageLabel: stageName),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Tampilan daftar foto fleksibel untuk Pengadaan Barang & Umum
  Widget _buildGeneralPhotoList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Foto Dokumentasi:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.add_a_photo, size: 18),
                  label: const Text('Tambah Foto'),
                  onPressed: () => _showImageSourcePicker(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_photos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.photo_camera_outlined,
                        size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada foto yang ditambahkan.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'Tekan "Tambah Foto" untuk foto barang / kegiatan.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ..._photos.asMap().entries.map((entry) {
                final idx = entry.key;
                final photo = entry.value;
                final file = File(photo.filePath);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: file.existsSync()
                              ? Image.file(file, fit: BoxFit.cover)
                              : const Icon(Icons.broken_image,
                                  color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Edit Caption
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Foto #${idx + 1}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              initialValue: photo.caption,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                hintText: 'Keterangan di bawah foto...',
                              ),
                              onChanged: (val) {
                                photo.caption = val;
                              },
                            ),
                          ],
                        ),
                      ),
                      // Hapus
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _photos.removeAt(idx);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
