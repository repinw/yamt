import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_balance_summary_view.dart';
import 'package:yamt/features/calories/provider/calorie_balance_summary_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  test('resolves balance bar layout metrics for under-pace progress', () {
    final layoutMetrics = resolveCaloriesBalanceBarLayoutMetrics(
      totalWidth: 200,
      progress: 0.5,
      isUnderPace: true,
      isOverPace: false,
    );

    expect(layoutMetrics.gradientWidth, closeTo(96, 0.0001));
    expect(layoutMetrics.barLeft, closeTo(54, 0.0001));
    expect(layoutMetrics.barWidth, closeTo(46, 0.0001));
    expect(layoutMetrics.markerCenterX, closeTo(52, 0.0001));
  });

  test('resolves balance bar layout metrics for over-pace progress', () {
    final layoutMetrics = resolveCaloriesBalanceBarLayoutMetrics(
      totalWidth: 200,
      progress: 0.5,
      isUnderPace: false,
      isOverPace: true,
    );

    expect(layoutMetrics.gradientWidth, closeTo(96, 0.0001));
    expect(layoutMetrics.barLeft, closeTo(100, 0.0001));
    expect(layoutMetrics.barWidth, closeTo(46, 0.0001));
    expect(layoutMetrics.markerCenterX, closeTo(148, 0.0001));
  });

  test('resolves empty fill when the balance bar has no usable width', () {
    final layoutMetrics = resolveCaloriesBalanceBarLayoutMetrics(
      totalWidth: 6,
      progress: 1,
      isUnderPace: true,
      isOverPace: false,
    );

    expect(layoutMetrics.gradientWidth, 0);
    expect(layoutMetrics.barLeft, 3);
    expect(layoutMetrics.barWidth, 0);
    expect(layoutMetrics.markerCenterX, 3);
  });

  test('resolves light theme balance colors from score', () {
    expect(
      resolveCaloriesBalanceColorForScore(0, brightness: Brightness.light),
      const Color(0xFFB71C1C),
    );
    expect(
      resolveCaloriesBalanceColorForScore(0.5, brightness: Brightness.light),
      Color.lerp(const Color(0xFFB71C1C), const Color(0xFF006941), 0.25),
    );
    expect(
      resolveCaloriesBalanceColorForScore(1, brightness: Brightness.light),
      const Color(0xFF006941),
    );
  });

  test('resolves dark theme balance colors from score', () {
    expect(
      resolveCaloriesBalanceColorForScore(0, brightness: Brightness.dark),
      const Color(0xFF991B1B),
    );
    expect(
      resolveCaloriesBalanceColorForScore(0.5, brightness: Brightness.dark),
      Color.lerp(const Color(0xFF991B1B), const Color(0xFF0B7A4B), 0.25),
    );
    expect(
      resolveCaloriesBalanceColorForScore(1, brightness: Brightness.dark),
      const Color(0xFF0B7A4B),
    );
  });

  testWidgets('shows a wait hint when the user is above the center', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        data: _summaryData(
          goalMode: CalorieGoalMode.gain,
          deltaKcal: 220,
          baseGoalKcal: 960,
          flexibleGoalKcal: 960,
          pacedGoalKcal: 480,
          rangeKcal: 400,
        ),
      ),
    );

    expect(find.text('Wait a bit before eating again'), findsOneWidget);
    expect(find.text('Back on pace around 16:40'), findsOneWidget);
  });

  testWidgets('shows an eat hint when the user is below the center', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        data: _summaryData(goalMode: CalorieGoalMode.lose, deltaKcal: -220),
      ),
    );

    expect(find.text('Eat about 220 kcal now'), findsOneWidget);
  });

  testWidgets('shows a balanced hint inside the dead zone', (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        data: _summaryData(goalMode: CalorieGoalMode.maintain, deltaKcal: 20),
      ),
    );

    expect(find.text('Well balanced for now'), findsOneWidget);
  });

  testWidgets(
    'shows a fasting recommendation when the carryover exceeds the base goal',
    (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          data: _summaryData(
            goalMode: CalorieGoalMode.maintain,
            deltaKcal: 0,
            carryoverKcal: -2200,
            flexibleGoalKcal: 0,
            pacedGoalKcal: 0,
          ),
        ),
      );

      expect(find.text('Recommendation: fast today'), findsOneWidget);
      expect(find.text('Wait a bit before eating again'), findsNothing);
      expect(find.textContaining('Back on pace around'), findsNothing);
    },
  );

  testWidgets(
    'shows a fasting recommendation when todays flex goal is already exceeded',
    (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          data: _summaryData(
            goalMode: CalorieGoalMode.maintain,
            deltaKcal: 523,
            baseGoalKcal: 2427,
            carryoverKcal: -1874,
            flexibleGoalKcal: 553,
            pacedGoalKcal: 92,
            consumedKcal: 800,
          ),
        ),
      );

      expect(
        find.text('Recommendation: fast for the rest of today'),
        findsOneWidget,
      );
      expect(
        find.text('Likely off pace for the rest of today'),
        findsOneWidget,
      );
      expect(find.text('Wait a bit before eating again'), findsNothing);
      expect(find.textContaining('Back on pace around'), findsNothing);
    },
  );

  testWidgets('uses goal-aware finished copy for historical gain days', (
    tester,
  ) async {
    final referenceNow = DateTime(2026, 4, 10, 14);
    final selectedDay = normalizeDiaryDay(
      referenceNow.subtract(const Duration(days: 1)),
    );

    await tester.pumpWidget(
      _buildHarness(
        data: _summaryData(
          goalMode: CalorieGoalMode.gain,
          deltaKcal: 180,
          selectedDay: selectedDay,
          referenceNow: referenceNow,
        ),
      ),
    );

    expect(
      find.text('Ended with 180 kcal extra for weight gain'),
      findsOneWidget,
    );
  });
}

