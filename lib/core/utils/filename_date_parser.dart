/// 파일명에 포함된 날짜/시간 패턴을 정규식으로 파싱하여 실제 촬영 일시를 복원하는 헬퍼 클래스
/// 
/// 카카오톡, 라인, 카메라 기본 앱에서 파일 복사/이동 시 EXIF가 손상되더라도
/// 파일명(예: IMG_20240512_142310, KakaoTalk_20230815_123000 등)을 분석하여 복원합니다.
class FilenameDateParser {
  // 1. 표준 카메라 패턴: IMG_20240512_142310, VID_20240512_142310, 20240512_142310
  static final RegExp _patternStandard = RegExp(r'(?:IMG_|VID_)?(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})');

  // 2. 하이픈 구분 패턴: 2024-05-12-14-23-10, 2024-05-12_14-23-10, Screenshot_2024-05-12-14-23-10
  static final RegExp _patternHyphen = RegExp(r'(\d{4})-(\d{2})-(\d{2})[-_](\d{2})[-_](\d{2})[-_](\d{2})');

  // 3. 날짜만 있는 패턴: IMG_20240512, 20240512_
  static final RegExp _patternDateOnly = RegExp(r'(?:IMG_|VID_)?(\d{4})(\d{2})(\d{2})');

  /// 파일명으로부터 가능한 실제 촬영 일시를 파싱합니다.
  /// 패턴 매칭에 실패하면 null을 반환합니다.
  static DateTime? parse(String? filename) {
    if (filename == null || filename.trim().isEmpty) {
      return null;
    }

    final name = filename.trim();

    // 1. 표준 카메라 패턴 매칭 (년월일_시분초)
    final matchStd = _patternStandard.firstMatch(name);
    if (matchStd != null) {
      try {
        final year = int.parse(matchStd.group(1)!);
        final month = int.parse(matchStd.group(2)!);
        final day = int.parse(matchStd.group(3)!);
        final hour = int.parse(matchStd.group(4)!);
        final minute = int.parse(matchStd.group(5)!);
        final second = int.parse(matchStd.group(6)!);

        if (_isValidDate(year, month, day, hour, minute, second)) {
          return DateTime(year, month, day, hour, minute, second);
        }
      } catch (_) {}
    }

    // 2. 하이픈 패턴 매칭 (년-월-일_시-분-초)
    final matchHyphen = _patternHyphen.firstMatch(name);
    if (matchHyphen != null) {
      try {
        final year = int.parse(matchHyphen.group(1)!);
        final month = int.parse(matchHyphen.group(2)!);
        final day = int.parse(matchHyphen.group(3)!);
        final hour = int.parse(matchHyphen.group(4)!);
        final minute = int.parse(matchHyphen.group(5)!);
        final second = int.parse(matchHyphen.group(6)!);

        if (_isValidDate(year, month, day, hour, minute, second)) {
          return DateTime(year, month, day, hour, minute, second);
        }
      } catch (_) {}
    }

    // 3. 날짜만 존재하는 패턴 (년월일)
    final matchDate = _patternDateOnly.firstMatch(name);
    if (matchDate != null) {
      try {
        final year = int.parse(matchDate.group(1)!);
        final month = int.parse(matchDate.group(2)!);
        final day = int.parse(matchDate.group(3)!);

        if (_isValidDate(year, month, day, 12, 0, 0)) {
          return DateTime(year, month, day, 12, 0, 0);
        }
      } catch (_) {}
    }

    return null;
  }

  static bool _isValidDate(int y, int m, int d, int h, int min, int s) {
    if (y < 1990 || y > 2100) return false;
    if (m < 1 || m > 12) return false;
    if (d < 1 || d > 31) return false;
    if (h < 0 || h > 23) return false;
    if (min < 0 || min > 59) return false;
    if (s < 0 || s > 59) return false;
    return true;
  }
}
