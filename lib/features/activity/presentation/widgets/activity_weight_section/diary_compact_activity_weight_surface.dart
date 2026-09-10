import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

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

/// Loaded compact weight metric.
class DiaryCompactActivityWeightMetricsRow extends StatelessWidget {
  /// Creates the loaded compact weight metric.
  const DiaryCompactActivityWeightMetricsRow({
    required this.data,
    required this.isWeightExpanded,
    required this.onTapWeight,
    super.key,
  });

  /// Loaded activity and weight data.
  final DiaryActivityWeightData data;

  /// Whether weight details are expanded.
  final bool isWeightExpanded;

  /// Opens weight dialog or toggles weight details.
  final VoidCallback onTapWeight;

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final weightFormat = NumberFormat('0.#', localeName);
    final l10n = AppLocalizations.of(context)!;
    final weightValue = data.selectedWeightKg == null
        ? '-'
        : '${weightFormat.format(data.selectedWeightKg)} '
              '${l10n.caloriesUnitKg}';

    return _CompactMetricItem(
      icon: Icons.monitor_weight_outlined,
      label: l10n.diaryWeightTitle,
      value: weightValue,
      isExpanded: isWeightExpanded,
      onTap: onTapWeight,
    );
  }
}

/// Skeleton row for compact activity and weight metrics.
class DiaryCompactActivityWeightSkeletonRow extends StatelessWidget {
  /// Creates compact metric skeleton row.
  const DiaryCompactActivityWeightSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _CompactMetricSkeletonItem(
      icon: Icons.monitor_weight_outlined,
      label: l10n.diaryWeightTitle,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header case final header?) ...[
          Expanded(child: header),
          const SizedBox(width: AppSpacing.md),
          const _CompactMetricDivider(),
          const SizedBox(width: AppSpacing.md),
        ],
        SizedBox(width: 92, child: body),
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xs,
        ),
        child: child,
      ),
    );
  }
}

class _CompactMetricItem extends StatelessWidget {
  const _CompactMetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isExpanded,
    required this.onTap,
  });

  final IconData icon;
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
            vertical: AppSpacing.xxs,
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
                    color: colors.primary,
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
                      color: colors.onSurfaceVariant,
                      size: AppSizes.actionChevron,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 20,
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
  const _CompactMetricSkeletonItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs,
        vertical: AppSpacing.xxs,
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
          const SizedBox(height: 2),
          SizedBox(
            height: 20,
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
      height: 32,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(
        alpha: AppOpacities.compactMetricDivider,
      ),
    );
  }
}
