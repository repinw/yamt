import 'package:yamt/core/device/key_backup.dart';

/// In-memory platform key backup for tests.
class FakeKeyBackup implements KeyBackup {
  /// Creates the backup with optional stored [values].
  new({Map<String, String>? values, this.passwordManagerSaves = true})
    : values = values ?? <String, String>{};

  /// The stored values by name.
  final Map<String, String> values;

  /// What [saveToPasswordManager] returns: `true` for saved, `false` for
  /// canceled.
  final bool passwordManagerSaves;

  /// The passwords that [saveToPasswordManager] received, by account id.
  final savedPasswords = <String, String>{};

  @override
  bool get canSaveToPasswordManager => true;

  @override
  Future<void> save(String name, String value) async {
    values[name] = value;
  }

  @override
  Future<String?> load(String name) async => values[name];

  @override
  Future<void> delete(String name) async {
    values.remove(name);
  }

  @override
  Future<bool> saveToPasswordManager({
    required String id,
    required String password,
  }) async {
    if (passwordManagerSaves) {
      savedPasswords[id] = password;
    }
    return passwordManagerSaves;
  }
}
