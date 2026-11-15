import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_line_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_line_assign_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_portion_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_text.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_line_picture.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_meal_box.dart';
import 'package:yamt/features/recipes/domain/cook_line_measure.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One line of "Fertig gekocht": what this cooking used in the ingredient's
/// own unit, as the card of the line says it ("300 ml Milch", "5 Zehen
/// Knoblauch", "≈ 20 g Butter"), with the food's name under it unless the
/// line names it already, or what holds it back. Under that, a chip names its
/// pot and a tap moves it to the next one. The edit button opens the keypad,
/// or the assign flow for a line that is not assigned, whose item is gone, or
/// that weighing cannot help. The remove button offers "Rückgängig"; an
/// ignored line can be assigned again.
class KochmodusPortionLine extends StatelessWidget {
  /// Creates the row of [line] for the cooking of [target], which cycles
  /// through [pots].
  const new({
    required this.target,
    required this.line,
    required this.pots,
    super.key,
  });

  /// Key of the pot chip of the line [lineId].
  static ValueKey<String> potKey(String lineId) =>
      ValueKey<String>('kochmodus-portion-pot-$lineId');

  /// Key of the edit button of the line [lineId].
  static ValueKey<String> editKey(String lineId) =>
      ValueKey<String>('kochmodus-portion-edit-$lineId');

  /// Key of the remove button of the line [lineId].
  static ValueKey<String> removeKey(String lineId) =>
      ValueKey<String>('kochmodus-portion-remove-$lineId');

  /// Key of the button that picks another food for the line [lineId], which
  /// holds more than its stock.
  static ValueKey<String> otherFoodKey(String lineId) =>
      ValueKey<String>('kochmodus-portion-other-food-$lineId');

  /// Key of the button that assigns the ignored line [lineId] again.
  static ValueKey<String> restoreKey(String lineId) =>
      ValueKey<String>('kochmodus-portion-restore-$lineId');

  /// What the page cooks.
  final KochmodusTarget target;

  /// The line.
  final KochmodusLineView line;

  /// The pots to cycle through; empty with one pot or none.
  final List<KochmodusMealView> pots;

  // A shopping line would lock "Kochen" and "Portion", so it is not offered.
  void _assign(BuildContext context) => unawaited(
    KochmodusLineAssignFlow.assign(
      context: context,
      target: target,
      line: line,
      canShop: false,
    ),
  );

  void _edit(BuildContext context) {
    if (line.settlement is LineAssigned &&
        !line.needsOtherFood &&
        !line.entryMissing &&
        !line.nutritionMissing) {
      unawaited(KochmodusActionFlow.weigh(context, target, line));
    } else {
      _assign(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final (sub, low) = _sub(l10n);
    final title = _title(l10n);
    final ignored = line.settlement is LineIgnored;
    // A line that does not count, such as a pinch of salt, still goes in.
    final struck = ignored && !line.notCounted;
    final index = pots.indexWhere((pot) => pot.potId == line.potId);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.rule)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        // At the top, the first line stays in place whether a second line
        // follows it or not.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            KochmodusLinePicture(line: line),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      color: struck ? colors.muted : colors.ink,
                      fontWeight: FontWeight.w700,
                      decoration: struck ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (sub != null)
                    Text(
                      sub,
                      style: textTheme.bodySmall?.copyWith(
                        color: low ? colors.low : colors.muted,
                      ),
                    ),
                  // Above the stock the pencil corrects the weight; this is
                  // the other way out, so nobody has to leave for "Zuweisen".
                  if (line.onlyAvailable != null)
                    TextButton(
                      key: KochmodusPortionLine.otherFoodKey(line.id),
                      onPressed: () => _assign(context),
                      child: Text(l10n.kochmodusChange),
                    ),
                  if (index >= 0)
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.kochmodusPotChipMaxWidth,
                      ),
                      child: OutlinedButton(
                        key: KochmodusPortionLine.potKey(line.id),
                        onPressed: () => unawaited(
                          KochmodusActionFlow.run(
                            context,
                            target,
                            (controller) => controller.setPot(
                              line.id,
                              pots[(index + 1) % pots.length].potId,
                            ),
                          ),
                        ),
                        child: Text(
                          KochmodusMealBox.potLabel(l10n, pots[index]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (ignored)
              IconButton(
                key: KochmodusPortionLine.restoreKey(line.id),
                tooltip: l10n.cookAssign,
                onPressed: () => _assign(context),
                icon: const Icon(Icons.add_rounded),
              )
            else ...[
              IconButton(
                key: KochmodusPortionLine.editKey(line.id),
                tooltip: l10n.kochmodusChange,
                onPressed: () => _edit(context),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                key: KochmodusPortionLine.removeKey(line.id),
                tooltip: l10n.kochmodusRemoveLine,
                onPressed: () => unawaited(
                  KochmodusActionFlow.removeLine(context, target, line),
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // What the cooking used: what the cook weighed when the takes follow it,
  // else the amount it needs ("≈" when only the recipe's rough weight), with
  // the ingredient's name ("≈ 3 g Zucker" for "etwas Zucker"); the line's
  // text without either.
  String _title(AppLocalizations l10n) {
    final need = line.shown;
    final weighed = line.weighsInstead ? line.line.weighed : null;
    if (line.settlement is! LineAssigned) return line.text;
    final amount = switch ((weighed, need)) {
      (final grams?, _) => l10n.cookAmountGrams('$grams'),
      (null, final need?) when line.roughNeed => l10n.eatPageApprox(
        kochmodusNeedText(l10n, need),
      ),
      (null, final need?) => kochmodusNeedText(l10n, need),
      (null, null) => null,
    };
    if (amount == null) return line.text;
    // The text's own measure gives way to a weight or a rough need ("≈ 3 g
    // Zucker" for "etwas Zucker"); next to its own count it stays ("5 Zehen
    // Knoblauch").
    final food = weighed != null || line.roughNeed
        ? cookTextMeasure(line.line.text)?.food
        : null;
    return l10n.cookAmountOf(amount, food ?? need?.name ?? line.text);
  }

  // The food the line takes, or what holds "In den Vorrat legen" back, and
  // whether it does.
  (String?, bool) _sub(AppLocalizations l10n) {
    if (line.settlement is LineIgnored) {
      return (
        line.notCounted
            ? l10n.kochmodusRowNotCounted
            : l10n.kochmodusRowIgnored,
        false,
      );
    }
    if (line.settlement is! LineAssigned) {
      return (l10n.kochmodusLineNotAssigned, true);
    }
    if (line.entryMissing) return (l10n.kochmodusEntryMissing, true);
    if (line.onlyAvailable case (:final item, :final available)?) {
      return (
        l10n.kochmodusOnlyAvailable(
          kochmodusItemAmountText(l10n, available, item.amountUnit, item),
        ),
        true,
      );
    }
    if (line.nutritionMissing) return (l10n.kochmodusNutritionMissing, true);
    if (line.needsOtherFood ||
        (line.takesNothing && line.weight is! CookWeightMissing)) {
      return (l10n.kochmodusTakesNothing, true);
    }
    final first = line.pictureItem;
    // A food whose name the line says already adds nothing.
    final food = first == null || kochmodusNamesItsFood(line)
        ? null
        : l10n.kochmodusAssignItems(first.name.trim(), line.itemCount - 1);
    if (line.weight is CookWeightMissing) {
      final missing = l10n.kochmodusWeightMissing;
      return (
        food == null ? missing : l10n.kochmodusJoined(food, missing),
        true,
      );
    }
    return (food, false);
  }
}
