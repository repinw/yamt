import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/calorie_goal_calculator_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/calorie_goal_start_dialog.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/diary/domain/diary_intro_data.dart';
import 'package:yamt/features/diary/presentation/diary_page_intro_coordinator.dart';
import 'package:yamt/features/health/presentation/controllers/health_connection_controller.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_sheet.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Tile for shifting the calorie goal start date.
class SettingsCalorieGoalStartTile extends ConsumerWidget {
  /// Creates the goal-start tile.
  const SettingsCalorieGoalStartTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(calorieGoalControllerProvider);
    final latestGoal = state.asData?.value.latestGoalEntry;
    final start = latestGoal?.effectiveCountingStartDate ?? DateTime.now();
    return SettingsTile(
      key: SettingsPageKeys.calorieGoalStartTile,
      icon: Icons.event_note_rounded,
      title: l10n.caloriesShiftGoalStartAction,
      subtitle: latestGoal == null
          ? l10n.settingsDiaryGoalSetGoalFirst
          : DateFormat.yMMMd(
              Localizations.localeOf(context).toString(),
            ).format(start),
      enabled: latestGoal != null && !state.isLoading,
      onTap: latestGoal == null || state.isLoading
          ? null
          : () => unawaited(_showGoalStart(context, ref, start)),
    );
  }

  Future<void> _showGoalStart(
    BuildContext context,
    WidgetRef ref,
    DateTime start,
  ) {
    return showCalorieGoalStartDialog(
      context: context,
      initialGoalStartDate: start,
      onSaveGoalStart: (date) => ref
          .read(calorieGoalControllerProvider.notifier)
          .shiftGoalStart(goalStartDate: date),
    );
  }
}

/// Tile for editing the calorie goal.
class SettingsCalorieGoalCalculatorTile extends ConsumerWidget {
  /// Creates the goal-calculator tile.
  const SettingsCalorieGoalCalculatorTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(calorieGoalControllerProvider);
    final settings = state.asData?.value;
    return SettingsTile(
      key: SettingsPageKeys.calorieGoalCalculatorTile,
      icon: Icons.track_changes_rounded,
      title: l10n.caloriesCalculatorAction,
      subtitle: l10n.caloriesCalculatorOnboardingSubtitle,
      enabled: settings != null && !state.isLoading,
      onTap: settings == null || state.isLoading
          ? null
          : () => unawaited(
              showCalorieGoalCalculatorSheet(
                context,
                initialSettings: settings,
              ),
            ),
    );
  }
}

/// Tile opening TDEE and weight analytics.
class SettingsTdeeAnalyticsTile extends StatelessWidget {
  /// Creates the analytics tile.
  const SettingsTdeeAnalyticsTile({super.key});

  @override
  Widget build(BuildContext context) => SettingsTile(
    icon: Icons.insights_rounded,
    title: 'TDEE- & Gewichtsverlauf',
    subtitle: 'Verbrauchskurve, Flux-Range & Ziel-Antizipation',
    onTap: () => unawaited(context.push(AppRoutes.homeCaloriesAnalytics)),
  );
}

/// Tile opening the goal archive.
class SettingsGoalArchiveTile extends StatelessWidget {
  /// Creates the goal-archive tile.
  const SettingsGoalArchiveTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsTile(
      key: SettingsPageKeys.goalArchiveTile,
      icon: Icons.archive_outlined,
      title: l10n.settingsGoalArchiveTitle,
      subtitle: l10n.settingsGoalArchiveSubtitle,
      onTap: () => unawaited(context.push(AppRoutes.homeSettingsGoalArchive)),
    );
  }
}

/// Tile opening macro targets.
class SettingsMacroGoalsTile extends StatelessWidget {
  /// Creates the macro-goals tile.
  const SettingsMacroGoalsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsTile(
      key: SettingsPageKeys.macroGoalsTile,
      icon: Icons.pie_chart_outline_rounded,
      title: l10n.settingsMacroGoalsTitle,
      subtitle: l10n.settingsMacroGoalsSubtitle,
      onTap: () => unawaited(showSettingsMacroGoalsSheet(context)),
    );
  }
}

/// Tile replaying the calorie goal introduction.
class SettingsCalorieGoalIntroTile extends ConsumerWidget {
  /// Creates the calorie-goal intro tile.
  const SettingsCalorieGoalIntroTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(calorieGoalControllerProvider);
    final settings = state.asData?.value;
    final enabled = settings != null && DiaryIntroData.canBuildFrom(settings);
    return SettingsTile(
      key: SettingsPageKeys.calorieGoalIntroTile,
      icon: Icons.auto_stories_outlined,
      title: l10n.settingsCalorieGoalIntroTitle,
      subtitle: l10n.settingsCalorieGoalIntroSubtitle,
      enabled: enabled && !state.isLoading,
      onTap: !enabled || state.isLoading
          ? null
          : () => _openIntro(context, ref, settings),
    );
  }

  void _openIntro(
    BuildContext context,
    WidgetRef ref,
    CalorieGoalSettings settings,
  ) {
    unawaited(
      runDiaryIntroFlow(
        context: context,
        ref: ref,
        introData: DiaryIntroData.fromSettings(settings),
        healthStatus: ref.read(healthConnectionControllerProvider).value,
      ),
    );
  }
}
