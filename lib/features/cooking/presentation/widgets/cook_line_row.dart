import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/initial_tile.dart';
import 'package:yamt/features/cooking/presentation/models/cook_view.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_amount_text.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One recipe line: its letter tile, its sized text, what supplies it, and
/// [trailing] actions; a tap on the items calls [onItems].
class CookLineRow extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.line,
    this.state,
    this.trailing,
    this.onItems,
    this.below,
    super.key,
  });

  /// The line.
  final CookLineView line;

  /// A grey state under the line instead of its items, such as "Weggelassen".
  final String? state;

  /// Actions at the end of the row.
  final Widget? trailing;

  /// Opens the item picker; `null` when the items are not tappable.
  final VoidCallback? onItems;

  /// Shown under the row, such as its buttons.
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final state = this.state;
    final trailing = this.trailing;
    final below = this.below;
    final missing = line.missing;
    final items = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final take in line.takes)
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              Text(
                cookTakeText(l10n, take),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.cookStockAfterTake(cookItemStock(l10n, take.item)),
                style: textTheme.bodyMedium?.copyWith(color: colors.muted),
              ),
            ],
          ),
        if (missing > 0)
          Text(
            l10n.cookMissingAmount(
              cookAmountText(l10n, missing, line.unit, scale: line.scale),
            ),
            style: textTheme.labelMedium?.copyWith(
              color: colors.low,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.rule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Row(
            spacing: AppSpacing.md,
            children: [
              InitialTile(text: line.food),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xxs,
                  children: [
                    Text(line.label, style: textTheme.bodyLarge),
                    if (state != null)
                      Text(
                        state,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.muted,
                        ),
                      )
                    else if (onItems != null)
                      AppInkWell(onTap: onItems, child: items)
                    else
                      items,
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          ?below,
        ],
      ),
    );
  }
}
