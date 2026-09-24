// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_invite_code_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines household invite code controller.

@ProviderFor(HouseholdInviteCodeController)
final householdInviteCodeControllerProvider =
    HouseholdInviteCodeControllerProvider._();

/// Defines household invite code controller.
final class HouseholdInviteCodeControllerProvider
    extends
        $NotifierProvider<
          HouseholdInviteCodeController,
          AsyncValue<HouseholdInvite?>
        > {
  /// Defines household invite code controller.
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
    r'8298948d7c462469f2c2f14926daa8f6b3bddc77';

/// Defines household invite code controller.

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
