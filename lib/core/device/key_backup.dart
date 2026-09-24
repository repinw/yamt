import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'key_backup.g.dart';

/// Backs up small secrets outside the app, so a new device of the same
/// platform account can restore them.
abstract interface class KeyBackup {
  /// Whether [saveToPasswordManager] can show the platform save dialog.
  bool get canSaveToPasswordManager;

  /// Saves [value] under [name].
  Future<void> save(String name, String value);

  /// Loads the value saved under [name].
  Future<String?> load(String name);

  /// Deletes the value saved under [name].
  Future<void> delete(String name);

  /// Lets the user pick a password saved for this app in the password
  /// manager. Returns `null` when the user cancels or nothing is saved.
  Future<String?> loadFromPasswordManager();

  /// Offers to save [password] for the account [id] in the password manager.
  ///
  /// Returns `false` when the user cancels.
  Future<bool> saveToPasswordManager({
    required String id,
    required String password,
  });
}

/// Android: Google Block Store and Credential Manager, through
/// `KeyBackupChannel.kt`.
class AndroidKeyBackup implements KeyBackup {
  /// Creates the backup.
  const new();

  static const _channel = MethodChannel('de.yamt.app/key_backup');

  @override
  bool get canSaveToPasswordManager => true;

  @override
  Future<void> save(String name, String value) {
    return _channel.invokeMethod<void>('save', <String, String>{
      'key': name,
      'value': value,
    });
  }

  @override
  Future<String?> load(String name) {
    return _channel.invokeMethod<String>('load', <String, String>{'key': name});
  }

  @override
  Future<void> delete(String name) {
    return _channel.invokeMethod<void>('delete', <String, String>{'key': name});
  }

  @override
  Future<String?> loadFromPasswordManager() {
    return _channel.invokeMethod<String>('loadFromPasswordManager');
  }

  @override
  Future<bool> saveToPasswordManager({
    required String id,
    required String password,
  }) async {
    final saved = await _channel.invokeMethod<bool>(
      'saveToPasswordManager',
      <String, String>{'id': id, 'password': password},
    );
    return saved ?? false;
  }
}

/// Platforms without a backup channel. iOS needs none: the secure storage
/// already syncs through the iCloud Keychain.
class UnavailableKeyBackup implements KeyBackup {
  /// Creates the backup.
  const new();

  @override
  bool get canSaveToPasswordManager => false;

  @override
  Future<void> save(String name, String value) async {}

  @override
  Future<String?> load(String name) async => null;

  @override
  Future<void> delete(String name) async {}

  @override
  Future<String?> loadFromPasswordManager() {
    throw UnsupportedError('No password manager on this platform.');
  }

  @override
  Future<bool> saveToPasswordManager({
    required String id,
    required String password,
  }) {
    throw UnsupportedError('No password manager on this platform.');
  }
}

/// Key backup of the current platform.
@Riverpod(keepAlive: true)
KeyBackup keyBackup(Ref ref) {
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? const AndroidKeyBackup()
      : const UnavailableKeyBackup();
}
