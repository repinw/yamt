import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/pending_ingredient_stock.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'prepared_meal_actions.dart';
import 'package:yamt/features/inventory/presentation/'
    'prepared_meal_edit_page.dart';
import 'package:yamt/features/inventory/presentation/'
    'prepared_meal_pending_food_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_meal_actions_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_meal_ingredients_box.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_discard_reason_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_pending_fill_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_pending_ingredient_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_portion_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_weight_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The parts of a meal's detail page under the eat controls: the "Zutaten"
/// box, where rows are filled, ignored or opened again and foods taken out
/// again, and the "Mahlzeit" card with edit, recipe, weight, unbundle and throw
/// away.
///
/// It follows the live meal. When the meal is gone, for example after
/// unbundling, it closes the page.
class EatMealDetailSections extends ConsumerStatefulWidget {
  /// Creates the sections for [meal].
  const new({required this.meal, required this.actions, super.key});

  /// The meal as the page opened it.
  final PreparedMeal meal;

  /// What the Vorrat page does for each action.
  final PreparedMealActions actions;

  @override
  ConsumerState<EatMealDetailSections> createState() =>
      _EatMealDetailSectionsState();
}

class _EatMealDetailSectionsState extends ConsumerState<EatMealDetailSections> {
  var _isWorking = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // The page closes when the meal is gone; until then it shows the meal as
    // the Vorrat holds it now.
    final meal =
        ref.watch(livePreparedMealProvider(widget.meal.id)).value ??
        widget.meal;
    final enabled = !_isWorking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xxl,
      children: [
        if (meal.components.isNotEmpty ||
            meal.hasPendingRecipeIngredients ||
            meal.ignoredPendingRecipeIngredients.isNotEmpty)
          EatMealIngredientsBox(
            meal: meal,
            onFill: enabled ? (name) => _fill(meal, name) : null,
            onIgnore: enabled ? (name) => _ignore(meal, name) : null,
            onUnignore: enabled
                ? (name) => _run(
                    () =>
                        widget.actions.unignorePendingIngredient(meal.id, name),
                    failureMessage:
                        l10n.preparedMealPendingIngredientUnignoreFailed,
                  )
                : null,
            // Taking a food out changes the ingredients, which stay fixed
            // once a portion is gone.
            onUnassign:
                enabled && meal.allows(PreparedMealAction.editIngredients)
                ? (component) => _run(
                    () => widget.actions.unassign(meal.id, component),
                    failureMessage: l10n.preparedMealUnassignFailed,
                  )
                : null,
          ),
        EatMealActionsCard(
          meal: meal,
          onEdit: enabled ? () => _edit(meal) : null,
          onSaveTemplate: enabled
              ? () => _run(
                  () => widget.actions.saveTemplate(
                    meal,
                    ScaffoldMessenger.of(context),
                  ),
                )
              : null,
          onChangeWeight: enabled ? () => _changeWeight(meal) : null,
          onUnbundle: enabled
              ? () => _run(() => widget.actions.unbundle(meal.id))
              : null,
          onThrowAway: enabled ? () => _throwAway(meal) : null,
        ),
      ],
    );
  }

  Future<void> _edit(PreparedMeal meal) async {
    final result = await showPreparedMealEditPage(context, meal: meal);
    if (!mounted || result == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    await _run(() => widget.actions.edit(meal.id, result, messenger));
  }

  Future<void> _changeWeight(PreparedMeal meal) async {
    final failed = AppLocalizations.of(context)!.preparedMealWeightFailed;
    final grams = await showPreparedMealWeightDialog(
      context: context,
      meal: meal,
    );
    if (!mounted || grams == null) {
      return;
    }
    await _run(
      // The dialog asked for the portions of [meal]; the weight belongs to
      // them, also when someone eats while it is open.
      () => widget.actions.changeWeight(meal, grams),
      failureMessage: failed,
    );
  }

  Future<void> _throwAway(PreparedMeal meal) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await showInventoryDiscardReasonDialog(context);
    if (!mounted || reason == null) {
      return;
    }
    // Lets the reason dialog finish closing before the next one opens.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }
    final portions = await showPreparedMealPortionDialog(
      context: context,
      meal: meal,
      title: l10n.preparedMealThrowAwayTitle,
    );
    if (!mounted || portions == null) {
      return;
    }
    await _run(() => widget.actions.throwAway(meal.id, portions, reason));
  }

  Future<void> _fill(PreparedMeal meal, String ingredient) async {
    final choice = await PreparedMealPendingFillSheet.show(
      context,
      ingredient: ingredient,
      // An ignored row can be filled, but it is ignored already.
      canIgnore: meal.pendingRecipeIngredients.contains(ingredient),
      match: _stock(ingredient).best,
    );
    if (!mounted || choice == null) {
      return;
    }
    switch (choice) {
      case PreparedMealPendingFillTake(:final item):
        await _fillFromStock(meal, ingredient, [item.id]);
      case PreparedMealPendingFillPickStock():
        // Lets the choice sheet finish closing before the next one opens.
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) {
          return;
        }
        final itemIds = await showPendingIngredientSelectionSheet(
          context: context,
          ingredient: ingredient,
          // Read now: the Vorrat may have changed while the sheet was open.
          stock: _stock(ingredient),
        );
        if (!mounted || itemIds == null || itemIds.isEmpty) {
          return;
        }
        await _fillFromStock(meal, ingredient, itemIds);
      case PreparedMealPendingFillFind(:final source):
        await _run(
          () async =>
              await PreparedMealPendingFoodFlow.fill(
                context: context,
                source: source,
                onFill: (itemId, amount) =>
                    widget.actions.fillPendingIngredientWithItem(
                      meal.id,
                      ingredient,
                      itemId,
                      amount,
                    ),
              ) ??
              true,
          failureMessage: AppLocalizations.of(context)!
              .preparedMealPendingIngredientFillFailed,
        );
      case PreparedMealPendingFillShoppingList():
        await _run(
          () => ref
              .read(preparedMealsControllerProvider.notifier)
              .putPendingIngredientOnShoppingList(ingredient),
          failureMessage: AppLocalizations.of(context)!
              .preparedMealFillShoppingListFailed,
          successMessage: AppLocalizations.of(context)!.eatPageOnShoppingList,
        );
      case PreparedMealPendingFillIgnore():
        await _ignore(meal, ingredient);
    }
  }

  Future<void> _fillFromStock(
    PreparedMeal meal,
    String ingredient,
    List<String> itemIds,
  ) {
    return _run(
      () => widget.actions.fillPendingIngredient(meal.id, ingredient, itemIds),
      failureMessage: AppLocalizations.of(context)!
          .preparedMealPendingIngredientFillFailed,
    );
  }

  Future<void> _ignore(PreparedMeal meal, String ingredient) {
    return _run(
      () => widget.actions.ignorePendingIngredient(meal.id, ingredient),
      failureMessage: AppLocalizations.of(context)!
          .preparedMealPendingIngredientIgnoreFailed,
    );
  }

  PendingIngredientStock _stock(String ingredient) => ref
      .read(preparedMealsControllerProvider.notifier)
      .pendingIngredientStock(
        ingredient: ingredient,
        inventoryItems: _inventoryItems(),
        localeCode: AppLocalizations.of(context)!.localeName,
      );

  List<InventoryItem> _inventoryItems() =>
      ref.read(inventoryItemsControllerProvider).value ??
      const <InventoryItem>[];

  /// Runs [action] and shows [failureMessage] when it fails or throws, or
  /// [successMessage] when it works. When the page has closed in the
  /// meantime, the message shows on the page below.
  Future<bool> _run(
    Future<bool> Function() action, {
    String? failureMessage,
    String? successMessage,
  }) async {
    final message =
        failureMessage ??
        AppLocalizations.of(context)!.preparedMealActionFailed;
    final pageMessenger = ScaffoldMessenger.of(context);
    final belowMessenger = ScaffoldMessenger.of(Navigator.of(context).context);
    setState(() => _isWorking = true);
    var success = false;
    try {
      success = await action();
    } on Object catch (error, stackTrace) {
      log('A meal action failed.', error: error, stackTrace: stackTrace);
    }
    if (mounted) {
      setState(() => _isWorking = false);
    }
    final messenger = pageMessenger.mounted ? pageMessenger : belowMessenger;
    if (!messenger.mounted) return success;
    if (!success) {
      messenger.showAppSnackBar(message, tone: AppSnackBarTone.error);
    } else if (successMessage != null) {
      messenger.showAppSnackBar(successMessage);
    }
    return success;
  }
}
