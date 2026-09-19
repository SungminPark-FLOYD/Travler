import 'package:latlong2/latlong.dart';

enum MediaItemType {
  image,
  video,
}

class MediaItem {
  final String id;
  final String? filePath; // 직접 선택하거나 공유받은 로컬 파일 경로 (File 지원)
  final String? title;
  final MediaItemType type;
  final LatLng? location;
  final DateTime shotAt;
  final int duration; // 동영상 재생 길이(초), 사진은 0
  final int width;
  final int height;
  final String? address; // 역지오코딩된 주소/지역명
  final List<String> comments;

  const MediaItem({
    required this.id,
    this.filePath,
    this.title,
    required this.type,
    this.location,
    required this.shotAt,
    this.duration = 0,
    required this.width,
    required this.height,
    this.address,
    this.comments = const [],
  });

  bool get hasLocation => location != null;

  MediaItem copyWith({
    String? id,
    String? filePath,
    String? title,
    MediaItemType? type,
    LatLng? location,
    DateTime? shotAt,
    int? duration,
    int? width,
    int? height,
    String? address,
    List<String>? comments,
  }) {
    return MediaItem(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      type: type ?? this.type,
      location: location ?? this.location,
      shotAt: shotAt ?? this.shotAt,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      address: address ?? this.address,
      comments: comments ?? this.comments,
    );
  }
}
