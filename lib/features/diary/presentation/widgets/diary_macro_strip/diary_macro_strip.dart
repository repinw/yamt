import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/calories/provider/calorie_balance_now_provider.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_segmented_progress_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Compact daily kcal, protein, carbs, and fat progress in the daily card's
/// style.
class DiaryMacroStrip extends ConsumerWidget {
  /// Creates the macro strip.
  const DiaryMacroStrip({
    required this.selectedDay,
    this.showKcal = true,
    this.showMacros = true,
    this.kcalRowKey,
    super.key,
  });

  /// Key of the kcal row, used to measure how much of the page it covers.
  final Key? kcalRowKey;

  /// Selected diary day.
  final DateTime selectedDay;

  /// Whether the kcal bar is revealed.
  final bool showKcal;

  /// Whether the protein, carbs, and fat bars are revealed.
  final bool showMacros;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref
        .watch(
          diaryDayDashboardControllerProvider(normalizeLocalDay(selectedDay)),
        )
        .data;
    if (dashboardData == null) {
      return const SizedBox.shrink();
    }
    final data = dashboardData.nutritionBars;
    final daily = DiaryBalanceSource.fromDashboardData(
      dashboardData,
    ).resolve(now: ref.watch(calorieBalanceNowProvider)()).loadedMetrics?.daily;
    final l10n = AppLocalizations.of(context)!;
    final accents = MetricAccentColors.of(context);
    final macros = [
      (
        l10n.caloriesProteinShortLetter,
        data.protein,
        data.goals.protein,
        accents.protein,
      ),
      (
        l10n.caloriesCarbsShortLetter,
        data.carbs,
        data.goals.carbs,
        accents.carbs,
      ),
      (l10n.caloriesFatShortLetter, data.fat, data.goals.fat, accents.fat),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (daily != null)
          _Reveal(
            visible: showKcal,
            child: Padding(
              key: kcalRowKey,
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _KcalStripItem(
                eaten: daily.eatenKcal,
                target: daily.targetKcal,
              ),
            ),
          ),
        _Reveal(
          visible: showMacros,
          child: Row(
            children: [
              for (final (index, (letter, current, target, color))
                  in macros.indexed) ...[
                if (index > 0) const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _MacroStripItem(
                    letter: letter,
                    current: current,
                    target: target,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Grows [child] downward from zero height while [visible] and collapses it
/// again otherwise.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: visible ? 1 : 0),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, shown, child) => shown == 0
          ? const SizedBox.shrink()
          : ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: shown,
                child: child,
              ),
            ),
    );
  }
}

class _KcalStripItem extends StatelessWidget {
  const _KcalStripItem({required this.eaten, required this.target});

  final double eaten;
  final double target;

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
              height: 4,
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
        Text(
          '${format.format(eaten.round())} / ${format.format(target.round())}',
          maxLines: 1,
          style: labelStyle,
        ),
      ],
    );
  }
}

class _MacroStripItem extends StatelessWidget {
  const _MacroStripItem({
    required this.letter,
    required this.current,
    required this.target,
    required this.color,
  });

  final String letter;
  final double current;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(letter, style: labelStyle),
            const Spacer(),
            Text(
              '${format.format(current.round())} / '
              '${format.format(target.round())}',
              maxLines: 1,
              style: labelStyle,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        DiarySegmentedProgressBar(
          progress: target <= 0 ? 0 : current / target,
          color: color,
          trackColor: colors.surfaceContainerHighest,
          isDark: colors.brightness == Brightness.dark,
          height: 4,
        ),
      ],
    );
  }
}
