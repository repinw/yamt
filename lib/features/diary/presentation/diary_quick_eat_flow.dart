import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/diary_inventory_food_picker.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_eat_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';

/// Diary quick-eat sources.
enum DiaryQuickEatSource {
  /// Eat from inventory.
  inventory,

  /// Scan barcode and eat.
  barcode,

  /// Manual product search and eat.
  manualSearch,

  /// AI food estimate and eat.
  ai,
}

/// Runs diary quick-eat flows.
class DiaryQuickEatFlow {
  const new _();

  /// Opens [source] for [selectedDay].
  ///
  /// The current time sets both the logged time and the preselected meal type.
  static Future<void> openSource({
    required BuildContext context,
    required DiaryQuickEatSource source,
    required DateTime selectedDay,
  }) {
    final now = DateTime.now();
    final day = normalizeLocalDay(selectedDay);
    return _openSelectedSource(
      context: context,
      source: source,
      mealType: MealType.defaultForDateTime(now),
      loggedAt: DateTime(day.year, day.month, day.day, now.hour, now.minute),
    );
  }

  static Future<void> _openSelectedSource({
    required BuildContext context,
    required DiaryQuickEatSource source,
    required MealType mealType,
    required DateTime loggedAt,
  }) {
    if (source == DiaryQuickEatSource.inventory) {
      return _openInventoryPicker(
        context: context,
        mealType: mealType,
        loggedAt: loggedAt,
      );
    }
    return _openProductSearchHub(
      context: context,
      initialIntent: _resolveProductSearchIntent(source),
      mealType: mealType,
      loggedAt: loggedAt,
    );
  }

  static ProductSearchHubInitialIntent _resolveProductSearchIntent(
    DiaryQuickEatSource source,
  ) {
    return switch (source) {
      DiaryQuickEatSource.barcode => ProductSearchHubInitialIntent.barcode,
      DiaryQuickEatSource.manualSearch => ProductSearchHubInitialIntent.search,
      DiaryQuickEatSource.ai => ProductSearchHubInitialIntent.ai,
      DiaryQuickEatSource.inventory => throw StateError(
        'Inventory source does not use product search.',
      ),
    };
  }

  static Future<void> _openProductSearchHub({
    required BuildContext context,
    required ProductSearchHubInitialIntent initialIntent,
    required MealType mealType,
    required DateTime loggedAt,
  }) async {
    await context.push<void>(
      AppRoutes.homeProductSearchHub,
      extra: ProductSearchHubRouteArgs.diary(
        initialIntent: initialIntent,
        preselectedMealType: mealType,
        preselectedLoggedAt: loggedAt,
      ),
    );
  }

  static Future<void> _openInventoryPicker({
    required BuildContext context,
    required MealType mealType,
    required DateTime loggedAt,
  }) async {
    final selection = await showModalBottomSheet<DiaryInventoryFoodSelection>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DiaryInventoryFoodPickerSheet(),
    );
    if (!context.mounted || selection == null) {
      return;
    }
    await _eatInventorySelection(
      context: context,
      selection: selection,
      mealType: mealType,
      loggedAt: loggedAt,
    );
  }

  static Future<void> _eatInventorySelection({
    required BuildContext context,
    required DiaryInventoryFoodSelection selection,
    required MealType mealType,
    required DateTime loggedAt,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final entry = await _eatSelection(
      context: context,
      selection: selection,
      mealType: mealType,
      loggedAt: loggedAt,
    );
    if (entry == null) {
      return;
    }
    unawaited(
      container
          .read(
            diaryDayDashboardControllerProvider(
              normalizeLocalDay(entry.loggedAt),
            ).notifier,
          )
          .refreshAfterMutation(),
    );
  }

  static Future<CalorieEntry?> _eatSelection({
    required BuildContext context,
    required DiaryInventoryFoodSelection selection,
    required MealType mealType,
    required DateTime loggedAt,
  }) {
    return switch (selection) {
      DiaryInventoryItemFoodSelection(:final item) => InventoryItemEatFlow.eat(
        context: context,
        item: item,
        initialLoggedAt: loggedAt,
        initialMealType: mealType,
      ),
      DiaryPreparedMealFoodSelection(:final meal) => PreparedMealEatFlow.eat(
        context: context,
        meal: meal,
        initialLoggedAt: loggedAt,
        initialMealType: mealType,
      ),
    };
  }
}
