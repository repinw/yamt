import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One food of a meal on the item hub: name, amount and calories.
/// Tapping it opens [ruler] under the row.
class EatCombineFoodRow extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.name,
    required this.amount,
    required this.isOpen,
    required this.onTap,
    this.kcal,
    this.ruler,
    this.errorText,
    this.onRemove,
    super.key,
  });

  /// Food name.
  final String name;

  /// Eaten amount, such as "80 g".
  final String amount;

  /// Calories of the amount.
  final String? kcal;

  /// Whether [ruler] shows.
  final bool isOpen;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Amount control, or null when the amount is set elsewhere.
  final Widget? ruler;

  /// Why the amount is not valid, shown under the row.
  final String? errorText;

  /// Removes the food from the meal, or null for the hub's own item.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final style = textTheme.bodyMedium?.copyWith(
      fontFamily: AppFonts.mono,
      color: colors.ink,
    );
    final kcalText = kcal;
    final remove = onRemove;
    final ruler = this.ruler;
    final errorText = this.errorText;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isOpen ? colors.paper : null,
        border: Border(bottom: BorderSide(color: colors.ink)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInkWell(
            onTap: ruler == null ? null : onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTapTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  spacing: AppSpacing.sm,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: style?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      amount,
                      style: textTheme.titleMedium?.copyWith(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                        decoration: ruler == null
                            ? null
                            : TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.dashed,
                        decorationColor: colors.muted,
                      ),
                    ),
                    if (kcalText != null) Text(kcalText, style: style),
                    if (remove != null)
                      IconButton(
                        tooltip: l10n.eatPageCombineRemove,
                        onPressed: remove,
                        icon: Icon(Icons.close_rounded, color: colors.muted),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (isOpen && ruler != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ruler,
            ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                errorText,
                style: textTheme.bodySmall?.copyWith(
                  fontFamily: AppFonts.mono,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
