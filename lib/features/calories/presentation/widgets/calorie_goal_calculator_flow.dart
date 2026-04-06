import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_activity_level_selector.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_input_controls.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_results.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'calorie_goal_calculator_flow_layout.dart';
part 'calorie_goal_calculator_flow_steps.dart';

enum CalorieGoalCalculatorFlowPresentation { bottomSheet, onboarding }

class CalorieGoalCalculatorFlow extends ConsumerStatefulWidget {
  const CalorieGoalCalculatorFlow({
    super.key,
    required this.initialSettings,
    required this.presentation,
  });

  final CalorieGoalSettings initialSettings;
  final CalorieGoalCalculatorFlowPresentation presentation;

  bool get isOnboarding =>
      presentation == CalorieGoalCalculatorFlowPresentation.onboarding;

  @override
  ConsumerState<CalorieGoalCalculatorFlow> createState() =>
      _CalorieGoalCalculatorFlowState();
}

class _CalorieGoalCalculatorFlowState
    extends ConsumerState<CalorieGoalCalculatorFlow> {
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;
  late final TextEditingController _goalSpeedController;
  var _currentStep = _CalculatorOnboardingStep.sex;

  @override
  void initState() {
    super.initState();
    final initialState = CalorieGoalCalculatorFormState.initial(
      widget.initialSettings.calculatorProfile,
    );
    _weightController = TextEditingController(text: initialState.weightKgText);
    _heightController = TextEditingController(text: initialState.heightCmText);
    _ageController = TextEditingController(text: initialState.ageYearsText);
    _goalSpeedController = TextEditingController(
      text: initialState.goalSpeedKgPerWeekText,
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _goalSpeedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body = widget.isOnboarding
        ? _buildOnboardingScaffold(context, l10n)
        : _buildBottomSheet(context, l10n);

    if (!widget.isOnboarding) {
      return body;
    }

    return PopScope(canPop: false, child: body);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final formProvider = calorieGoalCalculatorFormControllerProvider(
      widget.initialSettings.calculatorProfile,
    );
    final saved = await ref.read(formProvider.notifier).save();
    if (!mounted) {
      return;
    }
    if (saved) {
      if (!widget.isOnboarding) {
        Navigator.of(context).pop();
      }
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.caloriesCalculatorSaveFailed)),
    );
  }

  void _syncGoalSpeedText(String value) {
    if (_goalSpeedController.text == value) {
      return;
    }
    _goalSpeedController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _setCurrentStep(_CalculatorOnboardingStep step) {
    setState(() {
      _currentStep = step;
    });
  }
}
