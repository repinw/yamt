// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest_name_setup_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether guest setup can be canceled.

@ProviderFor(canCancelGuestSetup)
final canCancelGuestSetupProvider = CanCancelGuestSetupProvider._();

/// Whether guest setup can be canceled.

final class CanCancelGuestSetupProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether guest setup can be canceled.
  CanCancelGuestSetupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'canCancelGuestSetupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$canCancelGuestSetupHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return canCancelGuestSetup(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$canCancelGuestSetupHash() =>
    r'037723490c48673084a0c77909d31717d1c9ca07';

/// Defines guest name setup controller.

@ProviderFor(GuestNameSetupController)
final guestNameSetupControllerProvider = GuestNameSetupControllerProvider._();

/// Defines guest name setup controller.
final class GuestNameSetupControllerProvider
    extends $AsyncNotifierProvider<GuestNameSetupController, void> {
  /// Defines guest name setup controller.
  GuestNameSetupControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guestNameSetupControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guestNameSetupControllerHash();

  @$internal
  @override
  GuestNameSetupController create() => GuestNameSetupController();
}

String _$guestNameSetupControllerHash() =>
    r'41f1caf6021718e10eac4a8f03806d70a1d76ddc';

/// Defines guest name setup controller.

abstract class _$GuestNameSetupController extends $AsyncNotifier<void> {
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
