import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class PermissionHelper {
  PermissionHelper._();

  /// 미디어 갤러리 및 위치 메타데이터 접근 권한 요청
  static Future<bool> requestMediaPermissions() async {
    // 1. PhotoManager 자체 권한 요청
    final PermissionState state = await PhotoManager.requestPermissionExtend();
    if (state.isAuth || state.hasAccess) {
      return true;
    }

    // 2. 권한 거부 시 시스템 퍼미션 핸들러로 재확인
    final permissions = [
      Permission.photos,
      Permission.videos,
      Permission.storage,
      Permission.locationWhenInUse,
    ];

    final statuses = await permissions.request();
    final hasPhotoAccess = statuses[Permission.photos]?.isGranted ?? false;
    final hasStorageAccess = statuses[Permission.storage]?.isGranted ?? false;

    return hasPhotoAccess || hasStorageAccess;
  }

  /// 현재 권한 상태 확인
  static Future<bool> hasMediaPermission() async {
    final PermissionState state = await PhotoManager.requestPermissionExtend();
    return state.isAuth || state.hasAccess;
  }
}
