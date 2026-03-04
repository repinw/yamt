// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest_auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GuestAuthController)
final guestAuthControllerProvider = GuestAuthControllerProvider._();

final class GuestAuthControllerProvider
    extends $AsyncNotifierProvider<GuestAuthController, void> {
  GuestAuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guestAuthControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guestAuthControllerHash();

  @$internal
  @override
  GuestAuthController create() => GuestAuthController();
}

String _$guestAuthControllerHash() =>
    r'1a5aa3b438bae62f8259bf629fcd334ef19490db';

abstract class _$GuestAuthController extends $AsyncNotifier<void> {
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
