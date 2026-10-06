import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/app_update_status.dart';
import 'package:yamt/core/domain/app_version.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';

part 'app_version_config_repository.g.dart';

/// Reads `config/app_version`, which the release sets and every client may
/// read, also while signed out.
class AppVersionConfigRepository {
  /// Creates the repository on [_firestore], or on nothing while the session
  /// shuts down.
  const new(this._firestore);

  final FirebaseFirestore? _firestore;

  /// The config, or null while it is not set. Offline, the last config the
  /// device saw applies. A config that does not parse is an error event; the
  /// stream goes on, so a fixed config applies again.
  Stream<AppVersionConfig?> watchConfig() {
    final firestore = _firestore;
    if (firestore == null) {
      // The session shuts down; the last status stays until Firestore is
      // back, so a blocked app is not let in.
      return const Stream.empty();
    }
    return firestore.doc('config/app_version').snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : AppVersionConfig.fromJson(data);
    });
  }
}

/// The version config repository.
@Riverpod(keepAlive: true)
AppVersionConfigRepository appVersionConfigRepository(Ref ref) =>
    AppVersionConfigRepository(ref.watch(firebaseFirestoreProvider));

/// Whether this app may open and whether a newer version exists.
///
/// A failed check counts as up to date, like a missing config: a lost
/// connection or a broken config must not lock anyone out. After an error
/// event the status follows the next config again.
@Riverpod(keepAlive: true)
Stream<AppUpdateStatus> appUpdateStatus(Ref ref) async* {
  final AppVersion current;
  try {
    current = AppVersion.parse(await ref.watch(appVersionProvider.future));
  } on FormatException catch (error, stackTrace) {
    _logCheckFailure(error, stackTrace);
    yield const AppUpToDate();
    return;
  }
  yield* ref
      .watch(appVersionConfigRepositoryProvider)
      .watchConfig()
      .transform(
        StreamTransformer.fromHandlers(
          handleData: (config, sink) =>
              sink.add(AppUpdateStatus.of(current, config)),
          handleError: (error, stackTrace, sink) {
            _logCheckFailure(error, stackTrace);
            sink.add(const AppUpToDate());
          },
        ),
      );
}

void _logCheckFailure(Object error, StackTrace stackTrace) => log(
  'The app version check failed; the app opens.',
  name: 'AppUpdate',
  error: error,
  stackTrace: stackTrace,
);
