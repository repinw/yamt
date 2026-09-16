import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/diary/application/'
    'diary_food_log_mutation_adapter.dart';
import 'package:yamt/features/diary/domain/diary_food_log_session.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_food_log_feedback_controller.dart';
import 'package:yamt/features/diary/presentation/diary_inventory_food_picker.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_quick_eat_inventory_item_flow.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_quick_eat_prepared_meal_flow.dart';
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
    final session = DiaryFoodLogSession();
    await _openSourceWithSession(
      context: context,
      container: container,
      session: session,
      source: source,
      mealType: mealType,
      loggedAt: loggedAt,
    );
    if (!context.mounted) {
      return;
    }
    await _enqueueFeedback(
      context: context,
      container: container,
      session: session,
    );
  }

  static Future<void> _openSourceWithSession({
    required BuildContext context,
    required ProviderContainer container,
    required DiaryFoodLogSession session,
    required DiaryQuickEatSource source,
    required MealType mealType,
    required DateTime loggedAt,
  }) async {
    final subscription = container
        .read(diaryFoodLogMutationAdapterProvider)
        .listen(session);
    try {
      await _openSelectedSource(
        context: context,
        source: source,
        mealType: mealType,
        loggedAt: loggedAt,
      );
    } finally {
      await subscription.cancel();
    }
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

  static Future<void> _enqueueFeedback({
    required BuildContext context,
    required ProviderContainer container,
    required DiaryFoodLogSession session,
  }) async {
    if (!context.mounted || session.dayGroups.isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await container
        .read(diaryFoodLogFeedbackControllerProvider.notifier)
        .enqueue(session.dayGroups);
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
    final normalizedDay = normalizeLocalDay(selectedDay);
    return DateTime(
      normalizedDay.year,
      normalizedDay.month,
      normalizedDay.day,
      now.hour,
      now.minute,
    );
  }
}
