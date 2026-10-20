import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/documentation_record.dart';

class StorageService {
  static const String _keyRecords = 'spj_records_list';
  static const String _keySettings = 'spj_app_settings';

  /// Simpan pengaturan aplikasi
  static Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySettings, jsonEncode(settings.toJson()));
  }

  /// Ambil pengaturan aplikasi
  static Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keySettings);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(jsonString);
        return AppSettings.fromJson(map);
      } catch (_) {}
    }
    return AppSettings();
  }

  /// Ambil seluruh riwayat dokumentasi
  static Future<List<DocumentationRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyRecords);
    if (jsonString != null) {
      try {
        final List<dynamic> list = jsonDecode(jsonString);
        return list
            .map((item) =>
                DocumentationRecord.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    return [];
  }

  /// Simpan satu data dokumentasi baru atau perbarui
  static Future<void> saveRecord(DocumentationRecord record) async {
    final records = await loadRecords();
    final existingIndex = records.indexWhere((r) => r.id == record.id);
    if (existingIndex >= 0) {
      records[existingIndex] = record;
    } else {
      records.insert(0, record);
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonList = records.map((r) => r.toJson()).toList();
    await prefs.setString(_keyRecords, jsonEncode(jsonList));
  }

  /// Hapus satu dokumentasi
  static Future<void> deleteRecord(String id) async {
    final records = await loadRecords();
    records.removeWhere((r) => r.id == id);
    final prefs = await SharedPreferences.getInstance();
    final jsonList = records.map((r) => r.toJson()).toList();
    await prefs.setString(_keyRecords, jsonEncode(jsonList));
  }
}
