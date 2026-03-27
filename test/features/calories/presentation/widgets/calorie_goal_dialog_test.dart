import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/calorie_goal_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _buildHarness({
  required Future<bool> Function(double dailyKcalGoal) onSaveGoal,
  required Future<bool> Function() onClearGoal,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return Center(
            child: FilledButton(
              onPressed: () {
                showCalorieGoalDialog(
                  context: context,
                  currentGoal: 2200,
                  onSaveGoal: onSaveGoal,
                  onClearGoal: onClearGoal,
                );
              },
              child: const Text('Open'),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('clear failure shows the specific clear error message', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        onSaveGoal: (_) async => true,
        onClearGoal: () async => false,
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieGoalDialogKeys.clearButton));
    await tester.pumpAndSettle();

    expect(find.text('Could not clear calorie goal.'), findsOneWidget);
  });
}
