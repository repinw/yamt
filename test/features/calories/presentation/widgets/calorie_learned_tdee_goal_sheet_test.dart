import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_learned_tdee_goal_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _buildHarness({required CalorieGoalSettings initialSettings}) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                unawaited(
                  showCalorieLearnedTdeeGoalSheet(
                    context,
                    initialSettings: initialSettings,
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('keeps existing goal start date when editing learned TDEE goal', (
    tester,
  ) async {
    final goalStartDate = DateTime(2026, 4, 10, 16, 30);
    final initialSettings = CalorieGoalSettings.single(
      dailyKcalGoal: 2450,
      calculatorProfile: const CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.female,
        weightKg: 65,
        heightCm: 170,
        ageYears: 28,
        activityLevel: 1.7,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
      ),
      effectiveDate: goalStartDate,
      source: CalorieGoalSource.calculator,
      weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: DateTime(2026, 4, 8),
        windowEndDate: DateTime(2026, 4, 14),
        trendWeightChangePerDay: -0.08,
        calculatedTrueTdeeKcal: 2450,
        averageActiveKcal: 210,
        lowConfidence: false,
      ),
    );

    await tester.pumpWidget(
      _buildHarness(initialSettings: initialSettings),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final goalStartValue = tester.widget<Text>(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalStartValue),
    );

    expect(
      goalStartValue.data,
      DateFormat.yMMMd('en').format(DateTime(2026, 4, 10)),
    );
  });
}
