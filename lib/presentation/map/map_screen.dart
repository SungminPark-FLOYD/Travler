import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/model/media_item.dart';
import '../providers/media_provider.dart';
import '../widgets/media_detail_sheet.dart';
import '../widgets/media_thumbnail.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  static const LatLng _initialCenter = LatLng(37.5665, 126.9780); // 서울 시청 기본 좌표

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(mediaListProvider);
    final geoMediaList = ref.watch(geoMediaListProvider);
    final clusters = ref.watch(geoClustersProvider);
    final currentFilter = ref.watch(mediaTypeFilterProvider);

    // 전체 위치 미디어 중 사진/동영상 개수 계산
    final allGeoList = mediaAsync.maybeWhen(
      data: (items) => items.where((it) => it.hasLocation).toList(),
      orElse: () => <MediaItem>[],
    );
    final totalGeoCount = allGeoList.length;
    final photoGeoCount = allGeoList.where((it) => it.type == MediaItemType.image).length;
    final videoGeoCount = allGeoList.where((it) => it.type == MediaItemType.video).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.explore_outlined, color: Color(0xFF2E66E7)),
            const SizedBox(width: 8),
            const Text('Travel Map', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2E66E7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${clusters.length}곳 (${geoMediaList.length})',
                style: const TextStyle(fontSize: 12, color: Color(0xFF2E66E7), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: '첫 사진 위치로 이동',
            onPressed: () {
              if (clusters.isNotEmpty) {
                _mapController.move(clusters.first.location, 14.0);
              } else {
                _mapController.move(_initialCenter, 14.0);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '미디어 새로고침',
            onPressed: () {
              ref.read(mediaListProvider.notifier).scanMedia();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: clusters.isNotEmpty ? clusters.first.location : _initialCenter,
              initialZoom: 13.0,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.travler.travler',
              ),
              // 기기 사진/동영상 위치 클러스터 마커 레이어
              MarkerLayer(
                markers: clusters.map((cluster) {
                  final isVideoCluster = cluster.items.every((it) => it.type == MediaItemType.video);
                  final hasVideo = cluster.items.any((it) => it.type == MediaItemType.video);

                  return Marker(
                    point: cluster.location,
                    width: 62,
                    height: 62,
                    child: GestureDetector(
                      onTap: () => MediaDetailSheet.show(context, cluster.items),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isVideoCluster ? Colors.orangeAccent : Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: MediaThumbnail(
                                  item: cluster.representativeItem,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          // 동영상 뱃지
                          if (hasVideo)
                            Positioned(
                              bottom: 2,
                              left: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow, size: 12, color: Colors.white),
                              ),
                            ),
                          // 복수 사진 카운트 뱃지
                          if (cluster.count > 1)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E66E7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Text(
                                  '+${cluster.count}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 상단 플로팅 미디어 필터 칩 바 [전체 / 사진만 / 동영상만]
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _FilterChipItem(
                    label: '전체 ($totalGeoCount)',
                    icon: Icons.all_inclusive,
                    isSelected: currentFilter == MediaTypeFilter.all,
                    onTap: () {
                      ref.read(mediaTypeFilterProvider.notifier).state = MediaTypeFilter.all;
                    },
                  ),
                  _FilterChipItem(
                    label: '사진 ($photoGeoCount)',
                    icon: Icons.photo_outlined,
                    isSelected: currentFilter == MediaTypeFilter.photosOnly,
                    onTap: () {
                      ref.read(mediaTypeFilterProvider.notifier).state = MediaTypeFilter.photosOnly;
                    },
                  ),
                  _FilterChipItem(
                    label: '동영상 ($videoGeoCount)',
                    icon: Icons.videocam_outlined,
                    isSelected: currentFilter == MediaTypeFilter.videosOnly,
                    activeColor: Colors.orange,
                    onTap: () {
                      ref.read(mediaTypeFilterProvider.notifier).state = MediaTypeFilter.videosOnly;
                    },
                  ),
                ],
              ),
            ),
          ),

          // 스캔 중 표시
          if (mediaAsync.isLoading)
            const Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '기기 미디어 스캔 중...',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 위치 사진이 없는 경우 안내
          if (clusters.isEmpty && !mediaAsync.isLoading)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF2E66E7)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          currentFilter == MediaTypeFilter.videosOnly
                              ? '위치 정보가 포함된 동영상이 없습니다.\n타임라인 탭에서 수동으로 위치를 등록할 수 있습니다.'
                              : '위치 정보가 포함된 미디어가 지도에 표시됩니다.\n타임라인 탭에서 위치가 없는 사진/동영상에 위치를 등록할 수도 있습니다.',
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;

  const _FilterChipItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = activeColor ?? const Color(0xFF2E66E7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? effectiveColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? effectiveColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? effectiveColor : Colors.grey.shade600),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? effectiveColor : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
