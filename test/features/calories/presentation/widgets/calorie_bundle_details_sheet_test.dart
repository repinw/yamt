import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_bundle_details_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('bundle details sheet formats fractional portions', (
    tester,
  ) async {
    final entry = CalorieEntry.bundle(
      id: 'entry-1',
      userId: 'user-1',
      name: 'Soup',
      mealType: MealType.lunch,
      totalKcal: 120,
      totalProtein: 8,
      totalCarbs: 12,
      totalFat: 4,
      bundleSourcePreparedMealId: 'meal-1',
      bundleConsumedPortions: 0.5,
      bundleTotalPortions: 4,
      bundleComponents: const <CalorieEntryBundleComponent>[
        CalorieEntryBundleComponent(
          name: 'Beans',
          amountLabel: '50 g',
          totalKcal: 120,
          totalProtein: 8,
          totalCarbs: 12,
          totalFat: 4,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  unawaited(
                    showCalorieBundleDetailsSheet(context, entry: entry),
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('0.5/4 portions'), findsOneWidget);
    expect(find.text('Beans'), findsOneWidget);
  });
}
