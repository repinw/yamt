import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_activity_level_selector.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_input_controls.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_results.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_start_food_tracking_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_start_picker.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'calorie_goal_calculator_flow_layout.dart';
part 'calorie_goal_calculator_flow_steps.dart';

/// Defines calorie goal calculator flow.
class CalorieGoalCalculatorFlow extends ConsumerStatefulWidget {
  /// The calorie goal calculator flow.
  const CalorieGoalCalculatorFlow({
    required this.initialSettings,
    super.key,
  });

  /// The initial settings.
  final CalorieGoalSettings initialSettings;

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
  late DateTime _goalStartDate;
  _CalculatorStep _currentStep = _CalculatorStep.sex;

  @override
  void initState() {
    super.initState();
    final initialState = CalorieGoalCalculatorFormState.initial(
      widget.initialSettings.calculatorProfile,
    );
    if (!kReleaseMode) {
      final source = widget.initialSettings.calculatorProfile == null
          ? 'defaults'
          : 'saved_profile';
      final calculation = initialState.calculation;
      final message =
          'CALC_FLOW_DEBUG '
          'init source=$source '
          'hasGoal=${widget.initialSettings.hasGoal} '
          'dailyGoalKcal=${widget.initialSettings.dailyKcalGoal} '
          'sex=${initialState.sex?.name ?? 'null'} '
          'weightKg=${initialState.weightKgText} '
          'heightCm=${initialState.heightCmText} '
          'ageYears=${initialState.ageYearsText} '
          'activityLevel=${initialState.activityLevelOption.palValue} '
          'goalMode=${initialState.goalMode.name} '
          'goalSpeedKgPerWeek=${initialState.goalSpeedKgPerWeekText} '
          'tdeeKcal=${calculation?.tdeeKcal.toStringAsFixed(2) ?? 'null'} '
          'finalGoalKcal='
          '${calculation?.finalGoalKcal.toStringAsFixed(2) ?? 'null'}';
      log(message, name: 'CalorieGoalCalculatorFlow');
    }
    _weightController = TextEditingController(text: initialState.weightKgText);
    _heightController = TextEditingController(text: initialState.heightCmText);
    _ageController = TextEditingController(text: initialState.ageYearsText);
    _goalSpeedController = TextEditingController(
      text: initialState.goalSpeedKgPerWeekText,
    );
    final initialGoalEntry =
        widget.initialSettings.activeGoalEntryForDay(DateTime.now()) ??
        widget.initialSettings.latestGoalEntry;
    _goalStartDate = CalorieGoalStartPicker.normalizeDate(
      initialGoalEntry?.effectiveCountingStartDate ?? DateTime.now(),
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
    return _buildBottomSheet(context, l10n);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final formProvider = calorieGoalCalculatorFormControllerProvider(
      widget.initialSettings.calculatorProfile,
    );
    final formNotifier = ref.read(formProvider.notifier);
    final logRepository = ref.read(calorieLogRepositoryProvider);
    final allowsFutureGoalStart = _goalStartDate.isAfter(
      CalorieGoalStartPicker.normalizeDate(DateTime.now()),
    );
    final countGoalStartDayForLearning =
        await _resolveCountGoalStartDayForLearning(logRepository);
    if (countGoalStartDayForLearning == null && _shouldAskTrackedFoodToday) {
      return;
    }
    final saved = await formNotifier.save(
      goalStartDate: _goalStartDate,
      allowFutureGoalStart: allowsFutureGoalStart,
      countGoalStartDayForLearning: countGoalStartDayForLearning,
    );
    if (!mounted) {
      return;
    }
    if (saved) {
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
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

  void _setCurrentStep(_CalculatorStep step) {
    setState(() {
      _currentStep = step;
    });
  }

  Future<void> _pickGoalStart() async {
    final pickedDate = await CalorieGoalStartPicker.pickDate(
      context,
      initialGoalStartDate: _goalStartDate,
      now: DateTime.now(),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    if (CalorieGoalStartPicker.isSameDay(_goalStartDate, pickedDate)) {
      return;
    }

    setState(() {
      _goalStartDate = pickedDate;
    });
  }

  bool get _startsToday {
    return CalorieGoalStartPicker.isSameDay(
      _goalStartDate,
      CalorieGoalStartPicker.normalizeDate(DateTime.now()),
    );
  }

  bool get _shouldAskTrackedFoodToday {
    return _startsToday;
  }

  Future<bool?> _resolveCountGoalStartDayForLearning(
    CalorieLogRepositoryContract logRepository,
  ) async {
    if (!_shouldAskTrackedFoodToday) {
      return null;
    }
    final today = CalorieGoalStartPicker.normalizeDate(DateTime.now());
    final entries = await logRepository.readEntriesForDay(today);
    if (!mounted) {
      return null;
    }
    return showCalorieGoalStartFoodTrackingDialog(
      context,
      entryCount: entries.length,
    );
  }
}
