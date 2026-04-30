import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Stable keys for diary intro tests.
abstract final class DiaryIntroDialogKeys {
  /// Dialog shell.
  static const dialog = ValueKey<String>('diary-intro-dialog');

  /// Page view.
  static const pageView = ValueKey<String>('diary-intro-page-view');

  /// Back button.
  static const backButton = ValueKey<String>('diary-intro-back');

  /// Next button.
  static const nextButton = ValueKey<String>('diary-intro-next');

  /// Done button.
  static const doneButton = ValueKey<String>('diary-intro-done');

  /// Health action button.
  static const healthActionButton = ValueKey<String>(
    'diary-intro-health-action',
  );

  /// Button that opens the intro again from the first diary week.
  static const replayButton = ValueKey<String>('diary-intro-replay');

  /// Dot for one intro page.
  static ValueKey<String> dot(int index) {
    return ValueKey<String>('diary-intro-dot-$index');
  }
}

/// Health action shown inside the diary intro.
class DiaryIntroHealthAction {
  /// Creates health action data.
  const DiaryIntroHealthAction({
    required this.accessState,
    required this.hasConnectionError,
    required this.onPressed,
  });

  /// Health access state.
  final HealthDataAccessState accessState;

  /// Whether action should send user to settings after a failed grant.
  final bool hasConnectionError;

  /// Press callback.
  final VoidCallback onPressed;
}

/// Calculator values shown in the first diary intro.
class DiaryIntroData {
  /// Creates intro data.
  const DiaryIntroData({
    required this.goalMode,
    required this.maintenanceKcal,
    required this.dailyAdjustmentKcal,
    required this.targetKcal,
    required this.goalSpeedKgPerWeek,
    required this.activityLevelOption,
    required this.expectedActivityKcal,
  });

  /// Creates intro data from current calorie settings.
  factory DiaryIntroData.fromSettings(CalorieGoalSettings settings) {
    final entry = settings.latestGoalEntry;
    final profile = entry?.calculatorProfile ?? settings.calculatorProfile;
    final targetKcal = entry?.dailyKcalGoal ?? settings.dailyKcalGoal;
    if (profile == null || targetKcal == null) {
      throw ArgumentError('Diary intro needs calculator profile and target.');
    }
    final calculation = CalorieGoalCalculator.calculate(profile);
    return DiaryIntroData(
      goalMode: profile.goalMode,
      maintenanceKcal: calculation.tdeeKcal.round(),
      dailyAdjustmentKcal: calculation.dailyAdjustmentKcal.round(),
      targetKcal: targetKcal.round(),
      goalSpeedKgPerWeek: profile.goalSpeedKgPerWeek,
      activityLevelOption: CalorieActivityLevelOption.fromActivityLevel(
        profile.activityLevel,
      ),
      expectedActivityKcal: calculation.expectedActivityKcal.round(),
    );
  }

  /// Whether settings can build intro data.
  static bool canBuildFrom(CalorieGoalSettings settings) {
    final entry = settings.latestGoalEntry;
    final profile = entry?.calculatorProfile ?? settings.calculatorProfile;
    final targetKcal = entry?.dailyKcalGoal ?? settings.dailyKcalGoal;
    return profile != null && targetKcal != null;
  }

  /// Goal mode.
  final CalorieGoalMode goalMode;

  /// Estimated maintenance calories.
  final int maintenanceKcal;

  /// Daily goal adjustment from weekly speed.
  final int dailyAdjustmentKcal;

  /// Initial daily target.
  final int targetKcal;

  /// Selected weekly speed.
  final double goalSpeedKgPerWeek;

  /// Selected activity profile.
  final CalorieActivityLevelOption activityLevelOption;

  /// Expected daily activity calories.
  final int expectedActivityKcal;
}

/// Shows the first diary intro dialog.
Future<bool?> showDiaryIntroDialog({
  required BuildContext context,
  required DiaryIntroData data,
  DiaryIntroHealthAction? healthAction,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => DiaryIntroDialog(
      data: data,
      healthAction: healthAction,
    ),
  );
}

/// First diary intro carousel.
class DiaryIntroDialog extends StatefulWidget {
  /// Creates the intro dialog.
  const DiaryIntroDialog({
    required this.data,
    this.healthAction,
    super.key,
  });

  /// Real calculator data to show.
  final DiaryIntroData data;

  /// Optional Health connection action.
  final DiaryIntroHealthAction? healthAction;

  @override
  State<DiaryIntroDialog> createState() => _DiaryIntroDialogState();
}

