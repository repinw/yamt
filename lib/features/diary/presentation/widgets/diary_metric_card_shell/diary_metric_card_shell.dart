import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_card_helpers.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_metric_card_shell/diary_metric_sparkline_painter.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shared visual shell for diary metric cards.
class DiaryMetricCardShell extends StatelessWidget {
  /// Creates a metric card shell.
  const DiaryMetricCardShell({
    required this.accentColor,
    required this.watermarkIcon,
    required this.titleIcon,
    required this.title,
    required this.value,
    required this.unit,
    required this.trend,
    required this.footer,
    this.trailing,
    super.key,
  });

  /// Accent color for the title icon and chart.
  final Color accentColor;

  /// Large background icon.
  final IconData watermarkIcon;

  /// Small title icon.
  final IconData titleIcon;

  /// Localized title.
  final String title;

  /// Main metric value.
  final String value;

  /// Metric unit.
  final String unit;

  /// Seven day trend values.
  final List<double?> trend;

  /// Footer text below the sparkline.
  final String footer;

  /// Optional trailing widget.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return DiaryMetricCardFrame(
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -18,
            child: Icon(
              watermarkIcon,
              size: 86,
              color: colors.onSurface.withValues(alpha: isDark ? 0.05 : 0.03),
            ),
          ),
          if (trailing != null)
            Positioned(
              top: AppSpacing.lg,
              right: AppSpacing.lg,
              child: trailing!,
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(titleIcon, color: accentColor, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: value,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        TextSpan(
                          text: ' $unit',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 32,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: DiaryMetricSparklinePainter(
                        values: trend,
                        color: accentColor,
                        backgroundColor: colors.surfaceContainerLowest,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          footer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.diarySevenDaysLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
