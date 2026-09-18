import 'package:latlong2/latlong.dart';
import 'media_item.dart';

/// 여행 스토리 도메인 모델 (어디에, 누구와, 어떤 경험을, 언제, 선별된 사진들)
class TravelStory {
  final int id;
  final String title; // 여행 기록 제목 (예: "안목해변 카페거리 산책")
  final String placeName; // 어디에 (장소명, 예: "강릉 안목해변")
  final String? companions; // 누구와 (예: "가족", "친구 민우", "혼자")
  final String? content; // 어떤 경험을 했는지 (감상 및 여행 메모)
  final DateTime eventDate; // 언제 (여행/방문 일자)
  final LatLng? location; // 장소 지도 좌표
  final List<String> mediaIds; // 선별된 사진/동영상 미디어 ID 리스트
  final String? coverMediaId; // 대표 커버 사진 ID
  final DateTime createdAt;
  final List<MediaItem> mediaItems; // 매핑된 MediaItem 객체 목록 (UI 편의용)

  const TravelStory({
    required this.id,
    required this.title,
    required this.placeName,
    this.companions,
    this.content,
    required this.eventDate,
    this.location,
    this.mediaIds = const [],
    this.coverMediaId,
    required this.createdAt,
    this.mediaItems = const [],
  });

  bool get hasLocation => location != null;

  TravelStory copyWith({
    int? id,
    String? title,
    String? placeName,
    String? companions,
    String? content,
    DateTime? eventDate,
    LatLng? location,
    List<String>? mediaIds,
    String? coverMediaId,
    DateTime? createdAt,
    List<MediaItem>? mediaItems,
  }) {
    return TravelStory(
      id: id ?? this.id,
      title: title ?? this.title,
      placeName: placeName ?? this.placeName,
      companions: companions ?? this.companions,
      content: content ?? this.content,
      eventDate: eventDate ?? this.eventDate,
      location: location ?? this.location,
      mediaIds: mediaIds ?? this.mediaIds,
      coverMediaId: coverMediaId ?? this.coverMediaId,
      createdAt: createdAt ?? this.createdAt,
      mediaItems: mediaItems ?? this.mediaItems,
    );
  }
}
