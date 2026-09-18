import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/model/media_item.dart';
import '../../domain/model/travel_story.dart';
import '../providers/media_provider.dart';
import '../providers/story_provider.dart';
import '../story/story_detail_sheet.dart';
import '../story/story_editor_sheet.dart';
import '../widgets/media_detail_sheet.dart';
import '../widgets/media_thumbnail.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<String> _selectedMediaIds = {};
  bool _isSelectionMode = false;
  String? _selectedCompanionFilter;
  MediaTypeFilter _galleryFilter = MediaTypeFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleMediaSelection(String mediaId) {
    setState(() {
      if (_selectedMediaIds.contains(mediaId)) {
        _selectedMediaIds.remove(mediaId);
        if (_selectedMediaIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMediaIds.add(mediaId);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMediaIds.clear();
      _isSelectionMode = false;
    });
  }

  void _openStoryEditorWithSelected(List<MediaItem> allItems) {
    final selectedItems = allItems.where((it) => _selectedMediaIds.contains(it.id)).toList();
    if (selectedItems.isEmpty) return;

    _clearSelection();
    StoryEditorSheet.show(context, selectedMedia: selectedItems);
  }

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final mediaListAsync = ref.watch(mediaListProvider);
    final storiesAsync = ref.watch(storyListProvider);
    final companionTags = ref.watch(companionTagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedMediaIds.length}장 선택됨', style: const TextStyle(fontWeight: FontWeight.bold))
            : const Text('여행 아카이브', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : null,
        actions: [
          if (_isSelectionMode)
            mediaListAsync.maybeWhen(
              data: (items) => TextButton.icon(
                icon: const Icon(Icons.auto_stories, color: Color(0xFF2E66E7)),
                label: const Text('기록 만들기', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E66E7))),
                onPressed: () => _openStoryEditorWithSelected(items),
              ),
              orElse: () => const SizedBox.shrink(),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '새로고침',
              onPressed: () {
                ref.read(mediaListProvider.notifier).scanMedia();
                ref.read(storyListProvider.notifier).loadStories();
              },
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2E66E7),
          labelColor: const Color(0xFF2E66E7),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.auto_stories_outlined), text: '나의 여행 발자국'),
            Tab(icon: Icon(Icons.photo_library_outlined), text: '기기 갤러리'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. 나의 여행 발자국 (Stories Feed)
          _buildStoriesTab(storiesAsync, companionTags),

          // 2. 기기 갤러리 타임라인 (선택하여 여행 기록 만들기 + 사진/동영상 필터)
          _buildGalleryTab(mediaListAsync),
        ],
      ),
      floatingActionButton: !_isSelectionMode
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF2E66E7),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: const Text('새 여행 기록'),
              onPressed: () {
                _tabController.animateTo(1);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('여행 기록에 담을 사진/동영상을 길게 누르거나 터치하여 선택해 주세요.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            )
          : null,
    );
  }

  // =========================================================
  // 1. 여행 스토리 피드 탭
  // =========================================================
  Widget _buildStoriesTab(AsyncValue<List<TravelStory>> storiesAsync, List<String> companionTags) {
    return storiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('기록을 불러오지 못했습니다: $err')),
      data: (stories) {
        if (stories.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E66E7).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_stories, size: 56, color: Color(0xFF2E66E7)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '아직 등록된 여행 발자국이 없습니다.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '기기 갤러리에서 원하는 사진들을 선택하여\n어디서, 누구와, 어떤 경험을 했는지 기록해 보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('갤러리에서 사진 골라 기록하기'),
                    onPressed: () => _tabController.animateTo(1),
                  ),
                ],
              ),
            ),
          );
        }

        final filteredStories = _selectedCompanionFilter == null
            ? stories
            : stories.where((s) => s.companions != null && s.companions!.contains(_selectedCompanionFilter!)).toList();

        final dateFormat = DateFormat('yyyy년 MM월 dd일');

        return Column(
          children: [
            // 동행인 필터 칩 바
            if (companionTags.isNotEmpty)
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: const Text('전체 보기'),
                        selected: _selectedCompanionFilter == null,
                        onSelected: (_) => setState(() => _selectedCompanionFilter = null),
                      ),
                    ),
                    ...companionTags.map((tag) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          avatar: const Icon(Icons.people_outline, size: 14),
                          label: Text(tag),
                          selected: _selectedCompanionFilter == tag,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCompanionFilter = selected ? tag : null;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),

            // 스토리 카드 리스트
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredStories.length,
                itemBuilder: (context, index) {
                  final story = filteredStories[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => StoryDetailSheet.show(context, story),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 대표 사진 영역
                          if (story.coverMediaId != null)
                            SizedBox(
                              height: 180,
                              width: double.infinity,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  MediaThumbnail(
                                    item: MediaItem(
                                      id: story.coverMediaId!,
                                      type: MediaItemType.image,
                                      shotAt: story.eventDate,
                                      width: 800,
                                      height: 600,
                                    ),
                                    highQuality: true,
                                    fit: BoxFit.cover,
                                  ),
                                  // 사진 매수 배지
                                  Positioned(
                                    right: 12,
                                    bottom: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.photo_camera, size: 12, color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${story.mediaIds.length}장',
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // 지도 연동 배지
                                  if (story.hasLocation)
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2E66E7).withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.place, size: 12, color: Colors.white),
                                            SizedBox(width: 3),
                                            Text(
                                              '지도 발자국',
                                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                          // 스토리 내용 요약
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.place_outlined, color: Color(0xFF2E66E7), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      story.placeName,
                                      style: const TextStyle(color: Color(0xFF2E66E7), fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const Spacer(),
                                    Text(
                                      dateFormat.format(story.eventDate),
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  story.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                ),
                                if (story.companions != null && story.companions!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.people_alt_outlined, size: 14, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text(
                                        story.companions!,
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                                if (story.content != null && story.content!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    story.content!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // 2. 기기 갤러리 탭 (선택하여 여행 기록 만들기 + 미디어 필터)
  // =========================================================
  Widget _buildGalleryTab(AsyncValue<List<MediaItem>> mediaListAsync) {
    return mediaListAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('미디어 로드 오류: $err')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('기기 미디어가 없습니다.'));
        }

        final photoCount = items.where((it) => it.type == MediaItemType.image).length;
        final videoCount = items.where((it) => it.type == MediaItemType.video).length;

        // 선택된 미디어 필터 적용
        final filteredItems = items.where((item) {
          switch (_galleryFilter) {
            case MediaTypeFilter.all:
              return true;
            case MediaTypeFilter.photosOnly:
              return item.type == MediaItemType.image;
            case MediaTypeFilter.videosOnly:
              return item.type == MediaItemType.video;
          }
        }).toList();

        final grouped = _groupByDate(filteredItems);

        return Column(
          children: [
            // 상단 미디어 타입 필터 칩 바 [전체 / 사진 / 동영상]
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
              ),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('전체 (${items.length})'),
                    selected: _galleryFilter == MediaTypeFilter.all,
                    onSelected: (selected) {
                      if (selected) setState(() => _galleryFilter = MediaTypeFilter.all);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.photo_outlined, size: 16),
                    label: Text('사진 ($photoCount)'),
                    selected: _galleryFilter == MediaTypeFilter.photosOnly,
                    onSelected: (selected) {
                      if (selected) setState(() => _galleryFilter = MediaTypeFilter.photosOnly);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.videocam_outlined, size: 16),
                    label: Text('동영상 ($videoCount)'),
                    selected: _galleryFilter == MediaTypeFilter.videosOnly,
                    selectedColor: Colors.orange.withValues(alpha: 0.2),
                    onSelected: (selected) {
                      if (selected) setState(() => _galleryFilter = MediaTypeFilter.videosOnly);
                    },
                  ),
                ],
              ),
            ),

            // 날짜별 미디어 그리드 리스트
            Expanded(
              child: grouped.isEmpty
                  ? Center(
                      child: Text(
                        _galleryFilter == MediaTypeFilter.videosOnly ? '동영상이 없습니다.' : '표시할 미디어가 없습니다.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: grouped.keys.length,
                      itemBuilder: (context, index) {
                        final dateKey = grouped.keys.elementAt(index);
                        final mediaInDate = grouped[dateKey]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF2E66E7)),
                                  const SizedBox(width: 6),
                                  Text(dateKey, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const Spacer(),
                                  Text('${mediaInDate.length}장', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ],
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                              ),
                              itemCount: mediaInDate.length,
                              itemBuilder: (context, mIndex) {
                                final item = mediaInDate[mIndex];
                                final isSelected = _selectedMediaIds.contains(item.id);
                                final isVideo = item.type == MediaItemType.video;

                                return GestureDetector(
                                  onLongPress: () => _toggleMediaSelection(item.id),
                                  onTap: () {
                                    if (_isSelectionMode) {
                                      _toggleMediaSelection(item.id);
                                    } else {
                                      MediaDetailSheet.show(context, mediaInDate, initialIndex: mIndex);
                                    }
                                  },
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      MediaThumbnail(
                                        item: item,
                                        borderRadius: BorderRadius.circular(8),
                                        fit: BoxFit.cover,
                                      ),
                                      // 동영상 길이 뱃지
                                      if (isVideo)
                                        Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.7),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.play_arrow, size: 10, color: Colors.white),
                                                const SizedBox(width: 2),
                                                Text(
                                                  _formatDuration(item.duration),
                                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      // 선택 모드 오버레이
                                      if (isSelected)
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2E66E7).withValues(alpha: 0.45),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFF2E66E7), width: 3),
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.check_circle, color: Colors.white, size: 28),
                                          ),
                                        ),
                                      // 위치 핀 유무 배지
                                      if (!_isSelectionMode)
                                        Positioned(
                                          top: 4,
                                          left: 4,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: item.hasLocation
                                                  ? const Color(0xFF2E66E7).withValues(alpha: 0.85)
                                                  : Colors.black.withValues(alpha: 0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              item.hasLocation ? Icons.place : Icons.location_off,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Map<String, List<MediaItem>> _groupByDate(List<MediaItem> items) {
    final Map<String, List<MediaItem>> grouped = {};
    final format = DateFormat('yyyy년 MM월 dd일');

    for (final item in items) {
      final key = format.format(item.shotAt);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(item);
    }
    return grouped;
  }
}
