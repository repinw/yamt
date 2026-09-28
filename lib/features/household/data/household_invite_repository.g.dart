// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_invite_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Household invite repository, or `null` while signed out or Firestore is
/// unavailable.

@ProviderFor(householdInviteRepository)
final householdInviteRepositoryProvider = HouseholdInviteRepositoryProvider._();

/// Household invite repository, or `null` while signed out or Firestore is
/// unavailable.

final class HouseholdInviteRepositoryProvider
    extends
        $FunctionalProvider<
          HouseholdInviteRepository?,
          HouseholdInviteRepository?,
          HouseholdInviteRepository?
        >
    with $Provider<HouseholdInviteRepository?> {
  /// Household invite repository, or `null` while signed out or Firestore is
  /// unavailable.
  HouseholdInviteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdInviteRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdInviteRepositoryHash();

  @$internal
  @override
  $ProviderElement<HouseholdInviteRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HouseholdInviteRepository? create(Ref ref) {
    return householdInviteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HouseholdInviteRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HouseholdInviteRepository?>(value),
    );
  }
}

String _$householdInviteRepositoryHash() =>
    r'2ff6c4755d3b485d02dc7bbd6bd07f5a1c139373';
