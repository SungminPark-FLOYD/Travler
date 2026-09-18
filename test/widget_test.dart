import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travler/main.dart';

void main() {
  testWidgets('Travler app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TravlerApp(),
      ),
    );

    expect(find.text('지도'), findsOneWidget);
    expect(find.text('타임라인'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
  });
}
