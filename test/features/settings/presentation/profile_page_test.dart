import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/settings/presentation/profile_page.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_body_edit_sheet.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_body_tiles.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_edit_sheet_frame.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_number_input.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_run_day_picker.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_weight_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/profile_summary_source_overrides.dart';
import '../../calories/support/fake_calories_repositories.dart';

Future<void> _pumpProfilePage(
  WidgetTester tester,
  FakeCalorieSettingsRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: profileSummarySourceOverrides(
        settingsRepository: repository,
        now: DateTime(2026, 9, 24, 10),
      ),
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfilePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the current profile under a profile app bar', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2100,
        calculatorProfile: const CalorieCalculatorProfile.defaults(),
        effectiveDate: DateTime(2026, 9),
      ),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: profileSummarySourceOverrides(
          settingsRepository: repository,
          now: DateTime(2026, 9, 24, 10),
          displayName: 'Alex',
          weighIns: [
            ManualHealthWeightEntry(day: DateTime(2026, 9, 24), weightKg: 79.4),
          ],
        ),
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Profil')),
      findsOneWidget,
    );
    expect(find.text('Alex'), findsOneWidget);
    // Trend weight and last weigh-in are the same after one weigh-in.
    expect(find.text('79,4 kg'), findsNWidgets(2));
    expect(find.text('heute'), findsOneWidget);
    expect(find.text('80,0 kg'), findsNWidgets(2));
    expect(find.byKey(ProfileWeightCard.addWeightButtonKey), findsOneWidget);
    expect(find.text('180 cm'), findsOneWidget);
    // The goal lives on the Fortschritt tab now.
    expect(find.text('Gewicht halten'), findsNothing);
  });

  testWidgets('a height edit shows the new calorie goal before it saves', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2100,
        calculatorProfile: const CalorieCalculatorProfile.defaults(),
        effectiveDate: DateTime(2026, 9),
      ),
    );
    addTearDown(repository.dispose);
    await _pumpProfilePage(tester, repository);

    await tester.scrollUntilVisible(
      find.byKey(ProfileBodyTiles.heightTileKey),
      200,
    );
    await tester.tap(find.byKey(ProfileBodyTiles.heightTileKey));
    await tester.pumpAndSettle();

    expect(find.text('Größe'), findsWidgets);
    expect(find.text('Das ändert sich ab heute'.toUpperCase()), findsNothing);

    await tester.enterText(find.byType(ProfileNumberInput), '100');
    await tester.pump();
    expect(find.text('Zwischen 120 und 230 cm'), findsOneWidget);

    await tester.enterText(find.byType(ProfileNumberInput), '190');
    await tester.pump();
    expect(
      find.text('Das ändert sich ab Zielstart am 1.9.2026'.toUpperCase()),
      findsOneWidget,
    );
    // 10 × 80 + 6,25 × 190 − 5 × 30 + 5 = 1.842,5 kcal BMR, × 1,2 PAL.
    expect(find.text('2.100 → 2.211 kcal'), findsOneWidget);

    await tester.tap(find.byKey(ProfileEditSheetFrame.applyButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileBodyEditSheet), findsNothing);
    final saved = await repository.readSettings();
    expect(saved.calculatorProfile?.heightCm, 190);
    expect(saved.dailyKcalGoal, closeTo(2211, 0.001));
    expect(find.text('190 cm'), findsOneWidget);
  });

  testWidgets('a sex edit with a learned TDEE keeps the calorie goal', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2100,
        calculatorProfile: const CalorieCalculatorProfile.defaults(),
        effectiveDate: DateTime(2026, 9),
        weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
          windowStartDate: DateTime(2026, 9),
          windowEndDate: DateTime(2026, 9, 7),
          trendWeightChangePerDay: 0,
          lowConfidence: false,
          calculatedTdeeKcal: 2400,
          inputHash: 'hash',
          measuredTdeeKcal: 0,
          baseGoalKcal: 0,
          isRejected: false,
        ),
      ),
    );
    addTearDown(repository.dispose);
    await _pumpProfilePage(tester, repository);

    expect(
      find.descendant(
        of: find.byKey(ProfileWeightCard.startWeightKey),
        matching: find.byIcon(Icons.edit_outlined),
      ),
      findsNothing,
    );
    await tester.ensureVisible(find.text('Männlich'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Männlich'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiblich'));
    await tester.pump();

    expect(find.text('bleibt 2.100 kcal'), findsOneWidget);
    expect(
      find.text(
        'Dein Verbrauch ist gelernt. Deshalb ändert sich nur die Aufteilung '
        'der Makros.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(ProfileEditSheetFrame.applyButtonKey));
    await tester.pumpAndSettle();

    final saved = await repository.readSettings();
    expect(saved.calculatorProfile?.sex, CalorieCalculatorSex.female);
    expect(saved.dailyKcalGoal, 2100);
  });

  testWidgets('a training edit changes the days of the current run', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2100,
        calculatorProfile: const CalorieCalculatorProfile.defaults().copyWith(
          trainingWeekdays: [DateTime.monday, DateTime.wednesday],
          trainingDayKcalOffset: 210,
        ),
        effectiveDate: DateTime(2026, 9),
      ),
    );
    addTearDown(repository.dispose);
    await _pumpProfilePage(tester, repository);

    // The run of 24 September goes from Tuesday 22 to Monday 28.
    final tile = find.byKey(ProfileBodyTiles.trainingTileKey);
    await tester.scrollUntilVisible(tile, 200);
    expect(
      find.descendant(of: tile, matching: find.text('Mi · Mo')),
      findsOneWidget,
    );
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(ProfileRunDayPicker),
        matching: find.text('24'),
      ),
    );
    await tester.pump();

    // A training day gets one session (210 kcal) more than a rest day.
    // Two training days: rest days 2.100 − 2 × 210 / 7 = 2.040 kcal,
    // training days 2.100 + 5 × 210 / 7 = 2.250. Three training days:
    // rest days 2.100 − 3 × 210 / 7 = 2.010, training days 2.220.
    expect(find.text('2.040 → 2.220 kcal'), findsOneWidget);
    expect(find.text('4 übrige Ruhetage'), findsOneWidget);
    expect(find.text('2.040 → 2.010 kcal'), findsOneWidget);
    expect(find.text('2 übrige Trainingstage'), findsOneWidget);
    expect(find.text('2.250 → 2.220 kcal'), findsOneWidget);
    expect(find.text('bleibt 14.700 kcal'), findsOneWidget);

    await tester.tap(find.byKey(ProfileEditSheetFrame.applyButtonKey));
    await tester.pumpAndSettle();

    final saved = await repository.readSettings();
    expect(saved.trainingDayOverrides, {'2026-9-24': true});
    expect(
      find.descendant(of: tile, matching: find.text('Mi · Do · Mo')),
      findsOneWidget,
    );
  });
}
