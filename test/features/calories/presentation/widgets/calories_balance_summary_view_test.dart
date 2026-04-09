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
  testWidgets('shows a wait hint when the user is above the center', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        data: _summaryData(goalMode: CalorieGoalMode.gain, deltaKcal: 220),
      ),
    );

    expect(find.text('Wait a bit before eating again'), findsOneWidget);
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
}) {
  final resolvedNow = referenceNow ?? DateTime(2026, 4, 10, 14);
  final resolvedDay = selectedDay ?? normalizeDiaryDay(resolvedNow);
  return CalorieBalanceSummaryData(
    selectedDay: resolvedDay,
    referenceNow: resolvedNow,
    windowStartDate: resolvedNow.subtract(const Duration(days: 6)),
    balanceStartDate: resolvedNow.subtract(const Duration(days: 6)),
    baseGoalKcal: 2000,
    carryoverKcal: 0,
    goalMode: goalMode,
    flexibleGoalKcal: 2000,
    pacedGoalKcal: 1000,
    consumedKcal: 1000 + deltaKcal,
    deltaKcal: deltaKcal,
    paceRatio: 0.5,
    deadZoneKcal: 60,
    rangeKcal: 600,
  );
}
