import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_entry_change_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_plan_controller.dart';
import 'package:yamt/features/diary/presentation/diary_inventory_food_picker.dart';
import 'package:yamt/features/diary/presentation/diary_quick_entry_page.dart';
import 'package:yamt/features/diary/presentation/models/'
    'diary_quick_entry_result.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_detail_flow.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_eat_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
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

  /// Calories typed in by hand, without a food.
  quickEntry,
}

/// Runs diary quick-eat flows.
class DiaryQuickEatFlow {
  const new _();

  /// Opens [source] for [selectedDay].
  ///
  /// The current time sets both the logged time and the preselected meal type.
  /// [ref] backs the meal page that a meal in the pot or with open rows
  /// opens from the Vorrat picker.
  static Future<void> openSource({
    required BuildContext context,
    required WidgetRef ref,
    required DiaryQuickEatSource source,
    required DateTime selectedDay,
  }) {
    final now = DateTime.now();
    final day = normalizeLocalDay(selectedDay);
    return _openSelectedSource(
      context: context,
      ref: ref,
      source: source,
      mealType: MealType.defaultForDateTime(now),
      loggedAt: DateTime(day.year, day.month, day.day, now.hour, now.minute),
    );
  }

  static Future<void> _openSelectedSource({
    required BuildContext context,
    required WidgetRef ref,
    required DiaryQuickEatSource source,
    required MealType mealType,
    required DateTime loggedAt,
  }) {
    Future<void> openHub(ProductSearchHubInitialIntent intent) {
      return _openProductSearchHub(
        context: context,
        initialIntent: intent,
        mealType: mealType,
        loggedAt: loggedAt,
      );
    }

    return switch (source) {
      DiaryQuickEatSource.inventory => _openInventoryPicker(
        context: context,
        ref: ref,
        mealType: mealType,
        loggedAt: loggedAt,
      ),
      DiaryQuickEatSource.quickEntry => _openQuickEntry(
        context: context,
        mealType: mealType,
        loggedAt: loggedAt,
      ),
      DiaryQuickEatSource.barcode => openHub(
        ProductSearchHubInitialIntent.barcode,
      ),
      DiaryQuickEatSource.manualSearch => openHub(
        ProductSearchHubInitialIntent.search,
      ),
      DiaryQuickEatSource.ai => openHub(ProductSearchHubInitialIntent.ai),
    };
  }

  static Future<void> _openQuickEntry({
    required BuildContext context,
    required MealType mealType,
    required DateTime loggedAt,
  }) async {
    final result = await Navigator.of(context, rootNavigator: true)
        .push<DiaryQuickEntryResult>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => DiaryQuickEntryPage(
              initialLoggedAt: loggedAt,
              initialMealType: mealType,
            ),
          ),
        );
    if (result == null || !context.mounted) {
      return;
    }
    switch (result) {
      case DiaryQuickEntrySaved(:final entry, :final isPlan):
        _showQuickEntrySaved(context, entry, isPlan: isPlan);
      case DiaryQuickEntryAiRequested(:final loggedAt, :final mealType):
        await _openProductSearchHub(
          context: context,
          initialIntent: ProductSearchHubInitialIntent.ai,
          mealType: mealType,
          loggedAt: loggedAt,
        );
    }
  }

  static void _showQuickEntrySaved(
    BuildContext context,
    CalorieEntry entry, {
    required bool isPlan,
  }) {
    final container = ProviderScope.containerOf(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    if (isPlan) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        l10n.diaryPlanSaved,
        onUndo: () =>
            container.read(diaryPlanControllerProvider.notifier).delete(entry),
      );
      return;
    }
    ScaffoldMessenger.of(context).showAppSnackBar(
      l10n.diaryQuickEntrySaved,
      onUndo: () async {
        final result = await container
            .read(diaryEntryChangeControllerProvider.notifier)
            .delete(entry, restoreToInventory: false);
        return result.isSuccess;
      },
    );
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
    required WidgetRef ref,
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
    if (selection case DiaryOpenPreparedMealSelection(:final meal)) {
      // The cook finishes the meal first: "Gekocht" for a pot, the meal
      // page for open rows, as in the Kochbuch.
      await (meal.isInPot
          ? context.push(AppRoutes.homeCookedMealPath(meal.id))
          : PreparedMealDetailFlow.open(
              context: context,
              ref: ref,
              meal: meal,
            ));
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
      // Opened before, in _openInventoryPicker.
      DiaryOpenPreparedMealSelection() => Future.value(),
    };
  }
}