Widget _buildHarness({required CalorieBalanceSummaryData data}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CaloriesBalanceSummaryView(
        data: data,
        numberFormat: NumberFormat.decimalPattern('en'),
        kcalUnit: 'kcal',
      ),
    ),
  );
}

CalorieBalanceSummaryData _summaryData({
  required CalorieGoalMode goalMode,
  required double deltaKcal,
  DateTime? selectedDay,
  DateTime? referenceNow,
  double baseGoalKcal = 2000,
  double carryoverKcal = 0,
  double? flexibleGoalKcal,
  double? pacedGoalKcal,
  double? consumedKcal,
  double deadZoneKcal = 60,
  double rangeKcal = 600,
}) {
  final resolvedNow = referenceNow ?? DateTime(2026, 4, 10, 14);
  final resolvedDay = selectedDay ?? normalizeDiaryDay(resolvedNow);
  final resolvedFlexibleGoalKcal = flexibleGoalKcal ?? baseGoalKcal;
  final resolvedPacedGoalKcal = pacedGoalKcal ?? (baseGoalKcal * 0.5);
  return CalorieBalanceSummaryData(
    selectedDay: resolvedDay,
    referenceNow: resolvedNow,
    windowStartDate: resolvedNow.subtract(const Duration(days: 6)),
    balanceStartDate: resolvedNow.subtract(const Duration(days: 6)),
    paceWindowStart: DateTime(
      resolvedDay.year,
      resolvedDay.month,
      resolvedDay.day,
      6,
    ),
    paceWindowEnd: DateTime(
      resolvedDay.year,
      resolvedDay.month,
      resolvedDay.day,
      22,
    ),
    baseGoalKcal: baseGoalKcal,
    carryoverKcal: carryoverKcal,
    goalMode: goalMode,
    flexibleGoalKcal: resolvedFlexibleGoalKcal,
    pacedGoalKcal: resolvedPacedGoalKcal,
    consumedKcal: consumedKcal ?? (resolvedPacedGoalKcal + deltaKcal),
    deltaKcal: deltaKcal,
    paceRatio: 0.5,
    deadZoneKcal: deadZoneKcal,
    rangeKcal: rangeKcal,
    activityDeltaKcal: 0,
    usedLearnedTdee: false,
  );
}
