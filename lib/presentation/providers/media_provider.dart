import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/local/app_database.dart';
import '../../data/services/media_scanner_service.dart';
import '../../domain/model/geo_cluster.dart';
import '../../domain/model/media_item.dart';

/// 미디어 타입 필터 (전체, 사진만, 동영상만)
enum MediaTypeFilter { all, photosOnly, videosOnly }

/// 현재 선택된 미디어 타입 필터 프로바이더
final mediaTypeFilterProvider = StateProvider<MediaTypeFilter>((ref) => MediaTypeFilter.all);

/// 로컬 SQLite 데이터베이스 프로바이더
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// 미디어 스캐너 서비스 프로바이더
final mediaScannerServiceProvider = Provider<MediaScannerService>((ref) {
  final db = ref.watch(databaseProvider);
  return MediaScannerService(db);
});

/// 전체 미디어 로딩 및 관리 상태 Notifier
class MediaListNotifier extends StateNotifier<AsyncValue<List<MediaItem>>> {
  final MediaScannerService _scannerService;
  final AppDatabase _db;

  MediaListNotifier(this._scannerService, this._db) : super(const AsyncValue.loading()) {
    scanMedia();
  }

  /// 2단계 점진적 스캔 실행:
  /// 1. 초고속 초기 스캔 (최신 80장): 0.1~0.2초 이내에 UI에 즉각 표출
  /// 2. 백그라운드 잔여 스캔: 화면이 뜬 상태에서 나머지 사진들을 부드럽게 병합
  Future<void> scanMedia() async {
    state = const AsyncValue.loading();
    try {
      final initialItems = await _scannerService.scanInitialMedia(count: 80);
      state = AsyncValue.data(initialItems);

      // 백그라운드에서 잔여 미디어 추가 로드
      final remainingItems = await _scannerService.scanRemainingMedia(start: 80, maxCount: 1000);
      if (remainingItems.isNotEmpty) {
        final existingIds = initialItems.map((e) => e.id).toSet();
        final filteredRemaining = remainingItems.where((e) => !existingIds.contains(e.id)).toList();
        state = AsyncValue.data([...initialItems, ...filteredRemaining]);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 미디어에 코멘트 추가
  Future<void> addComment(String mediaId, String content) async {
    await _db.addComment(mediaId, content);
    state = state.whenData((items) {
      return items.map((item) {
        if (item.id == mediaId) {
          return item.copyWith(
            comments: [...item.comments, content],
          );
        }
        return item;
      }).toList();
    });
  }

  /// 미디어 코멘트 수정
  Future<void> updateComment(String mediaId, int index, String oldContent, String newContent) async {
    await _db.updateCommentContent(mediaId, oldContent, newContent);
    state = state.whenData((items) {
      return items.map((item) {
        if (item.id == mediaId) {
          final updated = List<String>.from(item.comments);
          if (index >= 0 && index < updated.length) {
            updated[index] = newContent;
          }
          return item.copyWith(comments: updated);
        }
        return item;
      }).toList();
    });
  }

  /// 미디어 코멘트 삭제
  Future<void> deleteComment(String mediaId, int index, String content) async {
    await _db.deleteCommentByContent(mediaId, content);
    state = state.whenData((items) {
      return items.map((item) {
        if (item.id == mediaId) {
          final updated = List<String>.from(item.comments);
          if (index >= 0 && index < updated.length) {
            updated.removeAt(index);
          }
          return item.copyWith(comments: updated);
        }
        return item;
      }).toList();
    });
  }

  /// 미디어 위치 수동 지정/수정
  Future<void> updateLocation(String mediaId, LatLng newLocation) async {
    await _db.setManualLocation(mediaId, newLocation.latitude, newLocation.longitude);
    state = state.whenData((items) {
      return items.map((item) {
        if (item.id == mediaId) {
          return item.copyWith(location: newLocation);
        }
        return item;
      }).toList();
    });
  }

  /// 특정 미디어를 지도 및 타임라인에서 숨김 처리
  Future<void> hideMedia(String mediaId) async {
    await _db.hideMedia(mediaId);
    state = state.whenData((items) => items.where((it) => it.id != mediaId).toList());
  }

  /// 숨김 해제 (복원)
  Future<void> unhideMedia(String mediaId) async {
    await _db.unhideMedia(mediaId);
    await scanMedia();
  }
}

final mediaListProvider = StateNotifierProvider<MediaListNotifier, AsyncValue<List<MediaItem>>>((ref) {
  final scanner = ref.watch(mediaScannerServiceProvider);
  final db = ref.watch(databaseProvider);
  return MediaListNotifier(scanner, db);
});

/// 지도로 표출할 GPS 위치 보유 미디어 필터링 프로바이더 (타입 필터 적용)
final geoMediaListProvider = Provider<List<MediaItem>>((ref) {
  final mediaAsync = ref.watch(mediaListProvider);
  final filter = ref.watch(mediaTypeFilterProvider);

  return mediaAsync.maybeWhen(
    data: (items) {
      return items.where((item) {
        if (!item.hasLocation) return false;
        switch (filter) {
          case MediaTypeFilter.all:
            return true;
          case MediaTypeFilter.photosOnly:
            return item.type == MediaItemType.image;
          case MediaTypeFilter.videosOnly:
            return item.type == MediaItemType.video;
        }
      }).toList();
    },
    orElse: () => [],
  );
});

/// 동일/근접 좌표(반경 50m 이내) 미디어들을 클러스터로 그룹화한 프로바이더
final geoClustersProvider = Provider<List<GeoCluster>>((ref) {
  final geoItems = ref.watch(geoMediaListProvider);
  if (geoItems.isEmpty) return [];

  const distanceCalculator = Distance();
  const double clusterRadiusMeters = 50.0; // 50m 이내 사진은 하나의 대표 핀으로 묶음

  final List<GeoCluster> clusters = [];

  for (final item in geoItems) {
    bool addedToExisting = false;

    for (final cluster in clusters) {
      final distance = distanceCalculator.as(
        LengthUnit.Meter,
        cluster.location,
        item.location!,
      );

      if (distance <= clusterRadiusMeters) {
        cluster.items.add(item);
        addedToExisting = true;
        break;
      }
    }

    if (!addedToExisting) {
      clusters.add(
        GeoCluster(
          id: 'cluster_${item.id}',
          location: item.location!,
          items: [item],
        ),
      );
    }
  }

  return clusters;
});

/// 숨긴 미디어 ID 목록 프로바이더
final hiddenMediaIdsProvider = FutureProvider<Set<String>>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.getHiddenMediaIds();
});
