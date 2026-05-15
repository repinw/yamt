import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_constants.dart';

/// Outer shell for diary Burn Week card states.
class DiaryBalanceShell extends StatelessWidget {
  /// Creates a Burn Week card shell.
  const DiaryBalanceShell({
    required this.child,
    this.framed = true,
    super.key,
  });

  /// Shell content.
  final Widget child;

  /// Whether to draw the full card frame.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final activity = MetricAccentColors.of(context).activityFor(
      colors.brightness,
    );
    final baseSurface = colors.surfaceContainerLowest;
    final primaryTint = Color.alphaBlend(
      colors.primary.withValues(alpha: isDark ? 0.1 : 0.035),
      baseSurface,
    );
    final activityTint = Color.alphaBlend(
      activity.withValues(alpha: isDark ? 0.08 : 0.03),
      baseSurface,
    );

    if (!framed) {
      return child;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseSurface, primaryTint, activityTint],
          stops: const [0, 0.58, 1],
        ),
        borderRadius: BorderRadius.circular(diaryBalanceCardRadius),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.32 : 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.3 : 0.09),
            blurRadius: isDark ? 30 : 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: child,
      ),
    );
  }
}
