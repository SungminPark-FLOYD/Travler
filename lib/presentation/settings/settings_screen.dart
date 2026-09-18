import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/permission_helper.dart';
import '../providers/media_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaListAsync = ref.watch(mediaListProvider);
    final geoMediaList = ref.watch(geoMediaListProvider);
    final hiddenIdsAsync = ref.watch(hiddenMediaIdsProvider);

    final totalCount = mediaListAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );

    final totalComments = mediaListAsync.maybeWhen(
      data: (items) => items.fold<int>(0, (sum, it) => sum + it.comments.length),
      orElse: () => 0,
    );

    final hiddenCount = hiddenIdsAsync.maybeWhen(
      data: (ids) => ids.length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정 & 저장소', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 프라이버시 원칙 안내 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        '100% On-Device 로컬 보관',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '미디어 원본 파일과 작성하신 메모는 외부 서버로 전송되지 않으며, 기기 내부에만 안전하게 저장됩니다.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 로컬 데이터 통계 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '로컬 아카이브 통계',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('표출 미디어', '$totalCount개', Icons.photo_library_outlined),
                      _buildStatItem('지도 위치 핀', '${geoMediaList.length}개', Icons.place_outlined),
                      _buildStatItem('작성된 메모', '$totalComments개', Icons.chat_bubble_outline),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 숨긴 사진 관리
          ListTile(
            leading: const Icon(Icons.visibility_off_outlined, color: Colors.orange),
            title: const Text('숨긴 사진 관리'),
            subtitle: Text('현재 $hiddenCount개의 사진이 숨김 처리되어 있습니다'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHiddenMediaDialog(context, ref, hiddenCount),
          ),

          // 권한 및 관리
          ListTile(
            leading: const Icon(Icons.perm_media_outlined, color: Color(0xFF2E66E7)),
            title: const Text('미디어 접근 권한 확인'),
            subtitle: const Text('기기 사진 및 동영상 스캔 권한 요청'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final granted = await PermissionHelper.requestMediaPermissions();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(granted ? '미디어 접근 권한이 허용되었습니다.' : '권한이 거부되었습니다. 설정에서 허용해 주세요.'),
                  ),
                );
                if (granted) {
                  ref.read(mediaListProvider.notifier).scanMedia();
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: Color(0xFF00C6AE)),
            title: const Text('미디어 다시 스캔하기'),
            subtitle: const Text('캡처 제외 및 새로 촬영된 사진 동기화'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ref.read(mediaListProvider.notifier).scanMedia();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로컬 미디어를 다시 스캔합니다.')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showHiddenMediaDialog(BuildContext context, WidgetRef ref, int count) {
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 숨김 처리된 사진이 없습니다.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('숨긴 사진 전체 복원'),
        content: Text('현재 숨겨진 $count개의 사진을 모두 다시 지도 및 타임라인에 표시하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final db = ref.read(databaseProvider);
              final ids = await db.getHiddenMediaIds();
              for (final id in ids) {
                await db.unhideMedia(id);
              }
              ref.invalidate(hiddenMediaIdsProvider);
              ref.read(mediaListProvider.notifier).scanMedia();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('모든 사진이 복원되었습니다.')),
                );
              }
            },
            child: const Text('모두 복원'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF2E66E7)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
