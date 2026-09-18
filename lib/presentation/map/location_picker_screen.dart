import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// 사용자가 지도 위에서 직접 원하는 여행 위치(핀)를 선택하는 화면
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? placeHint;

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.placeHint,
  });

  /// 위치 선택 화면 열기
  static Future<LatLng?> pick(
    BuildContext context, {
    LatLng? initialLocation,
    String? placeHint,
  }) {
    return Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: initialLocation,
          placeHint: placeHint,
        ),
      ),
    );
  }

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  late LatLng _currentCenter;
  static const LatLng _defaultCenter = LatLng(37.5665, 126.9780); // 서울 기본 좌표

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation ?? _defaultCenter;
  }

  Future<void> _moveToCurrentGps() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied || req == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('GPS 위치 권한이 필요합니다.')),
            );
          }
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      _mapController.move(latLng, 15.0);
      setState(() {
        _currentCenter = latLng;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('현재 위치를 가져오지 못했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.placeHint ?? '여행 위치 지정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: '현재 위치로 이동',
            onPressed: _moveToCurrentGps,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. 지도 뷰
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 14.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _currentCenter = camera.center;
                  });
                }
              },
              onTap: (tapPosition, point) {
                _mapController.move(point, _mapController.camera.zoom);
                setState(() {
                  _currentCenter = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.travler.travler',
              ),
            ],
          ),

          // 2. 화면 중앙 고정 핀 아이콘
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36), // 핀 하단 끝이 중앙 좌표를 가리키도록 보정
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '지도를 움직여 핀을 맞추세요',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.location_on,
                    size: 44,
                    color: Color(0xFF2E66E7),
                  ),
                ],
              ),
            ),
          ),

          // 3. 하단 확정 카드
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, color: Color(0xFF2E66E7)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '선택된 좌표',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                '${_currentCenter.latitude.toStringAsFixed(5)}, ${_currentCenter.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('이 위치로 설정', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.of(context).pop(_currentCenter);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
