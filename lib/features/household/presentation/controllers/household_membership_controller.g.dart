// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_membership_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs the membership actions of the household page.

@ProviderFor(HouseholdMembershipController)
final householdMembershipControllerProvider =
    HouseholdMembershipControllerProvider._();

/// Runs the membership actions of the household page.
final class HouseholdMembershipControllerProvider
    extends $AsyncNotifierProvider<HouseholdMembershipController, void> {
  /// Runs the membership actions of the household page.
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
    r'692197e79ac93317283052b814f69d852e161a04';

/// Runs the membership actions of the household page.

abstract class _$HouseholdMembershipController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
