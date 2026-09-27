import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/recent_weight_trend.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

part 'recent_weight_trend_provider.g.dart';

/// The weights of the last days from manual entries and Health samples.
///
/// Health samples load only when Health access is ready. Saving or deleting
/// a weight through `ManualHealthWeightEntriesController` refreshes it.
@riverpod
Future<RecentWeightTrend> recentWeightTrend(Ref ref) async {
  final today = normalizeLocalDay(ref.watch(clockProvider)());
  final manualRepository = ref.watch(manualHealthWeightRepositoryProvider);
  final connectionService = ref.watch(healthConnectionServiceProvider);
  final healthWeightService = ref.watch(healthWeightServiceProvider);

  final manualEntries = await manualRepository.readEntries();
  if (!ref.mounted) {
    throw StateError('Recent weight trend provider disposed.');
  }
  final status = await connectionService.loadStatus();
  if (!ref.mounted) {
    throw StateError('Recent weight trend provider disposed.');
  }
  // Load earlier weights too, so the trend is settled when the chart starts.
  final healthSamples = status.accessState == HealthDataAccessState.ready
      ? await healthWeightService.loadWeightSamples(
          startInclusive: addLocalDays(
            today,
            -(WeightTrendCalculator.warmUpDays +
                RecentWeightTrend.chartDayCount),
          ),
          endExclusive: nextLocalDay(today),
        )
      : const <HealthWeightSample>[];
  if (!ref.mounted) {
    throw StateError('Recent weight trend provider disposed.');
  }
  return RecentWeightTrend.fromSeries(
    WeightTrendCalculator.fromSources(
      manualEntries: manualEntries,
      healthSamples: healthSamples,
    ),
    today: today,
  );
}
