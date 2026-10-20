class PhotoItem {
  final String id;
  final String filePath;
  String caption;
  String? stage; // Contoh: '0%', '50%', '100%', 'Serah Terima', 'Pengadaan'
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;

  PhotoItem({
    required this.id,
    required this.filePath,
    required this.caption,
    this.stage,
    required this.timestamp,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'caption': caption,
        'stage': stage,
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
      };

  factory PhotoItem.fromJson(Map<String, dynamic> json) => PhotoItem(
        id: json['id'] as String,
        filePath: json['filePath'] as String,
        caption: json['caption'] as String? ?? '',
        stage: json['stage'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}
