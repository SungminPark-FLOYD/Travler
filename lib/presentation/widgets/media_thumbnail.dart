import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../domain/model/media_item.dart';

class MediaThumbnail extends StatefulWidget {
  final MediaItem item;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool highQuality;

  const MediaThumbnail({
    super.key,
    required this.item,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.highQuality = false,
  });

  @override
  State<MediaThumbnail> createState() => _MediaThumbnailState();
}

class _MediaThumbnailState extends State<MediaThumbnail> {
  Uint8List? _thumbnailBytes;
  File? _imageFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant MediaThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.filePath != widget.item.filePath ||
        oldWidget.highQuality != widget.highQuality) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    // 1. 직접 로컬 파일 경로가 있는 경우 (image_picker 또는 공유 인텐트)
    if (widget.item.filePath != null && widget.item.filePath!.isNotEmpty) {
      final file = File(widget.item.filePath!);
      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _imageFile = file;
            _isLoading = false;
          });
        }
        return;
      }
    }

    // 2. PhotoManager AssetEntity 기반인 경우
    try {
      final asset = await AssetEntity.fromId(widget.item.id);
      if (asset != null) {
        final size = widget.highQuality
            ? const ThumbnailSize(800, 800)
            : const ThumbnailSize(200, 200);
        final bytes = await asset.thumbnailDataWithSize(size);
        if (mounted) {
          setState(() {
            _thumbnailBytes = bytes;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isLoading) {
      child = Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (_imageFile != null) {
      child = Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _imageFile!,
            fit: widget.fit,
          ),
          if (widget.item.type == MediaItemType.video)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, size: 12, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(
                      _formatDuration(widget.item.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    } else if (_thumbnailBytes != null) {
      child = Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            _thumbnailBytes!,
            fit: widget.fit,
          ),
          if (widget.item.type == MediaItemType.video)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, size: 12, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(
                      _formatDuration(widget.item.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    } else {
      child = Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: child,
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: child,
    );
  }

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
