import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  bool _isLoading = true;

  final TextEditingController _villageCtrl = TextEditingController();
  final TextEditingController _yearCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await StorageService.loadSettings();
    _villageCtrl.text = _settings.villageName;
    _yearCtrl.text = _settings.defaultYear;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    _settings.villageName = _villageCtrl.text.trim();
    _settings.defaultYear = _yearCtrl.text.trim();
    await StorageService.saveSettings(_settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan berhasil disimpan!'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
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
        title: const Text('Pengaturan Aplikasi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bagian 1: Watermark Kamera
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Icon(Icons.branding_watermark,
                        color: AppTheme.primaryColor),
                    const SizedBox(width: 10),
                    const Text(
                      'Pengaturan Watermark Foto',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cap otomatis pada foto untuk bukti otentik kegiatan SPJ.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const Divider(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primaryColor,
                  title: const Text(
                    'Aktifkan Watermark',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(_settings.watermarkEnabled
                      ? 'Watermark akan dicap di bawah foto'
                      : 'Foto akan disimpan polos tanpa watermark'),
                  value: _settings.watermarkEnabled,
                  onChanged: (val) {
                    setState(() {
                      _settings.watermarkEnabled = val;
                    });
                    _saveSettings();
                  },
                ),
                if (_settings.watermarkEnabled) ...[
                  const Divider(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primaryColor,
                    title: const Text('Sertakan Tanggal & Jam'),
                    subtitle: const Text('Contoh: 21 Oktober 2026, 14:30 WIB'),
                    value: _settings.watermarkShowDateTime,
                    onChanged: (val) {
                      setState(() {
                        _settings.watermarkShowDateTime = val ?? true;
                      });
                      _saveSettings();
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primaryColor,
                    title: const Text('Sertakan Titik Koordinat GPS'),
                    subtitle: const Text('Lokasi latitude & longitude fisik'),
                    value: _settings.watermarkShowLocation,
                    onChanged: (val) {
                      setState(() {
                        _settings.watermarkShowLocation = val ?? true;
                      });
                      _saveSettings();
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primaryColor,
                    title: const Text('Sertakan Nama Kegiatan'),
                    value: _settings.watermarkShowActivity,
                    onChanged: (val) {
                      setState(() {
                        _settings.watermarkShowActivity = val ?? true;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bagian 2: Identitas Default
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_city,
                        color: AppTheme.primaryColor),
                    const SizedBox(width: 10),
                    const Text(
                      'Data Default Desa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _villageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Desa',
                    hintText: 'Contoh: Tanjung Manis',
                  ),
                  onChanged: (_) => _saveSettings(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _yearCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tahun Anggaran Default',
                    hintText: '2026',
                  ),
                  onChanged: (_) => _saveSettings(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bagian 3: Info Format SPJ
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Icon(Icons.description, color: AppTheme.primaryColor),
                    const SizedBox(width: 10),
                    const Text(
                      'Spesifikasi Format Dokumen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Ukuran Kertas', 'A4 (210 x 297 mm)'),
                _buildInfoRow('Kop Dokumen', 'Tanpa Kop Surat (Sesuai Permintaan)'),
                _buildInfoRow('Tanda Tangan', 'Tanpa Kolom TTD (Sesuai Permintaan)'),
                _buildInfoRow('Format Output', 'PDF & Word (.docx)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
