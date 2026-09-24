import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/daily_nutrition_target_resolver_service.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target_resolver.dart';

part 'profile_summary_controller.g.dart';

/// Body data and current goals shown on the profile summary card.
@immutable
class ProfileSummaryState {
  /// Creates a profile summary state.
  const new({
    required this.name,
    required this.profile,
    required this.ageYears,
    required this.dailyKcalGoal,
    required this.macroTarget,
  });

  /// Display name, or `null` when the user has not set one.
  final String? name;

  /// Body data and weight goal from the calorie calculator, or `null`.
  final CalorieCalculatorProfile? profile;

  /// Age in full years today, or `null` without a [profile].
  final int? ageYears;

  /// Base daily calorie goal, or `null` when no goal is set.
  final double? dailyKcalGoal;

  /// Protein, carbs, and fat for [dailyKcalGoal], or `null` without a goal.
  final DailyNutritionTarget? macroTarget;
}

/// Combines the user's name, calculator profile, and macro targets for the
/// profile summary card.
@riverpod
class ProfileSummaryController extends _$ProfileSummaryController {
  @override
  Stream<ProfileSummaryState> build() {
    final name = ref.watch(
      userProfileProvider.select((profile) => profile.value?.displayName),
    );
    final resolver = ref.watch(dailyNutritionTargetResolverProvider);
    final now = ref.watch(clockProvider)();
    return ref
        .watch(calorieSettingsRepositoryProvider)
        .watchSettings()
        .map(
          (settings) =>
              _summaryOf(settings, name: name, resolver: resolver, now: now),
        );
  }

  ProfileSummaryState _summaryOf(
    CalorieGoalSettings settings, {
    required String? name,
    required DailyNutritionTargetResolver resolver,
    required DateTime now,
  }) {
    final profile = settings.calculatorProfile;
    final goalKcal = settings.dailyKcalGoal;
    return ProfileSummaryState(
      name: name,
      profile: profile,
      ageYears: profile?.ageAt(now),
      dailyKcalGoal: goalKcal,
      macroTarget: goalKcal == null
          ? null
          : resolver.resolveBaseTarget(day: now, goalKcal: goalKcal),
    );
  }
}
