import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../data/services/address_resolver_service.dart';
import '../../domain/model/media_item.dart';
import '../../domain/model/travel_story.dart';
import '../map/location_picker_screen.dart';
import '../providers/media_provider.dart';
import '../providers/story_provider.dart';
import '../widgets/media_thumbnail.dart';

/// 여행 스토리 작성 및 편집 바텀시트
class StoryEditorSheet extends ConsumerStatefulWidget {
  final List<MediaItem> initialMedia;
  final TravelStory? editingStory;

  const StoryEditorSheet({
    super.key,
    required this.initialMedia,
    this.editingStory,
  });

  static Future<void> show(
    BuildContext context, {
    required List<MediaItem> selectedMedia,
    TravelStory? editingStory,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryEditorSheet(
        initialMedia: selectedMedia,
        editingStory: editingStory,
      ),
    );
  }

  @override
  ConsumerState<StoryEditorSheet> createState() => _StoryEditorSheetState();
}

class _StoryEditorSheetState extends ConsumerState<StoryEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _placeController;
  late final TextEditingController _companionsController;
  late final TextEditingController _contentController;

  late DateTime _eventDate;
  LatLng? _selectedLocation;
  late List<MediaItem> _selectedMedia;
  String? _coverMediaId;

  // 기본 추천 동행 태그 목록
  static const List<String> _suggestedCompanions = ['가족', '연인', '친구', '혼자', '반려동물'];

  @override
  void initState() {
    super.initState();
    final story = widget.editingStory;
    _selectedMedia = List.from(widget.initialMedia);

    if (story != null) {
      _titleController = TextEditingController(text: story.title);
      _placeController = TextEditingController(text: story.placeName);
      _companionsController = TextEditingController(text: story.companions ?? '');
      _contentController = TextEditingController(text: story.content ?? '');
      _eventDate = story.eventDate;
      _selectedLocation = story.location;
      _coverMediaId = story.coverMediaId ?? (_selectedMedia.isNotEmpty ? _selectedMedia.first.id : null);
    } else {
      // 신규 작성 시 첫 사진 메타데이터로 기본값 자동 추론
      final firstWithLoc = _selectedMedia.where((m) => m.hasLocation).firstOrNull;
      _selectedLocation = firstWithLoc?.location;

      _eventDate = _selectedMedia.isNotEmpty ? _selectedMedia.first.shotAt : DateTime.now();
      _coverMediaId = _selectedMedia.isNotEmpty ? _selectedMedia.first.id : null;

      _titleController = TextEditingController();
      _placeController = TextEditingController();
      _companionsController = TextEditingController();
      _contentController = TextEditingController();

      // 사진의 위치가 있으면 글로벌 도로명 주소를 조회하여 장소명 자동 추천 채우기
      if (_selectedLocation != null) {
        _autoFillAddress(_selectedLocation!.latitude, _selectedLocation!.longitude);
      }
    }
  }

  /// 좌표 기반 도로명 주소를 장소명에 자동 채우기
  Future<void> _autoFillAddress(double lat, double lng) async {
    final address = await AddressResolverService.instance.resolveAddress(lat, lng);
    if (mounted && _placeController.text.trim().isEmpty) {
      setState(() {
        _placeController.text = address;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _companionsController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _eventDate = picked;
      });
    }
  }

  Future<void> _pickLocationOnMap() async {
    final result = await LocationPickerScreen.pick(
      context,
      initialLocation: _selectedLocation,
      placeHint: _placeController.text.trim().isNotEmpty ? _placeController.text.trim() : null,
    );
    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
      // 핀으로 새 위치 선택 시 장소명 갱신 제안
      final address = await AddressResolverService.instance.resolveAddress(result.latitude, result.longitude);
      if (mounted && _placeController.text.trim().isEmpty) {
        setState(() {
          _placeController.text = address;
        });
      }
    }
  }

  /// 기기 갤러리에서 사진/동영상 추가 선택
  Future<void> _openAddMorePhotosSheet() async {
    final allMedia = ref.read(mediaListProvider).maybeWhen(
          data: (items) => items,
          orElse: () => <MediaItem>[],
        );

    final selectedResult = await showModalBottomSheet<List<MediaItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PhotoPickerModal(
        allMedia: allMedia,
        initiallySelected: _selectedMedia,
      ),
    );

    if (selectedResult != null && selectedResult.isNotEmpty) {
      setState(() {
        _selectedMedia = selectedResult;
        if (_coverMediaId == null || !_selectedMedia.any((m) => m.id == _coverMediaId)) {
          _coverMediaId = _selectedMedia.first.id;
        }
        // 선택된 미디어 중 위치가 있으면 위치 없던 경우 자동 채우기
        if (_selectedLocation == null) {
          final withLoc = _selectedMedia.where((m) => m.hasLocation).firstOrNull;
          if (withLoc != null) {
            _selectedLocation = withLoc.location;
            _autoFillAddress(withLoc.location!.latitude, withLoc.location!.longitude);
          }
        }
      });
    }
  }

  Future<void> _saveStory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 1장 이상의 사진이나 동영상을 선택해 주세요.')),
      );
      return;
    }

    final title = _titleController.text.trim();
    final place = _placeController.text.trim();
    final companions = _companionsController.text.trim();
    final content = _contentController.text.trim();
    final mediaIds = _selectedMedia.map((m) => m.id).toList();

    if (widget.editingStory != null) {
      await ref.read(storyListProvider.notifier).updateStory(
            id: widget.editingStory!.id,
            title: title,
            placeName: place,
            companions: companions.isNotEmpty ? companions : null,
            content: content.isNotEmpty ? content : null,
            eventDate: _eventDate,
            location: _selectedLocation,
            mediaIds: mediaIds,
            coverMediaId: _coverMediaId,
          );
    } else {
      await ref.read(storyListProvider.notifier).createStory(
            title: title,
            placeName: place,
            companions: companions.isNotEmpty ? companions : null,
            content: content.isNotEmpty ? content : null,
            eventDate: _eventDate,
            location: _selectedLocation,
            mediaIds: mediaIds,
            coverMediaId: _coverMediaId,
          );
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.editingStory != null ? '여행 기록을 수정했습니다.' : '새 여행 기록을 저장했습니다!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일');

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 상단 핸들 바 및 타이틀
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                    const Spacer(),
                    Text(
                      widget.editingStory != null ? '여행 기록 수정' : '새 여행 기록 만들기',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _saveStory,
                      child: const Text('저장'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 입력 폼 바디
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 1. 선별된 사진/동영상 캐러셀 섹션 (맨 앞에 미디어 추가 버튼)
                      Row(
                        children: [
                          const Icon(Icons.photo_library_outlined, size: 18, color: Color(0xFF2E66E7)),
                          const SizedBox(width: 6),
                          Text(
                            '선별된 사진 & 영상 (${_selectedMedia.length}개)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Spacer(),
                          const Text(
                            '* 탭하여 대표 커버 지정',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      SizedBox(
                        height: 96,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedMedia.length + 1, // 맨 앞 [+ 미디어 추가]
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              // [+ 미디어 추가] 버튼
                              return InkWell(
                                onTap: _openAddMorePhotosSheet,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 86,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E66E7).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF2E66E7).withValues(alpha: 0.35),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF2E66E7), size: 28),
                                      SizedBox(height: 4),
                                      Text(
                                        '+ 사진/영상',
                                        style: TextStyle(color: Color(0xFF2E66E7), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final mediaIndex = index - 1;
                            final item = _selectedMedia[mediaIndex];
                            final isCover = item.id == _coverMediaId;
                            final isVideo = item.type == MediaItemType.video;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _coverMediaId = item.id;
                                });
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 86,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isCover ? const Color(0xFF2E66E7) : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: MediaThumbnail(
                                        item: item,
                                        width: 86,
                                        height: 96,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  // 동영상 표시 아이콘
                                  if (isVideo)
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.play_arrow, size: 10, color: Colors.white),
                                      ),
                                    ),
                                  if (isCover)
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2E66E7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          '커버',
                                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  // 제거 버튼
                                  if (_selectedMedia.length > 1)
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedMedia.removeAt(mediaIndex);
                                            if (_coverMediaId == item.id) {
                                              _coverMediaId = _selectedMedia.first.id;
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. 제목 입력
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: '기록 제목 *',
                          hintText: '예: 안목해변 커피거리 산책',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '기록 제목을 입력해 주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // 3. 어디에 (장소명 + 지도 핀)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _placeController,
                              decoration: const InputDecoration(
                                labelText: '어디에 (장소명) *',
                                hintText: '예: 강릉 안목해변',
                                prefixIcon: Icon(Icons.place_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '장소명을 입력해 주세요.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            icon: Icon(
                              _selectedLocation != null ? Icons.pin_drop : Icons.add_location_alt_outlined,
                              color: _selectedLocation != null ? Colors.redAccent : const Color(0xFF2E66E7),
                            ),
                            label: Text(_selectedLocation != null ? '핀 완료' : '지도 핀'),
                            onPressed: _pickLocationOnMap,
                          ),
                        ],
                      ),
                      if (_selectedLocation != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            '📍 좌표: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)} (지도에 마커로 표시됩니다)',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF2E66E7)),
                          ),
                        ),
                      const SizedBox(height: 14),

                      // 4. 누구와 (동행인 입력 및 추천 태그)
                      TextFormField(
                        controller: _companionsController,
                        decoration: const InputDecoration(
                          labelText: '누구와 (동행인)',
                          hintText: '예: 가족, 친구 민우',
                          prefixIcon: Icon(Icons.group_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: _suggestedCompanions.map((tag) {
                          return ActionChip(
                            avatar: const Icon(Icons.add, size: 14),
                            label: Text(tag, style: const TextStyle(fontSize: 12)),
                            onPressed: () {
                              final cur = _companionsController.text.trim();
                              if (cur.isEmpty) {
                                _companionsController.text = tag;
                              } else if (!cur.contains(tag)) {
                                _companionsController.text = '$cur, $tag';
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // 5. 언제 (여행 일자)
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '언제 (방문 날짜)',
                            prefixIcon: Icon(Icons.calendar_month_outlined),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            dateFormat.format(_eventDate),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 6. 어떤 경험을 했는지 (자유 메모/일기)
                      TextFormField(
                        controller: _contentController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: '어떤 경험을 했나요? (여행 메모/일기)',
                          hintText: '바다 바람이 시원했고, 커피 콩빵이 맛있었다...',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 50),
                            child: Icon(Icons.edit_note),
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 30),
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

/// 기기 사진/동영상을 추가로 선택할 수 있는 갤러리 피커 모달 시트 (타입 필터 지원)
class _PhotoPickerModal extends StatefulWidget {
  final List<MediaItem> allMedia;
  final List<MediaItem> initiallySelected;

  const _PhotoPickerModal({
    required this.allMedia,
    required this.initiallySelected,
  });

  @override
  State<_PhotoPickerModal> createState() => _PhotoPickerModalState();
}

class _PhotoPickerModalState extends State<_PhotoPickerModal> {
  late final Set<String> _selectedIds;
  MediaTypeFilter _filter = MediaTypeFilter.all;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initiallySelected.map((m) => m.id).toSet();
  }

  void _toggleItem(MediaItem item) {
    setState(() {
      if (_selectedIds.contains(item.id)) {
        _selectedIds.remove(item.id);
      } else {
        _selectedIds.add(item.id);
      }
    });
  }

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final mediaMap = {for (var m in widget.allMedia) m.id: m};

    final photoCount = widget.allMedia.where((it) => it.type == MediaItemType.image).length;
    final videoCount = widget.allMedia.where((it) => it.type == MediaItemType.video).length;

    final displayedMedia = widget.allMedia.where((item) {
      switch (_filter) {
        case MediaTypeFilter.all:
          return true;
        case MediaTypeFilter.photosOnly:
          return item.type == MediaItemType.image;
        case MediaTypeFilter.videosOnly:
          return item.type == MediaItemType.video;
      }
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                    const Spacer(),
                    Text(
                      '사진/영상 추가 (${_selectedIds.length}개 선택)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        final selectedList = _selectedIds
                            .map((id) => mediaMap[id])
                            .whereType<MediaItem>()
                            .toList();
                        Navigator.of(context).pop(selectedList);
                      },
                      child: const Text('선택 완료'),
                    ),
                  ],
                ),
              ),

              // 미디어 타입 필터 칩 바 [전체 / 사진 / 동영상]
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('전체 (${widget.allMedia.length})'),
                      selected: _filter == MediaTypeFilter.all,
                      onSelected: (selected) {
                        if (selected) setState(() => _filter = MediaTypeFilter.all);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: const Icon(Icons.photo_outlined, size: 15),
                      label: Text('사진 ($photoCount)'),
                      selected: _filter == MediaTypeFilter.photosOnly,
                      onSelected: (selected) {
                        if (selected) setState(() => _filter = MediaTypeFilter.photosOnly);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: const Icon(Icons.videocam_outlined, size: 15),
                      label: Text('동영상 ($videoCount)'),
                      selected: _filter == MediaTypeFilter.videosOnly,
                      selectedColor: Colors.orange.withValues(alpha: 0.2),
                      onSelected: (selected) {
                        if (selected) setState(() => _filter = MediaTypeFilter.videosOnly);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: displayedMedia.isEmpty
                    ? Center(
                        child: Text(
                          _filter == MediaTypeFilter.videosOnly ? '동영상이 없습니다.' : '표시할 미디어가 없습니다.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: displayedMedia.length,
                        itemBuilder: (context, index) {
                          final item = displayedMedia[index];
                          final isSelected = _selectedIds.contains(item.id);
                          final isVideo = item.type == MediaItemType.video;

                          return GestureDetector(
                            onTap: () => _toggleItem(item),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                MediaThumbnail(
                                  item: item,
                                  borderRadius: BorderRadius.circular(8),
                                  fit: BoxFit.cover,
                                ),
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
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
