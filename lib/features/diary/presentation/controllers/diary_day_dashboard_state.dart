import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';

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
