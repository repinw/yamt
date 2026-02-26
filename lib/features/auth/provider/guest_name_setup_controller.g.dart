// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest_name_setup_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GuestNameSetupController)
final guestNameSetupControllerProvider = GuestNameSetupControllerProvider._();

final class GuestNameSetupControllerProvider
    extends $AsyncNotifierProvider<GuestNameSetupController, void> {
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
    r'029f5d1b7f4099ff5495209454d4e86913617d5b';

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
