// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_membership_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines household membership controller.

@ProviderFor(HouseholdMembershipController)
final householdMembershipControllerProvider =
    HouseholdMembershipControllerProvider._();

/// Defines household membership controller.
final class HouseholdMembershipControllerProvider
    extends $AsyncNotifierProvider<HouseholdMembershipController, void> {
  /// Defines household membership controller.
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
    r'9107db4ecba650d26de5a3b778d7592193e1ff33';

/// Defines household membership controller.

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
