// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'burn_week_live_mutation_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps track of in-flight Burn Week live mutations to prevent duplicates.

@ProviderFor(burnWeekLiveMutationCoordinator)
final burnWeekLiveMutationCoordinatorProvider =
    BurnWeekLiveMutationCoordinatorProvider._();

/// Keeps track of in-flight Burn Week live mutations to prevent duplicates.

final class BurnWeekLiveMutationCoordinatorProvider
    extends
        $FunctionalProvider<
          BurnWeekLiveMutationCoordinator,
          BurnWeekLiveMutationCoordinator,
          BurnWeekLiveMutationCoordinator
        >
    with $Provider<BurnWeekLiveMutationCoordinator> {
  /// Keeps track of in-flight Burn Week live mutations to prevent duplicates.
  BurnWeekLiveMutationCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'burnWeekLiveMutationCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$burnWeekLiveMutationCoordinatorHash();

  @$internal
  @override
  $ProviderElement<BurnWeekLiveMutationCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BurnWeekLiveMutationCoordinator create(Ref ref) {
    return burnWeekLiveMutationCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BurnWeekLiveMutationCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BurnWeekLiveMutationCoordinator>(
        value,
      ),
    );
  }
}

String _$burnWeekLiveMutationCoordinatorHash() =>
    r'928f804285ee76caed6af58d2c9e19ffadc8f179';
