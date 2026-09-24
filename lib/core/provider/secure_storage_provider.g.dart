// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secure_storage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Secure storage for secrets that must stay on the device.
///
/// iOS keeps the values in the iCloud Keychain (`synchronizable`), so a new
/// iPhone of the same Apple account finds them again.

@ProviderFor(secureStorage)
final secureStorageProvider = SecureStorageProvider._();

/// Secure storage for secrets that must stay on the device.
///
/// iOS keeps the values in the iCloud Keychain (`synchronizable`), so a new
/// iPhone of the same Apple account finds them again.

final class SecureStorageProvider
    extends
        $FunctionalProvider<
          FlutterSecureStorage,
          FlutterSecureStorage,
          FlutterSecureStorage
        >
    with $Provider<FlutterSecureStorage> {
  /// Secure storage for secrets that must stay on the device.
  ///
  /// iOS keeps the values in the iCloud Keychain (`synchronizable`), so a new
  /// iPhone of the same Apple account finds them again.
  SecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secureStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secureStorageHash();

  @$internal
  @override
  $ProviderElement<FlutterSecureStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterSecureStorage create(Ref ref) {
    return secureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterSecureStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterSecureStorage>(value),
    );
  }
}

String _$secureStorageHash() => r'448b41f50f1fbdb7abb368a8a4eb68f3521e595e';
