import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_time_range.dart';

part 'tdee_analytics_controller.g.dart';

/// UI state for user selections on the TDEE analytics view.
class TdeeAnalyticsUiState {
  /// Creates UI state for TDEE analytics.
  const TdeeAnalyticsUiState({
    required this.timeRange,
    this.selectedCycleIds = const <String>{'all'},
    this.showAnticipation = true,
  });

  /// IDs of selected goal cycles; `all` means every cycle.
  final Set<String> selectedCycleIds;

  /// Selected time filter window.
  final TdeeAnalyticsTimeRange timeRange;

  /// Whether the anticipation dashed projection is visible.
  final bool showAnticipation;

  /// Copy with.
  TdeeAnalyticsUiState copyWith({
    Set<String>? selectedCycleIds,
    TdeeAnalyticsTimeRange? timeRange,
    bool? showAnticipation,
  }) {
    return TdeeAnalyticsUiState(
      selectedCycleIds: selectedCycleIds ?? this.selectedCycleIds,
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
      timeRange: TdeeAnalyticsTimeRange.days28,
    );
  }

  /// Sets the selected goal cycle.
  void selectCycles(Set<String> cycleIds, {bool showFullRange = false}) {
    state = state.copyWith(
      selectedCycleIds: cycleIds.isEmpty ? const <String>{'all'} : cycleIds,
      timeRange: showFullRange ? TdeeAnalyticsTimeRange.all : state.timeRange,
    );
  }

  /// Backwards-compatible single-cycle selection.
  void selectCycle(String cycleId) {
    selectCycles(<String>{cycleId});
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
