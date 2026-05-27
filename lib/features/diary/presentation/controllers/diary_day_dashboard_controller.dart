import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/provider/calorie_resolved_goal_provider.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';
import 'package:yamt/features/diary/application/diary_entries_provider.dart';
import 'package:yamt/features/diary/application/diary_meal_sections_provider.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_provider.dart';
import 'package:yamt/features/diary/data/diary_day_dashboard_cache_store.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';

part 'diary_day_dashboard_controller.g.dart';

const _keepError = Object();

/// State for one diary day dashboard.
class DiaryDayDashboardState {
  /// Creates diary day dashboard state.
  const DiaryDayDashboardState({
    required this.data,
    required this.isFromCache,
    required this.isRefreshing,
    required this.error,
  });

  /// Current dashboard data.
  final DiaryDayDashboardData? data;

  /// Whether [data] came from persisted cache.
  final bool isFromCache;

  /// Whether fresh data is currently loading.
  final bool isRefreshing;

  /// Latest refresh error, when any.
  final Object? error;

  /// Whether an error should be shown in the UI.
  bool get showError => data == null && error != null;

  /// Returns a copy with selected overrides.
  DiaryDayDashboardState copyWith({
    DiaryDayDashboardData? data,
    bool? isFromCache,
    bool? isRefreshing,
    Object? error = _keepError,
  }) {
    return DiaryDayDashboardState(
      data: data ?? this.data,
      isFromCache: isFromCache ?? this.isFromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: identical(error, _keepError) ? this.error : error,
    );
  }
}

/// Loads and caches the render-ready diary dashboard for one day.
@riverpod
class DiaryDayDashboardController extends _$DiaryDayDashboardController {
  @override
  DiaryDayDashboardState build(DateTime selectedDay) {
    final normalizedDay = normalizeDiaryDay(selectedDay);
    final userId =
        ref.watch(authStateChangesProvider).asData?.value?.uid ??
        ref.watch(firebaseAuthProvider).currentUser?.uid;
    final preferences = ref.watch(appPreferencesProvider);
    final cacheStore = ref.watch(diaryDayDashboardCacheStoreProvider);
    final cachedData = userId == null
        ? null
        : cacheStore.readSync(
            preferences: preferences,
            userId: userId,
            day: normalizedDay,
          );

    ref.listen<int>(calorieOverviewRevisionProvider, (previous, next) {
      if (previous == null || previous == next) {
        return;
      }
      unawaited(
        _refresh(
          normalizedDay: normalizedDay,
          userId: userId,
          preferences: preferences,
          cacheStore: cacheStore,
        ),
      );
    });

    unawaited(
      Future<void>.microtask(
        () => _refresh(
          normalizedDay: normalizedDay,
          userId: userId,
          preferences: preferences,
          cacheStore: cacheStore,
        ),
      ),
    );

    return DiaryDayDashboardState(
      data: cachedData,
      isFromCache: cachedData != null,
      isRefreshing: true,
      error: null,
    );
  }

  /// Refreshes this dashboard from live providers.
  Future<void> retry() {
    final normalizedDay = normalizeDiaryDay(selectedDay);
    _invalidateDashboardInputs(normalizedDay);

    return _refresh(
      normalizedDay: normalizedDay,
      userId:
          ref.read(authStateChangesProvider).asData?.value?.uid ??
          ref.read(firebaseAuthProvider).currentUser?.uid,
      preferences: ref.read(appPreferencesProvider),
      cacheStore: ref.read(diaryDayDashboardCacheStoreProvider),
    );
  }

