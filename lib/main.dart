import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi format tanggal bahasa Indonesia (contoh: 21 Oktober 2026)
  await initializeDateFormatting('id_ID', null);

  runApp(const SpjDokumentasiApp());
}

class SpjDokumentasiApp extends StatelessWidget {
  const SpjDokumentasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dokumentasi SPJ Desa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
