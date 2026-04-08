// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_members_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(householdMembers)
final householdMembersProvider = HouseholdMembersProvider._();

final class HouseholdMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserProfile>>,
          List<UserProfile>,
          Stream<List<UserProfile>>
        >
    with
        $FutureModifier<List<UserProfile>>,
        $StreamProvider<List<UserProfile>> {
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
  $StreamProviderElement<List<UserProfile>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<UserProfile>> create(Ref ref) {
    return householdMembers(ref);
  }
}

String _$householdMembersHash() => r'd367bf7783d60822a5a42060b9bb1893d8fc27cc';
