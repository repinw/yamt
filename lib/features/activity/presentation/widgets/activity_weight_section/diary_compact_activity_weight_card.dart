import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
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
  final AsyncValue<int?> stepsState;

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
    return DiaryCompactActivityWeightSurface(
      header: header,
      body: DiaryCompactActivityWeightMetricsRow(
        data: data,
        stepsState: stepsState,
        isStepsExpanded: isStepsExpanded,
        isActivityExpanded: isActivityExpanded,
        isWeightExpanded: isWeightExpanded,
        onToggleSteps: onToggleSteps,
        onToggleActivity: onToggleActivity,
        onTapWeight: onTapWeight,
      ),
    );
  }
}

/// Stable compact activity and weight frame.
class DiaryCompactActivityWeightSurface extends StatelessWidget {
  /// Creates compact activity and weight surface.
  const DiaryCompactActivityWeightSurface({
    required this.body,
    this.header,
    super.key,
  });

  /// Optional content rendered above metric row.
  final Widget? header;

  /// Current metric row or skeleton row.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return _CompactMetricsFrame(
      child: _CompactMetricsContent(
        header: header,
        body: body,
      ),
    );
  }
}

/// Loaded compact activity and weight metric row.
class DiaryCompactActivityWeightMetricsRow extends StatelessWidget {
  /// Creates loaded compact metric row.
  const DiaryCompactActivityWeightMetricsRow({
    required this.data,
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

  /// Step summary state for compact step value.
  final AsyncValue<int?> stepsState;

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
    final totalSteps = stepsState.value;
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

    return Row(
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
    return DiaryCompactActivityWeightSurface(
      header: header,
      body: const DiaryCompactActivityWeightSkeletonRow(),
    );
  }
}

/// Skeleton row for compact activity and weight metrics.
class DiaryCompactActivityWeightSkeletonRow extends StatelessWidget {
  /// Creates compact metric skeleton row.
  const DiaryCompactActivityWeightSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accents = MetricAccentColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _CompactMetricSkeletonItem(
            icon: Icons.directions_walk_rounded,
            color: accents.stepsFor(colors.brightness),
            label: l10n.diaryStepsTitle,
          ),
        ),
        const _CompactMetricDivider(),
        Expanded(
          child: _CompactMetricSkeletonItem(
            icon: Icons.local_fire_department_rounded,
            color: accents.activityFor(colors.brightness),
            label: l10n.diaryActivityTitle,
          ),
        ),
        const _CompactMetricDivider(),
        Expanded(
          child: _CompactMetricSkeletonItem(
            icon: Icons.monitor_weight_outlined,
            color: accents.weight,
            label: l10n.diaryWeightTitle,
          ),
        ),
      ],
    );
  }
}

class _CompactMetricsContent extends StatelessWidget {
  const _CompactMetricsContent({
    required this.body,
    required this.header,
  });

  final Widget body;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header case final header?) ...[
          header,
          const SizedBox(height: AppSpacing.xl),
          const _CompactMetricsHorizontalDivider(),
          const SizedBox(height: AppSpacing.xl),
        ],
        body,
      ],
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
            blurRadius: isDark
                ? AppSizes.compactMetricCardShadowBlurDark
                : AppSizes.compactMetricCardShadowBlurLight,
            offset: const Offset(
              0,
              AppSizes.compactMetricCardShadowYOffset,
            ),
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
                  Icon(
                    icon,
                    color: color,
                    size: AppSizes.compactMetricIcon,
                  ),
                  const SizedBox(
                    width: AppSizes.compactMetricIconLabelGap,
                  ),
                  Flexible(
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: AppSizes.compactMetricLabelFont,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: AppDurations.compactMetricExpansion,
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: color,
                      size: AppSizes.actionChevron,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.compactMetricValueTopGap),
              SizedBox(
                height: AppSizes.compactMetricValueSlotHeight,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontSize: AppSizes.compactMetricValueFont,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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

class _CompactMetricSkeletonItem extends StatelessWidget {
  const _CompactMetricSkeletonItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
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
              Icon(
                icon,
                color: color,
                size: AppSizes.compactMetricIcon,
              ),
              const SizedBox(width: AppSizes.compactMetricIconLabelGap),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: AppSizes.compactMetricLabelFont,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.compactMetricValueTopGap),
          SizedBox(
            height: AppSizes.compactMetricValueSlotHeight,
            child: Center(
              child: MetricSkeletonBlock(
                width: AppSizes.compactMetricSkeletonValueWidth,
                height: AppSizes.compactMetricSkeletonValueHeight,
                color: colors.surfaceContainerHighest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMetricDivider extends StatelessWidget {
  const _CompactMetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.compactMetricDividerWidth,
      height: AppSizes.compactMetricDividerHeight,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(
        alpha: AppOpacities.compactMetricDivider,
      ),
    );
  }
}

class _CompactMetricsHorizontalDivider extends StatelessWidget {
  const _CompactMetricsHorizontalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.compactMetricDividerWidth,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(
        alpha: AppOpacities.compactMetricDivider,
      ),
    );
  }
}
