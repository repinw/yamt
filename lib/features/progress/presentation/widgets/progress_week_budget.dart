import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/progress/domain/progress_intake.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_header.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_segment_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The week budget: what the run allows in total, one segment per day, and
/// how much is left.
class ProgressWeekBudget extends StatelessWidget {
  /// Creates the week budget.
  const new({required this.intake, super.key});

  /// Intake of the current run.
  final ProgressIntake intake;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final date = DateFormat.MMMd(locale);
    final eaten = intake.weekEatenKcal;
    final goal = intake.weekGoalKcal;
    final left = (goal - eaten).round();
    final small = textTheme.labelSmall?.copyWith(color: colors.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n
                    .progressWeekBudgetKicker(
                      date.format(intake.weekDays.first.day),
                      date.format(intake.weekDays.last.day),
                    )
                    .toUpperCase(),
                style: progressKickerStyle(context),
              ),
            ),
            Text(
              l10n.progressWeekBudgetValue(
                number.format(eaten.round()),
                number.format(goal.round()),
              ),
              style: textTheme.labelMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ProgressSegmentBar(
          proteinKcal: intake.weekProteinKcal,
          carbsKcal: intake.weekCarbsKcal,
          fatKcal: intake.weekFatKcal,
          eatenKcal: eaten,
          goalKcal: goal,
          segments: intake.weekDays.length,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            left >= 0
                ? l10n.progressWeekBudgetLeft(number.format(left))
                : l10n.progressWeekBudgetOver(number.format(-left)),
            style: left >= 0 ? small : small?.copyWith(color: colors.low),
          ),
        ),
      ],
    );
  }
}
