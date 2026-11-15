import 'dart:async';

import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/kochmodus/application/cook_finish_check.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_portion_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_text.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_estimates_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_meal_box.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_nutrition_label.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_portion_lines.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_step_foot.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Fertig gekocht": a meal per pot with name, weight and count, the lines,
/// the nutrition with "Bei N Zutaten haben wir das Gewicht geschätzt" and
/// "Ansehen" under it, "Ins Kochbuch" for free cooking, and in the foot "In
/// den Vorrat legen" with its reason to wait as a line above it. While the
/// first reason is a pot without its weight, the main button says "Topf
/// wiegen" and weighs that pot.
class KochmodusPortionStep extends StatelessWidget {
  /// Creates the step of [view] for the cooking of [target].
  const new({required this.target, required this.view, super.key});

  /// Key of "In den Vorrat legen", also while it says "Topf wiegen".
  static const toStockKey = ValueKey<String>('kochmodus-portion-to-stock');

  /// Key of "Ansehen" beside "Bei N Zutaten haben wir das Gewicht geschätzt".
  static const reviewKey = ValueKey<String>('kochmodus-portion-review');

  /// Key of the line above "In den Vorrat legen" that says why it waits.
  static const blockKey = ValueKey<String>('kochmodus-portion-block');

  /// Key of the switch "Ins Kochbuch".
  static const cookbookKey = ValueKey<String>('kochmodus-portion-cookbook');

  /// What the page cooks; actions go to its controller.
  final KochmodusTarget target;

  /// The cooking as it is now.
  final KochmodusView view;

