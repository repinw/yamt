// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_profile_setup_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authProfileSetupCompleted)
final authProfileSetupCompletedProvider = AuthProfileSetupCompletedProvider._();

final class AuthProfileSetupCompletedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  AuthProfileSetupCompletedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProfileSetupCompletedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authProfileSetupCompletedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return authProfileSetupCompleted(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$authProfileSetupCompletedHash() =>
    r'4cfd2e7d68052015c1168037a63df4060ee36798';
