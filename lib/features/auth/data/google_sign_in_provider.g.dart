// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_sign_in_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Google sign-in client.

@ProviderFor(googleSignIn)
final googleSignInProvider = GoogleSignInProvider._();

/// Google sign-in client.

final class GoogleSignInProvider
    extends
        $FunctionalProvider<
          AsyncValue<GoogleSignIn>,
          GoogleSignIn,
          FutureOr<GoogleSignIn>
        >
    with $FutureModifier<GoogleSignIn>, $FutureProvider<GoogleSignIn> {
  /// Google sign-in client.
  GoogleSignInProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'googleSignInProvider',
        isAutoDispose: true,
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

String _$googleSignInHash() => r'a5688287353588b36651deca7a83b5a5fd2598ad';
