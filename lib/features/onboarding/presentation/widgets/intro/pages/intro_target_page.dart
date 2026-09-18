import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'intro_input_page_args.dart';
import 'package:yamt/features/onboarding/presentation/models/'
    'intro_weight_range.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_fill_page_content.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_picker_stack.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_vertical_wheel_field.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Intro page that asks for the target weight.
class IntroTargetPage extends StatelessWidget {
  /// Creates the target weight intro page.
  const new({required this.args, super.key});

  /// Chapter styling and the calculator form.
  final IntroInputPageArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasBothWeights =
        args.state.weightError == null &&
        args.state.targetWeightError == null &&
        args.state.weightKgText.isNotEmpty &&
        args.state.targetWeightKgText.isNotEmpty;

    return IntroFillPageContent(
      minFillHeight: AppIntroLayout.fillMinHeightOnePicker,
      kicker: args.kicker,
      accent: args.accent,
      title: l10n.onboardingGoalWeightTitle,
      subtitle: l10n.onboardingGoalWeightSubtitle,
      body: ({required fill}) => IntroPickerStack(
        fill: fill,
        children: [
          IntroVerticalWheelField(
            key: CalorieGoalOnboardingKeys.introTargetWeightWheel,
            label: l10n.onboardingGoalWeightTargetLabel,
            unit: l10n.introWeightKgUnit,
            icon: Icons.flag_outlined,
            valueText: args.state.targetWeightKgText,
            errorText: _targetWeightErrorText(l10n),
            onChanged: args.notifier.updateTargetWeightKg,
            minValue: minimumIntroWeightKg,
            maxValue: maximumIntroWeightKg,
            defaultValue: _defaultTargetWeightKg,
            step: introWeightStepKg,
            expand: fill,
          ),
        ],
      ),
      footer: _GoalModeFeedback(
        goalMode: args.state.goalMode,
        hasTargetWeight: hasBothWeights,
      ),
    );
  }

  /// Starts the wheel on the current weight so any move is a real choice.
  double get _defaultTargetWeightKg {
    return double.tryParse(args.state.weightKgText.replaceAll(',', '.')) ??
        defaultIntroWeightKg;
  }

  String? _targetWeightErrorText(AppLocalizations l10n) {
    if (!args.showErrors) {
      return null;
    }
    if (args.state.targetWeightKgText.isEmpty) {
      return l10n.caloriesCalculatorWeightEmpty;
    }
    return switch (args.state.targetWeightError) {
      CalorieCalculatorFieldError.empty => l10n.caloriesCalculatorWeightEmpty,
      CalorieCalculatorFieldError.invalid =>
        l10n.caloriesCalculatorWeightInvalid,
      null => null,
    };
  }
}

/// Feedback below the target wheel.
///
/// It is always rendered, so picking a target weight only swaps the text and
/// never shifts the page.
class _GoalModeFeedback extends StatelessWidget {
  const new({required this.goalMode, required this.hasTargetWeight});

  final CalorieGoalMode goalMode;
  final bool hasTargetWeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (icon, message) = !hasTargetWeight
        ? (Icons.flag_outlined, l10n.introTargetWeightHint)
        : switch (goalMode) {
            CalorieGoalMode.lose => (
              Icons.trending_down,
              l10n.onboardingGoalWeightLoseFeedback,
            ),
            CalorieGoalMode.gain => (
              Icons.trending_up,
              l10n.onboardingGoalWeightGainFeedback,
            ),
            CalorieGoalMode.maintain => (
              Icons.trending_flat,
              l10n.onboardingGoalWeightMaintainFeedback,
            ),
          };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Row(
          children: [
            Icon(icon, color: colors.onSecondaryContainer),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSecondaryContainer,
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
