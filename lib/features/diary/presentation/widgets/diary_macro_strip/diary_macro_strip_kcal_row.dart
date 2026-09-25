import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_amount_text.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Kcal row of the macro strip: label, a thin bar of four quarters like the
/// daily ruler, and amount.
class DiaryMacroStripKcalRow extends StatelessWidget {
  /// Creates the widget.
  const new({
    required this.eaten,
    required this.target,
    required this.showTotal,
    super.key,
  });

  /// Kcal eaten on the selected day.
  final double eaten;

  /// Target amount.
  final double target;

  /// Whether eaten and target are shown instead of what is left.
  final bool showTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    final progress = target <= 0 ? 0.0 : (eaten / target).clamp(0.0, 1.0);
    final labelColors = FoodLabelColors.of(context);

    return Row(
      children: [
        Text(l10n.caloriesUnitKcal, style: labelStyle),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: SizedBox(
            height: AppSizes.stripProgressBarHeight,
            child: Row(
              spacing: AppFoodLabel.outline,
              children: [
                for (final (index, alpha)
                    in AppFoodLabel.kcalQuarterAlphas.indexed)
                  Expanded(
                    child: ColoredBox(
                      color: labelColors.rule,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor:
                            (progress * AppFoodLabel.kcalQuarterAlphas.length -
                                    index)
                                .clamp(0.0, 1.0),
                        heightFactor: 1,
                        child: ColoredBox(
                          color: labelColors.accent.withValues(alpha: alpha),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        DiaryMacroStripAmountText(
          current: eaten,
          target: target,
          showTotal: showTotal,
          format: format,
          style: labelStyle,
        ),
      ],
    );
  }
}