  // A counted meal the cook did not touch goes in with its defaults.
  Future<void> _finish(
    BuildContext context,
    KochmodusPortionView portion,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    // A name being typed saves first: applying the unfocus now runs the
    // box's save at once, so its write comes before "In Vorrat" reads the
    // run, and a typed name is no default to fill in.
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    final defaults = [
      for (final meal in portion.meals)
        if (meal.draft == null) KochmodusMealBox.draftOf(l10n, meal),
    ];
    if (defaults.isNotEmpty) {
      final typed = await KochmodusActionFlow.run(
        context,
        target,
        (controller) => controller.addDefaultMeals(defaults),
      );
      if (!typed || !context.mounted) return;
    }
    await KochmodusActionFlow.result(
      context,
      target,
      (controller) => controller.finish(),
      failed: l10n.kochmodusFinishFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final portion = view.portion;
    final blocks = portion.blocks;
    final several = portion.meals.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: AppInsets.page,
            children: [
              Text(
                l10n.cookPortionTitle,
                style: textTheme.headlineSmall?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              for (final meal in portion.meals)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: KochmodusMealBox(
                    key: ValueKey<String>(meal.potId),
                    target: target,
                    meal: meal,
                    inCans: view.inCans,
                  ),
                ),
              const SizedBox(height: AppSpacing.xxxl),
              KochmodusPortionLines(target: target, portion: portion),
              for (final meal in portion.meals)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: _MealNutrition(
                    meal: meal,
                    inCans: view.inCans,
                    title: several
                        ? KochmodusMealBox.draftOf(l10n, meal).name
                        : null,
                  ),
                ),
              // Under the nutrition, which it is about; in the foot it would
              // push "In den Vorrat legen" off a small screen at large text.
              if (view.estimated.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          KochmodusEstimatesSheet.titleOf(l10n, view),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.muted,
                          ),
                        ),
                      ),
                      TextButton(
                        key: reviewKey,
                        onPressed: () => unawaited(
                          KochmodusEstimatesSheet.show(context, target),
                        ),
                        child: Text(l10n.kochmodusReview),
                      ),
                    ],
                  ),
                ),
              if (view.isFree)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: AppSwitchListTile(
                    key: cookbookKey,
                    value: view.run.toCookbook,
                    onChanged: (on) => unawaited(
                      KochmodusActionFlow.run(
                        context,
                        target,
                        (controller) => controller.setToCookbook(on: on),
                      ),
                    ),
                    title: Text(l10n.cookedToCookbook),
                    subtitle: Text(
                      l10n.kochmodusToCookbookNote,
                      style: textTheme.bodySmall?.copyWith(color: colors.muted),
                    ),
                  ),
                ),
            ],
          ),
        ),
        KochmodusStepFoot(
          children: [
            // The reason to wait stands readable above the disabled button.
            if (portion.potToWeigh == null && blocks.isNotEmpty)
              Text(
                _blockText(l10n, blocks, portion),
                key: blockKey,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.low,
                  fontWeight: FontWeight.w700,
                ),
              ),
            FilledButton(
              key: toStockKey,
              onPressed: switch (portion.potToWeigh) {
                _ when view.busy => null,
                final meal? => () => unawaited(
                  KochmodusMealBox.weigh(context, target, meal),
                ),
                null when blocks.isEmpty => () => unawaited(
                  _finish(context, portion),
                ),
                null => null,
              },
              style: KochmodusStepFoot.mainButtonStyle(context),
              child: Text(
                portion.potToWeigh != null
                    ? l10n.kochmodusWeighPotsAction(portion.unweighedPots)
                    : l10n.cookToStock,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // The first reason "In Vorrat" waits, in words.
  String _blockText(
    AppLocalizations l10n,
    List<CookFinishBlock> blocks,
    KochmodusPortionView portion,
  ) {
    final line = portion.blockLine?.text ?? '';
    return switch (blocks.first) {
      CookStockShort(:final itemId, :final available) =>
        switch (view.items[itemId]) {
          final item? => l10n.kochmodusBlockShort(
            line,
            kochmodusItemAmountText(l10n, available, item.amountUnit, item),
          ),
          null => l10n.kochmodusBlockEntryMissing(line),
        },
      CookEntryMissing() => l10n.kochmodusBlockEntryMissing(line),
      CookNutritionMissing() => l10n.kochmodusBlockNutritionMissing(line),
      CookLineWithoutTake(canWeigh: true) => l10n.kochmodusBlockWithoutTake(
        line,
      ),
      CookLineWithoutTake() => l10n.kochmodusBlockOtherFood(line),
      CookPotUnweighed() ||
      CookMealMissing() => l10n.kochmodusBlockWeighPots(portion.unweighedPots),
      // Without a pot no pot can be empty: no line takes from the Vorrat.
      CookPotEmpty(potId: countedMealPotId) => l10n.kochmodusBlockNoFood,
      CookPotEmpty(:final potId) => switch (portion.potMeals.length > 1
          ? portion.potMeals.firstWhereOrNull((meal) => meal.potId == potId)
          : null) {
        final meal? => l10n.kochmodusBlockPotEmptyNamed(
          KochmodusMealBox.potLabel(l10n, meal),
        ),
        null => l10n.kochmodusBlockPotEmpty,
      },
      CookLinesOpen() => l10n.kochmodusBlockLinesOpen,
    };
  }
}

/// The nutrition label of one meal: per portion, can or piece, and per
/// 100 g of the cooked food, "–" until the pot is weighed.
class _MealNutrition extends StatelessWidget {
  const new({required this.meal, required this.inCans, required this.title});

  final KochmodusMealView meal;
  final bool inCans;
  // The meal's name above the label when there are several meals.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final kind = meal.inPieces
        ? 'piece'
        : inCans
        ? 'can'
        : 'portion';
    final grams = meal.gramsPerCount;
    final title = this.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        if (title != null)
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        KochmodusNutritionLabel(
          eaten: meal.nutrition.perPortion(meal.count),
          per100: meal.per100,
          per100Header: l10n.caloriesEntryPer100Label(l10n.caloriesUnitGram),
          eatenHeader: grams == null
              ? l10n.kochmodusNutritionPer(kind)
              : l10n.kochmodusNutritionPerWeight(kind, grams),
        ),
      ],
    );
  }
}
