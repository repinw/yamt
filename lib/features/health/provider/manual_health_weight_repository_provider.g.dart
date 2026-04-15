// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_health_weight_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(manualHealthWeightRepository)
final manualHealthWeightRepositoryProvider =
    ManualHealthWeightRepositoryProvider._();

final class ManualHealthWeightRepositoryProvider
    extends
        $FunctionalProvider<
          ManualHealthWeightRepository,
          ManualHealthWeightRepository,
          ManualHealthWeightRepository
        >
    with $Provider<ManualHealthWeightRepository> {
  ManualHealthWeightRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualHealthWeightRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$manualHealthWeightRepositoryHash();

  @$internal
  @override
  $ProviderElement<ManualHealthWeightRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ManualHealthWeightRepository create(Ref ref) {
    return manualHealthWeightRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ManualHealthWeightRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ManualHealthWeightRepository>(value),
    );
  }
}

String _$manualHealthWeightRepositoryHash() =>
    r'a51c1cdca3f254d4f81f047488e4c7a84d8c7aed';
