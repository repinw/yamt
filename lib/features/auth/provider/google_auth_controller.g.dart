// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(googleSignIn)
final googleSignInProvider = GoogleSignInProvider._();

final class GoogleSignInProvider
    extends
        $FunctionalProvider<
          AsyncValue<GoogleSignIn>,
          GoogleSignIn,
          FutureOr<GoogleSignIn>
        >
    with $FutureModifier<GoogleSignIn>, $FutureProvider<GoogleSignIn> {
  GoogleSignInProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'googleSignInProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$googleSignInHash();

  @$internal
  @override
  $FutureProviderElement<GoogleSignIn> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GoogleSignIn> create(Ref ref) {
    return googleSignIn(ref);
  }
}

String _$googleSignInHash() => r'89e250ff7810efbf0683555296eb50695555bceb';

@ProviderFor(GoogleAuthController)
final googleAuthControllerProvider = GoogleAuthControllerProvider._();

final class GoogleAuthControllerProvider
    extends $AsyncNotifierProvider<GoogleAuthController, void> {
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
    r'88863efe044143bd8d41ac7562858ec68ee5a92b';

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
