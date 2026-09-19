import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/services/address_resolver_service.dart';
import '../../domain/model/media_item.dart';
import '../map/location_picker_screen.dart';
import '../providers/media_provider.dart';
import '../story/story_editor_sheet.dart';
import 'media_full_viewer.dart';
import 'media_thumbnail.dart';

class MediaDetailSheet extends ConsumerStatefulWidget {
  final List<MediaItem> items;
  final int initialIndex;

  const MediaDetailSheet({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  /// 단일 아이템으로 열기
  static Future<void> showSingle(BuildContext context, MediaItem item) {
    return show(context, [item], initialIndex: 0);
  }

  /// 다중 아이템(클러스터/그룹)으로 열기
  static Future<void> show(BuildContext context, List<MediaItem> items, {int initialIndex = 0}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaDetailSheet(items: items, initialIndex: initialIndex),
    );
  }

  @override
  ConsumerState<MediaDetailSheet> createState() => _MediaDetailSheetState();
}

class _MediaDetailSheetState extends ConsumerState<MediaDetailSheet> {
  final TextEditingController _commentController = TextEditingController();
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _submitComment(String mediaId) {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    ref.read(mediaListProvider.notifier).addComment(mediaId, text);
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  void _showEditCommentDialog(String mediaId, int index, String currentContent) {
    final editController = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('메모 수정'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '수정할 메모 내용을 입력하세요',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != currentContent) {
                ref.read(mediaListProvider.notifier).updateComment(mediaId, index, currentContent, newText);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('수정 완료'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteComment(String mediaId, int index, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('메모 삭제'),
        content: const Text('이 메모를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(mediaListProvider.notifier).deleteComment(mediaId, index, content);
              Navigator.of(ctx).pop();
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _confirmHideMedia(BuildContext context, MediaItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사진 숨기기'),
        content: const Text('이 사진을 지도와 타임라인에서 숨기시겠습니까?\n(설정 메뉴에서 언제든 다시 복원할 수 있습니다)'),
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
              ref.read(mediaListProvider.notifier).hideMedia(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('사진을 숨김 처리했습니다.')),
              );
            },
            child: const Text('숨기기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaListAsync = ref.watch(mediaListProvider);
    final targetItem = widget.items[_currentIndex];

    // 실시간 코멘트/메타데이터 업데이트 반영
    final currentItem = mediaListAsync.maybeWhen(
      data: (items) => items.firstWhere(
        (it) => it.id == targetItem.id,
        orElse: () => targetItem,
      ),
      orElse: () => targetItem,
    );

    final dateFormat = DateFormat('yyyy년 MM월 dd일 HH:mm');

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
              // 상단 핸들 바 및 옵션 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
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
                      icon: const Icon(Icons.visibility_off_outlined, color: Colors.grey, size: 20),
                      tooltip: '이 사진 숨기기',
                      onPressed: () => _confirmHideMedia(context, currentItem),
                    ),
                  ],
                ),
              ),

              // 다중 사진일 때 상단 카운터 표시
              if (widget.items.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E66E7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '이 위치의 사진 ${_currentIndex + 1} / ${widget.items.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E66E7),
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // 미디어 스와이프 뷰어 (고화질 + 탭 시 풀스크린)
                    SizedBox(
                      height: 260,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: widget.items.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final item = widget.items[index];
                              return GestureDetector(
                                onTap: () => MediaFullViewer.open(
                                  context,
                                  widget.items,
                                  initialIndex: index,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    color: Colors.black,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        MediaThumbnail(
                                          item: item,
                                          highQuality: true,
                                          fit: BoxFit.contain,
                                        ),
                                        Positioned(
                                          right: 10,
                                          bottom: 10,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.fullscreen,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (widget.items.length > 1) ...[
                            if (_currentIndex > 0)
                              Positioned(
                                left: 6,
                                top: 110,
                                child: IconButton.filledTonal(
                                  icon: const Icon(Icons.chevron_left, size: 20),
                                  onPressed: () {
                                    _pageController.previousPage(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                ),
                              ),
                            if (_currentIndex < widget.items.length - 1)
                              Positioned(
                                right: 6,
                                top: 110,
                                child: IconButton.filledTonal(
                                  icon: const Icon(Icons.chevron_right, size: 20),
                                  onPressed: () {
                                    _pageController.nextPage(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 여행 기록 만들기 바로가기 버튼
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E66E7),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.auto_stories, size: 18),
                        label: const Text('이 사진으로 여행 기록 만들기', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          StoryEditorSheet.show(context, selectedMedia: [currentItem]);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 메타데이터 정보 카드 (글로벌 도로명 주소 비동기 연동)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  currentItem.type == MediaItemType.video
                                      ? Icons.videocam_outlined
                                      : Icons.photo_outlined,
                                  color: const Color(0xFF2E66E7),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  dateFormat.format(currentItem.shotAt),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                  icon: Icon(
                                    currentItem.type == MediaItemType.video
                                        ? Icons.play_circle_outline
                                        : Icons.zoom_in,
                                    size: 16,
                                  ),
                                  label: Text(
                                    currentItem.type == MediaItemType.video ? '동영상 보기' : '원본 확대',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () => MediaFullViewer.open(
                                    context,
                                    widget.items,
                                    initialIndex: _currentIndex,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            if (currentItem.hasLocation)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(Icons.place_outlined, color: Colors.redAccent, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FutureBuilder<String>(
                                      future: AddressResolverService.instance.resolveAddress(
                                        currentItem.location!.latitude,
                                        currentItem.location!.longitude,
                                      ),
                                      builder: (context, snapshot) {
                                        final address = snapshot.data ?? '주소 변환 중...';
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              address,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                height: 1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${currentItem.location!.latitude.toStringAsFixed(5)}, ${currentItem.location!.longitude.toStringAsFixed(5)}',
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                                    child: const Text('위치 변경', style: TextStyle(fontSize: 11)),
                                    onPressed: () async {
                                      final newLoc = await LocationPickerScreen.pick(
                                        context,
                                        initialLocation: currentItem.location,
                                      );
                                      if (newLoc != null) {
                                        ref.read(mediaListProvider.notifier).updateLocation(currentItem.id, newLoc);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('위치를 업데이트했습니다.')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  const Icon(Icons.location_off_outlined, color: Colors.grey, size: 16),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text('위치 정보 없음', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ),
                                  FilledButton.tonalIcon(
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                    icon: const Icon(Icons.add_location_alt, size: 14),
                                    label: const Text('위치 등록', style: TextStyle(fontSize: 11)),
                                    onPressed: () async {
                                      final newLoc = await LocationPickerScreen.pick(context);
                                      if (newLoc != null) {
                                        ref.read(mediaListProvider.notifier).updateLocation(currentItem.id, newLoc);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('새 위치를 등록했습니다.')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 코멘트 섹션
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF2E66E7)),
                        const SizedBox(width: 6),
                        Text(
                          '사진 메모 & 코멘트 (${currentItem.comments.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (currentItem.comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            '이 사진에 남겨진 메모가 없습니다.\n아래에서 첫 번째 메모를 작성해 보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ),
                      )
                    else
                      ...List.generate(currentItem.comments.length, (cIndex) {
                        final comment = currentItem.comments[cIndex];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4, right: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  comment,
                                  style: const TextStyle(fontSize: 13, height: 1.3),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                                tooltip: '수정',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _showEditCommentDialog(currentItem.id, cIndex, comment),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                tooltip: '삭제',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _confirmDeleteComment(currentItem.id, cIndex, comment),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // 하단 코멘트 입력창 (SafeArea로 감싸 기기 하단 소프트키/제스처바 가림 완벽 방지)
              SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: MediaQuery.of(context).viewInsets.bottom > 0
                        ? MediaQuery.of(context).viewInsets.bottom + 8
                        : 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: '이 사진에 메모 남기기...',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          onSubmitted: (_) => _submitComment(currentItem.id),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.send_rounded, size: 20),
                        onPressed: () => _submitComment(currentItem.id),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
