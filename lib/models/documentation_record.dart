import 'photo_item.dart';

class DocumentationRecord {
  final String id;
  String title;
  String category; // 'Pengadaan Barang', 'Pembangunan Fisik', 'Kegiatan Umum'
  String activityName;
  String year;
  String location;
  final DateTime createdAt;
  List<PhotoItem> photos;

  DocumentationRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.activityName,
    required this.year,
    required this.location,
    required this.createdAt,
    required this.photos,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'activityName': activityName,
        'year': year,
        'location': location,
        'createdAt': createdAt.toIso8601String(),
        'photos': photos.map((p) => p.toJson()).toList(),
      };

  factory DocumentationRecord.fromJson(Map<String, dynamic> json) =>
      DocumentationRecord(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String? ?? 'Pengadaan Barang',
        activityName: json['activityName'] as String? ?? '',
        year: json['year'] as String? ?? '2026',
        location: json['location'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        photos: (json['photos'] as List<dynamic>?)
                ?.map((e) => PhotoItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
