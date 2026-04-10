import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:yamt/core/config/firebase_app_check_config.dart';
import 'package:yamt/firebase_options.dart';

const _firebaseConfigLogName = 'FirebaseConfig';
const _useAuthEmulator = bool.fromEnvironment(
  'USE_AUTH_EMULATOR',
  defaultValue: false,
);
const _useFirestoreEmulator = bool.fromEnvironment(
  'USE_FIRESTORE_EMULATOR',
  defaultValue: false,
);
const _emulatorHostFromDefine = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: '',
);
const _authEmulatorPort = int.fromEnvironment(
  'AUTH_EMULATOR_PORT',
  defaultValue: 9099,
);
const _firestoreEmulatorPort = int.fromEnvironment(
  'FIRESTORE_EMULATOR_PORT',
  defaultValue: 8080,
);

// coverage:ignore-file
Future<void> setupFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupFirebaseAppCheck();
  await _configureFirebaseEmulators();
}

Future<void> _configureFirebaseEmulators() async {
  final host = _resolveEmulatorHost();
  if (_useAuthEmulator) {
    try {
      await FirebaseAuth.instance.useAuthEmulator(host, _authEmulatorPort);
      _trace('Auth emulator enabled at $host:$_authEmulatorPort.');
    } catch (error, stackTrace) {
      _trace(
        'Auth emulator setup failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  if (_useFirestoreEmulator) {
    try {
      FirebaseFirestore.instance.useFirestoreEmulator(
        host,
        _firestoreEmulatorPort,
      );
      _trace('Firestore emulator enabled at $host:$_firestoreEmulatorPort.');
    } catch (error, stackTrace) {
      _trace(
        'Firestore emulator setup failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

String _resolveEmulatorHost() {
  final hostFromDefine = _emulatorHostFromDefine.trim();
  if (hostFromDefine.isNotEmpty) {
    return hostFromDefine;
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2';
  }
  return '127.0.0.1';
}

void _trace(String message, {Object? error, StackTrace? stackTrace}) {
  log(
    message,
    name: _firebaseConfigLogName,
    error: error,
    stackTrace: stackTrace,
  );
  debugPrint('[$_firebaseConfigLogName] $message');
  if (error != null) {
    debugPrint('[$_firebaseConfigLogName] error=$error');
  }
}
