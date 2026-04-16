// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_health_weight_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manual health weight repository.

@ProviderFor(manualHealthWeightRepository)
final manualHealthWeightRepositoryProvider =
    ManualHealthWeightRepositoryProvider._();

/// Manual health weight repository.

final class ManualHealthWeightRepositoryProvider
    extends
        $FunctionalProvider<
          ManualHealthWeightRepository,
          ManualHealthWeightRepository,
          ManualHealthWeightRepository
        >
    with $Provider<ManualHealthWeightRepository> {
  /// Manual health weight repository.
  ManualHealthWeightRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualHealthWeightRepositoryProvider',
        isAutoDispose: true,
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
    r'2aeca9c83a1a934800be11a61d7cb51d135b0f42';
