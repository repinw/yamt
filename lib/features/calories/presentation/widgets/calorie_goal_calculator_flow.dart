import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_onboarding_start.dart';
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

/// Defines calorie goal calculator flow presentation.
enum CalorieGoalCalculatorFlowPresentation {
  /// Bottom sheet.
  bottomSheet,

  /// Onboarding.
  onboarding,
}

enum _OnboardingGoalStartChoice { now, later }

/// Defines calorie goal calculator flow.
class CalorieGoalCalculatorFlow extends ConsumerStatefulWidget {
  /// The calorie goal calculator flow.
  const CalorieGoalCalculatorFlow({
    required this.initialSettings,
    required this.presentation,
    super.key,
  });

  /// The initial settings.
  final CalorieGoalSettings initialSettings;

  /// The presentation.
  final CalorieGoalCalculatorFlowPresentation presentation;

  /// Whether onboarding.
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
  late DateTime _goalStartDate;
  _OnboardingGoalStartChoice? _onboardingGoalStartChoice;
  CalorieGoalOnboardingTodayTracking? _onboardingTodayTrackingChoice;
  CalorieGoalOnboardingCatchUpEstimate _onboardingCatchUpEstimate =
      CalorieGoalOnboardingCatchUpEstimate.normal;
  _CalculatorOnboardingStep _currentStep = _CalculatorOnboardingStep.sex;

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
    final formNotifier = ref.read(formProvider.notifier);
    final logRepository = ref.read(calorieLogRepositoryProvider);
    final allowsFutureGoalStart =
        widget.isOnboarding ||
        _goalStartDate.isAfter(
          CalorieGoalStartPicker.normalizeDate(DateTime.now()),
        );
    final countGoalStartDayForLearning =
        await _resolveCountGoalStartDayForLearning(logRepository);
    if (countGoalStartDayForLearning == null && _shouldAskTrackedFoodToday) {
      return;
    }
    final useOnboardingEstimate =
        widget.isOnboarding &&
        _startsToday &&
        _onboardingTodayTrackingChoice ==
            CalorieGoalOnboardingTodayTracking.estimate;
    final saved = await formNotifier.save(
      goalStartDate: _goalStartDate,
      allowFutureGoalStart: allowsFutureGoalStart,
      syncBurnWeekForOnboarding: widget.isOnboarding,
      countGoalStartDayForLearning: countGoalStartDayForLearning,
      onboardingCatchUpEstimate: useOnboardingEstimate
          ? _onboardingCatchUpEstimate
          : null,
      onboardingPlaceholderName: l10n.caloriesOnboardingPlaceholderName,
    );
    if (!mounted) {
      return;
    }
    if (saved) {
      if (!widget.isOnboarding) {
        Navigator.of(context).pop();
      }
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

  void _setCurrentStep(_CalculatorOnboardingStep step) {
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
    return !widget.isOnboarding && _startsToday;
  }

  Future<bool?> _resolveCountGoalStartDayForLearning(
    CalorieLogRepositoryContract logRepository,
  ) async {
    if (widget.isOnboarding) {
      if (!_startsToday) {
        return null;
      }
      return switch (_onboardingTodayTrackingChoice) {
        CalorieGoalOnboardingTodayTracking.exact => true,
        CalorieGoalOnboardingTodayTracking.estimate => false,
        null => null,
      };
    }
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

  bool get _hasOnboardingStartChoice {
    if (!widget.isOnboarding) {
      return true;
    }
    if (_onboardingGoalStartChoice == null) {
      return false;
    }
    if (!_startsToday) {
      return true;
    }
    return _onboardingTodayTrackingChoice != null;
  }

  void _selectOnboardingStartNow() {
    final today = CalorieGoalStartPicker.normalizeDate(DateTime.now());
    if (_onboardingGoalStartChoice == _OnboardingGoalStartChoice.now &&
        _startsToday) {
      return;
    }
    setState(() {
      _onboardingGoalStartChoice = _OnboardingGoalStartChoice.now;
      _goalStartDate = today;
    });
  }

  void _selectOnboardingTodayTracking(
    CalorieGoalOnboardingTodayTracking value,
  ) {
    if (_onboardingTodayTrackingChoice == value) {
      return;
    }
    setState(() {
      _onboardingTodayTrackingChoice = value;
    });
  }

  void _selectOnboardingCatchUpEstimate(
    CalorieGoalOnboardingCatchUpEstimate value,
  ) {
    if (_onboardingCatchUpEstimate == value) {
      return;
    }
    setState(() {
      _onboardingCatchUpEstimate = value;
    });
  }

  Future<void> _selectOnboardingStartLater() async {
    final today = CalorieGoalStartPicker.normalizeDate(DateTime.now());
    if (_onboardingGoalStartChoice == _OnboardingGoalStartChoice.later &&
        _goalStartDate.isAfter(today)) {
      return;
    }
    setState(() {
      _onboardingGoalStartChoice = _OnboardingGoalStartChoice.later;
      _onboardingTodayTrackingChoice = null;
      _goalStartDate = today.add(const Duration(days: 1));
    });
  }

  Future<void> _pickOnboardingFutureGoalStart() async {
    final today = CalorieGoalStartPicker.normalizeDate(DateTime.now());
    final pickedDate = await CalorieGoalStartPicker.pickDate(
      context,
      initialGoalStartDate: _goalStartDate.isAfter(today)
          ? _goalStartDate
          : today.add(const Duration(days: 1)),
      now: DateTime.now(),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: DateTime(today.year + 10, today.month, today.day),
    );
    if (pickedDate == null || !mounted) {
      return;
    }
    if (CalorieGoalStartPicker.isSameDay(_goalStartDate, pickedDate)) {
      return;
    }
    setState(() {
      _onboardingGoalStartChoice = _OnboardingGoalStartChoice.later;
      _onboardingTodayTrackingChoice = null;
      _goalStartDate = pickedDate;
    });
  }
}
