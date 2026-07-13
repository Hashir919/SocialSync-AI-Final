import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socialsync_ai/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SocialSyncApp(),
      ),
    );

    // Verify the app renders (Supabase will fail in test but widget tree builds)
    expect(find.byType(SocialSyncApp), findsOneWidget);
  });
}
