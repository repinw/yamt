import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_nutrition_macro_row.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_scaled_value_text.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Quiet daily card header laid out like a macro row: the kcal left in the
/// value column, "kcal" in the label column, then the bar.
///
/// Future days show the target planned with carryover instead.
class DiaryQuietKcalRow extends StatelessWidget {
  /// Creates the quiet kcal row.
  const new({required this.data, required this.bar, super.key});

  /// Render-ready card data. Pause days are not supported.
  final DiaryDailyBalanceData data;

  /// The daily kcal progress bar.
  final Widget bar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = data.isOverTarget
        ? colors.error
        : MetricAccentColors.of(context).today;
    final label = data.isFutureDay
        ? l10n.diaryBalancePlannedWithCarryoverLabel
        : data.isOverTarget
        ? l10n.diaryBalanceOverGoalLabel
        : l10n.diaryBalanceLeftTodayLabel;
    final value = data.isFutureDay
        ? data.plannedWithCarryoverNumber
        : data.leftValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: accent,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          children: [
            SizedBox(
              width: diaryQuietMacroValueWidth,
              child: DiaryScaledValueText(
                value,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const SizedBox(width: diaryMacroValueLabelGap),
            SizedBox(
              width: diaryMacroLabelWidth,
              child: Text(
                data.caloriesUnit,
                maxLines: 1,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: bar),
          ],
        ),
      ],
    );
  }
}
