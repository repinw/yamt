// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines google auth controller.

@ProviderFor(GoogleAuthController)
final googleAuthControllerProvider = GoogleAuthControllerProvider._();

/// Defines google auth controller.
final class GoogleAuthControllerProvider
    extends $AsyncNotifierProvider<GoogleAuthController, void> {
  /// Defines google auth controller.
  GoogleAuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'googleAuthControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$googleAuthControllerHash();

  @$internal
  @override
  GoogleAuthController create() => GoogleAuthController();
}

String _$googleAuthControllerHash() =>
    r'9349a4a46214e471ee4021e733696a0ca97b2ca8';

/// Defines google auth controller.

abstract class _$GoogleAuthController extends $AsyncNotifier<void> {
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
