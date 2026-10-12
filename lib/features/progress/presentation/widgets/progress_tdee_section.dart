import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_progress_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/progress/application/progress_tdee_provider.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_tdee.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_axis_labels.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_day_chart.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_legend.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_header.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The daily TDEE of the period of a scope with its check-ins.
class ProgressTdeeSection extends ConsumerWidget {
  /// Creates the TDEE section for [scope].
  const new({required this.scope, super.key});

  /// Which goals the chart covers.
  final ProgressScope scope;

  /// Stable key of the section.
  static const sectionKey = ValueKey<String>('progress-tdee-section');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(progressTdeeProvider(scope))
        .when(
          data: (tdee) => _TdeeContent(key: sectionKey, tdee: tdee),
          loading: () => const ProgressSectionLoading(),
          error: (_, _) => const ProgressSectionError(),
        );
  }
}

class _TdeeContent extends StatelessWidget {
  const new({required this.tdee, super.key});

  final ProgressTdee tdee;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final signed = NumberFormat('+#,##0;−#,##0', locale);
    final current = tdee.currentTdeeKcal;
    final sinceYesterday = tdee.changeSinceYesterdayKcal;
    final thisWeek = tdee.changeThisWeekKcal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProgressSectionHeader(
          kicker: l10n.progressTdeeKicker,
          value: current == null ? '–' : number.format(current.round()),
          unit: l10n.caloriesUnitKcal,
          lines: [
            if (sinceYesterday != null)
              l10n.progressTdeeChange(signed.format(sinceYesterday.round())),
            if (thisWeek != null)
              l10n.progressTdeeWeekChange(signed.format(thisWeek.round())),
            if (tdee.isCheckInOpen)
              l10n.progressTdeeCheckInOpen
            else
              l10n.progressTdeeNextCheckIn(
                DateFormat.MMMd(locale).format(tdee.nextCheckInDay),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (current == null)
          ProgressSectionNote(text: l10n.progressTdeeEmpty)
        else ...[
          ProgressDayChart(
            days: [
              for (final day in tdee.days)
                (day: day.day, dot: day.measuredKcal, line: day.tdeeKcal),
            ],
            goalStarts: [
              for (final start in tdee.goalStarts)
                (start.day, l10n.progressGoalMarker(start.number)),
            ],
            markedDays: tdee.checkInDays,
            minRange: AppProgress.tdeeMinRangeKcal,
          ),
          const SizedBox(height: AppSpacing.xxs),
          ProgressAxisLabels.forDays(
            days: [for (final day in tdee.days) day.day],
            todayLabel: l10n.progressToday,
            locale: locale,
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgressLegend(
            items: [
              ProgressLegendItem(
                swatch: SizedBox(
                  width: AppProgress.legendSwatch * 2,
                  height: AppProgress.trendStroke,
                  child: ColoredBox(color: colors.ink),
                ),
                label: l10n.progressTdeeLegendLine,
              ),
              ProgressLegendItem(
                swatch: SizedBox.square(
                  dimension: AppProgress.weighInSize,
                  child: ColoredBox(color: colors.muted),
                ),
                label: l10n.progressTdeeLegendDay,
              ),
              if (tdee.checkInDays.isNotEmpty)
                ProgressLegendItem.color(
                  colors.ink,
                  l10n.progressTdeeLegendCheckIn,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
