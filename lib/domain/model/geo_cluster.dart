import 'package:latlong2/latlong.dart';
import 'media_item.dart';

/// 동일/근접 위치에 있는 미디어들의 그룹 클러스터
class GeoCluster {
  final String id;
  final LatLng location;
  final List<MediaItem> items;

  GeoCluster({
    required this.id,
    required this.location,
    required this.items,
  });

  /// 대표 미디어 (가장 최신 사진)
  MediaItem get representativeItem => items.first;

  /// 포함된 미디어 개수
  int get count => items.length;

  /// 단일 사진인지 여부
  bool get isSingle => items.length == 1;
}
