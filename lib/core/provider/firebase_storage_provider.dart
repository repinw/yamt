import 'dart:developer' show log;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';

part 'firebase_storage_provider.g.dart';

const _providerLogName = 'FirebaseStorageProvider';

/// Returns a Firebase Storage instance for tests and production.
typedef FirebaseStorageInstanceGetter = FirebaseStorage Function();

/// Structured logger used by the Storage provider.
typedef FirebaseStorageLogWriter =
    void Function(
      String message, {
      String name,
      Object? error,
      StackTrace? stackTrace,
    });

FirebaseStorage _defaultFirebaseStorageInstanceGetter() {
  return FirebaseStorage.instance;
}

void _defaultFirebaseStorageLogWriter(
  String message, {
  String name = _providerLogName,
  Object? error,
  StackTrace? stackTrace,
}) {
  log(message, name: name, error: error, stackTrace: stackTrace);
}

/// Test seam for simulating Firebase Storage availability.
@visibleForTesting
FirebaseStorageInstanceGetter debugFirebaseStorageInstanceGetter =
    _defaultFirebaseStorageInstanceGetter;

/// Test seam for capturing provider logs in unit tests.
@visibleForTesting
FirebaseStorageLogWriter debugFirebaseStorageLogWriter =
    _defaultFirebaseStorageLogWriter;

/// Restores default Firebase Storage provider test seams.
@visibleForTesting
void resetFirebaseStorageProviderDebugHooks() {
  debugFirebaseStorageInstanceGetter = _defaultFirebaseStorageInstanceGetter;
  debugFirebaseStorageLogWriter = _defaultFirebaseStorageLogWriter;
}

/// Returns Storage instance unless session shutdown is in progress.
@riverpod
FirebaseStorage? firebaseStorage(Ref ref) {
  final isSessionShutdownInProgress = ref.watch(
    sessionShutdownControllerProvider,
  );
  if (isSessionShutdownInProgress) {
    return null;
  }

  try {
    return debugFirebaseStorageInstanceGetter();
  } on Object catch (error, stackTrace) {
    debugFirebaseStorageLogWriter(
      'Falling back to unavailable Firebase Storage instance.',
      name: _providerLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}
