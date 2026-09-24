import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';

part 'burn_week_run_state_repository.g.dart';

const _logName = 'BurnWeekRunStateRepository';
const _usersCollection = 'users';
const _burnWeekRunStateField = 'burn_week_run_state';

/// Persistent store for Burn Week run state.
abstract interface class BurnWeekRunStateRepository {
  /// Reads saved Burn Week run state.
  Future<BurnWeekRunState> readState();

  /// Saves Burn Week run state.
  Future<bool> saveState(BurnWeekRunState state);
}

class _UnavailableBurnWeekRunStateRepository
    implements BurnWeekRunStateRepository {
  const new();

  @override
  Future<BurnWeekRunState> readState() async {
    return const BurnWeekRunState.initial();
  }

  @override
  Future<bool> saveState(BurnWeekRunState state) async {
    return false;
  }
}

/// Firestore-backed Burn Week state stored on the user profile document.
///
/// Household members can read the profile document, so the state is stored
/// as a payload encrypted with the data key of the user.
class FirestoreBurnWeekRunStateRepository
    implements BurnWeekRunStateRepository {
  /// Creates repository.
  const new({required this._firestore, required this._dataCipher});

  final FirebaseFirestore _firestore;
  final UserDataCipher? _dataCipher;

  @override
  Future<BurnWeekRunState> readState() async {
    final dataCipher = _dataCipher;
    if (dataCipher == null) {
      return const BurnWeekRunState.initial();
    }

    try {
      final field = _encryptedField(dataCipher.uid);
      final snapshot = await _firestore.doc(field.documentPath).get();
      final payload = snapshot.data()?[_burnWeekRunStateField];
      if (payload is! String) {
        return const BurnWeekRunState.initial();
      }
      return BurnWeekRunState.fromJson(
        await dataCipher.cipher.decryptJson(payload, aad: field.aad),
      );
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read Burn Week state for user ${dataCipher.uid}.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return const BurnWeekRunState.initial();
    }
  }

  @override
  Future<bool> saveState(BurnWeekRunState state) async {
    final dataCipher = _dataCipher;
    if (dataCipher == null) {
      return false;
    }

    try {
      final userId = dataCipher.uid;
      final field = _encryptedField(userId);
      await _firestore.doc(field.documentPath).set(<String, dynamic>{
        'uid': userId,
        _burnWeekRunStateField: await dataCipher.cipher.encryptJson(
          state.toJson(),
          aad: field.aad,
        ),
      }, SetOptions(merge: true));
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save Burn Week state for user ${dataCipher.uid}.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  EncryptedDocumentField _encryptedField(String userId) {
    return EncryptedDocumentField(
      '$_usersCollection/$userId',
      _burnWeekRunStateField,
    );
  }
}

/// Burn Week run state repository provider.
@Riverpod(keepAlive: true)
BurnWeekRunStateRepository burnWeekRunStateRepository(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    return const _UnavailableBurnWeekRunStateRepository();
  }
  return FirestoreBurnWeekRunStateRepository(
    firestore: firestore,
    dataCipher: ref.watch(userDataCipherProvider),
  );
}
