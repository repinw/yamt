import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_chapter_header.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_scroll_body.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_summary_result_card.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_warning_note.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Minimum daily goal the calculator clamps to.
const _minimumDailyGoalKcal = 1200;

/// Final intro page that shows the calculated goal.
///
/// The finish action lives in the intro control bar, next to the back action.
class IntroSummaryPage extends StatelessWidget {
  /// Creates the summary intro page.
  const new({
    required this.kicker,
    required this.accent,
    required this.calculation,
    required this.trainingDaysCount,
    super.key,
  });

  /// Kicker above the headline.
  final String kicker;

  /// Accent color of this chapter.
  final Color accent;

  /// Calculation preview shown before saving.
  final CalorieGoalCalculationResult? calculation;

  /// Number of weekdays that carry a workout.
  final int trainingDaysCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = calculation;

    return IntroScrollBody(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: AppSizes.welcomeIcon,
          color: accent,
        ),
        const SizedBox(height: AppSpacing.xxl),
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
            trainingDaysCount: trainingDaysCount,
          ),
          if (result.wasClampedToMinimum) ...[
            const SizedBox(height: AppSpacing.md),
            IntroWarningNote(
              message: l10n.caloriesCalculatorMinimumGoalWarning(
                _minimumDailyGoalKcal,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
