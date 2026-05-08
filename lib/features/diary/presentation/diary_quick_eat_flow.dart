import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_inventory_food_picker.dart';
import 'package:yamt/features/diary/provider/diary_entries_provider.dart';
import 'package:yamt/features/diary/provider/diary_meal_sections_provider.dart';
import 'package:yamt/features/diary/provider/diary_nutrition_bars_provider.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_manual_add_page.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_list/inventory_item_row/inventory_item_eat_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_action_dialogs.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

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
  inventoryBackedCalorieEntrySaveFlow,
])
class DiaryQuickEatFlow {
  const DiaryQuickEatFlow._();

  /// Open selected quick-eat source.
  static Future<void> openSource({
    required BuildContext context,
    required WidgetRef ref,
    required DiaryQuickEatSource source,
    required MealType mealType,
    required DateTime selectedDay,
  }) async {
    final loggedAt = _resolveLoggedAt(selectedDay);
    switch (source) {
      case DiaryQuickEatSource.inventory:
        await _openInventoryPicker(
          context: context,
          ref: ref,
          mealType: mealType,
          loggedAt: loggedAt,
        );
      case DiaryQuickEatSource.barcode:
        await _openManualAdd(
          context: context,
          action: InventoryManualAddInitialAction.barcodeScan,
          mealType: mealType,
          loggedAt: loggedAt,
        );
      case DiaryQuickEatSource.manualSearch:
        await _openManualAdd(
          context: context,
          action: InventoryManualAddInitialAction.manualSearch,
          mealType: mealType,
          loggedAt: loggedAt,
        );
      case DiaryQuickEatSource.ai:
        await _openManualAdd(
          context: context,
          action: InventoryManualAddInitialAction.aiSuggestion,
          mealType: mealType,
          loggedAt: loggedAt,
        );
    }
    if (context.mounted) {
      _refreshDiary(ref, loggedAt);
    }
  }

  static Future<void> _openManualAdd({
    required BuildContext context,
    required InventoryManualAddInitialAction action,
    required MealType mealType,
    required DateTime loggedAt,
  }) async {
    await context.push<void>(
      AppRoutes.homeInventoryManualAdd,
      extra: InventoryManualAddRouteArgs(
        initialAction: action,
        quickEatOnly: true,
        preselectedMealType: mealType,
        preselectedLoggedAt: loggedAt,
      ),
    );
  }

  static Future<void> _openInventoryPicker({
    required BuildContext context,
    required WidgetRef ref,
    required MealType mealType,
    required DateTime loggedAt,
  }) async {
    final itemsFuture = ref.read(inventoryItemsControllerProvider.future);
    final mealsFuture = ref.read(preparedMealsControllerProvider.future);
    final items = await itemsFuture;
    final meals = await mealsFuture;
    if (!context.mounted) {
      return;
    }
    final selection = await showModalBottomSheet<DiaryInventoryFoodSelection>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DiaryInventoryFoodPicker(
          items: items.where(canEatInventoryItem).toList(growable: false),
          meals: meals
              .where((meal) => !meal.isDepleted)
              .toList(
                growable: false,
              ),
        );
      },
    );
    if (!context.mounted || selection == null) {
      return;
    }
    switch (selection) {
      case DiaryInventoryItemFoodSelection(:final item):
        await _eatInventoryItem(
          context: context,
          ref: ref,
          item: item,
          mealType: mealType,
          loggedAt: loggedAt,
        );
      case DiaryPreparedMealFoodSelection(:final meal):
        await _eatPreparedMeal(
          context: context,
          ref: ref,
          meal: meal,
          mealType: mealType,
          loggedAt: loggedAt,
        );
    }
  }

  static Future<void> _eatInventoryItem({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem item,
    required MealType mealType,
    required DateTime loggedAt,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final maxAmount = maxInventoryAmount(item);
    if (maxAmount == null) {
      return;
    }
    final request = await showInventoryItemEatSheet(
      context: context,
      item: item,
      maxAmount: maxAmount,
      invalidAmountMessage: l10n.inventoryReceiptReviewInvalidNumber,
      initialLoggedAt: loggedAt,
      initialMealType: mealType,
    );
    if (!context.mounted || request == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final pendingConsumption = await controller.stagePendingConsumption(
      item.id,
      request.inventoryAmount,
    );
    if (pendingConsumption == null) {
      _showSnackBarWithMessenger(messenger, l10n.inventoryItemActionFailed);
      return;
    }
    if (!context.mounted) {
      await controller.discardPendingConsumption(pendingConsumption.id);
      return;
    }
    await InventoryItemEatFlow.complete(
      context: context,
      ref: ref,
      itemBeforeMutation: item,
      request: request,
      pendingConsumptionId: pendingConsumption.id,
    );
  }

  static Future<void> _eatPreparedMeal({
    required BuildContext context,
    required WidgetRef ref,
    required PreparedMeal meal,
    required MealType mealType,
    required DateTime loggedAt,
  }) async {
    final result = await showPreparedMealEatDialog(
      context,
      meal,
      useRootNavigator: true,
      initialLoggedAt: loggedAt,
      initialMealType: mealType,
    );
    if (!context.mounted || result == null) {
      return;
    }
    final saved = await ref
        .read(preparedMealsControllerProvider.notifier)
        .consumePreparedMeal(
          mealId: meal.id,
          consumedPortions: result.portions,
          mealType: result.mealType,
          loggedDay: result.loggedDay,
        );
    if (!context.mounted || saved) {
      return;
    }
    _showSnackBar(
      context,
      AppLocalizations.of(context)!.preparedMealActionFailed,
    );
  }

  /// Whether an inventory item can be selected for diary quick eat.
  @visibleForTesting
  static bool canEatInventoryItem(InventoryItem item) {
    return maxInventoryAmount(item) != null;
  }

  /// Maximum consumable inventory amount for diary quick eat.
  @visibleForTesting
  static int? maxInventoryAmount(InventoryItem item) {
    if (item.usesAmountProgress) {
      if (item.amountUnit == null || item.currentAmount < 1) {
        return null;
      }
      return item.currentAmount;
    }
    if (item.quantity < 1) {
      return null;
    }
    return item.quantity;
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

  static void _refreshDiary(WidgetRef ref, DateTime loggedAt) {
    final day = normalizeDiaryDay(loggedAt);
    ref
      ..invalidate(diaryEntriesForDayProvider(day))
      ..invalidate(diaryMealSectionsProvider(day))
      ..invalidate(diaryNutritionBarsDataProvider(day));
  }

  static void _showSnackBar(BuildContext context, String message) {
    _showSnackBarWithMessenger(ScaffoldMessenger.of(context), message);
  }

  static void _showSnackBarWithMessenger(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
