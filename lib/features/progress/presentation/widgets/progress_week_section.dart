import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/progress/application/progress_intake_provider.dart';
import 'package:yamt/features/progress/domain/progress_intake.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_day_row.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_legend.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_macro_averages_row.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_header.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_state.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_week_budget.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The current 7-day run: average per day, one bar per day, and the macro
/// averages.
class ProgressWeekSection extends ConsumerWidget {
  /// Creates the week section.
  const new({super.key});

  /// Stable key of the section.
  static const sectionKey = ValueKey<String>('progress-week-section');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = normalizeDiaryDay(ref.watch(clockProvider)());
    return ref
        .watch(progressIntakeProvider(ProgressScope.goal))
        .when(
          data: (intake) =>
              _WeekContent(key: sectionKey, intake: intake, today: today),
          loading: () => const ProgressSectionLoading(),
          error: (_, _) => const ProgressSectionError(),
        );
  }
}

class _WeekContent extends StatelessWidget {
  const new({required this.intake, required this.today, super.key});

  final ProgressIntake intake;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final date = DateFormat.MMMd(locale);
    final macros = MetricAccentColors.of(context);
    final week = intake.week;
    final days = intake.weekDays;
    final difference = (week.goalKcal - week.eatenKcal).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProgressSectionHeader(
          kicker: switch (intake.runNumber) {
            final run? => l10n.progressRunKicker(
              run,
              intake.weekDayNumber,
              days.length,
            ),
            null => l10n.progressWeekKicker(
              date.format(days.first.day),
              date.format(days.last.day),
            ),
          },
          value: number.format(week.eatenKcal.round()),
          unit: l10n.caloriesUnitKcal,
          caption: l10n.progressAveragePerDay,
          isMain: true,
          lines: [
            if (week.dayCount > 0) ...[
              l10n.progressGoalKcal(number.format(week.goalKcal.round())),
              if (difference >= 0)
                l10n.progressKcalUnderGoal(number.format(difference))
              else
                l10n.progressKcalOverGoal(number.format(-difference)),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ProgressWeekBudget(intake: intake),
        const SizedBox(height: AppSpacing.lg),
        for (final day in days) ...[
          ProgressDayRow(day: day, isToday: day.day == today),
          const SizedBox(height: AppSpacing.xs),
        ],
        const SizedBox(height: AppSpacing.xs),
        ProgressLegend(
          items: [
            ProgressLegendItem.color(macros.protein, l10n.caloriesProteinLabel),
            ProgressLegendItem.color(
              macros.carbs,
              l10n.caloriesCarbsShortLabel,
            ),
            ProgressLegendItem.color(macros.fat, l10n.caloriesFatLabel),
          ],
          note: l10n.progressDayBarLegend,
        ),
        const SizedBox(height: AppSpacing.md),
        ProgressMacroAveragesRow(average: week),
      ],
    );
  }
}
