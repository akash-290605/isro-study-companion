import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isro_study_companion/core/services/local_storage_service.dart';
import 'package:isro_study_companion/core/services/providers.dart';
import 'package:isro_study_companion/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ISRO Study Companion App loads and displays authentication screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorageService.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
        ],
        child: const IsroStudyCompanionApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify presence of ISRO Study Companion branding and Sign In
    expect(find.text('ISRO STUDY COMPANION'), findsWidgets);
    expect(find.text('Sign In'), findsWidgets);
  });
}
