import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_firestore_provider.g.dart';

const _providerLogName = 'FirebaseFirestoreProvider';

@riverpod
FirebaseFirestore? firebaseFirestore(Ref ref) {
  try {
    return FirebaseFirestore.instance;
  } catch (error, stackTrace) {
    log(
      'Falling back to unavailable Firestore instance.',
      name: _providerLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}
