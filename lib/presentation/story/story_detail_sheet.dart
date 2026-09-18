import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/model/media_item.dart';
import '../../domain/model/travel_story.dart';
import '../providers/media_provider.dart';
import '../providers/story_provider.dart';
import '../widgets/media_full_viewer.dart';
import '../widgets/media_thumbnail.dart';
import 'story_editor_sheet.dart';

/// 여행 스토리 상세 보기 바텀시트
class StoryDetailSheet extends ConsumerWidget {
  final TravelStory story;

  const StoryDetailSheet({super.key, required this.story});

  static Future<void> show(BuildContext context, TravelStory story) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryDetailSheet(story: story),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('여행 기록 삭제'),
        content: Text('\'${story.title}\' 기록을 삭제하시겠습니까?\n(기기의 원본 사진 파일은 삭제되지 않습니다)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // 바텀시트 닫기
              ref.read(storyListProvider.notifier).deleteStory(story.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('여행 기록이 삭제되었습니다.')),
              );
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일');
    final allMedia = ref.watch(mediaListProvider).maybeWhen(
          data: (items) => {for (var it in items) it.id: it},
          orElse: () => <String, MediaItem>{},
        );

    final List<MediaItem> resolvedItems = story.mediaIds.map((id) {
      return allMedia[id] ??
          MediaItem(
            id: id,
            type: MediaItemType.image,
            shotAt: story.eventDate,
            width: 0,
            height: 0,
          );
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 상단 바
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: '기록 삭제',
                      onPressed: () => _confirmDelete(context, ref),
                    ),
                    const Spacer(),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: '기록 수정',
                      onPressed: () {
                        Navigator.of(context).pop();
                        StoryEditorSheet.show(
                          context,
                          selectedMedia: List.from(resolvedItems),
                          editingStory: story,
                        );
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 여행 사진 캐러셀/슬라이더
                    if (resolvedItems.isNotEmpty)
                      SizedBox(
                        height: 250,
                        child: PageView.builder(
                          itemCount: resolvedItems.length,
                          itemBuilder: (context, index) {
                            final item = resolvedItems[index];
                            return GestureDetector(
                              onTap: () => MediaFullViewer.open(
                                context,
                                List.from(resolvedItems),
                                initialIndex: index,
                              ),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.black,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: MediaThumbnail(
                                  item: item,
                                  highQuality: true,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),

                    // 제목 & 일자
                    Text(
                      story.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(story.eventDate),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 어디에 & 누구와 정보 배지 카드
                    Card(
                      elevation: 0,
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.place_outlined, color: Color(0xFF2E66E7), size: 20),
                                const SizedBox(width: 8),
                                const Text('어디에: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Expanded(
                                  child: Text(
                                    story.placeName,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                if (story.hasLocation)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('지도 연동됨', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            if (story.companions != null && story.companions!.isNotEmpty) ...[
                              const Divider(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.people_alt_outlined, color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('누구와: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Expanded(
                                    child: Text(
                                      story.companions!,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 어떤 경험을 했는지 (스토리 내용)
                    if (story.content != null && story.content!.isNotEmpty) ...[
                      const Row(
                        children: [
                          Icon(Icons.format_quote, size: 20, color: Color(0xFF2E66E7)),
                          SizedBox(width: 4),
                          Text(
                            '우리의 여행 경험 & 메모',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          story.content!,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
