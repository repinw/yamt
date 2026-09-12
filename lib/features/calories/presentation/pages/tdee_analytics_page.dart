import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/application/tdee_analytics_provider.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_time_range.dart';
import 'package:yamt/features/calories/presentation/controllers/tdee_analytics_controller.dart';
import 'package:yamt/features/calories/presentation/widgets/tdee_analytics/tdee_analytics_header.dart';
import 'package:yamt/features/calories/presentation/widgets/tdee_analytics/tdee_flux_chart.dart';
import 'package:yamt/features/calories/presentation/widgets/tdee_analytics/tdee_goal_selector.dart';
import 'package:yamt/features/calories/presentation/widgets/tdee_analytics/tdee_insights_card.dart';
import 'package:yamt/features/calories/presentation/widgets/tdee_analytics/tdee_time_range_chips.dart';
import 'package:yamt/features/calories/presentation/widgets/tdee_analytics/tdee_weight_chart.dart';

/// Full-screen analytics page for TDEE expenditure, flux range,
/// and weight trend.
class TdeeAnalyticsPage extends ConsumerStatefulWidget {
  /// Creates the TDEE analytics page.
  const TdeeAnalyticsPage({super.key, this.initialCycleIds});

  /// Optional cycles selected by the goal archive.
  final Set<String>? initialCycleIds;

  @override
  ConsumerState<TdeeAnalyticsPage> createState() => _TdeeAnalyticsPageState();
}

class _TdeeAnalyticsPageState extends ConsumerState<TdeeAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    final initial = widget.initialCycleIds;
    if (initial != null && initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(tdeeAnalyticsControllerProvider.notifier)
            .selectCycles(initial, showFullRange: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(tdeeAnalyticsControllerProvider);
    final controller = ref.read(tdeeAnalyticsControllerProvider.notifier);

    final query = TdeeAnalyticsQuery(
      cycleIds: uiState.selectedCycleIds,
      timeRange: uiState.timeRange,
    );
    final analyticsAsync = ref.watch(tdeeAnalyticsProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('TDEE & Verbrauch'),
        actions: [
          analyticsAsync.whenOrNull(
                data: (data) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: TdeeGoalSelector(
                    selectedCycleIds: uiState.selectedCycleIds,
                    availableCycles: data.availableCycles,
                    onSelectCycles: controller.selectCycles,
                  ),
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: analyticsAsync.when(
        data: (data) => _buildContent(context, data, uiState, controller),
        loading: () => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Fehler beim Laden der Analyse: $err'),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TdeeAnalyticsState data,
    TdeeAnalyticsUiState uiState,
    TdeeAnalyticsController controller,
  ) {
    final points = data.points;
    final startDate = points.isNotEmpty ? points.first.day : DateTime.now();
    final endDate = points.isNotEmpty ? points.last.day : DateTime.now();

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          TdeeAnalyticsHeader(
            summary: data.summary,
            startDate: startDate,
            endDate: endDate,
          ),
          const SizedBox(height: AppSpacing.md),
          TdeeFluxChart(points: points),
          const SizedBox(height: AppSpacing.md),
          TdeeTimeRangeChips(
            selectedRange: uiState.timeRange,
            onSelectRange: controller.selectTimeRange,
          ),
          const SizedBox(height: AppSpacing.xxl),
          TdeeWeightChart(
            points: points,
            goalCycles: data.effectiveSelectedCycles,
            anticipation: data.anticipation,
            showAnticipation: uiState.showAnticipation,
            extendToProjectedGoal:
                uiState.timeRange == TdeeAnalyticsTimeRange.all,
          ),
          const SizedBox(height: AppSpacing.xl),
          TdeeInsightsCard(
            summary: data.summary,
            anticipation: data.anticipation,
            showAnticipation: uiState.showAnticipation,
            onToggleAnticipation: controller.toggleAnticipation,
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}
