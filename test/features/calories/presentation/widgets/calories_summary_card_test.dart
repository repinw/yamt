import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_classic.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_classic_gauge.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_balance_summary_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/memory_app_preferences.dart';

void main() {
  const labelStyle = TextStyle(fontSize: 12);

  test('doesCaloriesSummaryTextFitWidth detects fitting text', () {
    expect(
      doesCaloriesSummaryTextFitWidth(
        text: 'FETT',
        style: labelStyle,
        maxWidth: 200,
      ),
      isTrue,
    );
    expect(
      doesCaloriesSummaryTextFitWidth(
        text: 'KOHlenhydrate',
        style: labelStyle,
        maxWidth: 8,
      ),
      isFalse,
    );
  });

  test('resolveMacroLabelForWidth keeps the full label when it fits', () {
    final resolvedLabel = resolveMacroLabelForWidth(
      label: 'KOHLENHYDRATE',
      style: labelStyle,
      maxWidth: 200,
      textDirection: ui.TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    );

    expect(resolvedLabel, 'KOHLENHYDRATE');
  });

  test('resolveMacroLabelForWidth truncates and appends a dot', () {
    final resolvedLabel = resolveMacroLabelForWidth(
      label: 'KOHLENHYDRATE',
      style: labelStyle,
      maxWidth: 40,
      textDirection: ui.TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    );

    expect(resolvedLabel, isNot('KOHLENHYDRATE'));
    expect(resolvedLabel, endsWith('.'));
    expect(
      doesCaloriesSummaryTextFitWidth(
        text: 'KOHLENHYDRATE',
        style: labelStyle,
        maxWidth: 40,
      ),
      isFalse,
    );
    expect(
      doesCaloriesSummaryTextFitWidth(
        text: resolvedLabel,
        style: labelStyle,
        maxWidth: 40,
      ),
      isTrue,
    );
  });

  test('resolveMacroLabelForWidth falls back to first letter and dot', () {
    final resolvedLabel = resolveMacroLabelForWidth(
      label: 'KOHLENHYDRATE',
      style: labelStyle,
      maxWidth: 1,
      textDirection: ui.TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    );

    expect(resolvedLabel, 'K.');
  });

  test('resolveMacroLabelForWidth returns empty string for empty labels', () {
    final resolvedLabel = resolveMacroLabelForWidth(
      label: '',
      style: labelStyle,
      maxWidth: 40,
      textDirection: ui.TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    );

    expect(resolvedLabel, isEmpty);
  });

  testWidgets('switches between balance and classic summary modes', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    expect(find.byKey(CaloriesPageKeys.summaryBalanceBar), findsOneWidget);
    expect(find.byType(ClassicSummaryHero), findsNothing);

    await tester.tap(find.byKey(CaloriesPageKeys.summaryModeOption('classic')));
    await tester.pumpAndSettle();

    expect(find.byKey(CaloriesPageKeys.summaryBalanceBar), findsNothing);
    expect(find.byType(ClassicSummaryHero), findsOneWidget);
    expect(find.byType(ClassicSummaryGauge), findsOneWidget);

    await tester.tap(find.byKey(CaloriesPageKeys.summaryModeOption('balance')));
    await tester.pumpAndSettle();

    expect(find.byKey(CaloriesPageKeys.summaryBalanceBar), findsOneWidget);
    expect(find.byType(ClassicSummaryHero), findsNothing);
  });

  testWidgets('renders macro progress cards with current values and progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(CaloriesPageKeys.summaryMacroCard('carbs')),
      findsOneWidget,
    );
    expect(
      find.byKey(CaloriesPageKeys.summaryMacroCard('protein')),
      findsOneWidget,
    );
    expect(
      find.byKey(CaloriesPageKeys.summaryMacroCard('fat')),
      findsOneWidget,
    );

    final carbsValue = _macroValue(tester, 'carbs');
    final proteinValue = _macroValue(tester, 'protein');
    final fatValue = _macroValue(tester, 'fat');

    expect(carbsValue.text.toPlainText(), '100 / 225g');
    expect(proteinValue.text.toPlainText(), '90 / 125g');
    expect(fatValue.text.toPlainText(), '40 / 67g');

    final theme = Theme.of(tester.element(find.byType(CaloriesSummaryCard)));
    expect(_currentValueColor(carbsValue), theme.colorScheme.onSurface);
    expect(_currentValueColor(proteinValue), theme.colorScheme.onSurface);
    expect(_currentValueColor(fatValue), theme.colorScheme.onSurface);

    expect(_macroBar(tester, 'carbs').widthFactor, closeTo(100 / 225, 0.0001));
    expect(_macroBar(tester, 'protein').widthFactor, closeTo(90 / 125, 0.0001));
    expect(_macroBar(tester, 'fat').widthFactor, closeTo(0.6, 0.0001));
  });

  testWidgets('highlights a macro value when the current amount is over goal', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(totalCarbs: 280),
    );
    await tester.pumpAndSettle();

    final carbsValue = _macroValue(tester, 'carbs');

    expect(carbsValue.text.toPlainText(), '280 / 225g');
    expect(_currentValueColor(carbsValue), const Color(0xFF3B82F6));
    expect(_macroBar(tester, 'carbs').widthFactor, 1.0);
  });

  testWidgets('shows learned activity comparison in diary summary card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        balanceData: _balanceData(
          activityDeltaKcal: 135,
          activityComparisonKcal: 135,
          carryoverKcal: 240,
          usedLearnedTdee: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(CaloriesPageKeys.summaryActivityDeltaNote),
      findsOneWidget,
    );
    expect(find.text('Today vs usual: +135 kcal'), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.summaryCarryoverNote), findsOneWidget);
    expect(find.text('Carryover: +240 kcal'), findsOneWidget);
  });

  testWidgets(
    'shows negative learned activity comparison even when no bonus is applied',
    (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          balanceData: _balanceData(
            activityComparisonKcal: -120,
            usedLearnedTdee: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(CaloriesPageKeys.summaryActivityDeltaNote),
        findsOneWidget,
      );
      expect(find.text('Today vs usual: -120 kcal'), findsOneWidget);
    },
  );

  testWidgets('shows carryover in diary summary card without activity delta', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        balanceData: _balanceData(carryoverKcal: -180),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(CaloriesPageKeys.summaryActivityDeltaNote),
      findsNothing,
    );
    expect(find.byKey(CaloriesPageKeys.summaryCarryoverNote), findsOneWidget);
    expect(find.text('Carryover: -180 kcal'), findsOneWidget);
  });

  testWidgets('shows bootstrap workout bonus hint before learned TDEE', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        balanceData: _balanceData(activityDeltaKcal: 140),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(CaloriesPageKeys.summaryActivityDeltaNote),
      findsOneWidget,
    );
    expect(find.text('Workout bonus: +140 kcal'), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.summaryActivityHint), findsOneWidget);
    expect(
      find.text('We are still learning your activity pattern.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'classic summary uses error color when remaining drops below zero',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildHarness(
          goalKcal: 1500,
          remainingKcal: -100,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(CaloriesPageKeys.summaryModeOption('classic')),
      );
      await tester.pumpAndSettle();

      final classicHero = tester.widget<ClassicSummaryHero>(
        find.byType(ClassicSummaryHero),
      );
      final colorScheme = Theme.of(
        tester.element(find.byType(CaloriesSummaryCard)),
      ).colorScheme;

      expect(classicHero.remainingKcal, -100);
      expect(classicHero.color, colorScheme.error);
    },
  );

  testWidgets(
    'classic summary uses checkbox toggles below macros to update the circle',
    (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          balanceData: _balanceData(
            activityDeltaKcal: 135,
            activityComparisonKcal: 135,
            carryoverKcal: 240,
            usedLearnedTdee: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(CaloriesPageKeys.summaryModeOption('classic')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(CaloriesPageKeys.summaryMetaSection), findsOneWidget);
      expect(
        find.byKey(CaloriesPageKeys.summaryActivityDeltaToggle),
        findsOneWidget,
      );
      expect(
        find.byKey(CaloriesPageKeys.summaryCarryoverToggle),
        findsOneWidget,
      );
      expect(find.byType(ClassicSummaryHero), findsOneWidget);
      expect(find.byType(ClassicSummaryGauge), findsOneWidget);
      expect(find.text('+135'), findsOneWidget);
      expect(find.text('400'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(CaloriesPageKeys.summaryCarryoverToggle),
      );
      await tester.tap(find.byKey(CaloriesPageKeys.summaryCarryoverToggle));
      await tester.pumpAndSettle();

      expect(find.byType(ClassicSummaryGauge), findsOneWidget);
      expect(find.text('+240'), findsOneWidget);
      expect(find.text('640'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(CaloriesPageKeys.summaryActivityDeltaToggle),
      );
      await tester.tap(find.byKey(CaloriesPageKeys.summaryActivityDeltaToggle));
      await tester.pumpAndSettle();

      expect(find.byType(ClassicSummaryGauge), findsOneWidget);
      expect(find.text('505'), findsOneWidget);

      final macroBottom = tester.getBottomLeft(
        find.byKey(CaloriesPageKeys.summaryMacroCard('carbs')),
      );
      final metaTop = tester.getTopLeft(
        find.byKey(CaloriesPageKeys.summaryMetaSection),
      );
      expect(metaTop.dy, greaterThan(macroBottom.dy));
    },
  );

  testWidgets(
    'classic summary restores persisted global toggle selections',
    (tester) async {
      final preferences = MemoryAppPreferences(
        initialStrings: <String, String>{
          'calories_summary_classic_include_activity_delta': 'false',
          'calories_summary_classic_include_carryover': 'true',
        },
      );

      await tester.pumpWidget(
        _buildHarness(
          preferences: preferences,
          balanceData: _balanceData(
            activityDeltaKcal: 135,
            activityComparisonKcal: 135,
            carryoverKcal: 240,
            usedLearnedTdee: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(CaloriesPageKeys.summaryModeOption('classic')),
      );
      await tester.pumpAndSettle();

      expect(find.text('+240'), findsOneWidget);
      expect(find.text('+135'), findsNothing);
      expect(find.text('505'), findsOneWidget);

      final activityToggle = tester.widget<Checkbox>(
        find.byKey(CaloriesPageKeys.summaryActivityDeltaToggle),
      );
      final carryoverToggle = tester.widget<Checkbox>(
        find.byKey(CaloriesPageKeys.summaryCarryoverToggle),
      );

      expect(activityToggle.value, isFalse);
      expect(carryoverToggle.value, isTrue);
    },
  );
}

Widget _buildHarness({
  AppPreferences? preferences,
  CalorieBalanceSummaryData? balanceData,
  double consumedKcal = 1600,
  double goalKcal = 2000,
  double remainingKcal = 400,
  double totalCarbs = 100,
  double totalProtein = 90,
  double totalFat = 40,
}) {
  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(
        preferences ?? MemoryAppPreferences(),
      ),
      calorieBalanceSummaryProvider.overrideWith(
        (ref) async => balanceData ?? _balanceData(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 520,
              child: CaloriesSummaryCard(
                consumedKcal: consumedKcal,
                goalKcal: goalKcal,
                remainingKcal: remainingKcal,
                progress: goalKcal <= 0 ? 0 : consumedKcal / goalKcal,
                totalProtein: totalProtein,
                totalCarbs: totalCarbs,
                totalFat: totalFat,
                consumedLabel: 'Consumed',
                goalLabel: 'Goal',
                remainingLabel: 'Remaining',
                proteinLabel: 'Protein',
                carbsLabel: 'Carbs',
                fatLabel: 'Fat',
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

RichText _macroValue(WidgetTester tester, String macroId) {
  return tester.widget<RichText>(
    find.byKey(CaloriesPageKeys.summaryMacroValue(macroId)),
  );
}

FractionallySizedBox _macroBar(WidgetTester tester, String macroId) {
  return tester.widget<FractionallySizedBox>(
    find.byKey(CaloriesPageKeys.summaryMacroBar(macroId)),
  );
}

Color? _currentValueColor(RichText value) {
  final span = value.text as TextSpan;
  final children = span.children;
  if (children == null || children.isEmpty) {
    return null;
  }

  return (children.first as TextSpan).style?.color;
}

CalorieBalanceSummaryData _balanceData({
  double activityDeltaKcal = 0,
  double activityComparisonKcal = 0,
  double carryoverKcal = 0,
  bool usedLearnedTdee = false,
}) {
  final now = DateTime(2026, 4, 10, 14);
  return CalorieBalanceSummaryData(
    selectedDay: DateTime(2026, 4, 10),
    referenceNow: now,
    windowStartDate: now.subtract(const Duration(days: 6)),
    balanceStartDate: now.subtract(const Duration(days: 6)),
    paceWindowStart: DateTime(2026, 4, 10, 6),
    paceWindowEnd: DateTime(2026, 4, 10, 22),
    baseGoalKcal: 2000,
    carryoverKcal: carryoverKcal,
    goalMode: CalorieGoalMode.maintain,
    flexibleGoalKcal: 2000 + carryoverKcal,
    pacedGoalKcal: 1000 + carryoverKcal,
    consumedKcal: 1000,
    deltaKcal: 0,
    paceRatio: 0.5,
    deadZoneKcal: 60,
    rangeKcal: 600,
    activityDeltaKcal: activityDeltaKcal,
    activityComparisonKcal: activityComparisonKcal,
    usedLearnedTdee: usedLearnedTdee,
  );
}
