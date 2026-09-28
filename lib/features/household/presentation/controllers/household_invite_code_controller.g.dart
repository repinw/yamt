// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_invite_code_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the invite that the admin created for the active household.

@ProviderFor(HouseholdInviteCodeController)
final householdInviteCodeControllerProvider =
    HouseholdInviteCodeControllerProvider._();

/// Holds the invite that the admin created for the active household.
final class HouseholdInviteCodeControllerProvider
    extends
        $NotifierProvider<
          HouseholdInviteCodeController,
          AsyncValue<HouseholdInvite?>
        > {
  /// Holds the invite that the admin created for the active household.
  HouseholdInviteCodeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdInviteCodeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdInviteCodeControllerHash();

  @$internal
  @override
  HouseholdInviteCodeController create() => HouseholdInviteCodeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<HouseholdInvite?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<HouseholdInvite?>>(value),
    );
  }
}

String _$householdInviteCodeControllerHash() =>
    r'dd2d50de2be521877bbf5193ac7114616dbfddaf';

/// Holds the invite that the admin created for the active household.

abstract class _$HouseholdInviteCodeController
    extends $Notifier<AsyncValue<HouseholdInvite?>> {
  AsyncValue<HouseholdInvite?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<HouseholdInvite?>, AsyncValue<HouseholdInvite?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<HouseholdInvite?>,
                AsyncValue<HouseholdInvite?>
              >,
              AsyncValue<HouseholdInvite?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
