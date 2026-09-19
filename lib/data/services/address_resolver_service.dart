import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

/// 전 세계 위경도 좌표를 실제 도로명/행정구역 주소로 변환하는 글로벌 역지오코딩 서비스
/// 
/// - 한국(KR): "제주특별자치도 제주시 애월읍 애월로 12" 또는 "서울 강남구 테헤란로"
/// - 해외(Global): "Shibakoen, Minato City, Tokyo, Japan" / "Broadway, New York, NY, United States"
/// - 캐싱: 반경 약 100m 단위(소수점 3자리) 인메모리 캐싱으로 중복 조회 방지
class AddressResolverService {
  // 싱글톤 인스턴스
  static final AddressResolverService instance = AddressResolverService._internal();
  AddressResolverService._internal();

  final Geocoding _geocoding = Geocoding();

  // 소수점 3자리(약 100m) 기준 인메모리 캐시 ("37.566,126.978" -> "서울 중구 세종대로")
  final Map<String, String> _addressCache = {};

  /// 위도, 경도 좌표를 보기 좋은 도로명/지역 주소 문자열로 변환합니다.
  /// 
  /// 변환 실패 시(오프라인 등) 위경도 문자열(예: "37.5665, 126.9780")을 반환합니다.
  Future<String> resolveAddress(double latitude, double longitude) async {
    final cacheKey = _getCacheKey(latitude, longitude);

    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey]!;
    }

    try {
      final List<Placemark> placemarks = await _geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final formatted = _formatPlacemark(place);

        if (formatted.isNotEmpty) {
          _addressCache[cacheKey] = formatted;
          return formatted;
        }
      }
    } catch (e) {
      debugPrint('[AddressResolverService] Geocoding error for ($latitude, $longitude): $e');
    }

    // 변환 실패 시 좌표 기본값 반환
    final fallback = '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
    _addressCache[cacheKey] = fallback;
    return fallback;
  }

  /// 소수점 3자리(약 100m 정밀도) 캐시 키 생성
  String _getCacheKey(double lat, double lng) {
    return '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
  }

  /// 국가별 특성을 고려한 스마트 주소 포맷팅
  String _formatPlacemark(Placemark place) {
    final countryCode = place.isoCountryCode?.toUpperCase();

    // 1. 대한민국 주소 (큰 단위 -> 작은 단위)
    if (countryCode == 'KR' || place.country == '대한민국') {
      final parts = [
        place.administrativeArea, // 예: 서울특별시, 제주특별자치도, 경기도
        place.locality,           // 예: 성남시, 제주시
        place.subLocality,        // 예: 분당구, 애월읍, 종로구
        place.thoroughfare,       // 예: 테헤란로, 애월해맞이길
        place.subThoroughfare,    // 예: 12 (번지/건물번호)
      ].where((s) => s != null && s.trim().isNotEmpty).toSet().toList();

      if (parts.isNotEmpty) {
        return parts.join(' ');
      }
    }

    // 2. 글로벌 해외 주소 (작은 단위 -> 큰 단위, 서구식/일본 등)
    // 예: 4 Chome-2-8 Shibakoen, Minato City, Tokyo, Japan
    final globalParts = [
      place.street,             // 거리/번지 (예: 5 Av. Anatole France)
      place.subLocality,        // 세부 구역 (예: Shibakoen)
      place.locality,           // 도시 (예: Minato City, Paris)
      place.administrativeArea, // 주/도 (예: Tokyo, NY)
      place.country,            // 국가 (예: Japan, France)
    ].where((s) => s != null && s.trim().isNotEmpty).toSet().toList();

    if (globalParts.isNotEmpty) {
      return globalParts.join(', ');
    }

    // 3. Fallback: 이름이나 도로명이 있으면 표시
    final name = place.name;
    if (name != null && name.trim().isNotEmpty) {
      return name;
    }

    return '';
  }
}
