// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'burn_week_run_state_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Burn Week run state repository provider.

@ProviderFor(burnWeekRunStateRepository)
final burnWeekRunStateRepositoryProvider =
    BurnWeekRunStateRepositoryProvider._();

/// Burn Week run state repository provider.

final class BurnWeekRunStateRepositoryProvider
    extends
        $FunctionalProvider<
          BurnWeekRunStateRepository,
          BurnWeekRunStateRepository,
          BurnWeekRunStateRepository
        >
    with $Provider<BurnWeekRunStateRepository> {
  /// Burn Week run state repository provider.
  BurnWeekRunStateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'burnWeekRunStateRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$burnWeekRunStateRepositoryHash();

  @$internal
  @override
  $ProviderElement<BurnWeekRunStateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BurnWeekRunStateRepository create(Ref ref) {
    return burnWeekRunStateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BurnWeekRunStateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BurnWeekRunStateRepository>(value),
    );
  }
}

String _$burnWeekRunStateRepositoryHash() =>
    r'36c4cc0e3f9aab7efe6f5520463987f1d7347c21';
