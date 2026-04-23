import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/presentation/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_overview_card.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

const _foodDeltas = <double>[150, 500, 1000];
const _sportDeltas = <double>[-150, -500, -1000];
const _timeSpeedOptions = <int>[
  1,
  2,
  5,
  10,
  30,
  60,
  300,
  600,
  1800,
  3600,
  7200,
  21600,
  86400,
];
const int _debugSecondsPerDay = 24 * 60 * 60;

enum _BelowZoneAction { eatMore, useHeart }

/// Debug-only Burn Week mock page.
///
/// Mocks are debug-only and must stay hidden from normal user builds.
class BurnWeekMockPage extends ConsumerStatefulWidget {
  /// Creates Burn Week mock page.
  const BurnWeekMockPage({super.key, this.referenceNow});

  /// Fixed time for tests.
  final DateTime? referenceNow;

  @override
  ConsumerState<BurnWeekMockPage> createState() => _BurnWeekMockPageState();
}

class _BurnWeekMockPageState extends ConsumerState<BurnWeekMockPage> {
  static const int _startingStarCount = 0;
  static const int _startingHeartCount = 3;

  Timer? _ticker;
  late int _elapsedDebugSeconds;
  final List<_BurnWeekActionEvent> _events = <_BurnWeekActionEvent>[];
  final Set<int> _trackedDayNumbers = <int>{};
  final Set<int> _resolvedDayNumbers = <int>{};
  int _currentWeekNumber = 1;
  int _starCount = _startingStarCount;
  int _heartCount = _startingHeartCount;
  double _heartCreditKcal = 0;
  double _timeSpeedIndex = 0;
  bool _starBrokeThisWeek = false;
  bool _didResetRunDuringTick = false;
  bool _isZoneDialogOpen = false;
  BurnWeekZoneStatus _lastZoneStatus = BurnWeekZoneStatus.inside;
  String _weekMessage =
      'Keep at least 1 heart alive through the week to gain a star.';

