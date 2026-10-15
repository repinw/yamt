import 'package:uuid/uuid.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

const _installIdKey = 'app_install_id_v1';

/// Reads the id of this app installation from [preferences], and makes and
/// saves one on first use. Throws when the new id cannot be saved.
Future<String> readInstallId(AppPreferences preferences) =>
    // One read at a time, so two first callers do not make two ids.
    _pending[preferences] ??= _readOrCreate(preferences)
        .whenComplete(() => _pending[preferences] = null);

final _pending = Expando<Future<String>>();

Future<String> _readOrCreate(AppPreferences preferences) async {
  final stored = await preferences.getString(_installIdKey);
  if (stored != null) {
    return stored;
  }
  final created = const Uuid().v4();
  if (!await preferences.setString(_installIdKey, created)) {
    throw StateError('The install id was not saved.');
  }
  return created;
}
