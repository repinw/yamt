import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_line_parse.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_line_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_line_assign_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_text.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_change_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_step_foot.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

// `run` stores the answer and tells its argument of a food "Hab ich" or
// "Zweite Packung" brought.
typedef _Answer = ({
  Key key,
  String label,
  IconData icon,
  Future<bool> Function(ValueChanged<KochmodusNewFood> onFood) run,
});

/// The answers on the card of one line of "Was hast du da?": a large main
/// button and up to two quieter ones beside each other under it. Usually "Hab
/// ich" ("Anderes nehmen" once the line takes from the Vorrat), "Kaufen" and
/// "Weglassen", without the answer the line has already. A line whose items
/// hold too little (`KochmodusLineView.shortBy`) gets "N kaufen", "Zweite
/// Packung" and "Nur N nehmen" (only while something is there) instead; a
/// guessed spoon above what is left (`kochmodusGuessedTakeOnly`) gets "Nur N
/// nehmen" first, without "Kaufen".
/// [onAnswered] follows each answer that was stored, with the food it brought
/// (`KochmodusNewFood`), if any.
class KochmodusCardAnswers extends StatelessWidget {
  /// Creates the answers of [line] of the cooking of [target].
  const new({
    required this.target,
    required this.line,
    required this.onAnswered,
    super.key,
  });

  /// Key of "Hab ich" or "Anderes nehmen".
  static const haveKey = ValueKey<String>('kochmodus-card-have');

  /// Key of "Kaufen".
  static const shopKey = ValueKey<String>('kochmodus-card-shop');

  /// Key of "Weglassen".
  static const ignoreKey = ValueKey<String>('kochmodus-card-ignore');

  /// Key of "N kaufen" of a line with too little.
  static const buyRestKey = ValueKey<String>('kochmodus-card-buy-rest');

  /// Key of "Zweite Packung" of a line with too little.
  static const secondPackKey = ValueKey<String>('kochmodus-card-second-pack');

  /// Key of "Nur N nehmen" of a line with too little.
  static const takeOnlyKey = ValueKey<String>('kochmodus-card-take-only');

  /// What the page cooks; the answers go to its controller.
  final KochmodusTarget target;

  /// The line on the card.
  final KochmodusLineView line;

  /// Called once an answer is stored, with the food it brought.
  final ValueChanged<KochmodusNewFood?> onAnswered;

  /// The style of the main button of a card: full width and tall, in the
  /// accent colour.
  static ButtonStyle mainStyle(BuildContext context) =>
      KochmodusStepFoot.mainButtonStyle(context).copyWith(
        minimumSize: const WidgetStatePropertyAll(
          Size.fromHeight(AppSizes.primaryActionHeight),
        ),
      );

  // The unit of the cook's own amount on a line whose text names none.
  TemplateIngredientUnit? get _ownUnit =>
      line.parsed == null ? line.amountUnit : null;

  Future<bool> _store(
    BuildContext context,
    KochmodusChange answer,
    ValueChanged<KochmodusNewFood> onFood,
  ) => KochmodusLineAssignFlow.store(
    context: context,
    target: target,
    line: line,
    answer: answer,
    onFood: onFood,
  );

  Future<bool> _change(
    BuildContext context,
    Future<bool> Function(KochmodusController controller) action,
  ) => KochmodusActionFlow.run(context, target, action);

  // What the items have, and the rest on the shopping list; with nothing
  // there, the whole line goes on it.
  Future<bool> _buyRest(
    BuildContext context,
    TemplateIngredientRequirement need,
    int missing,
  ) {
    final available = need.amount - missing;
    return _change(
      context,
      (controller) => available <= 0
          ? controller.settle(line.id, const LineShopping())
          : controller.buyRest(
              line.id,
              own: line.ownAmountFor(available),
              unit: _ownUnit,
              rest: cookLineLabel(
                line.line,
                TemplateIngredientRequirement(
                  amount: missing,
                  unit: need.unit,
                  name: need.name,
                  countMeasureLabel: need.countMeasureLabel,
                ),
              ),
            ),
    );
  }