  @override
  void initState() {
    super.initState();
    _elapsedDebugSeconds = _resolveInitialDebugSeconds(widget.referenceNow);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _advanceDebugTimeInState(_selectedTimeSpeed);
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  BurnWeekMockDifficulty get _currentDifficulty {
    return resolveBurnWeekMockDifficulty(_starCount);
  }

  void _queueZoneDialogIfNeeded(BurnWeekMockMetrics metrics) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybeShowZoneDialog(metrics));
    });
  }

  Future<void> _maybeShowZoneDialog(BurnWeekMockMetrics metrics) async {
    if (!mounted) {
      return;
    }

    final zoneDecision = resolveBurnWeekZoneDecision(metrics);
    if (zoneDecision.status == BurnWeekZoneStatus.inside) {
      _lastZoneStatus = BurnWeekZoneStatus.inside;
      return;
    }
    if (_isZoneDialogOpen || zoneDecision.status == _lastZoneStatus) {
      return;
    }

    _lastZoneStatus = zoneDecision.status;
    _isZoneDialogOpen = true;
    switch (zoneDecision.status) {
      case BurnWeekZoneStatus.below:
        await _showBelowZoneDialog(metrics, zoneDecision);
      case BurnWeekZoneStatus.above:
        await _showAboveZoneDialog(metrics, zoneDecision);
      case BurnWeekZoneStatus.inside:
        break;
    }

    _isZoneDialogOpen = false;
  }

  Future<void> _showBelowZoneDialog(
    BurnWeekMockMetrics metrics,
    BurnWeekZoneDecision decision,
  ) async {
    if (decision.type == BurnWeekZoneDecisionType.belowNeedsHeart) {
      if (_heartCount <= 0) {
        await _showSimpleZoneDialog(
          title: 'Run over',
          content:
              'There are not enough calories left in this week to recover by '
              'eating. No hearts left, so a fresh run starts next day.',
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _resetRun(
            message:
                'Run over. Not enough week calories left to recover and no '
                'hearts left. Fresh run started.',
          );
        });
        return;
      }

      final shouldUseHeart = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Too far below target'),
            content: const Text(
              'There are not enough calories left in this week to recover by '
              'eating. Use 1 heart to restore?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Use heart'),
              ),
            ],
          );
        },
      );

      if (shouldUseHeart == true && mounted) {
        _useHeart(metrics.dailyGoalKcal);
      }
      return;
    }

    final action = await showDialog<_BelowZoneAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Out of safe zone'),
          content: Text(
            _heartCount > 0
                ? 'You are below target. Use a heart for one full Burn day '
                      'leap, or eat more to get back in target.'
                : 'You are below target. No hearts left. Eat more to get '
                      'back in target.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_BelowZoneAction.eatMore);
              },
              child: const Text('Eat more'),
            ),
            if (_heartCount > 0)
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(_BelowZoneAction.useHeart);
                },
                child: const Text('Use heart'),
              ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (action == _BelowZoneAction.useHeart) {
      _useHeart(metrics.dailyGoalKcal);
      return;
    }

    if (action == _BelowZoneAction.eatMore) {
      await _showSimpleZoneDialog(
        title: 'Eat more',
        content: 'Eat more to get back in target.',
      );
    }
  }

  Future<void> _showSimpleZoneDialog({
    required String title,
    required String content,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBurnWeekDetailsDialog({
    required String actualText,
    required String targetText,
    required String baseKcalText,
    required String expectedKcalText,
    required String chosenTargetText,
    required String targetSpeedText,
    required String goalEquationText,
    required String weeklyGoalText,
    required String safeZoneText,
    required String heartCreditText,
  }) {
    final colors = Theme.of(context).colorScheme;
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Burn Week details'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          key: CaloriesPageKeys.burnWeekMockActualValue,
                          title: 'ACTUAL (YOU)',
                          value: actualText,
                          borderColor: colors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatCard(
                          key: CaloriesPageKeys.burnWeekMockTargetValue,
                          title: 'TARGET (GOAL)',
                          value: targetText,
                          borderColor: colors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Card(
                    key: CaloriesPageKeys.burnWeekMockInfoCard,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How this is calculated',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _InfoLine(
                            label: 'Base kcal',
                            value: baseKcalText,
                          ),
                          _InfoLine(
                            label: 'Expected kcal (PAL)',
                            value: expectedKcalText,
                          ),
                          _InfoLine(
                            label: 'Chosen target',
                            value: chosenTargetText,
                          ),
                          _InfoLine(
                            label: 'Target speed',
                            value: targetSpeedText,
                          ),
                          _InfoLine(
                            label: 'Goal equation',
                            value: goalEquationText,
                          ),
                          _InfoLine(
                            label: 'Safe zone if',
                            value: safeZoneText,
                          ),
                          _InfoLine(
                            label: 'Heart kcal used',
                            value: heartCreditText,
                          ),
                          _InfoLine(
                            label: 'Week target',
                            value: weeklyGoalText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAboveZoneDialog(
    BurnWeekMockMetrics metrics,
    BurnWeekZoneDecision decision,
  ) async {
    if (decision.type == BurnWeekZoneDecisionType.aboveFastOnly) {
      await _showSimpleZoneDialog(
        title: 'Out of safe zone',
        content: 'You tracked too much. Fasting will help to get on track.',
      );
      return;
    }

    if (_heartCount <= 0) {
      await _showSimpleZoneDialog(
        title: 'Run over',
        content:
            'You are way over weekly limit and have no hearts left. '
            'This run ends and a fresh run starts next day.',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _resetRun(
          message:
              'Run over. Too far above weekly limit with no hearts left. '
              'Fresh run started.',
        );
      });
      return;
    }

    final shouldUseHeart = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Use heart?'),
          content: const Text(
            'You are way over weekly limit. Use 1 heart to reduce one full '
            'Burn day of calories?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (shouldUseHeart == true && mounted) {
      _useHeartToReduce(metrics.dailyGoalKcal);
    }
  }

  void _applyDelta(double delta) {
    setState(() {
      _trackedDayNumbers.add(_currentDebugDayNumber);
      _events.add(
        _BurnWeekActionEvent(
          elapsedDebugSeconds: _elapsedDebugSeconds,
          deltaKcal: delta,
        ),
      );
    });
  }

  void _useHeart(double dailyGoalKcal) {
    if (_heartCount <= 0) {
      return;
    }

    setState(() {
      _didResetRunDuringTick = false;
      _lastZoneStatus = BurnWeekZoneStatus.inside;
      _trackedDayNumbers.add(_currentDebugDayNumber);
      _spendHeart(
        simpleMessage:
            'Used 1 heart for +1 Burn day leap. It counts like one full '
            'Burn day of calories.',
      );
      if (_didResetRunDuringTick) {
        return;
      }
      _heartCreditKcal += dailyGoalKcal;
    });
  }

  void _useHeartToReduce(double dailyGoalKcal) {
    if (_heartCount <= 0) {
      return;
    }

    setState(() {
      _didResetRunDuringTick = false;
      _lastZoneStatus = BurnWeekZoneStatus.inside;
      _trackedDayNumbers.add(_currentDebugDayNumber);
      _spendHeart(
        simpleMessage:
            'Used 1 heart to remove 1 Burn day of calories and get closer '
            'to weekly target.',
      );
      if (_didResetRunDuringTick) {
        return;
      }
      _heartCreditKcal -= dailyGoalKcal;
    });
  }

  Future<void> _confirmUseHeart(double dailyGoalKcal) async {
    if (_heartCount <= 0) {
      return;
    }

    final shouldUseHeart = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Use heart?'),
          content: const Text(
            'Using a heart adds one full Burn day of calories to your run. '
            'If hearts hit 0, one star can break and restore more hearts. '
            'If no stars are left, leaving the safe zone with 0 hearts '
            'will restart the run.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Use heart'),
            ),
          ],
        );
      },
    );

    if (shouldUseHeart == true && mounted) {
      _useHeart(dailyGoalKcal);
    }
  }

  void _advanceDebugTimeInState(int deltaSeconds) {
    _didResetRunDuringTick = false;
    var remainingSeconds = deltaSeconds;

    while (remainingSeconds > 0 && !_didResetRunDuringTick) {
      final nextBoundarySecond = _resolveNextBoundarySecond();
      final secondsUntilBoundary = nextBoundarySecond - _elapsedDebugSeconds;
      final step = math.min(remainingSeconds, secondsUntilBoundary);

      if (step > 0) {
        _elapsedDebugSeconds += step;
        remainingSeconds -= step;
      }

      if (_elapsedDebugSeconds != nextBoundarySecond) {
        continue;
      }

      final completedDayNumber = (_elapsedDebugSeconds ~/ _debugSecondsPerDay)
          .clamp(1, burnWeekDaysPerWeek);
      _resolveCompletedDay(completedDayNumber);
      if (_didResetRunDuringTick) {
        break;
      }

      if (_elapsedDebugSeconds >= burnWeekMockSecondsPerWeek) {
        _startNextWeek();
      }
    }
  }

  int _resolveNextBoundarySecond() {
    final nextDayBoundary =
        ((_elapsedDebugSeconds ~/ _debugSecondsPerDay) + 1) *
        _debugSecondsPerDay;
    return math.min(nextDayBoundary, burnWeekMockSecondsPerWeek);
  }

  void _resolveCompletedDay(int dayNumber) {
    if (!_resolvedDayNumbers.add(dayNumber)) {
      return;
    }
    if (_trackedDayNumbers.contains(dayNumber)) {
      return;
    }
    // Mock stays debug-friendly: missing tracking should not block
    // week rollover progression while testing stars/hearts.
    _weekMessage =
        'Day $dayNumber had no tracking. Mock keeps star progression '
        'enabled for debug.';
  }

  void _spendHeart({String? simpleMessage}) {
    final spendResult = resolveBurnWeekHeartSpend(
      starCount: _starCount,
      heartCount: _heartCount,
      heartCreditKcal: _heartCreditKcal,
      kcalDelta: 0,
    );
    if (spendResult.heartCount == _heartCount &&
        !spendResult.didBreakStar &&
        !spendResult.didResetRun) {
      return;
    }
    if (spendResult.didResetRun) {
      _resetRun();
      return;
    }

    _starCount = spendResult.starCount;
    _heartCount = spendResult.heartCount;
    if (spendResult.didBreakStar) {
      _starBrokeThisWeek = true;
      _weekMessage =
          'A star broke and restored $_heartCount hearts. '
          'This week can still survive, but it will not gain a star.';
      return;
    }
    if (simpleMessage != null) {
      _weekMessage = simpleMessage;
    }
  }

  void _startNextWeek() {
    final earnedStar = resolveBurnWeekEarnedStar(
      heartCount: _heartCount,
      starBrokeThisWeek: _starBrokeThisWeek,
      // Mock stays debug-friendly: missing tracking should not block
      // week rollover progression while testing stars/hearts.
      missedTrackingThisWeek: false,
    );
    if (earnedStar) {
      _starCount += 1;
    }

    _currentWeekNumber += 1;
    _elapsedDebugSeconds = 0;
    _events.clear();
    _trackedDayNumbers.clear();
    _resolvedDayNumbers.clear();
    _heartCreditKcal = 0;
    _starBrokeThisWeek = false;
    _heartCount = math.max(_heartCount, _currentDifficulty.minimumHearts);
    _weekMessage = earnedStar
        ? 'Perfect week. Gained 1 star. New difficulty: '
              '${_currentDifficulty.label}.'
        : 'Saved week. Run continues, but no new star this time.';
  }

  void _resetRun({
    String message = 'Run over. Restarted at Week 1 with 3 hearts.',
  }) {
    _currentWeekNumber = 1;
    _starCount = _startingStarCount;
    _heartCount = _startingHeartCount;
    _elapsedDebugSeconds = 0;
    _events.clear();
    _trackedDayNumbers.clear();
    _resolvedDayNumbers.clear();
    _heartCreditKcal = 0;
    _starBrokeThisWeek = false;
    _didResetRunDuringTick = true;
    _weekMessage = message;
  }

  int get _selectedTimeSpeed {
    return _timeSpeedOptions[_timeSpeedIndex.round()];
  }

  double get _totalConsumedKcal {
    return _events.fold<double>(0, (sum, event) => sum + event.deltaKcal);
  }

  int get _currentDebugDayNumber {
    return _resolveDebugDayNumber(_elapsedDebugSeconds);
  }

  double get _todayConsumedKcal {
    final currentDayNumber = _currentDebugDayNumber;
    return _events
        .where(
          (event) =>
              _resolveDebugDayNumber(event.elapsedDebugSeconds) ==
              currentDayNumber,
        )
        .fold<double>(0, (sum, event) => sum + event.deltaKcal);
  }

  int _resolveInitialDebugSeconds(DateTime? referenceNow) {
    if (referenceNow == null) {
      return 0;
    }
    return math.min(
      burnWeekMockSecondsPerWeek,
      (referenceNow.hour * 60 * 60) +
          (referenceNow.minute * 60) +
          referenceNow.second,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final oneDecimalFormat = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 1,
    );
    final selectedDay = ref.watch(calorieDayControllerProvider);
    final settings = ref.watch(calorieGoalControllerProvider).asData?.value;
    final dailyGoalKcal = settings?.goalKcalForDay(selectedDay);
    final calculatorProfile = settings?.calculatorProfile;
    final learnedTdeeKcal = settings?.latestLearnedTdeeKcal;
    final calorieCalculation = calculatorProfile == null
        ? null
        : CalorieGoalCalculator.calculate(calculatorProfile);
    final difficulty = _currentDifficulty;
    final weekDayLabel = 'Week $_currentWeekNumber day $_currentDebugDayNumber';
    final effectiveConsumedKcal = _totalConsumedKcal + _heartCreditKcal;
    final metrics = resolveBurnWeekMockMetrics(
      elapsedDebugSeconds: _elapsedDebugSeconds,
      goalKcal: dailyGoalKcal,
      consumedKcal: effectiveConsumedKcal,
      safeZoneMultiplier: difficulty.safeZoneMultiplier,
    );
    _queueZoneDialogIfNeeded(metrics);
    const kcalUnit = 'kcal';
    final currentDayBudgetKcal = _currentDebugDayNumber * metrics.dailyGoalKcal;
    final todayLeftKcal = currentDayBudgetKcal - effectiveConsumedKcal;
    final todayActualText =
        '${numberFormat.format(_todayConsumedKcal.round())} $kcalUnit';
    final todayLeftText =
        '${numberFormat.format(todayLeftKcal.round())} $kcalUnit';
    final targetText =
        '${numberFormat.format(metrics.targetKcal.round())} $kcalUnit';
    final actualText =
        '${numberFormat.format(metrics.consumedKcal.round())} $kcalUnit';
    final weeklyGoalText =
        '${numberFormat.format(metrics.weeklyGoalKcal.round())} $kcalUnit';
    final safeMinText =
        '${numberFormat.format(metrics.safeZoneMinKcal.round())} $kcalUnit';
    final safeMaxText =
        '${numberFormat.format(metrics.safeZoneMaxKcal.round())} $kcalUnit';
    final heartCreditText =
        '${numberFormat.format(_heartCreditKcal.round())} $kcalUnit';
    final expectedActivityKcal = calorieCalculation == null
        ? null
        : calorieCalculation.tdeeKcal - calorieCalculation.bmrKcal;
    final palActivityPercent = calculatorProfile == null
        ? null
        : (calculatorProfile.activityLevel - 1) * 100;
    final goalAdjustmentSignedKcal = switch ((
      calculatorProfile,
      calorieCalculation,
    )) {
      (final profile?, final calculation?) => switch (profile.goalMode) {
        CalorieGoalMode.lose => -calculation.dailyAdjustmentKcal,
        CalorieGoalMode.maintain => 0.0,
        CalorieGoalMode.gain => calculation.dailyAdjustmentKcal,
      },
      _ => null,
    };
    final signedGoalSpeedKgPerWeek = switch (calculatorProfile?.goalMode) {
      CalorieGoalMode.lose => -(calculatorProfile?.goalSpeedKgPerWeek ?? 0),
      CalorieGoalMode.maintain => 0.0,
      CalorieGoalMode.gain => calculatorProfile?.goalSpeedKgPerWeek ?? 0,
      null => null,
    };
    final learnedBasePrefix = learnedTdeeKcal == null
        ? null
        : 'Current base uses learned TDEE = '
              '${numberFormat.format(learnedTdeeKcal.round())} $kcalUnit.';
    final baseKcalText = switch ((calculatorProfile, calorieCalculation)) {
      (final profile?, final calculation?) =>
        '${learnedBasePrefix == null ? '' : '$learnedBasePrefix\n'}'
            'BMR = (10 x ${profile.weightKg.toStringAsFixed(1)} kg) + '
            '(6.25 x ${profile.heightCm.toStringAsFixed(1)} cm) - '
            '(5 x ${profile.ageYears}) '
            '${profile.sex == CalorieCalculatorSex.male ? '+ 5' : '- 161'} = '
            '${numberFormat.format(calculation.bmrKcal.round())} $kcalUnit',
      _ => 'No learned kcal and no calculator profile yet.',
    };
    final expectedKcalText = switch ((calculatorProfile, calorieCalculation)) {
      (final profile?, final calculation?) =>
        'Activity kcal = TDEE - BMR = '
            '${numberFormat.format(calculation.tdeeKcal.round())} - '
            '${numberFormat.format(calculation.bmrKcal.round())} = '
            '${numberFormat.format(expectedActivityKcal!.round())} '
            '$kcalUnit\n'
            '(= BMR x ${palActivityPercent!.toStringAsFixed(0)}% '
            'from PAL ${profile.activityLevel.toStringAsFixed(2)})',
      _ => 'No PAL profile saved yet.',
    };
    final chosenTargetText = switch (calculatorProfile?.goalMode) {
      CalorieGoalMode.lose => 'Losing',
      CalorieGoalMode.maintain => 'Holding',
      CalorieGoalMode.gain => 'Gaining',
      null => 'No target mode saved yet.',
    };
    final targetSpeedText = switch (signedGoalSpeedKgPerWeek) {
      final speed? =>
        '${speed > 0 ? '+' : ''}${oneDecimalFormat.format(speed)} kg/week '
            '-> ${goalAdjustmentSignedKcal! > 0 ? '+' : ''}'
            '${numberFormat.format(goalAdjustmentSignedKcal.round())} '
            '$kcalUnit/day',
      null => 'No target speed saved yet.',
    };
    final goalEquationText = switch ((
      calculatorProfile,
      calorieCalculation,
      goalAdjustmentSignedKcal,
      expectedActivityKcal,
      learnedTdeeKcal,
    )) {
      (
        _,
        final calculation?,
        final adjustment?,
        final activity?,
        null,
      ) =>
        'Goal kcal = BMR + activity + target adjustment = '
            '${numberFormat.format(calculation.bmrKcal.round())} + '
            '${numberFormat.format(activity.round())} '
            '${adjustment >= 0 ? '+' : '-'} '
            '${numberFormat.format(adjustment.abs().round())} = '
            '${numberFormat.format(calculation.finalGoalKcal.round())} '
            '$kcalUnit/day',
      (
        _,
        _,
        final adjustment?,
        _,
        final learned?,
      ) =>
        'Goal kcal = learned TDEE + target adjustment = '
            '${numberFormat.format(learned.round())} '
            '${adjustment >= 0 ? '+' : '-'} '
            '${numberFormat.format(adjustment.abs().round())} = '
            '${numberFormat.format((learned + adjustment).round())} '
            '$kcalUnit/day',
      _ => 'No calculator target saved yet.',
    };
    final safeZoneExplanationText =
        'ACTUAL stays between $safeMinText and $safeMaxText.';
    final timeSpeedLabel =
        'Debug time speed: ${_selectedTimeSpeed}x '
        '(${_formatTimeLeap(_selectedTimeSpeed)}/sec)';

    return Scaffold(
      appBar: AppBar(title: const Text('Burn Week')),
      body: ListView(
        padding: responsivePagePadding(
          context,
          top: AppSpacing.lg,
          bottom: homeShellPageBottomPadding(context),
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    timeSpeedLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Slider(
                    value: _timeSpeedIndex,
                    max: (_timeSpeedOptions.length - 1).toDouble(),
                    divisions: _timeSpeedOptions.length - 1,
                    label: '${_selectedTimeSpeed}x',
                    onChanged: (value) {
                      setState(() {
                        _timeSpeedIndex = value;
                      });
                    },
                  ),
                  Text(
                    _weekMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          BurnWeekOverviewCard(
            title: weekDayLabel,
            metrics: metrics,
            numberFormat: numberFormat,
            kcalUnit: kcalUnit,
            barKey: CaloriesPageKeys.burnWeekMockBar,
            starCount: _starCount,
            heartCount: _heartCount,
            onHeartTap: _heartCount > 0
                ? () => _confirmUseHeart(metrics.dailyGoalKcal)
                : null,
            onInfoPressed: () {
              unawaited(
                _showBurnWeekDetailsDialog(
                  actualText: actualText,
                  targetText: targetText,
                  baseKcalText: baseKcalText,
                  expectedKcalText: expectedKcalText,
                  chosenTargetText: chosenTargetText,
                  targetSpeedText: targetSpeedText,
                  goalEquationText: goalEquationText,
                  weeklyGoalText: weeklyGoalText,
                  safeZoneText: safeZoneExplanationText,
                  heartCreditText: heartCreditText,
                ),
              );
            },
            infoTooltip: 'Show Burn Week details',
            primaryStat: BurnWeekOverviewStatData(
              title: 'EATEN',
              value: todayActualText,
              borderColor: colors.tertiary,
            ),
            secondaryStat: BurnWeekOverviewStatData(
              title: 'TODAY LEFT',
              value: todayLeftText,
              borderColor: todayLeftKcal < 0 ? colors.error : colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _QuickActionColumn(
                  title: 'Food (+)',
                  icon: Icons.restaurant_rounded,
                  deltas: _foodDeltas,
                  color: colors.errorContainer,
                  iconColor: colors.error,
                  numberFormat: numberFormat,
                  onTap: _applyDelta,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickActionColumn(
                  title: 'Sport (-)',
                  icon: Icons.directions_run_rounded,
                  deltas: _sportDeltas,
                  color: colors.primaryContainer,
                  iconColor: colors.primary,
                  numberFormat: numberFormat,
                  onTap: _applyDelta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.borderColor,
    super.key,
  });

  final String title;
  final String value;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: borderColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionColumn extends StatelessWidget {
  const _QuickActionColumn({
    required this.title,
    required this.icon,
    required this.deltas,
    required this.color,
    required this.iconColor,
    required this.numberFormat,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final List<double> deltas;
  final Color color;
  final Color iconColor;
  final NumberFormat numberFormat;
  final ValueChanged<double> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final delta in deltas) ...[
          _QuickActionCard(
            delta: delta,
            color: color,
            icon: icon,
            iconColor: iconColor,
            numberFormat: numberFormat,
            onTap: () => onTap(delta),
          ),
          if (delta != deltas.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.delta,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.numberFormat,
    required this.onTap,
  });

  final double delta;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final NumberFormat numberFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 108,
      child: Material(
        color: color.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          key: CaloriesPageKeys.burnWeekMockQuickAction(
            delta.round().toString(),
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _formatSignedDelta(delta, numberFormat),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: RichText(
        text: TextSpan(
          style: style?.copyWith(color: colors.onSurface),
          children: [
            TextSpan(
              text: '$label: ',
              style: style?.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

String _formatSignedDelta(double delta, NumberFormat numberFormat) {
  final sign = delta >= 0 ? '+' : '';
  return '$sign${numberFormat.format(delta.round())}';
}

String _formatTimeLeap(int seconds) {
  if (seconds < 60) {
    return '${seconds}s';
  }
  if (seconds < 3600) {
    return '${seconds ~/ 60}m';
  }
  if (seconds < _debugSecondsPerDay) {
    return '${seconds ~/ 3600}h';
  }
  if (seconds % _debugSecondsPerDay == 0) {
    return '${seconds ~/ _debugSecondsPerDay}d';
  }
  return '${seconds ~/ 3600}h';
}

int _resolveDebugDayNumber(int elapsedDebugSeconds) {
  if (elapsedDebugSeconds >= burnWeekMockSecondsPerWeek) {
    return burnWeekDaysPerWeek;
  }
  return (elapsedDebugSeconds ~/ _debugSecondsPerDay) + 1;
}

class _BurnWeekActionEvent {
  const _BurnWeekActionEvent({
    required this.elapsedDebugSeconds,
    required this.deltaKcal,
  });

  final int elapsedDebugSeconds;
  final double deltaKcal;
}
