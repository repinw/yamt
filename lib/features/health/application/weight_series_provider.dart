import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/health/application/manual_health_weight_entries_controller.dart';
import 'package:yamt/features/health/data/health_weight_sample_repository.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

part 'weight_series_provider.g.dart';

/// The Health weight samples of all the user's devices, from the cloud, the
/// local cache first.
///
/// A failed cloud read is an error, so no reader computes without them.
@riverpod
Stream<List<HealthWeightSample>> healthWeightSamples(Ref ref) {
  return ref.watch(healthWeightSampleRepositoryProvider).watchSamples();
}

/// Every weight of the user, manual and Health, as one daily series.
///
/// Health samples are stored from the first goal on, so the trend starts
/// there.
@riverpod
Future<DailyWeightSeries> weightSeries(Ref ref) async {
  final (manualEntries, healthSamples) = await (
    ref.watch(manualHealthWeightEntriesControllerProvider.future),
    ref.watch(healthWeightSamplesProvider.future),
  ).wait;
  return WeightTrendCalculator.fromSources(
    manualEntries: manualEntries,
    healthSamples: healthSamples,
  );
}
