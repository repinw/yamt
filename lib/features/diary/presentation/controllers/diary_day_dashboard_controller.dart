import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';
import 'package:yamt/features/diary/application/'
    'diary_day_dashboard_live_data_provider.dart';
import 'package:yamt/features/diary/application/'
    'diary_day_dashboard_mappers.dart';
import 'package:yamt/features/diary/application/diary_macro_targets_resolver.dart';
import 'package:yamt/features/diary/application/diary_meal_sections_provider.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_provider.dart';
import 'package:yamt/features/diary/data/diary_day_dashboard_cache_store.dart';

part 'diary_day_dashboard_controller.g.dart';

const _keepError = Object();
const _mutationRefreshSettlingDelay = Duration(milliseconds: 650);

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
  Future<void>? _refreshInFlight;
  Timer? _settledMutationRefreshTimer;
  int _refreshGeneration = 0;
  var _refreshQueued = false;

  @override
  DiaryDayDashboardState build(DateTime selectedDay) {
    final normalizedDay = normalizeDiaryDay(selectedDay);
    final userId =
        ref.watch(authStateChangesProvider).asData?.value?.uid ??
        ref.watch(firebaseAuthProvider).currentUser?.uid;
    final preferences = ref.watch(appPreferencesProvider);
    final cacheStore = ref.watch(diaryDayDashboardCacheStoreProvider);
    ref.onDispose(() {
      _settledMutationRefreshTimer?.cancel();
    });
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
      refreshAfterMutation();
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
    return _refreshSelectedDay(queueIfInFlight: true);
  }

  /// Refreshes after a calorie mutation that may need backend settling time.
  void refreshAfterMutation() {
    unawaited(_refreshSelectedDay(forceRefresh: true));
    _settledMutationRefreshTimer?.cancel();
    _settledMutationRefreshTimer = Timer(
      _mutationRefreshSettlingDelay,
      () {
        if (!ref.mounted) {
          return;
        }
        unawaited(_refreshSelectedDay(forceRefresh: true));
      },
    );
  }

  Future<void> _refreshSelectedDay({
    bool queueIfInFlight = false,
    bool forceRefresh = false,
  }) {
    final normalizedDay = normalizeDiaryDay(selectedDay);
    return _refresh(
      normalizedDay: normalizedDay,
      userId:
          ref.read(authStateChangesProvider).asData?.value?.uid ??
          ref.read(firebaseAuthProvider).currentUser?.uid,
      preferences: ref.read(appPreferencesProvider),
      cacheStore: ref.read(diaryDayDashboardCacheStoreProvider),
      queueIfInFlight: queueIfInFlight,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> _refresh({
    required DateTime normalizedDay,
    required String? userId,
    required AppPreferences preferences,
    required DiaryDayDashboardCacheStore cacheStore,
    bool queueIfInFlight = false,
    bool forceRefresh = false,
  }) async {
    final inFlight = _refreshInFlight;
    if (inFlight != null && !forceRefresh) {
      if (queueIfInFlight) {
        _refreshQueued = true;
      }
      return inFlight;
    }

    do {
      _refreshQueued = false;
      final generation = ++_refreshGeneration;
      final refresh = _runRefresh(
        normalizedDay: normalizedDay,
        userId: userId,
        preferences: preferences,
        cacheStore: cacheStore,
        generation: generation,
      );
      _refreshInFlight = refresh;
      try {
        await refresh;
      } finally {
        if (identical(_refreshInFlight, refresh)) {
          _refreshInFlight = null;
        }
      }
    } while (_refreshQueued && ref.mounted);
  }

  Future<void> _runRefresh({
    required DateTime normalizedDay,
    required String? userId,
    required AppPreferences preferences,
    required DiaryDayDashboardCacheStore cacheStore,
    required int generation,
  }) async {
    state = state.copyWith(isRefreshing: true, error: null);
    _invalidateDashboardInputs(normalizedDay);

    try {
      final liveData = await ref.read(
        diaryDayDashboardLiveDataProvider(normalizedDay).future,
      );
      if (!_isCurrentRefresh(generation)) {
        return;
      }
      final selectedDayEntries = liveData.selectedDayEntries;
      final goalKcal = liveData.selectedDayOverview.goalKcal;
      final macroTargets = resolveDiaryMacroTargets(ref, goalKcal: goalKcal);

      final data = DiaryDayDashboardData(
        selectedDay: normalizedDay,
        refreshedAt: DateTime.now(),
        weekOverview: liveData.weekOverview,
        selectedDayEntries: selectedDayEntries,
        runState: liveData.runState,
        mealSections: buildDiaryDashboardMealSections(selectedDayEntries),
        nutritionBars: buildDiaryDashboardNutritionBars(
          selectedDayEntries,
          goalKcal,
          macroTargets: macroTargets,
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
      if (_isCurrentRefresh(generation)) {
        ref.read(burnWeekLiveSyncProvider);
      }
    } on Object catch (error) {
      if (!_isCurrentRefresh(generation)) {
        return;
      }
      if (_isDisposedDuringProviderLoad(error)) {
        state = state.copyWith(isRefreshing: false, error: null);
        return;
      }
      state = state.copyWith(isRefreshing: false, error: error);
    }
  }

  bool _isCurrentRefresh(int generation) {
    return ref.mounted && generation == _refreshGeneration;
  }

  void _invalidateDashboardInputs(DateTime normalizedDay) {
    ref.read(diaryBalanceActionsProvider).refreshBalance(normalizedDay);
    ref
        .read(diaryNutritionBarsActionsProvider)
        .refreshNutritionBars(
          normalizedDay,
        );
    ref
      ..invalidate(diaryMealSectionsProvider(normalizedDay))
      ..invalidate(diaryDayDashboardLiveDataProvider(normalizedDay));
  }
}

bool _isDisposedDuringProviderLoad(Object error) {
  return error is StateError && error.message.contains('disposed');
}
