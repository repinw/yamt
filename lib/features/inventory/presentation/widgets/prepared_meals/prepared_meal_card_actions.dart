// Internal split file. Public names are imported only by sibling widgets.
// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_discard_reason_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_action_dialogs.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_card_pending_ingredient.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_edit_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

const preparedMealCardLogName = 'PreparedMealCard';

@Dependencies([InventoryItemsController, preparedMealImagePicker])
mixin PreparedMealCardActions<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  bool get expandedState;
  set expandedState(bool value);

  bool get workingState;
  set workingState(bool value);

  PreparedMeal get actionMeal;

  Future<bool> Function({
    required String mealId,
    required num portions,
    required MealType mealType,
    required DateTime loggedDay,
  })
  get eatPressedAction;

  Future<bool> Function(
    String mealId,
    num portions,
    InventoryDiscardReason reason,
  )
  get throwAwayPressedAction;

  Future<bool> Function(
    String mealId,
    String ingredient,
    List<String> inventoryItemIds,
  )?
  get fillPendingIngredientPressedAction;

  Future<bool> Function(String mealId, String ingredient)?
  get ignorePendingIngredientPressedAction;

  Future<bool> Function(String mealId, PreparedMealEditSheetResult result)
  get editPressedAction;

  Future<bool> Function(String mealId, PreparedMealEditSheetResult result)?
  get selectEditIngredientsPressedAction;

  Future<bool> Function(String mealId) get unbundlePressedAction;

  Future<bool> Function(PreparedMeal meal) get saveTemplatePressedAction;

  void toggleExpanded() {
    setState(() {
      expandedState = !expandedState;
    });
  }

  void handleEatPressed() {
    unawaited(_runEatFlow());
  }

  void handleThrowAwayPressed() {
    unawaited(_runThrowAwayFlow());
  }

  void handleFillPendingIngredient({
    required String ingredient,
    required List<InventoryItem> inventoryItems,
  }) {
    unawaited(
      _runFillPendingIngredientFlow(
        ingredient: ingredient,
        inventoryItems: inventoryItems,
      ),
    );
  }

  void handleIgnorePendingIngredient(String ingredient) {
    unawaited(_runIgnorePendingIngredientFlow(ingredient: ingredient));
  }

  void handleEditPressed() {
    unawaited(_runEditFlow());
  }

  void handleUnbundlePressed() {
    unawaited(
      _runAction(
        () => unbundlePressedAction(actionMeal.id),
        failureMessage: AppLocalizations.of(context)!.preparedMealActionFailed,
      ),
    );
  }

  void handleSaveTemplatePressed() {
    unawaited(
      _runAction(
        () => saveTemplatePressedAction(actionMeal),
        failureMessage: AppLocalizations.of(context)!.preparedMealActionFailed,
      ),
    );
  }

  Future<void> _runEatFlow() async {
    final l10n = AppLocalizations.of(context)!;
    final imageRef = maybeLocalImageAssetRef(actionMeal.imageAssetId);
    final imageBytes = imageRef == null
        ? null
        : ref.read(localImageBytesProvider(imageRef)).asData?.value;
    final result = await showPreparedMealEatDialog(
      context,
      actionMeal,
      imageBytes: imageBytes,
    );
    if (!mounted || result == null) {
      return;
    }

    await _runAction(
      () => eatPressedAction(
        mealId: actionMeal.id,
        portions: result.portions,
        mealType: result.mealType,
        loggedDay: result.loggedDay,
      ),
      failureMessage: l10n.preparedMealActionFailed,
    );
  }

  Future<void> _runEditFlow() async {
    final inventoryItems =
        ref.read(inventoryItemsControllerProvider).asData?.value ??
        const <InventoryItem>[];
    final result = await showPreparedMealEditSheet(
      context: context,
      meal: actionMeal,
      inventoryItems: inventoryItems,
    );
    if (!mounted || result == null) {
      return;
    }

    if (result.requestIngredientSelection) {
      final onSelectEditIngredientsPressed = selectEditIngredientsPressedAction;
      if (onSelectEditIngredientsPressed == null) {
        return;
      }
      await _runAction(
        () => onSelectEditIngredientsPressed(actionMeal.id, result),
        failureMessage: AppLocalizations.of(context)!.preparedMealActionFailed,
      );
      return;
    }

    await _runAction(
      () => editPressedAction(actionMeal.id, result),
      failureMessage: AppLocalizations.of(context)!.preparedMealActionFailed,
    );
  }

  Future<void> _runThrowAwayFlow() async {
    log(
      '_runThrowAwayFlow(): opening reason dialog for ${actionMeal.id}',
      name: preparedMealCardLogName,
    );
    final reason = await showInventoryDiscardReasonDialog(context);
    if (!mounted || reason == null) {
      log(
        '_runThrowAwayFlow(): reason dialog cancelled for ${actionMeal.id}',
        name: preparedMealCardLogName,
      );
      return;
    }
    log(
      '_runThrowAwayFlow(): confirmed reason=${reason.name} '
      'for ${actionMeal.id}',
      name: preparedMealCardLogName,
    );

    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }

    log(
      '_runThrowAwayFlow(): opening portion dialog for ${actionMeal.id}',
      name: preparedMealCardLogName,
    );
    final portions = await showPreparedMealPortionDialog(
      context: context,
      meal: actionMeal,
      title: AppLocalizations.of(context)!.preparedMealThrowAwayTitle,
    );
    if (!mounted || portions == null) {
      log(
        '_runThrowAwayFlow(): portion dialog cancelled for ${actionMeal.id}',
        name: preparedMealCardLogName,
      );
      return;
    }
    log(
      '_runThrowAwayFlow(): confirmed portions=$portions for ${actionMeal.id}',
      name: preparedMealCardLogName,
    );

    await _runAction(
      () => throwAwayPressedAction(actionMeal.id, portions, reason),
      failureMessage: AppLocalizations.of(context)!.preparedMealActionFailed,
    );
  }

  Future<void> _runFillPendingIngredientFlow({
    required String ingredient,
    required List<InventoryItem> inventoryItems,
  }) async {
    if (fillPendingIngredientPressedAction == null) {
      return;
    }

    final selectedItemIds = await showPendingIngredientSelectionSheet(
      context: context,
      ingredient: ingredient,
      inventoryItems: inventoryItems,
    );
    if (!mounted || selectedItemIds == null || selectedItemIds.isEmpty) {
      return;
    }

    await _runAction(
      () => fillPendingIngredientPressedAction!(
        actionMeal.id,
        ingredient,
        selectedItemIds,
      ),
      failureMessage: AppLocalizations.of(
        context,
      )!.preparedMealPendingIngredientFillFailed,
    );
  }

  Future<void> _runIgnorePendingIngredientFlow({
    required String ingredient,
  }) async {
    if (ignorePendingIngredientPressedAction == null) {
      return;
    }

    await _runAction(
      () => ignorePendingIngredientPressedAction!(actionMeal.id, ingredient),
      failureMessage: AppLocalizations.of(
        context,
      )!.preparedMealPendingIngredientIgnoreFailed,
    );
  }

  Future<void> _runAction(
    Future<bool> Function() action, {
    required String failureMessage,
  }) async {
    setState(() {
      workingState = true;
    });
    final success = await action();
    if (!mounted) {
      return;
    }
    setState(() {
      workingState = false;
    });
    if (success) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failureMessage)));
  }
}
