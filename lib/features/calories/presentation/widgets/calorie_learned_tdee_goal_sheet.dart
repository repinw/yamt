import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_eating_window_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_input_controls.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_results.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_start_picker.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Show calorie learned tdee goal sheet.
Future<void> showCalorieLearnedTdeeGoalSheet(
  BuildContext context, {
  required CalorieGoalSettings initialSettings,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return CalorieLearnedTdeeGoalSheet(initialSettings: initialSettings);
    },
  );
}

/// Defines calorie learned tdee goal sheet.
class CalorieLearnedTdeeGoalSheet extends ConsumerStatefulWidget {
  /// The calorie learned tdee goal sheet.
  const CalorieLearnedTdeeGoalSheet({required this.initialSettings, super.key});

  /// The initial settings.
  final CalorieGoalSettings initialSettings;

  @override
  ConsumerState<CalorieLearnedTdeeGoalSheet> createState() =>
      _CalorieLearnedTdeeGoalSheetState();
}

class _CalorieLearnedTdeeGoalSheetState
    extends ConsumerState<CalorieLearnedTdeeGoalSheet> {
  late final TextEditingController _goalSpeedController;
  late DateTime _goalStartAt;
  late int _eatingWindowStartMinuteOfDay;
  late int _eatingWindowEndMinuteOfDay;
  late CalorieGoalMode _goalMode;
  late String _lastNonMaintainGoalSpeedText;
  var _isSaving = false;

  double get _learnedTdeeKcal {
    return widget.initialSettings.latestLearnedTdeeKcal ?? 0;
  }

  double get _goalSpeedKgPerWeek {
    if (_goalMode == CalorieGoalMode.maintain) {
      return 0;
    }
    final normalizedValue = _goalSpeedController.text.trim().replaceAll(
      ',',
      '.',
    );
    return double.tryParse(normalizedValue) ?? 0;
  }

  double get _resolvedGoalKcal {
    return CalorieWeeklyCheckInCalculator.calculateGoalFromLearnedTdee(
      learnedTdeeKcal: _learnedTdeeKcal,
      goalSpeedKgPerWeek: _goalSpeedKgPerWeek,
      isLosing: _goalMode == CalorieGoalMode.lose,
      isGaining: _goalMode == CalorieGoalMode.gain,
    );
  }

  bool get _canSave {
    if (_isSaving || _learnedTdeeKcal <= 0) {
      return false;
    }
    if (_goalMode == CalorieGoalMode.maintain) {
      return true;
    }
    return _goalSpeedKgPerWeek > 0;
  }

  @override
  void initState() {
    super.initState();
    final profile =
        widget.initialSettings.calculatorProfile ??
        const CalorieCalculatorProfile.defaults();
    _goalMode = profile.goalMode;
    _lastNonMaintainGoalSpeedText = profile.goalSpeedKgPerWeek > 0
        ? profile.goalSpeedKgPerWeek.toString()
        : '0.5';
    _goalSpeedController = TextEditingController(
      text: _goalMode == CalorieGoalMode.maintain
          ? '0'
          : _lastNonMaintainGoalSpeedText,
    );
    _goalStartAt = CalorieGoalStartPicker.roundToMinute(DateTime.now());
    _eatingWindowStartMinuteOfDay =
        widget.initialSettings.normalizedEatingWindowStartMinuteOfDay;
    _eatingWindowEndMinuteOfDay =
        widget.initialSettings.normalizedEatingWindowEndMinuteOfDay;
  }

  @override
  void dispose() {
    _goalSpeedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          top: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.lg + viewInsets.bottom,
        ),
        child: Material(
          key: CalorieLearnedTdeeSheetKeys.sheet,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Padding(
              padding: AppInsets.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.caloriesLearnedTdeeSheetTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.caloriesLearnedTdeeSheetSubtitle),
                  const SizedBox(height: AppSpacing.lg),
                  _LearnedTdeeRow(
                    label: l10n.caloriesLearnedTdeeLabel,
                    value:
                        '${numberFormat.format(_learnedTdeeKcal.round())} '
                        '${l10n.caloriesUnitKcal}',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.caloriesCalculatorGoalModeLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CalorieGoalCalculatorGoalModeSegmentedControl(
                    selectedGoalMode: _goalMode,
                    onSelected: _updateGoalMode,
                  ),
                  if (_goalMode != CalorieGoalMode.maintain) ...<Widget>[
                    const SizedBox(height: AppSpacing.lg),
                    CalorieGoalCalculatorNumberField(
                      fieldKey: CalorieGoalCalculatorSheetKeys.goalSpeedField,
                      controller: _goalSpeedController,
                      label: l10n.caloriesCalculatorGoalSpeedLabel,
                      hintText: l10n.caloriesCalculatorGoalSpeedHint,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _LearnedTdeeRow(
                    label: l10n.caloriesLearnedTdeeResultLabel,
                    value:
                        '${numberFormat.format(_resolvedGoalKcal.round())} '
                        '${l10n.caloriesUnitKcal}',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CalorieGoalCalculatorGoalStartCard(
                    goalStartAt: _goalStartAt,
                    onChangeRequested: _pickGoalStart,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CalorieGoalCalculatorEatingWindowCard(
                    startMinuteOfDay: _eatingWindowStartMinuteOfDay,
                    endMinuteOfDay: _eatingWindowEndMinuteOfDay,
                    onChangeRequested: _pickEatingWindow,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      TextButton(
                        key: CalorieLearnedTdeeSheetKeys.fullResetButton,
                        onPressed: _isSaving ? null : _openFullReset,
                        child: Text(
                          l10n.caloriesLearnedTdeeUseProfileResetAction,
                        ),
                      ),
                      FilledButton(
                        key: CalorieLearnedTdeeSheetKeys.saveButton,
                        onPressed: _canSave ? _save : null,
                        child: Text(l10n.caloriesCalculatorSaveAction),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateGoalMode(CalorieGoalMode nextGoalMode) {
    setState(() {
      _goalMode = nextGoalMode;
      if (nextGoalMode == CalorieGoalMode.maintain) {
        final currentValue = _goalSpeedController.text.trim();
        if (currentValue.isNotEmpty && currentValue != '0') {
          _lastNonMaintainGoalSpeedText = currentValue;
        }
        _goalSpeedController.text = '0';
        return;
      }

      _goalSpeedController.text = _lastNonMaintainGoalSpeedText;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isSaving = true;
    });

    final saved = await ref
        .read(calorieGoalControllerProvider.notifier)
        .saveLearnedTdeeGoal(
          goalMode: _goalMode,
          goalSpeedKgPerWeek: _goalSpeedKgPerWeek,
          goalStartAt: _goalStartAt,
          eatingWindowStartMinuteOfDay: _eatingWindowStartMinuteOfDay,
          eatingWindowEndMinuteOfDay: _eatingWindowEndMinuteOfDay,
        );

    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
    });
    if (saved) {
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.caloriesLearnedTdeeSaveFailed)),
      );
  }

  Future<void> _openFullReset() async {
    Navigator.of(context).pop();
    await showCalorieGoalCalculatorSheet(
      context,
      initialSettings: widget.initialSettings,
      preferLearnedTdee: false,
    );
  }

  Future<void> _pickGoalStart() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final now = CalorieGoalStartPicker.roundToMinute(DateTime.now());
    final initialGoalStart = _goalStartAt;
    final pickedDate = await CalorieGoalStartPicker.pickDate(
      context,
      initialGoalStartAt: initialGoalStart,
      now: now,
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    if (!DateUtils.isSameDay(pickedDate, now)) {
      setState(() {
        _goalStartAt = CalorieGoalStartPicker.sixAm(pickedDate);
      });
      return;
    }

    final pickedTime = await CalorieGoalStartPicker.pickTime(
      context,
      initialGoalStartAt: initialGoalStart,
    );
    if (pickedTime == null || !mounted) {
      return;
    }

    final pickedGoalStart = CalorieGoalStartPicker.combineDateAndTime(
      date: pickedDate,
      time: pickedTime,
    );
    if (pickedGoalStart.isAfter(now)) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.caloriesCalculatorGoalStartFutureError)),
        );
      return;
    }

    setState(() {
      _goalStartAt = pickedGoalStart;
    });
  }

  Future<void> _pickEatingWindow() async {
    await showCalorieEatingWindowDialog(
      context: context,
      initialStartMinuteOfDay: _eatingWindowStartMinuteOfDay,
      initialEndMinuteOfDay: _eatingWindowEndMinuteOfDay,
      onSaveEatingWindow: (startMinuteOfDay, endMinuteOfDay) async {
        if (!mounted) {
          return false;
        }
        setState(() {
          _eatingWindowStartMinuteOfDay = startMinuteOfDay;
          _eatingWindowEndMinuteOfDay = endMinuteOfDay;
        });
        return true;
      },
    );
  }
}

class _LearnedTdeeRow extends StatelessWidget {
  const _LearnedTdeeRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label)),
        const SizedBox(width: AppSpacing.md),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
