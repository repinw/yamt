// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_backup.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Key backup of the current platform.

@ProviderFor(keyBackup)
final keyBackupProvider = KeyBackupProvider._();

/// Key backup of the current platform.

final class KeyBackupProvider
    extends $FunctionalProvider<KeyBackup, KeyBackup, KeyBackup>
    with $Provider<KeyBackup> {
  /// Key backup of the current platform.
  KeyBackupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'keyBackupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$keyBackupHash();

  @$internal
  @override
  $ProviderElement<KeyBackup> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KeyBackup create(Ref ref) {
    return keyBackup(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KeyBackup value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KeyBackup>(value),
    );
  }
}

String _$keyBackupHash() => r'488df46153beb128b4530359e478862fb3d131b9';
