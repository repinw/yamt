import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
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
    'eat_action_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
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
                  ? () => _run(
                      () => widget.actions.saveTemplate(
                        meal,
                        ScaffoldMessenger.of(context),
                      ),
                    )
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
    final result = await showPreparedMealEditPage(context, meal: meal);
    if (!mounted || result == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    await _run(() => widget.actions.edit(meal.id, result, messenger));
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
      match: ref
          .read(preparedMealsControllerProvider.notifier)
          .pendingIngredientStockMatch(
            ingredient: ingredient,
            inventoryItems: _inventoryItems(),
            localeCode: AppLocalizations.of(context)!.localeName,
          ),
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
          inventoryItems: _inventoryItems(),
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

  List<InventoryItem> _inventoryItems() =>
      ref.read(inventoryItemsControllerProvider).value ??
      const <InventoryItem>[];

  /// Runs [action] and shows [failureMessage] when it fails. When the page
  /// has closed in the meantime, the message shows on the page below.
  Future<bool> _run(
    Future<bool> Function() action, {
    String? failureMessage,
  }) async {
    final message =
        failureMessage ??
        AppLocalizations.of(context)!.preparedMealActionFailed;
    final pageMessenger = ScaffoldMessenger.of(context);
    final belowMessenger = ScaffoldMessenger.of(Navigator.of(context).context);
    setState(() => _isWorking = true);
    final success = await action();
    if (mounted) {
      setState(() => _isWorking = false);
    }
    if (success) return true;
    final messenger = pageMessenger.mounted ? pageMessenger : belowMessenger;
    if (messenger.mounted) {
      messenger.showAppSnackBar(message, tone: AppSnackBarTone.error);
    }
    return false;
  }
}
