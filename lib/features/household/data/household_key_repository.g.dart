// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_key_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Household key repository, or `null` while Firestore is unavailable.

@ProviderFor(householdKeyRepository)
final householdKeyRepositoryProvider = HouseholdKeyRepositoryProvider._();

/// Household key repository, or `null` while Firestore is unavailable.

final class HouseholdKeyRepositoryProvider
    extends
        $FunctionalProvider<
          HouseholdKeyRepository?,
          HouseholdKeyRepository?,
          HouseholdKeyRepository?
        >
    with $Provider<HouseholdKeyRepository?> {
  /// Household key repository, or `null` while Firestore is unavailable.
  HouseholdKeyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdKeyRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdKeyRepositoryHash();

  @$internal
  @override
  $ProviderElement<HouseholdKeyRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HouseholdKeyRepository? create(Ref ref) {
    return householdKeyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HouseholdKeyRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HouseholdKeyRepository?>(value),
    );
  }
}

String _$householdKeyRepositoryHash() =>
    r'304c7d29e74fa663aefea1009216aa0195a3f2d3';
