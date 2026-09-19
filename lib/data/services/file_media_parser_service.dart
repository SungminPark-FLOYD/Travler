import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:native_exif/native_exif.dart';
import 'package:path/path.dart' as p;
import '../../core/utils/filename_date_parser.dart';
import '../../domain/model/media_item.dart';

/// 외부 파일(갤러리 앱 공유 파일, ImagePicker 선택 파일 등)의 
/// EXIF 메타데이터(위치, 촬영일) 및 파일명 타임스탬프를 파싱하여 MediaItem 객체로 변환하는 서비스
class FileMediaParserService {
  static final FileMediaParserService instance = FileMediaParserService._internal();
  FileMediaParserService._internal();

  /// 단일 로컬 파일 경로를 분석하여 [MediaItem] 생성
  Future<MediaItem> parseFile(String filePath) async {
    final file = File(filePath);
    final fileName = p.basename(filePath);
    final ext = p.extension(filePath).toLowerCase();

    final isVideo = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp'].contains(ext);
    final mediaType = isVideo ? MediaItemType.video : MediaItemType.image;

    LatLng? location;
    DateTime? shotAt;

    // 1. 이미지인 경우 native_exif를 통한 원본 EXIF 메타데이터 분석
    if (!isVideo) {
      try {
        final exif = await Exif.fromPath(filePath);
        final latLong = await exif.getLatLong();
        if (latLong != null && latLong.latitude != 0.0 && latLong.longitude != 0.0) {
          location = LatLng(latLong.latitude, latLong.longitude);
        }

        final originalDate = await exif.getOriginalDate();
        if (originalDate != null) {
          shotAt = originalDate;
        }

        await exif.close();
      } catch (e) {
        debugPrint('[FileMediaParserService] EXIF parsing error for $filePath: $e');
      }
    }

    // 2. 일시 복원 전략: 파일명 패턴 분석 (EXIF 날짜가 없거나 조작된 경우 보정)
    final parsedFromFilename = FilenameDateParser.parse(fileName);
    if (parsedFromFilename != null) {
      if (shotAt == null) {
        shotAt = parsedFromFilename;
      } else if (shotAt.difference(parsedFromFilename).abs().inHours > 24) {
        // EXIF 일시와 파일명 타임스탬프가 하루 이상 차이나면 파일명 날짜 우선 복원
        shotAt = parsedFromFilename;
      }
    }

    // 3. Fallback: 파일의 실제 수정/생성 일자 또는 현재 시각
    if (shotAt == null) {
      try {
        final stat = await file.stat();
        shotAt = stat.modified;
      } catch (_) {
        shotAt = DateTime.now();
      }
    }

    // 고유 ID 생성 (파일 경로 기반 해시 또는 파일명)
    final uniqueId = 'local_${filePath.hashCode.abs()}';

    return MediaItem(
      id: uniqueId,
      filePath: filePath,
      title: fileName,
      type: mediaType,
      location: location,
      shotAt: shotAt,
      width: 0,
      height: 0,
      duration: 0,
    );
  }

  /// 복수 개의 파일 경로 일괄 변환
  Future<List<MediaItem>> parseFiles(List<String> filePaths) async {
    final List<MediaItem> results = [];
    for (final path in filePaths) {
      try {
        final item = await parseFile(path);
        results.add(item);
      } catch (e) {
        debugPrint('[FileMediaParserService] Failed to parse $path: $e');
      }
    }
    return results;
  }
}
