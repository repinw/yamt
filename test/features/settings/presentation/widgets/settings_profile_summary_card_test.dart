import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_profile_summary_card/settings_profile_summary_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/profile_summary_source_overrides.dart';
import '../../../calories/support/fake_calories_repositories.dart';

/// Width of a Material drawer, where the card is shown.
const _drawerWidth = 304.0;

final _birthDate = DateTime(1990, 10, 2);

final _profile = CalorieCalculatorProfile(
  sex: CalorieCalculatorSex.female,
  weightKg: 60,
  heightCm: 165,
  ageYears: 30,
  birthDate: _birthDate,
  activityLevel: 1.4,
  goalMode: CalorieGoalMode.lose,
  goalSpeedKgPerWeek: 0.5,
  targetWeightKg: 55,
);

CalorieGoalSettings _settingsWithGoal() {
  return CalorieGoalSettings.single(
    dailyKcalGoal: 1810,
    calculatorProfile: _profile,
    effectiveDate: DateTime(2026, 9),
  );
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required FakeCalorieSettingsRepository repository,
  String? displayName,
  List<ManualHealthWeightEntry> weighIns = const [],
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: profileSummarySourceOverrides(
        settingsRepository: repository,
        now: DateTime(2026, 9, 24, 10),
        displayName: displayName,
        weighIns: weighIns,
      ),
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: _drawerWidth,
                child: SingleChildScrollView(
                  child: SettingsProfileSummaryCard(),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows name, body data, and goals of the profile', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: _settingsWithGoal(),
    );
    addTearDown(repository.dispose);

    await _pumpCard(
      tester,
      repository: repository,
      displayName: 'Alex',
      weighIns: [
        ManualHealthWeightEntry(day: DateTime(2026, 9, 22), weightKg: 61.2),
      ],
    );
    final tdeeKcal = CalorieGoalCalculator.calculate(_profile).tdeeKcal;

    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Größe'), findsOneWidget);
    expect(find.text('165 cm'), findsOneWidget);
    expect(find.text('Aktuelles Gewicht'), findsOneWidget);
    expect(find.text('61,2 kg'), findsOneWidget);
    expect(find.text('Geschlecht'), findsOneWidget);
    expect(find.text('Weiblich'), findsOneWidget);
    expect(find.text('Geburtstag'), findsOneWidget);
    expect(
      find.text('${DateFormat.yMMMd('de').format(_birthDate)} (35 Jahre)'),
      findsOneWidget,
    );
    expect(find.text('Verbrauch (TDEE)'), findsOneWidget);
    expect(
      find.text(
        '${NumberFormat.decimalPattern('de').format(tdeeKcal.round())} '
        'kcal/Tag (geschätzt)',
      ),
      findsOneWidget,
    );
    expect(find.text('Ziele'), findsOneWidget);
    expect(find.text('1.810 kcal/Tag'), findsOneWidget);
    expect(find.text('Zielgewicht'), findsOneWidget);
    expect(find.text('55 kg'), findsOneWidget);
    expect(find.text('Abnehmen · 0,5 kg/Woche'), findsOneWidget);
    // Female without training days: 1.2 g protein and 0.9 g fat per kg,
    // carbs fill the remaining calories.
    expect(find.text('72 g'), findsOneWidget);
    expect(find.text('54 g'), findsOneWidget);
    expect(find.text('259 g'), findsOneWidget);
  });

  testWidgets('shows fallbacks without name, body data, or goal', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await _pumpCard(tester, repository: repository);

    expect(find.text('Dein Profil'), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(
      find.text('Noch keine Körperdaten. Der Kalorienrechner speichert sie.'),
      findsOneWidget,
    );
    expect(find.text('Zuerst Ziel setzen'), findsOneWidget);
    expect(find.text('Kalorien'), findsNothing);
  });

  testWidgets('fits the drawer with large text', (tester) async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: _settingsWithGoal(),
    );
    addTearDown(repository.dispose);

    await _pumpCard(
      tester,
      repository: repository,
      displayName: 'Alexandra Musterfrau-Beispielname',
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Abnehmen · 0,5 kg/Woche'), findsOneWidget);
  });

  testWidgets('edit macros button opens the macro settings', (tester) async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: _settingsWithGoal(),
    );
    addTearDown(repository.dispose);

    await _pumpCard(tester, repository: repository);
    final editMacrosButton = find.byKey(
      SettingsProfileSummaryCard.editMacrosButtonKey,
    );
    await tester.ensureVisible(editMacrosButton);
    await tester.tap(editMacrosButton);
    await tester.pumpAndSettle();

    expect(find.text('Makronährstoff-Verteilung'), findsOneWidget);
  });
}
