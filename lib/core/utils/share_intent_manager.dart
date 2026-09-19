import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../data/services/file_media_parser_service.dart';
import '../../domain/model/media_item.dart';
import '../../presentation/providers/media_provider.dart';
import '../../presentation/story/story_editor_sheet.dart';

/// 외부 앱(갤러리, 포토 등)에서 "공유하기"로 넘어온 사진/동영상을 감지하고
/// Travler 앱의 스토리 작성 및 지도 마커 등록 흐름으로 자동 연결하는 매니저
class ShareIntentManager {
  static final ShareIntentManager instance = ShareIntentManager._internal();
  ShareIntentManager._internal();

  StreamSubscription? _intentSub;
  bool _initialized = false;

  /// 앱 진입점(최상위 위젯)에서 초기화
  void init(BuildContext context, WidgetRef ref) {
    if (_initialized) return;
    _initialized = true;

    // 1. 앱이 백그라운드/포그라운드 실행 중일 때 공유받은 미디어 감지
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> files) {
        if (files.isNotEmpty && context.mounted) {
          _handleSharedFiles(context, ref, files);
        }
      },
      onError: (err) {
        debugPrint('[ShareIntentManager] getMediaStream error: $err');
      },
    );

    // 2. 앱이 완전히 종료된 상태에서 "공유하기"로 처음 켜졌을 때의 미디어 감지
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> files) {
      if (files.isNotEmpty && context.mounted) {
        _handleSharedFiles(context, ref, files);
        // 중복 트리거 방지 초기화
        ReceiveSharingIntent.instance.reset();
      }
    }).catchError((err) {
      debugPrint('[ShareIntentManager] getInitialMedia error: $err');
    });
  }

  /// 공유받은 파일 파싱 및 스토리 에디터 즉시 노출
  Future<void> _handleSharedFiles(
    BuildContext context,
    WidgetRef ref,
    List<SharedMediaFile> sharedFiles,
  ) async {
    final filePaths = sharedFiles.map((f) => f.path).toList();
    if (filePaths.isEmpty) return;

    // 1. EXIF 메타데이터 및 파일명 타임스탬프 분석하여 MediaItem 리스트 생성
    final List<MediaItem> mediaItems = await FileMediaParserService.instance.parseFiles(filePaths);
    if (mediaItems.isEmpty) return;

    // 2. 전체 미디어 목록에 추가
    ref.read(mediaListProvider.notifier).addImportedMediaItems(mediaItems);

    // 3. UI가 마운트되어 있으면 즉시 스토리 작성 시트를 열어 지도 마커 및 여행 기록 생성 유도
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${mediaItems.length}개의 사진/영상을 가져왔습니다. 여행 기록을 작성해보세요!'),
          backgroundColor: const Color(0xFF2E66E7),
          duration: const Duration(seconds: 2),
        ),
      );

      await StoryEditorSheet.show(
        context,
        selectedMedia: mediaItems,
      );
    }
  }

  void dispose() {
    _intentSub?.cancel();
    _initialized = false;
  }
}
