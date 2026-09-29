import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'intro_input_page_args.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_page_content.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_week_depot_chart.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_weekday_selector.dart';
import 'package:yamt/l10n/app_localizations.dart';

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

    return IntroPageContent(
      kicker: args.kicker,
      accent: args.accent,
      title: l10n.introSportTitle,
      subtitle: l10n.introSportSubtitle,
      children: [
        const SizedBox(height: AppSpacing.xl),
        IntroWeekdaySelector(
          selectedWeekdays: state.trainingWeekdays,
          onToggleWeekday: _toggleWeekday,
        ),
        const SizedBox(height: AppSpacing.sm),
        IntroWeekDepotChart(
          baseGoalKcal: state.calculation?.finalGoalKcal ?? 0,
          trainingWeekdays: state.trainingWeekdays,
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
