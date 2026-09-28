// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_members_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The members of the active household, the admin first, then by the day
/// they joined. Empty while there is no household yet.

@ProviderFor(householdMembers)
final householdMembersProvider = HouseholdMembersProvider._();

/// The members of the active household, the admin first, then by the day
/// they joined. Empty while there is no household yet.

final class HouseholdMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HouseholdMember>>,
          List<HouseholdMember>,
          Stream<List<HouseholdMember>>
        >
    with
        $FutureModifier<List<HouseholdMember>>,
        $StreamProvider<List<HouseholdMember>> {
  /// The members of the active household, the admin first, then by the day
  /// they joined. Empty while there is no household yet.
  HouseholdMembersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdMembersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdMembersHash();

  @$internal
  @override
  $StreamProviderElement<List<HouseholdMember>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<HouseholdMember>> create(Ref ref) {
    return householdMembers(ref);
  }
}

String _$householdMembersHash() => r'a2cdd1af967176ce6230bc177b9f58e976038ee8';

/// The other members of the active household who wait for its key after a
/// fresh start.

@ProviderFor(householdKeyRestoreRequests)
final householdKeyRestoreRequestsProvider =
    HouseholdKeyRestoreRequestsProvider._();

/// The other members of the active household who wait for its key after a
/// fresh start.

final class HouseholdKeyRestoreRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HouseholdMember>>,
          List<HouseholdMember>,
          Stream<List<HouseholdMember>>
        >
    with
        $FutureModifier<List<HouseholdMember>>,
        $StreamProvider<List<HouseholdMember>> {
  /// The other members of the active household who wait for its key after a
  /// fresh start.
  HouseholdKeyRestoreRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdKeyRestoreRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdKeyRestoreRequestsHash();

  @$internal
  @override
  $StreamProviderElement<List<HouseholdMember>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<HouseholdMember>> create(Ref ref) {
    return householdKeyRestoreRequests(ref);
  }
}

String _$householdKeyRestoreRequestsHash() =>
    r'8c227dd845d7ac538f330d45ac57002a41bab349';
