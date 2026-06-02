import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/'
    'diary_quick_eat_inventory_provider.dart';
import 'package:yamt/features/diary/presentation/diary_inventory_food_picker.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_food_flow.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';
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
@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  diaryQuickEatInventory,
  inventoryBackedCalorieEntrySaveFlow,
])
class DiaryQuickEatFlow {
  const DiaryQuickEatFlow._();

  /// Open selected quick-eat source.
  static Future<void> openSource({
    required BuildContext context,
    required DiaryQuickEatSource source,
    required MealType mealType,
    required DateTime selectedDay,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final loggedAt = _resolveLoggedAt(selectedDay);
    switch (source) {
      case DiaryQuickEatSource.inventory:
        await _openInventoryPicker(
          context: context,
          mealType: mealType,
          loggedAt: loggedAt,
        );
      case DiaryQuickEatSource.barcode:
        await _openProductSearchHub(
          context: context,
          initialIntent: ProductSearchHubInitialIntent.barcode,
          mealType: mealType,
          loggedAt: loggedAt,
        );
      case DiaryQuickEatSource.manualSearch:
        await _openProductSearchHub(
          context: context,
          initialIntent: ProductSearchHubInitialIntent.search,
          mealType: mealType,
          loggedAt: loggedAt,
        );
      case DiaryQuickEatSource.ai:
        await _openProductSearchHub(
          context: context,
          initialIntent: ProductSearchHubInitialIntent.ai,
          mealType: mealType,
          loggedAt: loggedAt,
        );
    }
    if (context.mounted) {
      refreshDiaryAfterQuickEat(container, loggedAt);
    }
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
    switch (selection) {
      case DiaryInventoryItemFoodSelection(:final item):
        await eatDiaryQuickEatInventoryItem(
          context: context,
          item: item,
          mealType: mealType,
          loggedAt: loggedAt,
        );
      case DiaryPreparedMealFoodSelection(:final meal):
        await eatDiaryQuickEatPreparedMeal(
          context: context,
          meal: meal,
          mealType: mealType,
          loggedAt: loggedAt,
        );
    }
  }

  static DateTime _resolveLoggedAt(DateTime selectedDay) {
    final now = DateTime.now();
    final normalizedDay = normalizeDiaryDay(selectedDay);
    return DateTime(
      normalizedDay.year,
      normalizedDay.month,
      normalizedDay.day,
      now.hour,
      now.minute,
    );
  }
}
