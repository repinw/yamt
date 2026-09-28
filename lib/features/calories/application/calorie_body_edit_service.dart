import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/daily_nutrition_target_resolver_service.dart';
import 'package:yamt/features/calories/application/macro_goal_settings_controller.dart';
import 'package:yamt/features/calories/domain/calorie_body_edit.dart';
import 'package:yamt/features/calories/domain/calorie_goal_body_edits.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';

part 'calorie_body_edit_service.g.dart';

/// What a body edit changes on today's calorie goal and macros.
@immutable
class CalorieBodyEditEffect {
  /// Creates the effect of one body edit.
  const new({
    required this.reach,
    required this.correctionStart,
    required this.before,
    required this.after,
  });

  /// How far the edit reaches into the calorie plan.
  final CalorieBodyEditReach reach;

  /// Start of the goal that the edit corrects, or `null` when it applies
  /// from today.
  final DateTime? correctionStart;

  /// Today's calorie goal and macros now, or `null` without a goal.
  final DailyNutritionTarget? before;

  /// Today's calorie goal and macros after the edit, or `null` without a
  /// goal.
  final DailyNutritionTarget? after;
}

/// Shows and saves what an edit of the body data changes.
class CalorieBodyEditService {
  /// Creates the service for the current [settings].
  const new({
    required this.settings,
    required this.macroSettings,
    required this.goalController,
  });

  /// Current calorie goal settings, or `null` while they load.
  final CalorieGoalSettings? settings;

  /// Current macro multipliers.
  final MacroGoalSettings macroSettings;

  /// Saves the calorie goal settings.
  final CalorieGoalController goalController;

  /// What [edit] would change at [now], or `null` while the settings load or
  /// without a calculator profile.
  CalorieBodyEditEffect? effectOf(
    CalorieBodyEdit edit, {
    required DateTime now,
  }) {
    final settings = this.settings;
    if (settings == null || settings.calculatorProfile == null) {
      return null;
    }
    return CalorieBodyEditEffect(
      reach: settings.bodyEditReach(now),
      correctionStart: settings.bodyCorrectionStart(now),
      before: _targetOf(settings, now),
      after: _targetOf(settings.applyBodyEdit(edit, now: now), now),
    );
  }

  /// Saves [edit] at [now] and reports whether it was stored.
  Future<bool> save(CalorieBodyEdit edit, {required DateTime now}) async {
    final previous = await goalController.currentSettings();
    return await goalController.persistSettings(
      previous.applyBodyEdit(edit, now: now),
    );
  }

  DailyNutritionTarget? _targetOf(CalorieGoalSettings settings, DateTime now) {
    if (!settings.hasGoal) {
      return null;
    }
    return DailyNutritionTargetResolverService(
      macroSettings: macroSettings,
      goalSettings: settings,
    ).resolveBaseTarget(day: now, goalKcal: settings.baseGoalKcalForDay(now));
  }
}

/// Provides the body edit service for the current calorie settings.
@riverpod
CalorieBodyEditService calorieBodyEditService(Ref ref) {
  return CalorieBodyEditService(
    settings: ref.watch(calorieGoalControllerProvider).value,
    macroSettings: ref.watch(macroGoalSettingsControllerProvider),
    goalController: ref.watch(calorieGoalControllerProvider.notifier),
  );
}
