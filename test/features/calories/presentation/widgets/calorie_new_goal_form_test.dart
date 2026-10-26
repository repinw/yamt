import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_new_goal_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('the reach estimate counts from a later goal start', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CalorieNewGoalForm(
              goalKcal: 1900,
              learnedTdeeKcal: 2450,
              goalStartDate: DateTime(2026, 5, 31),
              currentWeightKg: 65,
              targetWeightKg: 60,
              goalMode: CalorieGoalMode.lose,
              paceKgPerWeek: 0.55,
              expandedRow: CalorieNewGoalRow.pace,
              onRowTapped: (_) {},
              onTargetChanged: (_, _) {},
              onPaceChanged: (_) {},
              onStartTapped: () {},
              today: DateTime(2026, 5, 2),
            ),
          ),
        ),
      ),
    );

    // 5 kg at 0.55 kg a week is 64 days after the start on May 31.
    expect(find.textContaining('August 3, 2026'), findsOneWidget);
  });
}
