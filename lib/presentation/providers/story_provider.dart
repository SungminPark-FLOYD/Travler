import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/local/app_database.dart';
import '../../domain/model/media_item.dart';
import '../../domain/model/travel_story.dart';
import 'media_provider.dart';

/// 여행 스토리 목록 Notifier
class StoryListNotifier extends StateNotifier<AsyncValue<List<TravelStory>>> {
  final AppDatabase _db;
  final Ref _ref;

  StoryListNotifier(this._db, this._ref) : super(const AsyncValue.loading()) {
    loadStories();
  }

  /// 전체 스토리 불러오기 (미디어 아이템 매핑 포함 - Null 안전성 100% 보장)
  Future<void> loadStories() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final rawStories = await _db.getAllStories();
      final allMediaMap = _ref.read(mediaListProvider).maybeWhen(
            data: (items) => {for (var it in items) it.id: it},
            orElse: () => <String, MediaItem>{},
          );

      return rawStories.map((story) {
        final List<MediaItem> resolvedItems = story.mediaIds.map((id) {
          final found = allMediaMap[id];
          if (found != null) return found;
          // 미디어가 아직 스캔 중이거나 누락된 경우에도 절대 Null이 리스트에 유입되지 않도록 안전한 fallback 객체 생성
          return MediaItem(
            id: id,
            type: MediaItemType.image,
            shotAt: story.eventDate,
            width: 0,
            height: 0,
          );
        }).toList();

        return story.copyWith(
          mediaItems: resolvedItems,
        );
      }).toList();
    });
  }

  /// 새 여행 스토리 작성
  Future<int> createStory({
    required String title,
    required String placeName,
    String? companions,
    String? content,
    required DateTime eventDate,
    LatLng? location,
    required List<String> mediaIds,
    String? coverMediaId,
  }) async {
    final storyId = await _db.insertStory(
      title: title,
      placeName: placeName,
      companions: companions,
      content: content,
      eventDate: eventDate,
      location: location,
      mediaIds: mediaIds,
      coverMediaId: coverMediaId,
    );

    await loadStories();
    return storyId;
  }

  /// 기존 스토리 수정
  Future<void> updateStory({
    required int id,
    required String title,
    required String placeName,
    String? companions,
    String? content,
    required DateTime eventDate,
    LatLng? location,
    required List<String> mediaIds,
    String? coverMediaId,
  }) async {
    await _db.updateStory(
      id: id,
      title: title,
      placeName: placeName,
      companions: companions,
      content: content,
      eventDate: eventDate,
      location: location,
      mediaIds: mediaIds,
      coverMediaId: coverMediaId,
    );

    await loadStories();
  }

  /// 스토리 삭제
  Future<void> deleteStory(int id) async {
    await _db.deleteStory(id);
    state = state.whenData((list) => list.where((s) => s.id != id).toList());
  }
}

final storyListProvider = StateNotifierProvider<StoryListNotifier, AsyncValue<List<TravelStory>>>((ref) {
  final db = ref.watch(databaseProvider);
  return StoryListNotifier(db, ref);
});

/// 지도에 표출할 위치(GPS)가 있는 여행 스토리 목록
final geoStoryListProvider = Provider<List<TravelStory>>((ref) {
  final storiesAsync = ref.watch(storyListProvider);
  return storiesAsync.maybeWhen(
    data: (stories) => stories.where((s) => s.hasLocation).toList(),
    orElse: () => [],
  );
});

/// 등록된 모든 동행인 고유 태그 목록 (필터 칩용)
final companionTagsProvider = Provider<List<String>>((ref) {
  final storiesAsync = ref.watch(storyListProvider);
  return storiesAsync.maybeWhen(
    data: (stories) {
      final Set<String> tags = {};
      for (final s in stories) {
        if (s.companions != null && s.companions!.trim().isNotEmpty) {
          final parts = s.companions!.split(RegExp(r'[,/ ]+'));
          for (final p in parts) {
            final trimmed = p.trim();
            if (trimmed.isNotEmpty) tags.add(trimmed);
          }
        }
      }
      return tags.toList()..sort();
    },
    orElse: () => [],
  );
});
