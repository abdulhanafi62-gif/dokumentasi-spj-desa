# Dokumentasi SPJ Desa (Aplikasi Mobile Android APK & iOS)

Aplikasi mobile khusus untuk mempermudah perangkat desa dalam membuat dokumentasi lampiran **SPJ (Surat Pertanggungjawaban)** kegiatan desa secara otomatis, rapi, dan cepat tanpa perlu memindahkan foto ke laptop dan mengedit manual di Microsoft Word.

---

## 🌟 Fitur Utama Aplikasi

1. **Format Kertas Standar A4**:
   - Seluruh dokumen otomatis diformat ke ukuran **A4**.
   - Posisi judul kegiatan tebal di bagian atas tengah:
     - Contoh: `DOKUMENTASI PENGADAAN PRINTER KANTOR DESA TAHUN 2026`.
   - Tanpa kop surat dan tanpa kolom tanda tangan (sesuai kebutuhan fleksibilitas SPJ desa Anda).
   - Penataan foto rapi (maksimal 2 foto per halaman) sehingga proporsi gambar tidak gepeng atau pecah.

2. **Dua Format Output Sekaligus**:
   - **PDF**: Siap langsung dicetak ke printer fisik (Wi-Fi/Bluetooth) atau dibagikan via WhatsApp.
   - **Microsoft Word (.docx)**: Dokumen Word asli standar OpenXML yang bisa dibuka dan diedit kembali di MS Word/WPS Office jika ada revisi teks.

3. **Kategori Kegiatan Terstruktur**:
   - **Pengadaan Barang**: Menghasilkan judul otomatis sesuai nama barang yang dibeli + foto-foto barang dan kuitansi.
   - **Pembangunan Fisik**: Dilengkapi slot bertahap resmi:
     - Titik 0% (Kondisi awal sebelum proyek dimulai)
     - Titik 50% (Proses pengerjaan fisik)
     - Titik 100% (Pekerjaan fisik selesai)
     - Serah Terima / Papan Prasasti Proyek
   - **Kegiatan Umum**: Bebas untuk rapat, musyawarah desa, penyaluran BLT, dll.

4. **Fitur Watermark Kamera Cerdas**:
   - Dapat diaktifkan / dimatikan sewaktu-waktu di menu **Pengaturan**.
   - Jika aktif, membubuhkan stempel resmi di bawah foto:
     - Nama Kegiatan
     - Tanggal & Waktu pemotretan (WIB/WITA/WIT)
     - Titik Koordinat GPS fisik (Latitude & Longitude)

5. **Bekerja 100% Offline**:
   - Tidak memerlukan koneksi internet untuk mengolah foto, membuat PDF, maupun Word.
   - Semua data tersimpan aman di memori smartphone.

---

## 📁 Struktur Kode Flutter

```
dokumentasi_spj_desa/
├── pubspec.yaml                       # Konfigurasi dependensi library
├── android/
│   └── app/src/main/AndroidManifest.xml # Izin kamera, galeri, dan GPS
└── lib/
    ├── main.dart                      # Titik awal aplikasi & inisialisasi lokal ID
    ├── models/
    │   ├── app_settings.dart          # Model pengaturan watermark & identitas desa
    │   ├── documentation_record.dart  # Model data dokumentasi SPJ
    │   └── photo_item.dart            # Model foto & koordinat GPS
    ├── services/
    │   ├── docx_generator_service.dart# Mesin pembuat file Microsoft Word (.docx)
    │   ├── pdf_generator_service.dart # Mesin pembuat file PDF & print preview A4
    │   ├── watermark_service.dart     # Mesin cap watermark teks & tanggal pada foto
    │   ├── location_service.dart      # Layanan GPS koordinat HP
    │   └── storage_service.dart       # Penyimpanan database lokal offline
    ├── screens/
    │   ├── home_screen.dart           # Halaman utama daftar dokumentasi & menu
    │   ├── create_documentation_screen.dart # Form input kegiatan & kamera
    │   ├── preview_export_screen.dart # Pratinjau cetak & tombol kirim PDF/Word
    │   └── settings_screen.dart       # Halaman pengaturan watermark & nama desa
    └── utils/
        └── app_theme.dart             # Tema warna resmi administrasi pemerintahan
```

---

## 🚀 Cara Menjalankan & Membuild File APK

### Langkah 1: Persiapan di Laptop
Pastikan di laptop Anda sudah terpasang:
1. **Flutter SDK** (versi 3.10 atau lebih baru)
2. **Android Studio** atau Android SDK Command-line Tools

### Langkah 2: Mengambil Dependensi Library
Buka terminal/PowerShell di folder proyek ini:
```powershell
cd "C:\Users\Asus GK\.gemini\antigravity\scratch\dokumentasi_spj_desa"
flutter pub get
```

### Langkah 3: Menjalankan di HP Fisik (Mode Pengujian)
1. Hubungkan HP Android Anda ke laptop dengan kabel USB.
2. Aktifkan **USB Debugging** di menu Opsi Pengembang (Developer Options) di HP.
3. Jalankan perintah:
```powershell
flutter run
```

### Langkah 4: Membuild File Installer APK
Untuk menghasilkan file `.apk` mandiri yang bisa dibagikan dan langsung diinstall di HP rekan-rekan perangkat desa:
```powershell
flutter build apk --release
```
Hasil file installer APK akan berada di:
`build/app/outputs/flutter-apk/app-release.apk`
Tinggal kirim file APK tersebut lewat WhatsApp Web ke HP Anda, lalu pasang (install)!

---

## ☁️ Opsi Build Otomatis Tanpa Beban Laptop (GitHub Actions)
Jika laptop Anda tidak ingin diisi Android Studio yang berukuran besar, proyek ini sudah siap dimasukkan ke repositori GitHub pribadi. Anda bisa mengaktifkan GitHub Actions gratis yang otomatis mengompilasi kode ini menjadi file `.apk` (dan `.ipa` untuk iPhone) dan langsung bisa Anda download!
