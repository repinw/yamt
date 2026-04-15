import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';

part 'firebase_firestore_provider.g.dart';

const _providerLogName = 'FirebaseFirestoreProvider';

/// Returns a Firestore instance for tests and production.
typedef FirebaseFirestoreInstanceGetter = FirebaseFirestore Function();

/// Structured logger used by the Firestore provider.
typedef FirebaseFirestoreLogWriter =
    void Function(
      String message, {
      String name,
      Object? error,
      StackTrace? stackTrace,
    });

FirebaseFirestore _defaultFirebaseFirestoreInstanceGetter() {
  return FirebaseFirestore.instance;
}

void _defaultFirebaseFirestoreLogWriter(
  String message, {
  String name = _providerLogName,
  Object? error,
  StackTrace? stackTrace,
}) {
  log(message, name: name, error: error, stackTrace: stackTrace);
}

/// Test seam for simulating Firestore availability in provider tests.
@visibleForTesting
FirebaseFirestoreInstanceGetter debugFirebaseFirestoreInstanceGetter =
    _defaultFirebaseFirestoreInstanceGetter;

/// Test seam for capturing provider logs in unit tests.
@visibleForTesting
FirebaseFirestoreLogWriter debugFirebaseFirestoreLogWriter =
    _defaultFirebaseFirestoreLogWriter;

/// Restores the default Firestore provider test seams.
@visibleForTesting
void resetFirebaseFirestoreProviderDebugHooks() {
  debugFirebaseFirestoreInstanceGetter =
      _defaultFirebaseFirestoreInstanceGetter;
  debugFirebaseFirestoreLogWriter = _defaultFirebaseFirestoreLogWriter;
}

/// Returns Firestore instance unless session shutdown is already in progress.
@riverpod
FirebaseFirestore? firebaseFirestore(Ref ref) {
  final isSessionShutdownInProgress = ref.watch(
    sessionShutdownControllerProvider,
  );
  if (isSessionShutdownInProgress) {
    return null;
  }

  try {
    return debugFirebaseFirestoreInstanceGetter();
  } on Object catch (error, stackTrace) {
    debugFirebaseFirestoreLogWriter(
      'Falling back to unavailable Firestore instance.',
      name: _providerLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}
