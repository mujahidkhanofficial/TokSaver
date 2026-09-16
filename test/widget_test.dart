import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_downloader/app/app.dart';
import 'package:tiktok_downloader/core/storage/app_database.dart';
import 'package:tiktok_downloader/core/storage/storage_providers.dart';

void main() {
  testWidgets('App launches and renders bottom navigation destinations',
      (WidgetTester tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
        ],
        child: const TokSaverApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify navigation destinations and home elements exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('History'), findsWidgets);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Download TikTok Media'), findsOneWidget);

    await testDb.close();
  });
}
