import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_budget_details_button.dart';

/// Row showing subtitle breakdown and budget details trigger.
class DiaryDailyBalanceSubtitleRow extends StatelessWidget {
  /// Creates the daily balance subtitle row.
  const new({required this.data, this.onBudgetDetailsTap, super.key});

  /// Render-ready card data.
  final DiaryDailyBalanceData data;

  /// Optional callback when budget details are tapped.
  final VoidCallback? onBudgetDetailsTap;

  @override
  Widget build(BuildContext context) {
    if (data.leftSubtitle == null && onBudgetDetailsTap == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: data.leftSubtitle == null
              ? const SizedBox.shrink()
              : DiaryDailyBalanceSubtitleText(data: data),
        ),
        if (onBudgetDetailsTap != null) ...[
          const SizedBox(width: AppSpacing.xs),
          DiaryDailyBudgetDetailsButton(onTap: onBudgetDetailsTap!),
        ],
      ],
    );
  }
}

/// Formatted subtitle text or structured subtitle parts.
class DiaryDailyBalanceSubtitleText extends StatelessWidget {
  /// Creates the subtitle text display.
  const new({required this.data, super.key});

  /// Render-ready card data.
  final DiaryDailyBalanceData data;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    if (data.isPauseDay ||
        data.isFutureDay ||
        data.bufferAdjustmentLabel != null ||
        data.leftSubtitleParts.isEmpty) {
      return Text(
        data.leftSubtitle ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.labelSmall?.copyWith(
          fontFamily: AppFonts.mono,
          color: data.isPauseDay ? colors.muted : colors.accentText,
        ),
      );
    }

    final spans = <InlineSpan>[];
    final labelStyle = textTheme.labelSmall?.copyWith(
      fontFamily: AppFonts.mono,
      color: colors.muted,
    );

    for (final part in data.leftSubtitleParts) {
      if (spans.isNotEmpty) {
        spans.add(TextSpan(text: ' · ', style: labelStyle));
      }
      final valueColor = switch (part.type) {
        DiaryDailyBalanceSubtitleType.base => colors.ink,
        DiaryDailyBalanceSubtitleType.carryover => colors.accentText,
      };
      spans.addAll([
        TextSpan(text: '${part.label} ', style: labelStyle),
        TextSpan(
          text: part.value,
          style: labelStyle?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]);
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
