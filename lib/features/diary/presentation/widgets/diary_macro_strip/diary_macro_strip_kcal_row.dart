import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_amount_text.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Kcal row of the macro strip: label, thin bar, and amount.
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

    return Row(
      children: [
        Text(l10n.caloriesUnitKcal, style: labelStyle),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: AppSizes.stripProgressBarHeight,
              child: ColoredBox(
                color: colors.surfaceContainerHighest,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: ColoredBox(color: colors.primary),
                ),
              ),
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
