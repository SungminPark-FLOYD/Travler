import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../domain/model/media_item.dart';
import 'media_thumbnail.dart';
import 'video_player_widget.dart';

class MediaFullViewer extends StatefulWidget {
  final List<MediaItem> items;
  final int initialIndex;

  const MediaFullViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  static void open(BuildContext context, List<MediaItem> items, {int initialIndex = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaFullViewer(
          items: items,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  State<MediaFullViewer> createState() => _MediaFullViewerState();
}

class _MediaFullViewerState extends State<MediaFullViewer> {
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.items[_currentIndex];
    final dateFormat = DateFormat('yyyy년 MM월 dd일 HH:mm');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  currentItem.type == MediaItemType.video
                      ? Icons.videocam_outlined
                      : Icons.photo_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_currentIndex + 1} / ${widget.items.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              dateFormat.format(currentItem.shotAt),
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
          ],
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.items.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return _FullMediaItem(item: item);
        },
      ),
    );
  }
}

class _FullMediaItem extends StatefulWidget {
  final MediaItem item;

  const _FullMediaItem({required this.item});

  @override
  State<_FullMediaItem> createState() => _FullMediaItemState();
}

class _FullMediaItemState extends State<_FullMediaItem> {
  File? _file;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void didUpdateWidget(covariant _FullMediaItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _loadFile();
    }
  }

  Future<void> _loadFile() async {
    if (widget.item.type == MediaItemType.video) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final asset = await AssetEntity.fromId(widget.item.id);
    if (asset != null) {
      final file = await asset.file;
      if (mounted) {
        setState(() {
          _file = file;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // 1. 동영상 재생기 (video_player)
    if (widget.item.type == MediaItemType.video) {
      return VideoPlayerWidget(item: widget.item);
    }

    // 2. 이미지 뷰어 (InteractiveViewer + Image.file + Safe fallback)
    if (_file != null) {
      return InteractiveViewer(
        minScale: 0.8,
        maxScale: 4.0,
        child: Center(
          child: Image.file(
            _file!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return MediaThumbnail(
                item: widget.item,
                highQuality: true,
                fit: BoxFit.contain,
              );
            },
          ),
        ),
      );
    }

    // 원본 파일 경로를 얻지 못한 경우 고화질 썸네일로 fallback
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4.0,
      child: Center(
        child: MediaThumbnail(
          item: widget.item,
          highQuality: true,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
