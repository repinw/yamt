import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_budget_details_button.dart';

/// Row showing subtitle breakdown and budget details trigger.
class DiaryDailyBalanceSubtitleRow extends StatelessWidget {
  /// Creates the daily balance subtitle row.
  const DiaryDailyBalanceSubtitleRow({
    required this.data,
    this.onBudgetDetailsTap,
    super.key,
  });

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
          DiaryDailyBudgetDetailsButton(
            onTap: onBudgetDetailsTap!,
            isHeartDay: data.isHeartDay,
          ),
        ],
      ],
    );
  }
}

/// Formatted subtitle text or structured subtitle parts.
class DiaryDailyBalanceSubtitleText extends StatelessWidget {
  /// Creates the subtitle text display.
  const DiaryDailyBalanceSubtitleText({required this.data, super.key});

  /// Render-ready card data.
  final DiaryDailyBalanceData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accents = MetricAccentColors.of(context);
    final metrics = data.metrics;

    if (data.isHeartDay ||
        data.isFutureDay ||
        metrics.heartAdjustmentKcal.round() != 0 ||
        data.bufferAdjustmentLabel != null ||
        data.leftSubtitleParts.isEmpty) {
      return Text(
        data.leftSubtitle ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: data.isHeartDay
              ? accents.heartFor(colors.brightness).withValues(alpha: 0.78)
              : accents.today.withValues(alpha: 0.78),
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      );
    }

    final spans = <InlineSpan>[];
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    );
    final separatorStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
      fontWeight: FontWeight.w800,
    );

    for (final part in data.leftSubtitleParts) {
      if (spans.isNotEmpty) {
        spans.add(TextSpan(text: ' · ', style: separatorStyle));
      }
      final valueColor = switch (part.type) {
        DiaryDailyBalanceSubtitleType.base => colors.onSurface,
        DiaryDailyBalanceSubtitleType.carryover => accents.today,
        DiaryDailyBalanceSubtitleType.sport => accents.activityFor(
          colors.brightness,
        ),
      };
      spans.addAll([
        TextSpan(text: '${part.label} ', style: labelStyle),
        TextSpan(
          text: part.value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
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
