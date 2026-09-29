import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/training_day_chips.dart';
import 'package:yamt/features/calories/presentation/widgets/training_week_depot_chart.dart';
import 'package:yamt/features/onboarding/presentation/calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'intro_input_page_args.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_page_content.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Any Monday, used to render localized weekday names.
final _referenceMonday = DateTime(2024);

/// The first two letters of a weekday name, like the chips always showed.
String _shortLabel(String weekday) {
  return weekday.length <= 2 ? weekday : weekday.substring(0, 2);
}

/// Intro page that asks for the weekly training schedule.
///
/// The weekdays are picked directly; every picked day counts as one session
/// (see `CalorieGoalCalculatorFormController.updateTrainingWeekdays`), and no
/// selection means every day gets the same target. The chart below always
/// shows the week, so selecting days never grows the page.
class IntroSportPage extends StatelessWidget {
  /// Creates the training schedule intro page.
  const new({required this.args, super.key});

  /// Chapter styling and the calculator form.
  final IntroInputPageArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = args.state;
    final weekdayFormat = DateFormat.E(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final weekdays = [
      for (var weekday = 1; weekday <= DateTime.daysPerWeek; weekday++)
        (
          weekday: weekday,
          name: weekdayFormat.format(
            _referenceMonday.add(Duration(days: weekday - 1)),
          ),
          isTraining: state.trainingWeekdays.contains(weekday),
        ),
    ];

    return IntroPageContent(
      kicker: args.kicker,
      accent: args.accent,
      title: l10n.introSportTitle,
      subtitle: l10n.introSportSubtitle,
      children: [
        const SizedBox(height: AppSpacing.xl),
        TrainingDayChips(
          days: [
            for (final day in weekdays)
              (
                key: CalorieGoalOnboardingKeys.introTrainingWeekday(
                  day.weekday,
                ),
                label: _shortLabel(day.name),
                caption: null,
                isTraining: day.isTraining,
              ),
          ],
          onToggle: (index) => _toggleWeekday(weekdays[index].weekday),
        ),
        const SizedBox(height: AppSpacing.sm),
        TrainingWeekDepotChart(
          days: [
            for (final day in weekdays)
              (label: day.name, isTraining: day.isTraining),
          ],
          baseGoalKcal: state.calculation?.finalGoalKcal ?? 0,
          sessionKcal: state.trainingDayKcalOffset,
          accent: args.accent,
        ),
      ],
    );
  }

  void _toggleWeekday(int weekday) {
    final next = List<int>.from(args.state.trainingWeekdays);
    if (next.contains(weekday)) {
      next.remove(weekday);
    } else {
      next
        ..add(weekday)
        ..sort();
    }

    args.notifier.updateTrainingWeekdays(next);
  }
}
