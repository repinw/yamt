import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';

part 'app_client_repository.g.dart';

const _installIdKey = 'app_install_id_v1';
const _recordedKeyPrefix = 'app_client_recorded_v1';
const _recordAgainAfter = Duration(days: 1);

/// Records which app version runs on each device of a user, in
/// `users/{uid}/clients/{installId}`, so a release can count the devices that
/// still run an old version before it removes a migration.
///
/// Version and platform are no health data, so the document is plaintext and
/// an admin query can count it.
class AppClientRepository {
  /// Creates the repository on [_firestore] and the device [_preferences].
  const new(this._firestore, this._preferences);

  final FirebaseFirestore? _firestore;
  final AppPreferences _preferences;

  /// Saves [appVersion] of this device for [uid] at [now]. Skips the write
  /// when this device already saved the same version for [uid] less than a
  /// day ago. Throws when Firestore is gone or the write fails.
  Future<void> saveClientVersion({
    required String uid,
    required String appVersion,
    required DateTime now,
  }) async {
    final firestore =
        _firestore ?? (throw StateError('Firestore is shutting down.'));
    final recordedKey = '$_recordedKeyPrefix:$uid';
    final recorded = await _preferences.getString(recordedKey);
    if (recorded != null && !_isDue(recorded, appVersion, now)) {
      return;
    }
    final installId = await _installId();
    await firestore.doc('users/$uid/clients/$installId').set({
      'app_version': appVersion,
      'platform': Platform.operatingSystem,
      'last_seen_at': Timestamp.fromDate(now),
    });
    await _preferences.setString(
      recordedKey,
      '$appVersion|${now.toUtc().toIso8601String()}',
    );
  }

  bool _isDue(String recorded, String appVersion, DateTime now) {
    final separator = recorded.indexOf('|');
    if (separator < 0) {
      return true;
    }
    final version = recorded.substring(0, separator);
    final at = DateTime.tryParse(recorded.substring(separator + 1));
    return version != appVersion ||
        at == null ||
        now.difference(at) >= _recordAgainAfter;
  }

  Future<String> _installId() async {
    final stored = await _preferences.getString(_installIdKey);
    if (stored != null) {
      return stored;
    }
    final created = const Uuid().v4();
    if (!await _preferences.setString(_installIdKey, created)) {
      throw StateError('The install id was not saved.');
    }
    return created;
  }
}

/// The client repository.
@riverpod
AppClientRepository appClientRepository(Ref ref) => AppClientRepository(
  ref.watch(firebaseFirestoreProvider),
  ref.watch(appPreferencesProvider),
);
