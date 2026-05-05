import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/burn_week_mock_page.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../support/fake_calories_repositories.dart';

Widget _buildHarness({
  required FakeCalorieSettingsRepository settingsRepository,
}) {
  final container = ProviderContainer(
    overrides: [
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(settingsRepository.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BurnWeekMockPage(
        referenceNow: DateTime(2026, 4, 21, 12),
      ),
    ),
  );
}

void main() {
  testWidgets('renders mock page and opens details dialog', (tester) async {
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 4, 20),
      ),
    );

    await tester.pumpWidget(
      _buildHarness(settingsRepository: settingsRepository),
    );
    await tester.pump();

    expect(find.text('Burn Week'), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.burnWeekMockBar), findsOneWidget);
    expect(find.text('EATEN'), findsOneWidget);
    expect(find.text('TODAY LEFT'), findsOneWidget);

    await tester.tap(find.byTooltip('Show Burn Week details'));
    await tester.pumpAndSettle();

    expect(find.text('Burn Week details'), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.burnWeekMockInfoCard), findsOneWidget);
  });

  testWidgets('quick actions update eaten value and heart day state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 4, 20),
      ),
    );

    await tester.pumpWidget(
      _buildHarness(settingsRepository: settingsRepository),
    );
    await tester.pump();

    final quickAction = find.byKey(
      CaloriesPageKeys.burnWeekMockQuickAction('500'),
    );
    await tester.ensureVisible(quickAction);
    await tester.tap(quickAction);
    await tester.pump();

    expect(find.text('500 kcal'), findsOneWidget);

    await tester.ensureVisible(find.text('x 1'));
    await tester.tap(find.text('x 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use heart'));
    await tester.pumpAndSettle();

    expect(find.text('x 1'), findsNothing);
    expect(
      find.textContaining('Today counts as a perfect Burn day'),
      findsOneWidget,
    );
  });

  testWidgets('details dialog shows calculator profile formulas', (
    tester,
  ) async {
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 1800,
        calculatorProfile: const CalorieCalculatorProfile(
          sex: CalorieCalculatorSex.female,
          weightKg: 72,
          heightCm: 168,
          ageYears: 30,
          activityLevel: 1.55,
          goalMode: CalorieGoalMode.lose,
          goalSpeedKgPerWeek: 0.5,
        ),
        effectiveDate: DateTime(2026, 4, 20),
      ),
    );

    await tester.pumpWidget(
      _buildHarness(settingsRepository: settingsRepository),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Show Burn Week details'));
    await tester.pumpAndSettle();

    expect(
      _findRichTextContaining('BMR = (10 x 72.0 kg)'),
      findsOneWidget,
    );
    expect(_findRichTextContaining('Chosen target: Losing'), findsOneWidget);
    expect(
      _findRichTextContaining('Target speed: -0.5 kg/week'),
      findsOneWidget,
    );
    expect(
      _findRichTextContaining('Goal kcal = BMR + activity'),
      findsOneWidget,
    );
  });

  testWidgets('debug speed opens below-zone recover dialog', (tester) async {
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 4, 20),
      ),
    );

    await tester.pumpWidget(
      _buildHarness(settingsRepository: settingsRepository),
    );
    await tester.pump();
    tester.widget<Slider>(find.byType(Slider)).onChanged!(12);
    await tester.pump();

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Out of safe zone'), findsOneWidget);

    await tester.tap(find.text('Eat more'));
    await tester.pumpAndSettle();

    expect(find.text('Eat more to get back in target.'), findsOneWidget);
  });

  testWidgets('food quick actions open above-zone fast dialog', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 4, 20),
      ),
    );

    await tester.pumpWidget(
      _buildHarness(settingsRepository: settingsRepository),
    );
    await tester.pump();

    final quickAction = find.byKey(
      CaloriesPageKeys.burnWeekMockQuickAction('1000'),
    );
    await tester.ensureVisible(quickAction);
    for (var index = 0; index < 4; index += 1) {
      await tester.tap(quickAction);
      await tester.pump();
    }
    await tester.pump();

    expect(find.text('Out of safe zone'), findsOneWidget);
    expect(
      find.text('You tracked too much. Fasting will help to get on track.'),
      findsOneWidget,
    );
  });
}

Finder _findRichTextContaining(String text) {
  return find.byWidgetPredicate((widget) {
    return widget is RichText && widget.text.toPlainText().contains(text);
  });
}
