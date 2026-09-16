import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/diary/application/'
    'diary_quick_eat_inventory_provider.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_quick_eat_flow_support.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_picker.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_prepared_meal_eat_request.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _diaryQuickEatFlowLogName = 'DiaryQuickEatFlow';

/// Eats a prepared meal from the diary quick-eat flow.
Future<void> eatDiaryQuickEatPreparedMeal({
  required BuildContext context,
  required PreparedMeal meal,
  required MealType mealType,
  required DateTime loggedAt,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final result = await container
      .read(inventoryQuickEatPickerProvider)
      .pickPreparedMeal(
        context: context,
        meal: meal,
        useRootNavigator: true,
        initialLoggedAt: loggedAt,
        initialMealType: mealType,
      );
  if (!context.mounted || result == null) {
    return;
  }
  await _consumePreparedMeal(context: context, meal: meal, request: result);
}

Future<void> _consumePreparedMeal({
  required BuildContext context,
  required PreparedMeal meal,
  required InventoryPreparedMealEatRequest request,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  try {
    await withDiaryQuickEatActions(
      container: container,
      action: () => _runPreparedMealMutation(
        context: context,
        container: container,
        meal: meal,
        request: request,
      ),
    );
  } on Object catch (error, stackTrace) {
    log(
      'Diary prepared meal eat flow failed.',
      name: _diaryQuickEatFlowLogName,
      error: error,
      stackTrace: stackTrace,
    );
    if (context.mounted) {
      _showPreparedMealFailure(context);
    }
  }
}

Future<void> _runPreparedMealMutation({
  required BuildContext context,
  required ProviderContainer container,
  required PreparedMeal meal,
  required InventoryPreparedMealEatRequest request,
}) async {
  if (!context.mounted) {
    return;
  }
  final saved = await container
      .read(diaryQuickEatInventoryActionsProvider)
      .consumePreparedMeal(
        mealId: meal.id,
        consumedPortions: request.portions,
        mealType: request.mealType,
        loggedDay: request.loggedDay,
      );
  if (saved) {
    refreshDiaryAfterQuickEat(container, request.loggedDay);
    return;
  }
  if (context.mounted) {
    _showPreparedMealFailure(context);
  }
}

void _showPreparedMealFailure(BuildContext context) {
  showDiaryQuickEatSnackBar(
    context,
    AppLocalizations.of(context)!.preparedMealActionFailed,
  );
}
