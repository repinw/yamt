import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/health/domain/diary_activity_summary.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Compact fused activity and weight card for diary page.
class DiaryCompactActivityWeightCard extends StatelessWidget {
  /// Creates compact activity and weight card.
  const DiaryCompactActivityWeightCard({
    required this.data,
    required this.header,
    required this.stepsState,
    required this.isStepsExpanded,
    required this.isActivityExpanded,
    required this.isWeightExpanded,
    required this.onToggleSteps,
    required this.onToggleActivity,
    required this.onTapWeight,
    super.key,
  });

  /// Loaded activity and weight data.
  final DiaryActivityWeightData data;

  /// Optional content rendered above metric row.
  final Widget? header;

  /// Step summary state for compact step value.
  final AsyncValue<DiaryActivitySummary> stepsState;

  /// Whether step details are expanded.
  final bool isStepsExpanded;

  /// Whether activity details are expanded.
  final bool isActivityExpanded;

  /// Whether weight details are expanded.
  final bool isWeightExpanded;

  /// Toggles step details.
  final VoidCallback onToggleSteps;

  /// Toggles activity details.
  final VoidCallback onToggleActivity;

  /// Opens weight dialog or toggles weight details.
  final VoidCallback onTapWeight;

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(localeName);
    final weightFormat = NumberFormat('0.#', localeName);
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final accents = MetricAccentColors.of(context);
    final summary = stepsState.value;
    final totalSteps = summary?.totalSteps;
    final stepsValue = totalSteps == null
        ? '-'
        : numberFormat.format(totalSteps);
    final activityValue = data.activityKcal == null
        ? '-'
        : '${numberFormat.format(data.activityKcal)} '
              '${l10n.caloriesUnitKcal}';
    final weightValue = data.selectedWeightKg == null
        ? '-'
        : '${weightFormat.format(data.selectedWeightKg)} '
              '${l10n.caloriesUnitKg}';

    return _CompactMetricsFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header case final header?) ...[
            header,
            const SizedBox(height: AppSpacing.xl),
            const _CompactMetricsHorizontalDivider(),
            const SizedBox(height: AppSpacing.xl),
          ],
          Row(
            children: [
              Expanded(
                child: _CompactMetricItem(
                  icon: Icons.directions_walk_rounded,
                  color: accents.stepsFor(colors.brightness),
                  label: l10n.diaryStepsTitle,
                  value: stepsValue,
                  isExpanded: isStepsExpanded,
                  onTap: onToggleSteps,
                ),
              ),
              const _CompactMetricDivider(),
              Expanded(
                child: _CompactMetricItem(
                  icon: Icons.local_fire_department_rounded,
                  color: accents.activityFor(colors.brightness),
                  label: l10n.diaryActivityTitle,
                  value: activityValue,
                  isExpanded: isActivityExpanded,
                  onTap: onToggleActivity,
                ),
              ),
              const _CompactMetricDivider(),
              Expanded(
                child: _CompactMetricItem(
                  icon: Icons.monitor_weight_outlined,
                  color: accents.weight,
                  label: l10n.diaryWeightTitle,
                  value: weightValue,
                  isExpanded: isWeightExpanded,
                  onTap: onTapWeight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton state for compact activity and weight card.
class DiaryCompactActivityWeightSkeleton extends StatelessWidget {
  /// Creates compact activity and weight skeleton.
  const DiaryCompactActivityWeightSkeleton({this.header, super.key});

  /// Optional content rendered above metric row.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _CompactMetricsFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header case final header?) ...[
            header,
            const SizedBox(height: AppSpacing.xl),
            const _CompactMetricsHorizontalDivider(),
            const SizedBox(height: AppSpacing.xl),
          ],
          Row(
            children: [
              for (var index = 0; index < 3; index += 1) ...[
                if (index > 0) const _CompactMetricDivider(),
                Expanded(
                  child: Column(
                    children: [
                      MetricSkeletonBlock(
                        width: 74,
                        height: 12,
                        color: colors.surfaceContainerHighest,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      MetricSkeletonBlock(
                        width: 58,
                        height: 18,
                        color: colors.surfaceContainerHighest,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactMetricsFrame extends StatelessWidget {
  const _CompactMetricsFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppEditorialSurfaces.liftedCard(colors),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppEditorialSurfaces.solidCardBorder(colors)),
        boxShadow: [
          BoxShadow(
            color: AppEditorialSurfaces.ambientShadow(colors),
            blurRadius: isDark ? 22 : 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: child,
      ),
    );
  }
}

class _CompactMetricItem extends StatelessWidget {
  const _CompactMetricItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isExpanded,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AppInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: color,
                      size: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactMetricDivider extends StatelessWidget {
  const _CompactMetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(
        alpha: 0.42,
      ),
    );
  }
}

class _CompactMetricsHorizontalDivider extends StatelessWidget {
  const _CompactMetricsHorizontalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(
        alpha: 0.42,
      ),
    );
  }
}
