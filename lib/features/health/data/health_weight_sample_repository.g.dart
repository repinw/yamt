// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_weight_sample_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Health weight samples of the user's devices, in the cloud.

@ProviderFor(healthWeightSampleRepository)
final healthWeightSampleRepositoryProvider =
    HealthWeightSampleRepositoryProvider._();

/// The Health weight samples of the user's devices, in the cloud.

final class HealthWeightSampleRepositoryProvider
    extends
        $FunctionalProvider<
          HealthWeightSampleRepository,
          HealthWeightSampleRepository,
          HealthWeightSampleRepository
        >
    with $Provider<HealthWeightSampleRepository> {
  /// The Health weight samples of the user's devices, in the cloud.
  HealthWeightSampleRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthWeightSampleRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthWeightSampleRepositoryHash();

  @$internal
  @override
  $ProviderElement<HealthWeightSampleRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HealthWeightSampleRepository create(Ref ref) {
    return healthWeightSampleRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthWeightSampleRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthWeightSampleRepository>(value),
    );
  }
}

String _$healthWeightSampleRepositoryHash() =>
    r'323b1daa5d70e3e5973408391eeabe5a997557fb';
