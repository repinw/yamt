import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_summary_result_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

CalorieCalculatorProfile _profile({
  required CalorieGoalMode goalMode,
  double goalSpeedKgPerWeek = 0.5,
}) {
  return CalorieCalculatorProfile(
    sex: CalorieCalculatorSex.female,
    weightKg: 80,
    heightCm: 170,
    ageYears: 30,
    activityLevel: 1.375,
    goalMode: goalMode,
    goalSpeedKgPerWeek: goalSpeedKgPerWeek,
    targetWeightKg: 75,
  );
}

Future<void> _pumpCard(
  WidgetTester tester,
  CalorieGoalCalculationResult calculation, {
  List<int> trainingWeekdays = const [],
  double trainingDayKcalOffset = 0,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: IntroSummaryResultCard(
          calculation: calculation,
          trainingWeekdays: trainingWeekdays,
          trainingDayKcalOffset: trainingDayKcalOffset,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('describes a deficit when the user wants to lose weight', (
    tester,
  ) async {
    final calculation = CalorieGoalCalculator.calculate(
      _profile(goalMode: CalorieGoalMode.lose),
    );

    await _pumpCard(tester, calculation);

    final difference = (calculation.tdeeKcal - calculation.finalGoalKcal)
        .round();
    expect(
      find.text('$difference kcal below your expenditure, so you lose weight.'),
      findsOneWidget,
    );
  });

  testWidgets('describes a surplus when the user wants to gain weight', (
    tester,
  ) async {
    final calculation = CalorieGoalCalculator.calculate(
      _profile(goalMode: CalorieGoalMode.gain),
    );

    await _pumpCard(tester, calculation);

    final difference = (calculation.finalGoalKcal - calculation.tdeeKcal)
        .round();
    expect(
      find.text('$difference kcal above your expenditure, so you gain weight.'),
      findsOneWidget,
    );
  });

  testWidgets('describes maintaining the weight', (tester) async {
    final calculation = CalorieGoalCalculator.calculate(
      _profile(goalMode: CalorieGoalMode.maintain, goalSpeedKgPerWeek: 0),
    );

    await _pumpCard(tester, calculation);

    expect(
      find.text('Matches your expenditure, so your weight stays where it is.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the expenditure and the target', (tester) async {
    final calculation = CalorieGoalCalculator.calculate(
      _profile(goalMode: CalorieGoalMode.lose),
    );

    await _pumpCard(tester, calculation);

    expect(find.text('${calculation.tdeeKcal.round()} kcal'), findsOneWidget);
    expect(
      find.text('${calculation.finalGoalKcal.round()} kcal'),
      findsOneWidget,
    );
  });

  testWidgets('shows the targets of training and rest days', (tester) async {
    final calculation = CalorieGoalCalculator.calculate(
      _profile(goalMode: CalorieGoalMode.maintain, goalSpeedKgPerWeek: 0),
    );

    await _pumpCard(
      tester,
      calculation,
      trainingWeekdays: const [1, 3, 5],
      trainingDayKcalOffset: 200,
    );

    final base = calculation.finalGoalKcal;
    expect(find.text('${(base + 200).round()} kcal'), findsOneWidget);
    expect(find.text('${(base - 150).round()} kcal'), findsOneWidget);
  });
}
