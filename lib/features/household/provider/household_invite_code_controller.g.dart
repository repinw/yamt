// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_invite_code_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HouseholdInviteCodeController)
final householdInviteCodeControllerProvider =
    HouseholdInviteCodeControllerProvider._();

final class HouseholdInviteCodeControllerProvider
    extends
        $NotifierProvider<HouseholdInviteCodeController, AsyncValue<String?>> {
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
  Override overrideWithValue(AsyncValue<String?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<String?>>(value),
    );
  }
}

String _$householdInviteCodeControllerHash() =>
    r'3cc51937d2156ef9cf7947b5bea2a77db353b8e9';

abstract class _$HouseholdInviteCodeController
    extends $Notifier<AsyncValue<String?>> {
  AsyncValue<String?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, AsyncValue<String?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, AsyncValue<String?>>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
