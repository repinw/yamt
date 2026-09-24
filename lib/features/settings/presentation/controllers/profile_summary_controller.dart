import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_data_provider.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/daily_nutrition_target_resolver_service.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target_resolver.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'profile_summary_controller.g.dart';

/// Daily energy expenditure in kcal and whether weekly check-ins learned it.
typedef ProfileSummaryTdee = ({double kcal, bool isLearned});

/// Body data and current goals shown on the profile summary card.
@immutable
class ProfileSummaryState {
  /// Creates a profile summary state.
  const new({
    required this.name,
    required this.profile,
    required this.ageYears,
    required this.currentWeightKg,
    required this.tdee,
    required this.dailyKcalGoal,
    required this.macroTarget,
  });

  /// Display name, or `null` when the user has not set one.
  final String? name;

  /// Body data and weight goal from the calorie calculator, or `null`.
  final CalorieCalculatorProfile? profile;

  /// Age in full years today, or `null` without a [profile].
  final int? ageYears;

  /// Latest weigh-in of the last seven days, else the profile weight. `null`
  /// while the weight data loads or without either.
  final double? currentWeightKg;

  /// Expenditure learned from weekly check-ins, else estimated from the
  /// [profile]. `null` without either.
  final ProfileSummaryTdee? tdee;

  /// Base daily calorie goal, or `null` when no goal is set.
  final double? dailyKcalGoal;

  /// Protein, carbs, and fat for [dailyKcalGoal], or `null` without a goal.
  final DailyNutritionTarget? macroTarget;

  /// Whether there is any body data to show.
  bool get hasBodyData =>
      profile != null || currentWeightKg != null || tdee != null;
}

/// Combines the user's name, calculator profile, recent weigh-ins, and macro
/// targets for the profile summary card.
@riverpod
class ProfileSummaryController extends _$ProfileSummaryController {
  @override
  Stream<ProfileSummaryState> build() {
    final name = ref.watch(
      userProfileProvider.select((profile) => profile.value?.displayName),
    );
    final resolver = ref.watch(dailyNutritionTargetResolverProvider);
    final now = ref.watch(clockProvider)();
    final weightData = ref
        .watch(diaryActivityWeightDataProvider(normalizeDiaryDay(now)))
        .value;
    return ref
        .watch(calorieSettingsRepositoryProvider)
        .watchSettings()
        .map(
          (settings) => _summaryOf(
            settings,
            name: name,
            weightData: weightData,
            resolver: resolver,
            now: now,
          ),
        );
  }

  ProfileSummaryState _summaryOf(
    CalorieGoalSettings settings, {
    required String? name,
    required DiaryActivityWeightData? weightData,
    required DailyNutritionTargetResolver resolver,
    required DateTime now,
  }) {
    final profile = settings.calculatorProfile;
    final goalKcal = settings.dailyKcalGoal;
    return ProfileSummaryState(
      name: name,
      profile: profile,
      ageYears: profile?.ageAt(now),
      currentWeightKg: weightData == null ? null : _currentWeightKg(weightData),
      tdee: _tdeeOf(settings),
      dailyKcalGoal: goalKcal,
      macroTarget: goalKcal == null
          ? null
          : resolver.resolveBaseTarget(day: now, goalKcal: goalKcal),
    );
  }

  double? _currentWeightKg(DiaryActivityWeightData weightData) {
    final latestWeighIn = weightData.weightDays.reversed
        .map((day) => day.weightKg)
        .nonNulls
        .firstOrNull;
    return latestWeighIn ?? weightData.profileWeightKg;
  }

  ProfileSummaryTdee? _tdeeOf(CalorieGoalSettings settings) {
    final learnedKcal = settings.latestLearnedTdeeKcal;
    if (learnedKcal != null) {
      return (kcal: learnedKcal, isLearned: true);
    }
    final profile = settings.calculatorProfile;
    if (profile == null) {
      return null;
    }
    return (
      kcal: CalorieGoalCalculator.calculate(profile).tdeeKcal,
      isLearned: false,
    );
  }
}
