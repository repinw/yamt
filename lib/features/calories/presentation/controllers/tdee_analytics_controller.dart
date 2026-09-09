import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_time_range.dart';

part 'tdee_analytics_controller.g.dart';

/// UI state for user selections on the TDEE analytics view.
class TdeeAnalyticsUiState {
  /// Creates UI state for TDEE analytics.
  const TdeeAnalyticsUiState({
    required this.selectedCycleId,
    required this.timeRange,
    this.showAnticipation = true,
  });

  /// ID of the currently selected goal cycle or 'all'.
  final String selectedCycleId;

  /// Selected time filter window.
  final TdeeAnalyticsTimeRange timeRange;

  /// Whether the anticipation dashed projection is visible.
  final bool showAnticipation;

  /// Copy with.
  TdeeAnalyticsUiState copyWith({
    String? selectedCycleId,
    TdeeAnalyticsTimeRange? timeRange,
    bool? showAnticipation,
  }) {
    return TdeeAnalyticsUiState(
      selectedCycleId: selectedCycleId ?? this.selectedCycleId,
      timeRange: timeRange ?? this.timeRange,
      showAnticipation: showAnticipation ?? this.showAnticipation,
    );
  }
}

/// Controller managing UI filter selections for TDEE analytics.
@riverpod
class TdeeAnalyticsController extends _$TdeeAnalyticsController {
  @override
  TdeeAnalyticsUiState build() {
    return const TdeeAnalyticsUiState(
      selectedCycleId: 'all',
      timeRange: TdeeAnalyticsTimeRange.days28,
    );
  }

  /// Sets the selected goal cycle.
  void selectCycle(String cycleId) {
    state = state.copyWith(selectedCycleId: cycleId);
  }

  /// Sets the selected time range.
  void selectTimeRange(TdeeAnalyticsTimeRange range) {
    state = state.copyWith(timeRange: range);
  }

  /// Toggles anticipation visibility.
  void toggleAnticipation() {
    state = state.copyWith(showAnticipation: !state.showAnticipation);
  }
}
