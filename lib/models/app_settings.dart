class AppSettings {
  bool watermarkEnabled;
  bool watermarkShowDateTime;
  bool watermarkShowLocation;
  bool watermarkShowActivity;
  String villageName;
  String districtName;
  String regencyName;
  String defaultYear;

  AppSettings({
    this.watermarkEnabled = true,
    this.watermarkShowDateTime = true,
    this.watermarkShowLocation = true,
    this.watermarkShowActivity = true,
    this.villageName = 'Tanjung Manis',
    this.districtName = '',
    this.regencyName = '',
    this.defaultYear = '2026',
  });

  Map<String, dynamic> toJson() => {
        'watermarkEnabled': watermarkEnabled,
        'watermarkShowDateTime': watermarkShowDateTime,
        'watermarkShowLocation': watermarkShowLocation,
        'watermarkShowActivity': watermarkShowActivity,
        'villageName': villageName,
        'districtName': districtName,
        'regencyName': regencyName,
        'defaultYear': defaultYear,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        watermarkEnabled: json['watermarkEnabled'] as bool? ?? true,
        watermarkShowDateTime: json['watermarkShowDateTime'] as bool? ?? true,
        watermarkShowLocation: json['watermarkShowLocation'] as bool? ?? true,
        watermarkShowActivity: json['watermarkShowActivity'] as bool? ?? true,
        villageName: json['villageName'] as String? ?? 'Tanjung Manis',
        districtName: json['districtName'] as String? ?? '',
        regencyName: json['regencyName'] as String? ?? '',
        defaultYear: json['defaultYear'] as String? ?? '2026',
      );
}