class _DiaryIntroDialogState extends State<DiaryIntroDialog> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _introPages(context, l10n);
    final isLastPage = _pageIndex == pages.length - 1;

    return Dialog(
      key: DiaryIntroDialogKeys.dialog,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: PageView.builder(
                  key: DiaryIntroDialogKeys.pageView,
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _pageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) => _DiaryIntroPage(
                    title: pages[index].title,
                    body: pages[index].body,
                    action: pages[index].action,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < pages.length; index += 1)
                    _DiaryIntroDot(
                      key: DiaryIntroDialogKeys.dot(index),
                      isActive: index == _pageIndex,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: AppSpacing.sm,
                overflowSpacing: AppSpacing.sm,
                children: [
                  TextButton(
                    key: DiaryIntroDialogKeys.backButton,
                    onPressed: _pageIndex == 0 ? null : _previousPage,
                    child: Text(l10n.diaryIntroBackAction),
                  ),
                  FilledButton(
                    key: isLastPage
                        ? DiaryIntroDialogKeys.doneButton
                        : DiaryIntroDialogKeys.nextButton,
                    onPressed: isLastPage ? _finish : _nextPage,
                    child: Text(
                      isLastPage
                          ? l10n.diaryIntroDoneAction
                          : l10n.diaryIntroNextAction,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_DiaryIntroPageData> _introPages(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final locale = Localizations.localeOf(context).toString();
    final speedFormat = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = 2;
    final kcalFormat = NumberFormat.decimalPattern(locale);
    final speed = speedFormat.format(widget.data.goalSpeedKgPerWeek);
    final maintenanceKcal = kcalFormat.format(widget.data.maintenanceKcal);
    final adjustmentKcal = kcalFormat.format(widget.data.dailyAdjustmentKcal);
    final targetKcal = kcalFormat.format(widget.data.targetKcal);
    final activityKcal = kcalFormat.format(widget.data.expectedActivityKcal);
    final activityProfile = _activityLevelTitle(
      l10n,
      widget.data.activityLevelOption,
    );
    return <_DiaryIntroPageData>[
      _DiaryIntroPageData(
        title: l10n.diaryIntroStartTitle,
        body: l10n.diaryIntroStartBody(maintenanceKcal),
      ),
      _DiaryIntroPageData(
        title: l10n.diaryIntroGoalTitle,
        body: switch (widget.data.goalMode) {
          CalorieGoalMode.lose => l10n.diaryIntroGoalLoseBody(
            speed,
            adjustmentKcal,
          ),
          CalorieGoalMode.gain => l10n.diaryIntroGoalGainBody(
            speed,
            adjustmentKcal,
          ),
          CalorieGoalMode.maintain => l10n.diaryIntroGoalMaintainBody,
        },
      ),
      _DiaryIntroPageData(
        title: l10n.diaryIntroTargetTitle,
        body: l10n.diaryIntroTargetBody(targetKcal),
      ),
      _DiaryIntroPageData(
        title: l10n.diaryIntroWeekOneTitle,
        body: l10n.diaryIntroWeekOneBody,
      ),
      _DiaryIntroPageData(
        title: l10n.diaryIntroBetterDataTitle,
        body: l10n.diaryIntroBetterDataBody,
      ),
      _DiaryIntroPageData(
        title: l10n.diaryIntroActivityTitle,
        body: l10n.diaryIntroActivityBody(activityProfile, activityKcal),
        action: _buildHealthAction(context, l10n),
      ),
    ];
  }

  Widget? _buildHealthAction(BuildContext context, AppLocalizations l10n) {
    final action = widget.healthAction;
    if (action == null) {
      return null;
    }
    final label = action.hasConnectionError
        ? l10n.diaryHealthSettingsAction
        : switch (action.accessState) {
            HealthDataAccessState.installRequired =>
              l10n.diaryHealthInstallAction,
            HealthDataAccessState.historyRequired =>
              l10n.diaryHealthAllowAction,
            HealthDataAccessState.permissionRequired =>
              l10n.diaryHealthConnectAction,
            HealthDataAccessState.ready ||
            HealthDataAccessState.unsupported => l10n.diaryHealthConnectAction,
          };
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: FilledButton.tonalIcon(
        key: DiaryIntroDialogKeys.healthActionButton,
        onPressed: action.onPressed,
        icon: const Icon(Icons.health_and_safety_rounded),
        label: Text(label),
      ),
    );
  }

  String _activityLevelTitle(
    AppLocalizations l10n,
    CalorieActivityLevelOption option,
  ) {
    return switch (option) {
      CalorieActivityLevelOption.none =>
        l10n.caloriesCalculatorActivityLevelNoneTitle,
      CalorieActivityLevelOption.low =>
        l10n.caloriesCalculatorActivityLevelLowTitle,
      CalorieActivityLevelOption.medium =>
        l10n.caloriesCalculatorActivityLevelMediumTitle,
      CalorieActivityLevelOption.high =>
        l10n.caloriesCalculatorActivityLevelHighTitle,
      CalorieActivityLevelOption.extreme =>
        l10n.caloriesCalculatorActivityLevelExtremeTitle,
    };
  }

  void _previousPage() {
    unawaited(
      _pageController.previousPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _nextPage() {
    unawaited(
      _pageController.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _finish() {
    Navigator.of(context).pop(true);
  }
}

class _DiaryIntroPage extends StatelessWidget {
  const _DiaryIntroPage({
    required this.title,
    required this.body,
    this.action,
  });

  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_graph_rounded,
                  color: colors.primary,
                  size: 42,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

class _DiaryIntroDot extends StatelessWidget {
  const _DiaryIntroDot({required this.isActive, super.key});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: isActive ? 18 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: isActive ? colors.primary : colors.outlineVariant,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _DiaryIntroPageData {
  const _DiaryIntroPageData({
    required this.title,
    required this.body,
    this.action,
  });

  final String title;
  final String body;
  final Widget? action;
}
