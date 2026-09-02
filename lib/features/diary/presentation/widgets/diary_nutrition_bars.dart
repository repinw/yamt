import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Stable keys for diary nutrition bar tests.
abstract final class DiaryNutritionBarsKeys {
  /// Retry button key.
  static const retryButton = ValueKey<String>(
    'diary-nutrition-bars-retry-button',
  );
}

/// Macro nutrition bars for the diary page.
class DiaryNutritionBars extends ConsumerStatefulWidget {
  /// Creates standalone diary nutrition bars.
  const DiaryNutritionBars({
    required this.selectedDay,
    super.key,
  }) : _framed = true,
       _showTitle = true;

  /// Creates embedded diary nutrition bars without a standalone card frame.
  const DiaryNutritionBars.embedded({
    required this.selectedDay,
    super.key,
  }) : _framed = false,
       _showTitle = false;

  /// The selected diary day.
  final DateTime selectedDay;

  /// Whether to draw the standalone card shell.
  final bool _framed;

  /// Whether to show the macro section title.
  final bool _showTitle;

  @override
  ConsumerState<DiaryNutritionBars> createState() => _DiaryNutritionBarsState();
}

class _DiaryNutritionBarsState extends ConsumerState<DiaryNutritionBars>
    with AutomaticKeepAliveClientMixin<DiaryNutritionBars> {
  DiaryNutritionBarsData? _lastData;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final normalizedDay = normalizeDiaryDay(widget.selectedDay);
    final dashboardState = ref.watch(
      diaryDayDashboardControllerProvider(normalizedDay),
    );
    final loadedData = dashboardState.data?.nutritionBars;
    if (loadedData != null) {
      _lastData = loadedData;
    }
    final data = loadedData ?? _lastData;
    final l10n = AppLocalizations.of(context)!;
    final showError = data == null && dashboardState.showError;

    final content = IconTheme.merge(
      data: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      child: showError
          ? MetricErrorRetryContent(
              message: l10n.diaryNutritionLoadFailed,
              retryLabel: l10n.caloriesRetryAction,
              retryButtonKey: DiaryNutritionBarsKeys.retryButton,
              onRetry: () => _retryNutritionBars(normalizedDay),
            )
          : data == null
          ? _NutritionBarsSkeleton(showTitle: widget._showTitle)
          : _NutritionBarsContent(data: data, showTitle: widget._showTitle),
    );

    if (!widget._framed) {
      return content;
    }

    return MetricDetailCardShell(child: content);
  }

  void _retryNutritionBars(DateTime normalizedDay) {
    unawaited(
      ref
          .read(diaryDayDashboardControllerProvider(normalizedDay).notifier)
          .retry(),
    );
  }
}

class _NutritionBarsContent extends StatelessWidget {
  const _NutritionBarsContent({
    required this.data,
    required this.showTitle,
  });

  final DiaryNutritionBarsData data;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final l10n = AppLocalizations.of(context)!;
    final accentColors = MetricAccentColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            l10n.diaryNutritionTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Column(
          children: [
            _NutritionMacroRow(
              label: l10n.caloriesProteinLabel,
              current: data.protein,
              target: data.goals.protein,
              color: accentColors.protein,
              numberFormat: numberFormat,
              unit: l10n.caloriesUnitGram,
              leftLabel: l10n.diaryBalanceLeftLabel.toLowerCase(),
            ),
            const SizedBox(height: AppSpacing.xs),
            _NutritionMacroRow(
              label: l10n.caloriesCarbsLabel,
              current: data.carbs,
              target: data.goals.carbs,
              color: accentColors.carbs,
              numberFormat: numberFormat,
              unit: l10n.caloriesUnitGram,
              leftLabel: l10n.diaryBalanceLeftLabel.toLowerCase(),
            ),
            const SizedBox(height: AppSpacing.xs),
            _NutritionMacroRow(
              label: l10n.caloriesFatLabel,
              current: data.fat,
              target: data.goals.fat,
              color: accentColors.fat,
              numberFormat: numberFormat,
              unit: l10n.caloriesUnitGram,
              leftLabel: l10n.diaryBalanceLeftLabel.toLowerCase(),
            ),
          ],
        ),
      ],
    );
  }
}

class _NutritionMacroRow extends StatelessWidget {
  const _NutritionMacroRow({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.numberFormat,
    required this.unit,
    required this.leftLabel,
  });

  final String label;
  final double current;
  final double target;
  final Color color;
  final NumberFormat numberFormat;
  final String unit;
  final String leftLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    final remaining = target - current;
    final isOverTarget = remaining < -0.5;
    final roundedRemaining = remaining.round();
    final rowBg = color.withValues(alpha: isDark ? 0.08 : 0.04);
    final rowBorder = color.withValues(alpha: isDark ? 0.22 : 0.14);
    final trackColor = AppEditorialSurfaces.appBackground(colors);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: rowBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: isOverTarget
                          ? '+${numberFormat.format(-roundedRemaining)}$unit '
                          : '${numberFormat.format(
                              math.max(0, roundedRemaining),
                            )}$unit ',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: isOverTarget ? '' : leftLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: numberFormat.format(current.round()),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${numberFormat.format(target.round())}$unit',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOut,
              tween: Tween<double>(begin: 0, end: progress),
              builder: (context, value, child) {
                return FractionallySizedBox(widthFactor: value, child: child);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: isDark ? 0.35 : 0.42),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionBarsSkeleton extends StatelessWidget {
  const _NutritionBarsSkeleton({required this.showTitle});

  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          MetricSkeletonBlock(
            width: 138,
            height: 18,
            color: colors.surfaceContainerHighest,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (var index = 0; index < 3; index += 1) ...[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    MetricSkeletonBlock(
                      width: 60,
                      height: 12,
                      color: colors.surfaceContainerHighest,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    MetricSkeletonBlock(
                      width: 50,
                      height: 12,
                      color: colors.surfaceContainerHighest,
                    ),
                    const Spacer(),
                    MetricSkeletonBlock(
                      width: 55,
                      height: 12,
                      color: colors.surfaceContainerHighest,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                MetricSkeletonBlock(
                  height: 6,
                  color: colors.surfaceContainerHighest,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
