// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_profile_setup_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the signed-in user has a name, so the router skips the name setup.
///
/// The name lives on the account, so signing in to an existing account on a
/// new device counts as set up. The stored mark covers a linked guest whose
/// account has no name yet.

@ProviderFor(authProfileSetupCompleted)
final authProfileSetupCompletedProvider = AuthProfileSetupCompletedProvider._();

/// Whether the signed-in user has a name, so the router skips the name setup.
///
/// The name lives on the account, so signing in to an existing account on a
/// new device counts as set up. The stored mark covers a linked guest whose
/// account has no name yet.

final class AuthProfileSetupCompletedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the signed-in user has a name, so the router skips the name setup.
  ///
  /// The name lives on the account, so signing in to an existing account on a
  /// new device counts as set up. The stored mark covers a linked guest whose
  /// account has no name yet.
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
    r'bfc11e2dcb1a6812196e743760c433dc8f660043';
