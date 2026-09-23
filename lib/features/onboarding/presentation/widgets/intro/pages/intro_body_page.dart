import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
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
    'intro_page_note.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_picker_stack.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_vertical_wheel_field.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Smallest selectable height in centimetres.
const _minimumHeightCm = 120.0;

/// Largest selectable height in centimetres.
const _maximumHeightCm = 230.0;

/// Height the wheel starts on while nothing is picked.
const _defaultHeightCm = 175.0;

/// Intro page that asks for height and current weight.
class IntroBodyPage extends StatelessWidget {
  /// Creates the body measurements intro page.
  const new({required this.args, super.key});

  /// Chapter styling and the calculator form.
  final IntroInputPageArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return IntroFillPageContent(
      minFillHeight: AppIntroLayout.fillMinHeightTwoPickers,
      kicker: args.kicker,
      accent: args.accent,
      title: l10n.introBodyTitle,
      subtitle: l10n.introBodySubtitle,
      body: ({required fill}) => IntroPickerStack(
        fill: fill,
        children: [
          IntroVerticalWheelField(
            key: CalorieGoalOnboardingKeys.introHeightWheel,
            label: l10n.caloriesCalculatorHeightLabel,
            unit: l10n.introHeightCmUnit,
            icon: Icons.straighten_outlined,
            valueText: args.state.heightCmText,
            errorText: args.showErrors
                ? _heightErrorText(args.state.heightError, l10n)
                : null,
            onChanged: args.notifier.updateHeightCm,
            minValue: _minimumHeightCm,
            maxValue: _maximumHeightCm,
            defaultValue: _defaultHeightCm,
            expand: fill,
          ),
          IntroVerticalWheelField(
            key: CalorieGoalOnboardingKeys.introWeightWheel,
            label: l10n.introCurrentWeightLabel,
            unit: l10n.introWeightKgUnit,
            icon: Icons.monitor_weight_outlined,
            valueText: args.state.weightKgText,
            errorText: args.showErrors
                ? _weightErrorText(args.state.weightError, l10n)
                : null,
            onChanged: args.notifier.updateWeightKg,
            minValue: minimumIntroWeightKg,
            maxValue: maximumIntroWeightKg,
            defaultValue: defaultIntroWeightKg,
            step: introWeightStepKg,
            expand: fill,
          ),
        ],
      ),
      footer: IntroPageNote(
        icon: Icons.wb_sunny_outlined,
        message: l10n.introBodyWeighInNote,
      ),
    );
  }

  String? _heightErrorText(
    CalorieCalculatorFieldError? error,
    AppLocalizations l10n,
  ) {
    return switch (error) {
      CalorieCalculatorFieldError.empty => l10n.caloriesCalculatorHeightEmpty,
      CalorieCalculatorFieldError.invalid =>
        l10n.caloriesCalculatorHeightInvalid,
      null => null,
    };
  }

  String? _weightErrorText(
    CalorieCalculatorFieldError? error,
    AppLocalizations l10n,
  ) {
    return switch (error) {
      CalorieCalculatorFieldError.empty => l10n.caloriesCalculatorWeightEmpty,
      CalorieCalculatorFieldError.invalid =>
        l10n.caloriesCalculatorWeightInvalid,
      null => null,
    };
  }
}
