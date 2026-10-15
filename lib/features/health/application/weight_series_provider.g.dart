// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_series_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Health weight samples of all the user's devices, from the cloud, the
/// local cache first.
///
/// A failed cloud read is an error, so no reader computes without them.

@ProviderFor(healthWeightSamples)
final healthWeightSamplesProvider = HealthWeightSamplesProvider._();

/// The Health weight samples of all the user's devices, from the cloud, the
/// local cache first.
///
/// A failed cloud read is an error, so no reader computes without them.

final class HealthWeightSamplesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HealthWeightSample>>,
          List<HealthWeightSample>,
          Stream<List<HealthWeightSample>>
        >
    with
        $FutureModifier<List<HealthWeightSample>>,
        $StreamProvider<List<HealthWeightSample>> {
  /// The Health weight samples of all the user's devices, from the cloud, the
  /// local cache first.
  ///
  /// A failed cloud read is an error, so no reader computes without them.
  HealthWeightSamplesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthWeightSamplesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthWeightSamplesHash();

  @$internal
  @override
  $StreamProviderElement<List<HealthWeightSample>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<HealthWeightSample>> create(Ref ref) {
    return healthWeightSamples(ref);
  }
}

String _$healthWeightSamplesHash() =>
    r'd007f41b515f43dea3205a30e905aff3a82786f2';

/// Every weight of the user, manual and Health, as one daily series.
///
/// Health samples are stored from the first goal on, so the trend starts
/// there.

@ProviderFor(weightSeries)
final weightSeriesProvider = WeightSeriesProvider._();

/// Every weight of the user, manual and Health, as one daily series.
///
/// Health samples are stored from the first goal on, so the trend starts
/// there.

final class WeightSeriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyWeightSeries>,
          DailyWeightSeries,
          FutureOr<DailyWeightSeries>
        >
    with
        $FutureModifier<DailyWeightSeries>,
        $FutureProvider<DailyWeightSeries> {
  /// Every weight of the user, manual and Health, as one daily series.
  ///
  /// Health samples are stored from the first goal on, so the trend starts
  /// there.
  WeightSeriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weightSeriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weightSeriesHash();

  @$internal
  @override
  $FutureProviderElement<DailyWeightSeries> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DailyWeightSeries> create(Ref ref) {
    return weightSeries(ref);
  }
}

String _$weightSeriesHash() => r'822ac7993487720e9ed5d6f0ebe4c03a66d05b4d';