  Future<void> _refresh({
    required DateTime normalizedDay,
    required String? userId,
    required AppPreferences preferences,
    required DiaryDayDashboardCacheStore cacheStore,
  }) async {
    state = state.copyWith(isRefreshing: true, error: null);
    _invalidateDashboardInputs(normalizedDay);

    try {
      final weekOverviewFuture = ref.read(
        calorieWeekOverviewForWindowProvider(normalizedDay).future,
      );
      final runStateFuture = ref.read(burnWeekRunControllerProvider.future);
      final entriesFuture = ref
          .read(calorieLogRepositoryProvider)
          .readEntriesForDay(normalizedDay);

      final weekOverview = await weekOverviewFuture;
      if (!ref.mounted) {
        return;
      }
      final runState = await runStateFuture;
      if (!ref.mounted) {
        return;
      }
      final selectedDayEntries = await entriesFuture;
      if (!ref.mounted) {
        return;
      }
      final selectedDayOverview = weekOverview.days.last;

      final data = DiaryDayDashboardData(
        selectedDay: normalizedDay,
        refreshedAt: DateTime.now(),
        weekOverview: weekOverview,
        selectedDayEntries: selectedDayEntries,
        runState: runState,
        mealSections: _mealSectionsFrom(selectedDayEntries),
        nutritionBars: _nutritionBarsFrom(
          selectedDayEntries,
          selectedDayOverview.goalKcal,
        ),
      );
      state = DiaryDayDashboardState(
        data: data,
        isFromCache: false,
        isRefreshing: false,
        error: null,
      );

      if (userId != null) {
        await cacheStore.save(
          preferences: preferences,
          userId: userId,
          data: data,
        );
      }
      if (ref.mounted) {
        ref.read(burnWeekLiveSyncProvider);
      }
    } on Object catch (error) {
      if (!ref.mounted) {
        return;
      }
      if (_isDisposedDuringProviderLoad(error)) {
        state = state.copyWith(isRefreshing: false, error: null);
        return;
      }
      state = state.copyWith(isRefreshing: false, error: error);
    }
  }

  void _invalidateDashboardInputs(DateTime normalizedDay) {
    final visibleDays = buildDiaryVisibleDays(anchorDay: normalizedDay);
    ref
      ..invalidate(diaryEntriesForDayProvider(normalizedDay))
      ..invalidate(diaryBalanceSourceProvider(normalizedDay))
      ..invalidate(resolvedCalorieGoalForDayProvider(normalizedDay))
      ..invalidate(
        resolvedCalorieGoalsForDaysProvider(
          ResolvedCalorieGoalDaysRequest.fromDays(visibleDays),
        ),
      )
      ..invalidate(calorieWeekOverviewForWindowProvider(normalizedDay))
      ..invalidate(diaryMealSectionsProvider(normalizedDay))
      ..invalidate(diaryNutritionBarsDataProvider(normalizedDay));
  }
}

bool _isDisposedDuringProviderLoad(Object error) {
  return error is StateError && error.message.contains('disposed');
}

List<DiaryMealSection> _mealSectionsFrom(List<CalorieEntry> entries) {
  final sectionEntries = <MealType, List<DiaryMealEntry>>{
    for (final mealType in MealType.sectionOrder) mealType: <DiaryMealEntry>[],
  };
  final sectionKcal = <MealType, double>{
    for (final mealType in MealType.sectionOrder) mealType: 0,
  };

  for (final entry in entries) {
    sectionEntries[entry.mealType]?.add(_mealEntryFrom(entry));
    sectionKcal[entry.mealType] =
        (sectionKcal[entry.mealType] ?? 0) + entry.totalKcal;
  }

  return MealType.sectionOrder
      .map((mealType) {
        return DiaryMealSection(
          mealType: mealType,
          entries: List<DiaryMealEntry>.unmodifiable(
            sectionEntries[mealType] ?? const <DiaryMealEntry>[],
          ),
          totalKcal: sectionKcal[mealType] ?? 0,
        );
      })
      .toList(growable: false);
}

DiaryMealEntry _mealEntryFrom(CalorieEntry entry) {
  return DiaryMealEntry(
    id: entry.id,
    mealType: entry.mealType,
    name: entry.name,
    imageUrl: entry.imageUrl,
    imageAssetId: entry.imageAssetId,
    totalKcal: entry.totalKcal,
    totalProtein: entry.totalProtein,
    totalCarbs: entry.totalCarbs,
    totalFat: entry.totalFat,
  );
}

DiaryNutritionBarsData _nutritionBarsFrom(
  List<CalorieEntry> entries,
  double goalKcal,
) {
  var carbs = 0.0;
  var protein = 0.0;
  var fat = 0.0;
  for (final entry in entries) {
    carbs += entry.totalCarbs;
    protein += entry.totalProtein;
    fat += entry.totalFat;
  }

  return DiaryNutritionBarsData(
    carbs: carbs,
    protein: protein,
    fat: fat,
    goals: DiaryMacroTargets.fromGoalKcal(goalKcal),
  );
}
