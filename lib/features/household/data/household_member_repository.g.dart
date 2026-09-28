// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_member_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Household member repository, or `null` while signed out or Firestore is
/// unavailable.

@ProviderFor(householdMemberRepository)
final householdMemberRepositoryProvider = HouseholdMemberRepositoryProvider._();

/// Household member repository, or `null` while signed out or Firestore is
/// unavailable.

final class HouseholdMemberRepositoryProvider
    extends
        $FunctionalProvider<
          HouseholdMemberRepository?,
          HouseholdMemberRepository?,
          HouseholdMemberRepository?
        >
    with $Provider<HouseholdMemberRepository?> {
  /// Household member repository, or `null` while signed out or Firestore is
  /// unavailable.
  HouseholdMemberRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdMemberRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdMemberRepositoryHash();

  @$internal
  @override
  $ProviderElement<HouseholdMemberRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HouseholdMemberRepository? create(Ref ref) {
    return householdMemberRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HouseholdMemberRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HouseholdMemberRepository?>(value),
    );
  }
}

String _$householdMemberRepositoryHash() =>
    r'4a997b301dd206fd0b98575946ff7a4a4a7e6356';
