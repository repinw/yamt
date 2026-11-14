import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/sealed_document.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/ai_chef/domain/ai_chef_exclusions.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';

part 'ai_chef_exclusions_repository.g.dart';

const _logName = 'AiChefExclusionsRepository';
const _usersCollection = 'users';
const _settingsCollection = 'ai_chef_settings';
const _exclusionsDocumentId = 'exclusions';

/// AI Chef exclusions repository provider.
@riverpod
AiChefExclusionsRepository aiChefExclusionsRepository(Ref ref) {
  return AiChefExclusionsRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    dataCipher: ref.watch(userDataCipherProvider),
  );
}

/// Stores the ingredients a user never wants in an AI recipe.
///
/// The list belongs to the user, not to the household, and lives encrypted
/// with the data key of the user in
/// `users/{uid}/ai_chef_settings/exclusions`, so it follows the user to every
/// device.
class AiChefExclusionsRepository {
  /// Creates the repository.
  const new({required this._firestore, required this._dataCipher});

  final FirebaseFirestore? _firestore;
  final UserDataCipher? _dataCipher;

  /// Watches the list.
  ///
  /// Emits nothing while there is no data key (signed out, or the key is
  /// still loading): an empty list would let a request go out without the
  /// stored exclusions.
  Stream<AiChefExclusions> watchExclusions() {
    final firestore = _firestore;
    final dataCipher = _dataCipher;
    if (firestore == null || dataCipher == null) {
      return const Stream<AiChefExclusions>.empty();
    }
    // A missing document read from the cache only says the device has not
    // seen the list yet; only the server can say there is none. The server's
    // word on a document the cache already knows as missing changes only the
    // metadata, so metadata changes must come through.
    return _document(firestore, dataCipher.uid)
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => snapshot.exists || !snapshot.metadata.isFromCache)
        .asyncMap((snapshot) => _decode(dataCipher, snapshot))
        .distinct();
  }

  /// Saves [exclusions] as the whole list.
  ///
  /// Firestore applies the write to its local cache at once and sends it
  /// when a connection is available, so this does not wait for the server.
  /// A later rejection by the server is logged.
  Future<void> saveExclusions(AiChefExclusions exclusions) async {
    final firestore = _firestore;
    final dataCipher = _dataCipher;
    if (firestore == null || dataCipher == null) {
      throw StateError('Cannot save AI Chef exclusions while signed out.');
    }
    final reference = _document(firestore, dataCipher.uid);
    final sealed = await sealDocument(
      exclusions.toJson(),
      path: reference.path,
      cipher: dataCipher.cipher,
    );
    unawaited(
      reference.set(sealed).catchError((Object error, StackTrace stackTrace) {
        log(
          'The server rejected the AI Chef exclusions.',
          name: _logName,
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
  }

  DocumentReference<Map<String, dynamic>> _document(
    FirebaseFirestore firestore,
    String userId,
  ) {
    return firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_settingsCollection)
        .doc(_exclusionsDocumentId);
  }

  Future<AiChefExclusions> _decode(
    UserDataCipher dataCipher,
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final raw = snapshot.data();
    if (raw == null) {
      return AiChefExclusions.empty;
    }
    return AiChefExclusions.fromJson(
      await openDocument(
        raw,
        path: snapshot.reference.path,
        cipher: dataCipher.cipher,
      ),
    );
  }
}
