import 'package:latlong2/latlong.dart';
import 'package:photo_manager/photo_manager.dart' hide LatLng;
import '../../core/utils/permission_helper.dart';
import '../../domain/model/media_item.dart';
import '../local/app_database.dart';

class MediaScannerService {
  final AppDatabase _db;

  MediaScannerService(this._db);

  /// 1단계: 첫 화면을 위한 고속 초기 스캔 (기본 80장, 약 0.1~0.2초 이내)
  Future<List<MediaItem>> scanInitialMedia({int count = 80}) async {
    return _scanMediaInternal(start: 0, end: count);
  }

  /// 2단계: 백그라운드 잔여 미디어 스캔 (start부터 maxCount까지)
  Future<List<MediaItem>> scanRemainingMedia({int start = 80, int maxCount = 1000}) async {
    return _scanMediaInternal(start: start, end: maxCount);
  }

  /// 전체 일괄 스캔 (기존 호환용)
  Future<List<MediaItem>> scanDeviceMedia({int maxCount = 1000}) async {
    return _scanMediaInternal(start: 0, end: maxCount);
  }

  /// 고성능 병렬/인메모리 미디어 스캐너 내부 구현
  Future<List<MediaItem>> _scanMediaInternal({
    required int start,
    required int end,
  }) async {
    final hasPermission = await PermissionHelper.requestMediaPermissions();
    if (!hasPermission) {
      return [];
    }

    // 1. N+1 쿼리 방지: 숨김 ID, 전체 코멘트 맵, 전체 수동 위치 맵, 앨범 목록을 병렬로 1회 일괄 적재
    final results = await Future.wait([
      _db.getHiddenMediaIds(),
      _db.getAllCommentsMap(),
      _db.getAllManualLocationsMap(),
      PhotoManager.getAssetPathList(
        type: RequestType.common,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(
              type: OrderOptionType.createDate,
              asc: false, // 최신순
            ),
          ],
        ),
      ),
    ]);

    final hiddenIds = results[0] as Set<String>;
    final allComments = results[1] as Map<String, List<String>>;
    final allManualLocs = results[2] as Map<String, ManualLocation>;
    final albums = results[3] as List<AssetPathEntity>;

    if (albums.isEmpty) {
      return [];
    }

    final AssetPathEntity recentAlbum = albums.first;
    final totalCount = await recentAlbum.assetCountAsync;
    if (start >= totalCount) {
      return [];
    }

    final actualEnd = end > totalCount ? totalCount : end;
    if (start >= actualEnd) {
      return [];
    }

    // 2. 요청된 범위의 에셋 일괄 조회
    final List<AssetEntity> assets = await recentAlbum.getAssetListRange(
      start: start,
      end: actualEnd,
    );

    // 3. 병렬 청크 처리 (동시 25개씩 병렬 비동기 처리하여 속도 극대화)
    const chunkSize = 25;
    final List<MediaItem> allItems = [];

    for (int i = 0; i < assets.length; i += chunkSize) {
      final chunk = assets.sublist(i, (i + chunkSize > assets.length) ? assets.length : i + chunkSize);

      final chunkResults = await Future.wait(
        chunk.map((asset) => _processAsset(
              asset: asset,
              hiddenIds: hiddenIds,
              allComments: allComments,
              allManualLocs: allManualLocs,
            )),
      );

      allItems.addAll(chunkResults.whereType<MediaItem>());
    }

    return allItems;
  }

  /// 단일 에셋 변환 (동기 좌표 우선 활용 + O(1) 인메모리 매핑)
  Future<MediaItem?> _processAsset({
    required AssetEntity asset,
    required Set<String> hiddenIds,
    required Map<String, List<String>> allComments,
    required Map<String, ManualLocation> allManualLocs,
  }) async {
    // 1. 숨긴 사진 필터링
    if (hiddenIds.contains(asset.id)) {
      return null;
    }

    // 2. 스크린샷 제외 필터링
    final titleLower = (asset.title ?? '').toLowerCase();
    if (_isScreenshot(titleLower)) {
      return null;
    }

    // 3. 위치 정보 결정
    LatLng? location;

    // 3-1. 수동 지정 위치가 인메모리 맵에 있으면 즉시 적용 (O(1))
    final manualLoc = allManualLocs[asset.id];
    if (manualLoc != null) {
      location = LatLng(manualLoc.latitude, manualLoc.longitude);
    } else {
      // 3-2. MediaStore 동기식 좌표(nullable)가 유효하면 latlngAsync() 호출 생략 (0ms)
      final lat = asset.latitude;
      final lng = asset.longitude;
      if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        location = LatLng(lat, lng);
      } else {
        // 3-3. 없으면 EXIF 비동기 조회
        try {
          final latLng = await asset.latlngAsync();
          if (latLng != null && latLng.latitude != 0.0 && latLng.longitude != 0.0) {
            location = LatLng(latLng.latitude, latLng.longitude);
          }
        } catch (_) {
          // EXIF 읽기 예외 시 무시
        }
      }
    }

    // 4. 인메모리 코멘트 매핑 (O(1))
    final comments = allComments[asset.id] ?? const [];

    return MediaItem(
      id: asset.id,
      title: asset.title,
      type: asset.type == AssetType.video ? MediaItemType.video : MediaItemType.image,
      location: location,
      shotAt: asset.createDateTime,
      duration: asset.duration,
      width: asset.width,
      height: asset.height,
      comments: comments,
    );
  }

  /// 스크린샷 파일명 패턴 필터링
  bool _isScreenshot(String titleLower) {
    return titleLower.contains('screenshot') ||
        titleLower.contains('스크린샷') ||
        titleLower.contains('화면_캡처') ||
        titleLower.contains('screen_capture') ||
        titleLower.startsWith('capture_');
  }
}
