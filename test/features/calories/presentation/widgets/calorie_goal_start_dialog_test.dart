import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_start_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _buildHarness({
  required SaveCalorieGoalStart onSaveGoalStart,
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
                unawaited(
                  showCalorieGoalStartDialog(
                    context: context,
                    initialGoalStartDate: DateTime(2026, 4, 10, 16, 30),
                    onSaveGoalStart: onSaveGoalStart,
                  ),
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
  testWidgets('save failure shows the specific goal start error message', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(onSaveGoalStart: (_) async => false),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieGoalStartDialogKeys.saveButton));
    await tester.pumpAndSettle();

    expect(find.text('Could not update goal start.'), findsOneWidget);
  });
}
