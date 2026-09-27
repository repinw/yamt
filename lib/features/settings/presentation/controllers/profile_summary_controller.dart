import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/daily_nutrition_target_resolver_service.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target.dart';
import 'package:yamt/features/calories/domain/daily_nutrition_target_resolver.dart';
import 'package:yamt/features/health/application/recent_weight_trend_provider.dart';
import 'package:yamt/features/health/domain/recent_weight_trend.dart';

part 'profile_summary_controller.g.dart';

/// Daily energy expenditure in kcal and whether weekly check-ins learned it.
typedef ProfileSummaryTdee = ({double kcal, bool isLearned});

/// Who the user is, as the profile page shows it.
typedef ProfileSummaryAccount = ({String? name, String? email, bool isGuest});

/// Body data, weights, and current goals shown on the profile page.
@immutable
class ProfileSummaryState {
  /// Creates a profile summary state.
  const new({
    required this.account,
    required this.profile,
    required this.ageYears,
    required this.weight,
    required this.macroWeightKg,
    required this.macroWeightSince,
    required this.tdee,
    required this.dailyKcalGoal,
    required this.macroTarget,
  });

  /// Name, email, and guest state of the signed-in user.
  final ProfileSummaryAccount account;

  /// Body data and weight goal from the calculator, or `null`.
  final CalorieCalculatorProfile? profile;

  /// Age in full years today, or `null` without a [profile].
  final int? ageYears;

  /// Recent weigh-ins and trend weight, or `null` while they load.
  final RecentWeightTrend? weight;

  /// Body weight that today's protein and fat targets use.
  final double? macroWeightKg;

  /// Day since which [macroWeightKg] applies, or `null` when it comes from the
  /// calculator profile.
  final DateTime? macroWeightSince;

  /// Expenditure learned from weekly check-ins, else estimated from the
  /// [profile]. `null` without either.
  final ProfileSummaryTdee? tdee;

  /// Base daily calorie goal, or `null` when no goal is set.
  final double? dailyKcalGoal;

  /// Protein, carbs, and fat for [dailyKcalGoal], or `null` without a goal.
  final DailyNutritionTarget? macroTarget;

  /// The weight that counts now: the trend weight, else the last weigh-in.
  double? get currentWeightKg =>
      weight?.trendWeightKg ?? weight?.latestWeighInKg;

  /// Kilograms left to the target weight, or `null` without a target.
  double? get kgToTarget {
    final target = profile?.targetWeightKg;
    final current = currentWeightKg;
    if (target == null || current == null) {
      return null;
    }
    return (current - target).abs();
  }

  /// Share of the way from the start weight to the target weight, 0 to 1.
  double? get goalProgress {
    final start = profile?.weightKg;
    final target = profile?.targetWeightKg;
    final current = currentWeightKg;
    if (start == null || target == null || current == null) {
      return null;
    }
    final distance = start - target;
    if (distance == 0) {
      return 1;
    }
    return ((start - current) / distance).clamp(0, 1).toDouble();
  }
}

/// Combines the user's account, calculator profile, recent weigh-ins, and
/// macro targets for the profile page.
@riverpod
class ProfileSummaryController extends _$ProfileSummaryController {
  @override
  Stream<ProfileSummaryState> build() {
    final account = ref.watch(
      userProfileProvider.select(
        (profile) => (
          name: profile.value?.displayName,
          email: profile.value?.email,
          isGuest: profile.value?.isAnonymous ?? true,
        ),
      ),
    );
    final resolver = ref.watch(dailyNutritionTargetResolverProvider);
    final now = ref.watch(clockProvider)();
    final weight = ref.watch(recentWeightTrendProvider).value;
    return ref
        .watch(calorieSettingsRepositoryProvider)
        .watchSettings()
        .map(
          (settings) => _summaryOf(
            settings,
            account: account,
            weight: weight,
            resolver: resolver,
            now: now,
          ),
        );
  }

  ProfileSummaryState _summaryOf(
    CalorieGoalSettings settings, {
    required ProfileSummaryAccount account,
    required RecentWeightTrend? weight,
    required DailyNutritionTargetResolver resolver,
    required DateTime now,
  }) {
    final profile = settings.calculatorProfile;
    final goalKcal = settings.dailyKcalGoal;
    return ProfileSummaryState(
      account: account,
      profile: profile,
      ageYears: profile?.ageAt(now),
      weight: weight,
      macroWeightKg: settings.macroWeightKgForDay(now),
      macroWeightSince: settings.macroWeightEntryForDay(now)?.effectiveDate,
      tdee: _tdeeOf(settings),
      dailyKcalGoal: goalKcal,
      macroTarget: goalKcal == null
          ? null
          : resolver.resolveBaseTarget(day: now, goalKcal: goalKcal),
    );
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
