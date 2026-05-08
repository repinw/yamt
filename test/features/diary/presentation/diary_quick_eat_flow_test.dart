import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/inventory_manual_add_page.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  inventoryBackedCalorieEntrySaveFlow,
])
void main() {
  testWidgets('manual quick-eat sources push manual add with route args', (
    tester,
  ) async {
    final cases = <DiaryQuickEatSource, InventoryManualAddInitialAction>{
      DiaryQuickEatSource.barcode: InventoryManualAddInitialAction.barcodeScan,
      DiaryQuickEatSource.manualSearch:
          InventoryManualAddInitialAction.manualSearch,
      DiaryQuickEatSource.ai: InventoryManualAddInitialAction.aiSuggestion,
    };

    for (final entry in cases.entries) {
      await tester.pumpWidget(
        _RouteHarness(
          source: entry.key,
          selectedDay: DateTime(2026, 4, 27),
        ),
      );

      await tester.tap(find.byKey(_openFlowButtonKey));
      await tester.pumpAndSettle();

      expect(find.text('action:${entry.value.name}'), findsOneWidget);
      expect(find.text('quickEatOnly:true'), findsOneWidget);
      expect(find.text('mealType:lunch'), findsOneWidget);
      expect(find.text('loggedDay:2026-04-27'), findsOneWidget);
    }
  });

  testWidgets(
    'inventory picker shows empty state without shrink-wrapping list',
    (
      tester,
    ) async {
      await _pumpPickerHarness(
        tester,
        items: const <InventoryItem>[],
        meals: const <PreparedMeal>[],
      );

      await tester.tap(find.byKey(_openPickerButtonKey));
      await tester.pumpAndSettle();

      expect(find.text('No available food in inventory.'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    },
  );

  testWidgets('inventory picker renders foods lazily and returns selection', (
    tester,
  ) async {
    final item = _inventoryItem(id: 'item-1', name: 'Greek Yogurt');
    final meal = _preparedMeal(id: 'meal-1', name: 'Pasta Bowl');

    await _pumpPickerHarness(tester, items: [item], meals: [meal]);

    await tester.tap(find.byKey(_openPickerButtonKey));
    await tester.pumpAndSettle();

    final listView = tester.widget<ListView>(find.byType(ListView));
    expect(listView.shrinkWrap, isFalse);
    expect(find.text('Greek Yogurt'), findsOneWidget);
    expect(find.text('Pasta Bowl'), findsOneWidget);

    await tester.tap(find.text('Greek Yogurt'));
    await tester.pumpAndSettle();

    expect(find.text('selected:item:item-1'), findsOneWidget);

    await tester.tap(find.byKey(_openPickerButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pasta Bowl'));
    await tester.pumpAndSettle();

    expect(find.text('selected:meal:meal-1'), findsOneWidget);
  });
}

const _openFlowButtonKey = Key('open_quick_eat_flow');
const _openPickerButtonKey = Key('open_inventory_picker');

@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  inventoryBackedCalorieEntrySaveFlow,
])
class _RouteHarness extends StatelessWidget {
  const _RouteHarness({
    required this.source,
    required this.selectedDay,
  });

  final DiaryQuickEatSource source;
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: AppRoutes.root,
      routes: [
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) => _QuickEatRouteLauncher(
            source: source,
            selectedDay: selectedDay,
          ),
        ),
        GoRoute(
          path: AppRoutes.homeInventoryManualAdd,
          builder: (context, state) {
            final args = state.extra! as InventoryManualAddRouteArgs;
            final loggedAt = args.preselectedLoggedAt!;
            final dayText =
                '${loggedAt.year.toString().padLeft(4, '0')}-'
                '${loggedAt.month.toString().padLeft(2, '0')}-'
                '${loggedAt.day.toString().padLeft(2, '0')}';

            return Scaffold(
              body: Column(
                children: [
                  Text('action:${args.initialAction.name}'),
                  Text('quickEatOnly:${args.quickEatOnly}'),
                  Text('mealType:${args.preselectedMealType!.jsonValue}'),
                  Text('loggedDay:$dayText'),
                ],
              ),
            );
          },
        ),
      ],
    );

    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}

@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  inventoryBackedCalorieEntrySaveFlow,
])
class _QuickEatRouteLauncher extends ConsumerWidget {
  const _QuickEatRouteLauncher({
    required this.source,
    required this.selectedDay,
  });

  final DiaryQuickEatSource source;
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: TextButton(
        key: _openFlowButtonKey,
        onPressed: () {
          unawaited(
            DiaryQuickEatFlow.openSource(
              context: context,
              ref: ref,
              source: source,
              mealType: MealType.lunch,
              selectedDay: selectedDay,
            ),
          );
        },
        child: const Text('Open'),
      ),
    );
  }
}

Future<void> _pumpPickerHarness(
  WidgetTester tester, {
  required List<InventoryItem> items,
  required List<PreparedMeal> meals,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _PickerHarness(items: items, meals: meals),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _PickerHarness extends StatefulWidget {
  const _PickerHarness({
    required this.items,
    required this.meals,
  });

  final List<InventoryItem> items;
  final List<PreparedMeal> meals;

  @override
  State<_PickerHarness> createState() => _PickerHarnessState();
}

class _PickerHarnessState extends State<_PickerHarness> {
  String _selectedText = 'selected:none';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(_selectedText),
          TextButton(
            key: _openPickerButtonKey,
            onPressed: () {
              unawaited(_openPicker());
            },
            child: const Text('Open picker'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPicker() async {
    final selection = await showModalBottomSheet<DiaryInventoryFoodSelection>(
      context: context,
      builder: (context) => DiaryInventoryFoodPicker(
        items: widget.items,
        meals: widget.meals,
      ),
    );
    if (!mounted || selection == null) {
      return;
    }

    setState(() {
      _selectedText = switch (selection) {
        DiaryInventoryItemFoodSelection(:final item) =>
          'selected:item:${item.id}',
        DiaryPreparedMealFoodSelection(:final meal) =>
          'selected:meal:${meal.id}',
      };
    });
  }
}

InventoryItem _inventoryItem({
  required String id,
  required String name,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime(2026, 4, 27),
    storeName: 'Test Store',
    quantity: 1,
    brand: 'Test Brand',
    imageUrl: 'https://example.com/$id.jpg',
  );
}

PreparedMeal _preparedMeal({
  required String id,
  required String name,
}) {
  return PreparedMeal(
    id: id,
    name: name,
    totalPortions: 2,
    remainingPortions: 1,
    totalKcal: 500,
    totalProtein: 20,
    totalCarbs: 60,
    totalFat: 10,
    createdAt: DateTime(2026, 4, 27),
    updatedAt: DateTime(2026, 4, 27),
    components: const [],
    imageUrl: 'https://example.com/$id.jpg',
  );
}
