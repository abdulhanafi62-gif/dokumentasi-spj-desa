import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import '../models/app_settings.dart';

class WatermarkService {
  /// Membubuhkan watermark pada foto jika diaktifkan di pengaturan
  static Future<File> applyWatermarkIfNeeded({
    required File originalFile,
    required AppSettings settings,
    required String activityTitle,
    double? latitude,
    double? longitude,
  }) async {
    // Jika watermark dimatikan di setting, kembalikan file asli tanpa diubah
    if (!settings.watermarkEnabled) {
      return originalFile;
    }

    try {
      final bytes = await originalFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return originalFile;

      // Orientasikan gambar dengan benar jika ada EXIF orientation
      image = img.bakeOrientation(image);

      final int width = image.width;
      final int height = image.height;

      // Susun baris-baris informasi watermark
      final List<String> lines = [];

      if (settings.watermarkShowActivity && activityTitle.isNotEmpty) {
        lines.add('Kegiatan: $activityTitle');
      }

      if (settings.watermarkShowDateTime) {
        final now = DateTime.now();
        final formattedDate =
            DateFormat('dd MMMM yyyy, HH:mm:ss', 'id_ID').format(now);
        lines.add('Waktu: $formattedDate WIB');
      }

      if (settings.watermarkShowLocation &&
          latitude != null &&
          longitude != null) {
        lines.add(
            'GPS: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}');
      }

      if (lines.isEmpty) {
        return originalFile;
      }

      // Tentukan ukuran font dan tinggi watermark bar
      final font = width > 1200 ? img.arial48 : img.arial24;
      final int lineHeight = font.lineHeight + 10;
      final int boxPadding = 20;
      final int boxHeight = (lines.length * lineHeight) + (boxPadding * 2);
      final int boxY = height - boxHeight;

      // Gambar kotak transparan hitam di bagian bawah foto
      img.fillRect(
        image,
        x1: 0,
        y1: boxY > 0 ? boxY : 0,
        x2: width,
        y2: height,
        color: img.ColorRgba8(0, 0, 0, 160),
      );

      // Gambar teks putih di atas kotak transparan
      for (int i = 0; i < lines.length; i++) {
        final currentY = boxY + boxPadding + (i * lineHeight);
        img.drawString(
          image,
          lines[i],
          font: font,
          x: boxPadding,
          y: currentY,
          color: img.ColorRgba8(255, 255, 255, 255),
        );
      }

      // Simpan kembali foto hasil watermark ke path baru
      final stampedPath = originalFile.path.replaceAll(
        RegExp(r'\.(jpe?g|png)$', caseSensitive: false),
        '_watermarked.jpg',
      );
      final stampedBytes = img.encodeJpg(image, quality: 88);
      final stampedFile = File(stampedPath);
      await stampedFile.writeAsBytes(stampedBytes);

      return stampedFile;
    } catch (_) {
      // Jika terjadi kendala saat memproses gambar, tetap gunakan file asli
      return originalFile;
    }
  }
}
