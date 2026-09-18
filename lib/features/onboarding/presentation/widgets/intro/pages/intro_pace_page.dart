import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/domain/goal_target_date_estimator.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'intro_input_page_args.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_fill_page_content.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_page_content.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_picker_stack.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_vertical_wheel_field.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_warning_note.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Slowest pace the wheel offers, in kilograms per week.
const _minimumPaceKgPerWeek = 0.05;

/// Fastest pace the wheel offers, in kilograms per week.
const _maximumPaceKgPerWeek = 1.5;

/// Distance between two pace wheel items, in kilograms per week.
const _paceStepKgPerWeek = 0.05;

/// Pace the wheel starts on, in kilograms per week.
const _defaultPaceKgPerWeek = 0.5;

/// Pace above which the flow warns about an ambitious plan.
const _ambitiousPaceKgPerWeek = 0.5;

/// Intro page that asks how fast the target weight should be reached.
class IntroPacePage extends StatelessWidget {
  /// Creates the pace intro page.
  const new({required this.args, required this.today, super.key});

  /// Chapter styling and the calculator form.
  final IntroInputPageArgs args;

  /// Current day used for the target-date estimate.
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (args.state.goalMode == CalorieGoalMode.maintain) {
      return IntroPageContent(
        kicker: args.kicker,
        accent: args.accent,
        title: l10n.onboardingPaceTitle,
        subtitle: l10n.onboardingPaceMaintainMessage,
        children: const [],
      );
    }

    final currentPace =
        double.tryParse(
          args.state.goalSpeedKgPerWeekText.replaceAll(',', '.'),
        ) ??
        _defaultPaceKgPerWeek;

    return IntroFillPageContent(
      minFillHeight: AppIntroLayout.fillMinHeightOnePicker,
      kicker: args.kicker,
      accent: args.accent,
      title: l10n.onboardingPaceTitle,
      subtitle: l10n.onboardingPaceSubtitle,
      body: ({required fill}) => IntroPickerStack(
        fill: fill,
        children: [
          IntroVerticalWheelField(
            key: CalorieGoalOnboardingKeys.introPaceWheel,
            label: l10n.introPaceLabel,
            unit: l10n.introPacePerWeekUnit,
            icon: Icons.speed_outlined,
            valueText: args.state.goalSpeedKgPerWeekText,
            errorText: null,
            onChanged: args.notifier.updateGoalSpeedKgPerWeek,
            minValue: _minimumPaceKgPerWeek,
            maxValue: _maximumPaceKgPerWeek,
            defaultValue: _defaultPaceKgPerWeek,
            step: _paceStepKgPerWeek,
            expand: fill,
          ),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TargetDateEstimate(state: args.state, today: today),
          if (currentPace > _ambitiousPaceKgPerWeek) ...[
            const SizedBox(height: AppSpacing.md),
            IntroWarningNote(
              message: args.state.goalMode == CalorieGoalMode.gain
                  ? l10n.onboardingPaceWarningGainMessage
                  : l10n.onboardingPaceWarningLoseMessage,
            ),
          ],
        ],
      ),
    );
  }
}

class _TargetDateEstimate extends StatelessWidget {
  const new({required this.state, required this.today});

  final CalorieGoalCalculatorFormState state;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final profile = state.profile;
    final targetWeightKg = profile?.targetWeightKg;
    if (profile == null || targetWeightKg == null) {
      return const SizedBox.shrink();
    }

    final reachedOn = estimateGoalReachedDate(
      currentWeightKg: profile.weightKg,
      targetWeightKg: targetWeightKg,
      goalSpeedKgPerWeek: profile.goalSpeedKgPerWeek,
      today: today,
    );
    if (reachedOn == null) {
      return const SizedBox.shrink();
    }

    final locale = Localizations.localeOf(context).toLanguageTag();

    return DecoratedBox(
      key: CalorieGoalOnboardingKeys.introTargetDateEstimate,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Row(
          children: [
            Icon(Icons.event_available, color: colors.onPrimaryContainer),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                l10n.introTargetDateEstimate(
                  DateFormat.yMMMMd(locale).format(reachedOn),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
