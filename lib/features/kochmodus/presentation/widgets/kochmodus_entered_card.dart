import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'prepared_meal_pending_food_flow.dart';
import 'package:yamt/features/kochmodus/application/cook_line_amount.dart';
import 'package:yamt/features/kochmodus/application/cook_pick_need.dart';
import 'package:yamt/features/kochmodus/application/cook_take_ask.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_text.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The line under the card of "Was hast du da?" once "Hab ich" brought
/// [food] to [line]: a check mark, the food's name on one line and what the
/// app booked under it, "1 kg eingetragen. Wir nehmen 250 g davon, 750 g
/// bleiben.", for an estimated food "Werte geschätzt. Wir nehmen 250 g.",
/// for a food from the Vorrat what the line takes of what that food still
/// has for it, counted as the row counts it (`KochmodusView.stockLeftOf`):
/// "Aus dem Vorrat. Wir nehmen 400 g von 500 g." when the line's amount is in
/// the food's unit (`cookNeedInItemUnit`), "Aus dem Vorrat. 500 g da. Gewogen
/// wird beim Kochen." for a line that waits under "Noch zu wiegen"
/// (`KochmodusView.toWeigh`) and is neither short nor without anything left,
/// else "Aus dem Vorrat. 350 ml da."; for a new
/// food the line cannot take from yet, such as pieces without a weight on a
/// line in grams, "Eingetragen. Die Menge fehlt uns noch.", and for one whose
/// line waits under "Noch zu wiegen" "1 kg eingetragen. Gewogen wird beim
/// Kochen.". The numbers are what the line takes now, with "≈" for a rough
/// need or an estimated weight ("Wir nehmen ≈ 3 g davon"), never as a fact.
/// "Ändern" asks on the amount page how much of a
/// new food is at home and lets the line take again; for a food from the
/// Vorrat, whose stock is real, it puts the line back on the card
/// ([onShowLine]).
class KochmodusEnteredCard extends StatelessWidget {
  /// Creates the line for [food] of [line] of the cooking of [target], as
  /// [view] shows it.
  const new({
    required this.target,
    required this.view,
    required this.line,
    required this.food,
    required this.onShowLine,
    super.key,
  });

  /// Key of the line.
  static const cardKey = ValueKey<String>('kochmodus-entered');

  /// Key of "Ändern".
  static const changeKey = ValueKey<String>('kochmodus-entered-change');

  /// What the page cooks; changes go to its controller.
  final KochmodusTarget target;

  /// The cooking: the food as the Vorrat has it now, and what it still has
  /// for [line].
  final KochmodusView view;

  /// The line the food went to.
  final KochmodusLineView line;

  /// What "Hab ich" brought.
  final KochmodusNewFood food;

  /// Puts [line] back on the card.
  final VoidCallback onShowLine;

  // The food as the Vorrat has it now.
  InventoryItem get _item => view.items[food.item.id] ?? food.item;

  Future<void> _change(BuildContext context) async {
    if (food.fromStock) {
      onShowLine();
      return;
    }
    final pick = cookPickNeed(line.need, line.line.conversion);
    final saved = await PreparedMealPendingFoodFlow.recount(
      context: context,
      item: _item,
      need: pick.need,
      pieceWeight: pick.pieceWeight,
    );
    if (saved == null || !context.mounted) return;
    await KochmodusActionFlow.run(
      context,
      target,
      (controller) => controller.assignFound(line.id, saved),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final item = _item;
    final booked = _bookedText(l10n, item);
    return Semantics(
      key: cardKey,
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: AppGraphit.confirmTintOpacity),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
          ),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              SizedBox.square(
                dimension: AppGraphit.confirmCheck,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: AppGraphit.chipIcon,
                    color: colors.onAccent,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (booked != null)
                      Text(
                        booked,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(
                key: changeKey,
                onPressed: () => unawaited(_change(context)),
                child: Text(l10n.kochmodusEnteredChange),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // What the line takes of [item] and what stays, in its unit; for a food
  // from the Vorrat what it has for the line; for a new food the line cannot
  // take from yet, that it takes nothing; `null` on a line without a need,
  // which takes nothing of any new food, or when a new food has no unit.
  String? _bookedText(AppLocalizations l10n, InventoryItem item) {
    final unit = item.amountUnit;
    String amount(int value) =>
        kochmodusItemAmountText(l10n, value, unit, item);
    final taken = line.takes
        .where((take) => take.itemId == item.id)
        .fold<int>(0, (sum, take) => sum + take.amount);
    if (food.fromStock) {
      final left = view.stockLeftOf(line, item);
      final there = amount(left);
      // Only a line that really waits for a weight: never a short one, nor
      // one whose food has nothing left for it.
      if (left > 0 &&
          line.shortBy == null &&
          view.toWeigh.any((other) => other.id == line.id)) {
        return l10n.kochmodusEnteredFromStockWeigh(there);
      }
      return taken > 0 && !line.roughNeed && cookNeedInItemUnit(line.need, item)
          ? l10n.kochmodusEnteredFromStockTake(amount(taken), there)
          : l10n.kochmodusEnteredFromStock(there);
    }
    if (!line.takesFrom(item.id)) return l10n.kochmodusEnteredNothing;
    if (unit == null || taken <= 0) return null;
    // A rough need ("etwas Zucker") or an estimated weight ("1 Zwiebel" of a
    // net in grams) takes about that much; a count of a food kept in pieces
    // ("3 Eier") is exact. No-break spaces keep "≈ 3 g" on one line.
    final need =
        line.roughNeed ||
            (line.weight is CookWeightEstimated && cookKeptByWeight(item))
        ? l10n.eatPageApprox(amount(taken)).replaceAll(' ', _noBreakSpace)
        : amount(taken);
    if (item.aiEstimated) return l10n.kochmodusEnteredEstimated(need);
    final rest = item.currentAmount - taken;
    final pack = amount(item.initialAmount);
    if (view.toWeigh.any((other) => other.id == line.id)) {
      return l10n.kochmodusEnteredPackWeigh(pack);
    }
    return rest > 0
        ? l10n.kochmodusEnteredPack(pack, need, amount(rest))
        : l10n.kochmodusEnteredPackAll(pack);
  }
}

const _noBreakSpace = '\u00A0';
