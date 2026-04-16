// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest_name_setup_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
    r'92cf06929ee8cf7447f53b43ee3379d994deeb86';

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
