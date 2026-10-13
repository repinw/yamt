import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_text_link.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// A row no food fills: open in the low color with "Zutat ergänzen" and
/// "Zutat ignorieren", or ignored, struck through with "Zutat ergänzen" and
/// "Nicht mehr ignorieren".
class EatMealMissingRow extends StatelessWidget {
  /// Creates the row of [name].
  const new({
    required this.name,
    required this.isIgnored,
    required this.fillKey,
    required this.toggleKey,
    required this.onFill,
    required this.onToggle,
    super.key,
  });

  /// The row's text, such as "200 g Reis".
  final String name;

  /// Whether the cook ignored the row.
  final bool isIgnored;

  /// Key of "Zutat ergänzen".
  final Key fillKey;

  /// Key of "Zutat ignorieren", or of "Nicht mehr ignorieren".
  final Key toggleKey;

  /// Fills the row.
  final VoidCallback? onFill;

  /// Ignores the open row, or opens the ignored row again.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final color = isIgnored ? colors.muted : colors.low;
    final onFill = this.onFill;
    final onToggle = this.onToggle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xxs,
      children: [
        Text(
          name,
          style: textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            decoration: isIgnored ? TextDecoration.lineThrough : null,
            decorationColor: color,
          ),
        ),
        Text(
          isIgnored
              ? l10n.eatPageIngredientIgnored
              : l10n.eatPageIngredientMissing,
          style: textTheme.labelSmall?.copyWith(color: color),
        ),
        Wrap(
          spacing: AppSpacing.lg,
          children: [
            if (onFill != null)
              EatTextLink(
                buttonKey: fillKey,
                label: l10n.preparedMealPendingIngredientAddAction,
                onPressed: onFill,
              ),
            if (onToggle != null)
              EatTextLink(
                buttonKey: toggleKey,
                label: isIgnored
                    ? l10n.preparedMealPendingIngredientUnignoreAction
                    : l10n.preparedMealPendingIngredientIgnoreAction,
                onPressed: onToggle,
                isMuted: true,
              ),
          ],
        ),
      ],
    );
  }
}
