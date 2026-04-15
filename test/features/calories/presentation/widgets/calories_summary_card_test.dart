import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
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
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byKey(CaloriesPageKeys.summaryModeOption('classic')));
    await tester.pumpAndSettle();

    expect(find.byKey(CaloriesPageKeys.summaryBalanceBar), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byKey(CaloriesPageKeys.summaryModeOption('balance')));
    await tester.pumpAndSettle();

    expect(find.byKey(CaloriesPageKeys.summaryBalanceBar), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders macro progress cards with current values and progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(totalCarbs: 100, totalProtein: 90, totalFat: 40),
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
      _buildHarness(totalCarbs: 280, totalProtein: 90, totalFat: 40),
    );
    await tester.pumpAndSettle();

    final carbsValue = _macroValue(tester, 'carbs');

    expect(carbsValue.text.toPlainText(), '280 / 225g');
    expect(_currentValueColor(carbsValue), const Color(0xFF3B82F6));
    expect(_macroBar(tester, 'carbs').widthFactor, 1.0);
  });

  testWidgets('shows learned-TDEE activity delta in diary summary card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        balanceData: _balanceData(
          activityDeltaKcal: 135,
          usedLearnedTdee: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(CaloriesPageKeys.summaryActivityDeltaNote),
      findsOneWidget,
    );
    expect(find.text('Today activity delta: +135 kcal'), findsOneWidget);
  });
}

Widget _buildHarness({
  AppPreferences? preferences,
  CalorieBalanceSummaryData? balanceData,
  double totalCarbs = 100,
  double totalProtein = 90,
  double totalFat = 40,
}) {
  return ProviderScope(
    overrides: [
      appPreferencesProvider.overrideWithValue(
        preferences ?? MemoryAppPreferences(),
      ),
      calorieBalanceSummaryProvider.overrideWith(
        (ref) async => balanceData ?? _balanceData(),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 520,
            child: CaloriesSummaryCard(
              consumedKcal: 1600,
              goalKcal: 2000,
              remainingKcal: 400,
              progress: 0.8,
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
    carryoverKcal: 0,
    goalMode: CalorieGoalMode.maintain,
    flexibleGoalKcal: 2000,
    pacedGoalKcal: 1000,
    consumedKcal: 1000,
    deltaKcal: 0,
    paceRatio: 0.5,
    deadZoneKcal: 60,
    rangeKcal: 600,
    activityDeltaKcal: activityDeltaKcal,
    usedLearnedTdee: usedLearnedTdee,
  );
}
