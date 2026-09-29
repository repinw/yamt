import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'prepared_meal_actions.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_action_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_meal_ingredients_box.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_discard_reason_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_edit_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_pending_ingredient_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_portion_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The parts of a meal's detail page under the eat controls: the "Zutaten"
/// box and the "Mahlzeit" card with edit, recipe, unbundle and throw away.
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

  PreparedMeal? _liveMeal(List<PreparedMeal>? meals) =>
      meals?.firstWhereOrNull((meal) => meal.id == widget.meal.id);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    ref.listen(
      preparedMealsControllerProvider.select(
        (value) => value.hasValue && _liveMeal(value.value) == null,
      ),
      (_, isGone) {
        if (isGone) {
          Navigator.of(context).pop();
        }
      },
    );
    final meal =
        ref.watch(
          preparedMealsControllerProvider.select(
            (value) => _liveMeal(value.value),
          ),
        ) ??
        widget.meal;
    final enabled = !_isWorking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xxl,
      children: [
        if (meal.components.isNotEmpty || meal.hasPendingRecipeIngredients)
          EatMealIngredientsBox(
            meal: meal,
            onFill: enabled ? (name) => _fill(meal, name) : null,
            onIgnore: enabled ? (name) => _ignore(meal, name) : null,
          ),
        EatActionCard(
          title: l10n.eatPageMealTitle,
          actions: [
            (
              key: const Key('eat_meal_action_edit'),
              icon: Icons.edit_outlined,
              label: l10n.inventoryReceiptReviewEditAction,
              color: colors.ink,
              onPressed: enabled ? () => _edit(meal) : null,
            ),
            (
              key: const Key('eat_meal_action_save_template'),
              icon: Icons.bookmark_add_outlined,
              label: l10n.preparedMealSaveTemplateAction,
              color: colors.ink,
              onPressed: enabled
                  ? () => _run(() => widget.actions.saveTemplate(meal))
                  : null,
            ),
            (
              key: const Key('eat_meal_action_unbundle'),
              icon: Icons.call_split_rounded,
              label: l10n.preparedMealUnbundleAction,
              color: colors.ink,
              onPressed: enabled
                  ? () => _run(() => widget.actions.unbundle(meal.id))
                  : null,
            ),
            (
              key: const Key('eat_meal_action_throw_away'),
              icon: Icons.delete_outline_rounded,
              label: l10n.inventoryItemThrowAwayAction,
              color: colors.low,
              onPressed: enabled && !meal.isDepleted
                  ? () => _throwAway(meal)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _edit(PreparedMeal meal) async {
    final result = await showPreparedMealEditSheet(
      context: context,
      meal: meal,
      inventoryItems: _inventoryItems(),
    );
    if (!mounted || result == null) {
      return;
    }
    if (!result.requestIngredientSelection) {
      await _run(() => widget.actions.edit(meal.id, result));
      return;
    }
    // Picking more ingredients happens in the Vorrat list below this page.
    final started = await _run(
      () => widget.actions.selectEditIngredients(meal.id, result),
    );
    if (started && mounted) {
      Navigator.of(context).pop();
    }
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
    final l10n = AppLocalizations.of(context)!;
    final itemIds = await showPendingIngredientSelectionSheet(
      context: context,
      ingredient: ingredient,
      inventoryItems: _inventoryItems(),
    );
    if (!mounted || itemIds == null || itemIds.isEmpty) {
      return;
    }
    await _run(
      () => widget.actions.fillPendingIngredient(meal.id, ingredient, itemIds),
      failureMessage: l10n.preparedMealPendingIngredientFillFailed,
    );
  }

  Future<void> _ignore(PreparedMeal meal, String ingredient) {
    return _run(
      () => widget.actions.ignorePendingIngredient(meal.id, ingredient),
      failureMessage: AppLocalizations.of(context)!
          .preparedMealPendingIngredientIgnoreFailed,
    );
  }

  List<InventoryItem> _inventoryItems() =>
      ref.read(inventoryItemsControllerProvider).value ??
      const <InventoryItem>[];

  /// Runs [action] and shows [failureMessage] when it fails.
  Future<bool> _run(
    Future<bool> Function() action, {
    String? failureMessage,
  }) async {
    final message =
        failureMessage ??
        AppLocalizations.of(context)!.preparedMealActionFailed;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isWorking = true);
    final success = await action();
    if (mounted) {
      setState(() => _isWorking = false);
    }
    if (!success) {
      messenger.showAppSnackBar(message, tone: AppSnackBarTone.error);
    }
    return success;
  }
}
