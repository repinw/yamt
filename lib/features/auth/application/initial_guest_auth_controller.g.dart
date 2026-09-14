// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'initial_guest_auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages automatic anonymous guest sign-in on initial app launch.

@ProviderFor(InitialGuestAuthController)
final initialGuestAuthControllerProvider =
    InitialGuestAuthControllerProvider._();

/// Manages automatic anonymous guest sign-in on initial app launch.
final class InitialGuestAuthControllerProvider
    extends $AsyncNotifierProvider<InitialGuestAuthController, void> {
  /// Manages automatic anonymous guest sign-in on initial app launch.
  InitialGuestAuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialGuestAuthControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initialGuestAuthControllerHash();

  @$internal
  @override
  InitialGuestAuthController create() => InitialGuestAuthController();
}

String _$initialGuestAuthControllerHash() =>
    r'b79fc967f63a9b8ecb513141fe5384da2cb13334';

/// Manages automatic anonymous guest sign-in on initial app launch.

abstract class _$InitialGuestAuthController extends $AsyncNotifier<void> {
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
