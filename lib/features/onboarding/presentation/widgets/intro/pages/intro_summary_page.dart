import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_chapter_header.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_page_note.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_scroll_body.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_start_day_selector.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_summary_result_card.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_warning_note.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Final intro page that shows the calculated goal and asks for the start day.
///
/// The finish action lives in the intro control bar, next to the back action.
class IntroSummaryPage extends StatelessWidget {
  /// Creates the summary intro page.
  const new({
    required this.kicker,
    required this.accent,
    required this.calculation,
    required this.trainingWeekdays,
    required this.trainingDayKcalOffset,
    required this.today,
    required this.startDate,
    required this.onStartDateChanged,
    this.adjustedMacroWeightKg,
    super.key,
  });

  /// Kicker above the headline.
  final String kicker;

  /// Accent color of this chapter.
  final Color accent;

  /// Calculation preview shown before saving.
  final CalorieGoalCalculationResult? calculation;

  /// Weekdays that carry a workout, 1 = Monday.
  final List<int> trainingWeekdays;

  /// Extra calories granted on a training day.
  final double trainingDayKcalOffset;

  /// Current day.
  final DateTime today;

  /// Selected start day of the first tracked week.
  final DateTime startDate;

  /// Called when the user picks another start day.
  final ValueChanged<DateTime> onStartDateChanged;

  /// Adjusted body weight for protein and fat, set only above a BMI of 25.
  final double? adjustedMacroWeightKg;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = calculation;

    return IntroScrollBody(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntroChapterHeader(
          kicker: kicker,
          title: l10n.onboardingReadyTitle,
          body: l10n.introSummarySubtitle,
          accent: accent,
          alignment: CrossAxisAlignment.center,
        ),
        if (result != null) ...[
          const SizedBox(height: AppSpacing.xl),
          IntroSummaryResultCard(
            calculation: result,
            trainingWeekdays: trainingWeekdays,
            trainingDayKcalOffset: trainingDayKcalOffset,
          ),
          if (result.wasClampedToMinimum) ...[
            const SizedBox(height: AppSpacing.md),
            IntroWarningNote(
              message: l10n.caloriesCalculatorMinimumGoalWarning(
                minimumCalorieGoalKcal.round(),
              ),
            ),
          ],
        ],
        if (adjustedMacroWeightKg case final weightKg?) ...[
          const SizedBox(height: AppSpacing.md),
          IntroPageNote(
            icon: Icons.info_outline_rounded,
            message: l10n.macroAdjustedWeightNote(weightKg.round().toString()),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        IntroStartDaySelector(
          today: today,
          startDate: startDate,
          onChanged: onStartDateChanged,
        ),
      ],
    );
  }
}
