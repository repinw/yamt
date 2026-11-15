import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_card_answers.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_card_texts.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/l10n/app_localizations.dart';

// An empty text one line high.
const _oneLine = ' ';

/// The card of one line of "Was hast du da?": what it asks in small
/// capitals ("HAST DU DAS DA?", "ZU WENIG DA", "BEREIT", …), the amount very
/// large with the food under it, one or a few calm lines (what the Vorrat
/// has, what is missing) in room for at least two hints, so the answers sit
/// at the same place for every line, and the answers
/// (`KochmodusCardAnswers`). Once the
/// line takes from the Vorrat its amount opens "Menge für dieses Kochen"
/// ("Menge eintragen" without one). [onClose] puts the next open line back
/// on the card; `null` hides the close button.
class KochmodusIngredientCard extends StatelessWidget {
  /// Creates the card of [line] of [view] for the cooking of [target].
  const new({
    required this.target,
    required this.view,
    required this.line,
    required this.onAnswered,
    this.onClose,
    super.key,
  });

  /// Key of the amount, which opens the amount sheet.
  static const amountKey = ValueKey<String>('kochmodus-card-amount');

  /// Key of the close button.
  static const closeKey = ValueKey<String>('kochmodus-card-close');

  /// What the page cooks; changes go to its controller.
  final KochmodusTarget target;

  /// The cooking as it is now.
  final KochmodusView view;

  /// The line on the card.
  final KochmodusLineView line;

  /// Called once an answer is stored, with the food it brought.
  final ValueChanged<KochmodusNewFood?> onAnswered;

  /// Called by the close button.
  final VoidCallback? onClose;

  Future<void> _editAmount(BuildContext context) async {
    if (line.weighsInstead) {
      await KochmodusActionFlow.weigh(context, target, line);
      return;
    }
    final choice = await KochmodusAmountSheet.show(
      context,
      line: line,
      portions: view.run.portions,
    );
    if (choice == null || !context.mounted) return;
    await KochmodusActionFlow.run(
      context,
      target,
      (controller) => controller.setAmount(
        line.id,
        choice.own,
        unit: line.parsed == null ? line.amountUnit : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final title = kochmodusCardTitle(l10n, line);
    final assigned = line.settlement is LineAssigned;
    final amountStyle = textTheme.displayMedium?.copyWith(
      color: colors.ink,
      height: AppGraphit.displayLineHeight,
    );
    final amount = title.amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                kochmodusCardLabel(l10n, line).toUpperCase(),
                style: textTheme.labelMedium?.copyWith(
                  color: colors.muted,
                  letterSpacing: AppGraphit.kickerTracking,
                ),
              ),
            ),
            if (onClose case final close?)
              IconButton(
                key: closeKey,
                onPressed: close,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (assigned && amount == null)
              OutlinedButton(
                key: amountKey,
                onPressed: () => unawaited(_editAmount(context)),
                child: Text(l10n.kochmodusAssignSetAmount),
              )
            else if (assigned && amount != null)
              Tooltip(
                message: l10n.kochmodusCardChangeAmount,
                child: AppInkWell(
                  key: amountKey,
                  onTap: () => unawaited(_editAmount(context)),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSizes.minTapTarget,
                    ),
                    child: Text(
                      amount,
                      style: amountStyle?.copyWith(
                        color: colors.accentText,
                        decoration: TextDecoration.underline,
                        decorationColor: colors.accentText,
                      ),
                    ),
                  ),
                ),
              )
            else if (amount != null)
              Text(amount, style: amountStyle),
            Text(
              title.name,
              style: textTheme.headlineSmall?.copyWith(
                color: colors.ink,
                // A line that does not count still goes into the pot.
                decoration: line.settlement is LineIgnored && !line.notCounted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ],
        ),
        // Room for two hints of one line each, spaced like the real ones, so
        // the answers stay in place from one line to the next.
        Stack(
          children: [
            ExcludeSemantics(
              child: Opacity(
                opacity: 0,
                child: Column(
                  spacing: AppSpacing.md,
                  children: [
                    Text(_oneLine, style: textTheme.bodyMedium),
                    Text(_oneLine, style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                for (final hint in kochmodusCardHints(l10n, line))
                  Text(
                    hint.text,
                    style: textTheme.bodyMedium?.copyWith(
                      color: hint.warn ? colors.low : colors.muted,
                      fontWeight: hint.warn ? FontWeight.w700 : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
        KochmodusCardAnswers(
          target: target,
          line: line,
          onAnswered: onAnswered,
        ),
      ],
    );
  }
}
