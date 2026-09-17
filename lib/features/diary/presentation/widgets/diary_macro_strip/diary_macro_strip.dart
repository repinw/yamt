import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_details_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_kcal_row.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_macro_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Compact daily kcal, protein, carbs, and fat progress in the daily card's
/// style.
class DiaryMacroStrip extends ConsumerWidget {
  /// Creates the macro strip.
  const new({
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
    final daily = DiaryBalanceSource.fromDashboardData(dashboardData)
        .resolve(now: ref.watch(clockProvider)())
        .loadedMetrics
        ?.daily;
    final showDetails = ref.watch(diaryBalanceDetailsControllerProvider);
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
              child: DiaryMacroStripKcalRow(
                eaten: daily.eatenKcal,
                target: daily.targetKcal,
                showTotal: showDetails,
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
                  child: DiaryMacroStripMacroItem(
                    letter: letter,
                    current: current,
                    target: target,
                    color: color,
                    showTotal: showDetails,
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
  const new({required this.visible, required this.child});

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
