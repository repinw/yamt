import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_entries_provider.dart';
import 'package:yamt/features/diary/application/diary_meal_sections_provider.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_provider.dart';
import 'package:yamt/features/diary/application/'
    'diary_quick_eat_inventory_provider.dart';
import 'package:yamt/features/diary/presentation/diary_inventory_food_picker.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_manual_add_page.dart';
import 'package:yamt/features/inventory/presentation/inventory_quick_eat_flow.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
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
  diaryQuickEatInventory,
  diaryQuickEatInventoryActions,
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
    final container = ProviderScope.containerOf(context, listen: false);
    final inventoryData = await container.read(
      diaryQuickEatInventoryProvider.future,
    );
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
          items: inventoryData.items,
          meals: inventoryData.meals,
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
    required InventoryItem item,
    required MealType mealType,
    required DateTime loggedAt,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final maxAmount = maxDiaryQuickEatInventoryAmount(item);
    if (maxAmount == null) {
      return;
    }
    final request = await InventoryQuickEatFlow.showItemSheet(
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
    final container = ProviderScope.containerOf(context, listen: false);
    final actions = container.read(diaryQuickEatInventoryActionsProvider);
    final pendingConsumptionId = await actions.stageInventoryItemConsumption(
      itemId: item.id,
      amount: request.inventoryAmount,
    );
    if (pendingConsumptionId == null) {
      _showSnackBarWithMessenger(messenger, l10n.inventoryItemActionFailed);
      return;
    }
    if (!context.mounted) {
      await actions.discardInventoryItemConsumption(pendingConsumptionId);
      return;
    }
    await InventoryItemEatFlow.complete(
      context: context,
      container: container,
      itemBeforeMutation: item,
      request: request,
      pendingConsumptionId: pendingConsumptionId,
    );
  }

  static Future<void> _eatPreparedMeal({
    required BuildContext context,
    required WidgetRef ref,
    required PreparedMeal meal,
    required MealType mealType,
    required DateTime loggedAt,
  }) async {
    final result = await InventoryQuickEatFlow.showPreparedMealSheet(
      context: context,
      meal: meal,
      useRootNavigator: true,
      initialLoggedAt: loggedAt,
      initialMealType: mealType,
    );
    if (!context.mounted || result == null) {
      return;
    }
    final saved = await ref
        .read(diaryQuickEatInventoryActionsProvider)
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
