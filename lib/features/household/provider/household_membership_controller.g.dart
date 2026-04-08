// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_membership_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HouseholdMembershipController)
final householdMembershipControllerProvider =
    HouseholdMembershipControllerProvider._();

final class HouseholdMembershipControllerProvider
    extends $AsyncNotifierProvider<HouseholdMembershipController, void> {
  HouseholdMembershipControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdMembershipControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdMembershipControllerHash();

  @$internal
  @override
  HouseholdMembershipController create() => HouseholdMembershipController();
}

String _$householdMembershipControllerHash() =>
    r'3e5d1d4ac9cd8b31a38c0029c02f02fcc6d800da';

abstract class _$HouseholdMembershipController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
