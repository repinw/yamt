import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/statistics/domain/calorie_metrics.dart';
import 'package:yamt/features/statistics/domain/statistics_models.dart';
import 'package:yamt/features/statistics/presentation/views/'
    'statistics_calories_view.dart';
import 'package:yamt/features/statistics/presentation/views/'
    'statistics_spending_view.dart';
import 'package:yamt/features/statistics/presentation/views/'
    'statistics_waste_view.dart';
import 'package:yamt/features/statistics/provider/'
    'statistics_calorie_data_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _FakeInventoryDiscardEventRepository
    implements InventoryDiscardEventRepository {
  const _FakeInventoryDiscardEventRepository(this.events);

  final List<InventoryDiscardEvent> events;

  @override
  Future<List<InventoryDiscardEvent>> readAll() async {
    return events;
  }

  @override
  Future<bool> saveEvent(InventoryDiscardEvent event) async {
    return true;
  }

  @override
  Future<bool> deleteEvent(String eventId) async {
    return true;
  }
}

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

  testWidgets('StatisticsSpendingView shows newest seven chart days', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final inventoryItems = List.generate(8, (index) {
      final day = today.subtract(Duration(days: 7 - index));
      return InventoryItem.create(
        id: 'item-$index',
        name: 'Item $index',
        entryDate: day,
        storeName: 'REWE',
        quantity: 1,
        unitPrice: 1,
        receiptDate: day,
      );
    });

    await tester.pumpWidget(
      _TestApp(
        child: StatisticsSpendingView(
          timeframe: StatisticsTimeframe.total,
          inventoryAsync: AsyncValue.data(inventoryItems),
          onRetry: () {},
        ),
      ),
    );

    final locale = DateFormat.Md('en');
    final oldestLabel = locale.format(today.subtract(const Duration(days: 7)));
    final newestVisibleLabel = locale.format(
      today.subtract(const Duration(days: 6)),
    );
    final latestLabel = locale.format(today);

    expect(find.text(oldestLabel), findsNothing);
    expect(find.text(newestVisibleLabel), findsOneWidget);
    expect(find.text(latestLabel), findsOneWidget);
  });

  testWidgets('StatisticsWasteView renders placeholder cards', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        overrides: [
          inventoryDiscardEventRepositoryProvider.overrideWithValue(
            const _FakeInventoryDiscardEventRepository(
              <InventoryDiscardEvent>[],
            ),
          ),
        ],
        child: StatisticsWasteView(
          timeframe: StatisticsTimeframe.week,
          onRetry: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

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
        overrides: [
          statisticsCalorieDataProvider(
            StatisticsTimeframe.week,
          ).overrideWith((ref) async => snapshot),
        ],
        child: StatisticsCaloriesView(
          timeframe: StatisticsTimeframe.week,
          onRetry: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calories overview'), findsOneWidget);
    expect(find.text('Goal streak'), findsOneWidget);
    expect(find.text('Macro split'), findsNWidgets(2));
  });

  testWidgets(
    'StatisticsCaloriesView shows no data when macro shares are empty',
    (tester) async {
      final snapshot = StatisticsCalorieSnapshot(
        days: [
          StatisticsCalorieDaySummary(
            date: DateTime(2026, 3, 27),
            entryCount: 0,
            totalKcal: 0,
            goalKcal: 2000,
          ),
        ],
        totalEntries: 0,
        balanceRemainingKcal: 2000,
        trackedDayCount: 0,
        goalMetDayCount: 0,
        averageTrackedKcal: 0,
        macroShares: const [
          StatisticsMacroShare(
            type: StatisticsMacroType.carbs,
            grams: 0,
            share: 0,
          ),
          StatisticsMacroShare(
            type: StatisticsMacroType.protein,
            grams: 0,
            share: 0,
          ),
          StatisticsMacroShare(
            type: StatisticsMacroType.fat,
            grams: 0,
            share: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        _TestApp(
          overrides: [
            statisticsCalorieDataProvider(
              StatisticsTimeframe.week,
            ).overrideWith((ref) async => snapshot),
          ],
          child: StatisticsCaloriesView(
            timeframe: StatisticsTimeframe.week,
            onRetry: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No data yet'), findsAtLeastNWidgets(1));
      expect(
        find.text('No calorie entries in this period yet.'),
        findsOneWidget,
      );
    },
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child, this.overrides = const []});

  final Widget child;
  final List<dynamic> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides.cast(),
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
