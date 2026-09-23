import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_data_provider.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/activity/presentation/widgets/diary_weight_missing_prompt_section.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_missing_prompt_card.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/memory_app_preferences.dart';

void main() {
  final day = DateTime(2026, 4, 27);

  testWidgets('shows the prompt when the day has no weight', (tester) async {
    await _pumpPrompt(tester, day: day, hasSavedWeight: false);

    expect(find.byType(DiaryWeightMissingPromptCard), findsOneWidget);
  });

  testWidgets('hides the prompt when the day has a weight', (tester) async {
    await _pumpPrompt(tester, day: day, hasSavedWeight: true);

    expect(find.byType(DiaryWeightMissingPromptCard), findsNothing);
  });

  testWidgets('hides the prompt after it is dismissed', (tester) async {
    await _pumpPrompt(tester, day: day, hasSavedWeight: false);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(DiaryWeightMissingPromptCard)),
    )!;
    await tester.tap(find.text(l10n.diaryOkAction));
    await tester.pumpAndSettle();

    expect(find.byType(DiaryWeightMissingPromptCard), findsNothing);
  });
}

Future<void> _pumpPrompt(
  WidgetTester tester, {
  required DateTime day,
  required bool hasSavedWeight,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        diaryActivityWeightDataProvider(day).overrideWith(
          (ref) async => DiaryActivityWeightData(
            profileWeightKg: 78.4,
            selectedWeightKg: 78.4,
            hasSelectedDayWeight: hasSavedWeight,
            weightTrend: const [],
            weightDays: const [],
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DiaryWeightMissingPromptSection(day: day)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
