class WallpaperModel {
  const WallpaperModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.isLive,
    required this.eidLabel,
    this.createdAt,
  });

  final int id;
  final String name;
  final String imageUrl;
  final String thumbnailUrl;
  final bool isLive;
  final String eidLabel;
  final DateTime? createdAt;

  factory WallpaperModel.fromJson(Map<String, dynamic> json) {
    return WallpaperModel(
      id: _readInt(json['id']),
      name: json['name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString() ?? '',
      isLive: _readBool(json['is_live']),
      eidLabel: json['eid_label']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'is_live': isLive ? 1 : 0,
      'eid_label': eidLabel,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static int _readInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    final String normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }
}
