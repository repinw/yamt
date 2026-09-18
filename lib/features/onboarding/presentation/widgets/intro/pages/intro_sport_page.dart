import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'intro_input_page_args.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_page_content.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_week_depot_chart.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_weekday_selector.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Extra calories granted on a training day when calorie cycling is on.
const _trainingDayExtraKcal = 200.0;

/// Intro page that asks for the weekly training schedule.
///
/// The weekdays are picked directly; no selection means every day gets the
/// same target. The chart below always shows the week, so selecting days never
/// grows the page.
class IntroSportPage extends StatelessWidget {
  /// Creates the training schedule intro page.
  const new({required this.args, super.key});

  /// Chapter styling and the calculator form.
  final IntroInputPageArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = args.state;
    final hasTrainingDays = state.trainingWeekdays.isNotEmpty;

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
        AppSwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: hasTrainingDays && state.trainingDayKcalOffset > 0,
          onChanged: hasTrainingDays
              ? (enabled) => args.notifier.updateTrainingDayKcalOffset(
                  enabled ? _trainingDayExtraKcal : 0.0,
                )
              : null,
          title: Text(
            l10n.onboardingTrainingDaysExtraKcalLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        IntroWeekDepotChart(
          baseGoalKcal: state.calculation?.finalGoalKcal ?? 0,
          trainingWeekdays: state.trainingWeekdays,
          offsetKcal: state.trainingDayKcalOffset,
          accent: args.accent,
        ),
      ],
    );
  }

  void _toggleWeekday(int weekday) {
    final current = args.state.trainingWeekdays;
    final next = List<int>.from(current);
    if (next.contains(weekday)) {
      next.remove(weekday);
    } else {
      next
        ..add(weekday)
        ..sort();
    }

    args.notifier.updateTrainingWeekdays(next);
    if (next.isEmpty) {
      args.notifier.updateTrainingDayKcalOffset(0);
    } else if (current.isEmpty) {
      // First training day: calorie cycling starts switched on.
      args.notifier.updateTrainingDayKcalOffset(_trainingDayExtraKcal);
    }
  }
}