  List<_Answer> _shortAnswers(
    BuildContext context,
    TemplateIngredientRequirement need,
    int missing,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final available = need.amount - missing;
    String amount(int value) =>
        kochmodusAmountText(l10n, value, need.unit, need.countMeasureLabel);
    return [
      (
        key: buyRestKey,
        label: l10n.kochmodusAmountBuyRest(amount(missing)),
        icon: Icons.shopping_cart_outlined,
        run: (_) => _buyRest(context, need, missing),
      ),
      (
        key: secondPackKey,
        label: l10n.kochmodusAmountSecondPack,
        icon: Icons.add_rounded,
        run: (onFood) => KochmodusLineAssignFlow.pickMore(
          context: context,
          target: target,
          line: line,
          onFood: onFood,
        ),
      ),
      if (available > 0)
        (
          key: takeOnlyKey,
          label: l10n.kochmodusAmountTakeOnly(amount(available)),
          icon: Icons.check_rounded,
          run: (_) => _change(
            context,
            (controller) => controller.setAmount(
              line.id,
              line.ownAmountFor(available),
              unit: _ownUnit,
            ),
          ),
        ),
    ];
  }

  // A guessed spoon that takes more than is left takes again from its items,
  // at most what they have; it never goes shopping while some is left.
  List<_Answer> _spoonAnswers(
    BuildContext context,
    ({InventoryItem item, int available}) only,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final there = kochmodusItemAmountText(
      l10n,
      only.available,
      only.item.amountUnit,
      only.item,
    );
    return [
      (
        key: takeOnlyKey,
        label: l10n.kochmodusAmountTakeOnly(there),
        icon: Icons.check_rounded,
        run: (_) => _change(
          context,
          (controller) => controller.assignItems(line.id, [
            for (final take in line.takes) take.itemId,
          ]),
        ),
      ),
      for (final answer in _answers(context))
        if (answer.key != shopKey) answer,
    ];
  }

  List<_Answer> _answers(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settlement = line.settlement;
    return [
      (
        key: haveKey,
        label: settlement is LineAssigned
            ? l10n.kochmodusTakeOther
            : l10n.kochmodusAssignHave,
        icon: Icons.check_rounded,
        run: (onFood) => _store(context, KochmodusChange.have, onFood),
      ),
      // A line that came in while cooking has no shopping pause.
      if (!line.isNew && settlement is! LineShopping)
        (
          key: shopKey,
          label: l10n.kochmodusAssignShop,
          icon: Icons.shopping_cart_outlined,
          run: (onFood) => _store(context, KochmodusChange.shop, onFood),
        ),
      if (settlement is! LineIgnored)
        (
          key: ignoreKey,
          label: l10n.kochmodusAssignIgnore,
          icon: Icons.remove_rounded,
          run: (onFood) => _store(context, KochmodusChange.ignore, onFood),
        ),
    ];
  }

  void _answer(_Answer answer) {
    KochmodusNewFood? food;
    unawaited(
      answer.run((brought) => food = brought).then((stored) {
        if (stored) onAnswered(food);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final need = line.need;
    final missing = line.shortBy;
    final only = kochmodusGuessedTakeOnly(line);
    final [main, ...others] = need != null && missing != null
        ? _shortAnswers(context, need, missing)
        : only != null
        ? _spoonAnswers(context, only)
        : _answers(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        FilledButton.icon(
          key: main.key,
          onPressed: () => _answer(main),
          style: mainStyle(context),
          icon: Icon(main.icon),
          label: Text(main.label, textAlign: TextAlign.center),
        ),
        // Both as tall as the taller one when a label wraps.
        if (others.isNotEmpty)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                for (final answer in others)
                  Expanded(
                    child: FilledButton.tonalIcon(
                      key: answer.key,
                      onPressed: () => _answer(answer),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, AppGraphit.buttonHeight),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                      ),
                      icon: Icon(answer.icon),
                      label: Text(answer.label, textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
