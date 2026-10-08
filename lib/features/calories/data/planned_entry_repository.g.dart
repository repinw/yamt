// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planned_entry_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Planned entry repository of the signed-in user.

@ProviderFor(plannedEntryRepository)
final plannedEntryRepositoryProvider = PlannedEntryRepositoryProvider._();

/// Planned entry repository of the signed-in user.

final class PlannedEntryRepositoryProvider
    extends
        $FunctionalProvider<
          PlannedEntryRepository,
          PlannedEntryRepository,
          PlannedEntryRepository
        >
    with $Provider<PlannedEntryRepository> {
  /// Planned entry repository of the signed-in user.
  PlannedEntryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plannedEntryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plannedEntryRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlannedEntryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlannedEntryRepository create(Ref ref) {
    return plannedEntryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlannedEntryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlannedEntryRepository>(value),
    );
  }
}

String _$plannedEntryRepositoryHash() =>
    r'af0d6cdd7fd898777ed384f7b43655d0495eff7f';
