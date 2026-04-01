import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/statistics/domain/calorie_metrics.dart';
import 'package:yamt/features/statistics/domain/statistics_models.dart';
import 'package:yamt/features/statistics/presentation/views/'
    'statistics_calories_view.dart';
import 'package:yamt/features/statistics/presentation/views/'
    'statistics_spending_view.dart';
import 'package:yamt/features/statistics/presentation/views/'
    'statistics_waste_view.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('StatisticsSpendingView renders tracked spending cards', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      _TestApp(
        child: StatisticsSpendingView(
          timeframe: StatisticsTimeframe.week,
          inventoryAsync: AsyncValue.data([
            InventoryItem.create(
              id: 'rice',
              name: 'Rice',
              entryDate: now,
              storeName: 'REWE',
              quantity: 2,
              initialQuantity: 2,
              unitPrice: 2,
              receiptDate: now.subtract(const Duration(days: 1)),
            ),
          ]),
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Tracked spending'), findsOneWidget);
    expect(find.text('Top stores'), findsOneWidget);
    expect(find.text('Most expensive items'), findsOneWidget);
  });

  testWidgets('StatisticsWasteView renders placeholder cards', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: StatisticsWasteView(
          inventoryAsync: const AsyncValue.data(<InventoryItem>[]),
          mealsAsync: const AsyncValue.data(<PreparedMeal>[]),
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Food waste overview'), findsOneWidget);
    expect(find.text('Waste reasons'), findsOneWidget);
  });

  testWidgets('StatisticsCaloriesView renders overview cards', (tester) async {
    final snapshot = StatisticsCalorieSnapshot(
      days: [
        StatisticsCalorieDaySummary(
          date: DateTime(2026, 3, 27),
          entryCount: 1,
          totalKcal: 1800,
          goalKcal: 2000,
        ),
      ],
      totalEntries: 1,
      balanceRemainingKcal: 200,
      trackedDayCount: 1,
      goalMetDayCount: 1,
      averageTrackedKcal: 1800,
      macroShares: const [
        StatisticsMacroShare(
          type: StatisticsMacroType.carbs,
          grams: 120,
          share: 0.5,
        ),
        StatisticsMacroShare(
          type: StatisticsMacroType.protein,
          grams: 90,
          share: 0.3,
        ),
        StatisticsMacroShare(
          type: StatisticsMacroType.fat,
          grams: 40,
          share: 0.2,
        ),
      ],
    );

    await tester.pumpWidget(
      _TestApp(
        child: StatisticsCaloriesView(
          calorieAsync: AsyncValue.data(snapshot),
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Calories overview'), findsOneWidget);
    expect(find.text('Goal streak'), findsOneWidget);
    expect(find.text('Macro split'), findsNWidgets(2));
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }
}
