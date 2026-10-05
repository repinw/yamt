import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/data/calorie_entry_document_codec.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'planned_entry_repository.g.dart';

const _logName = 'PlannedEntryRepository';
const _usersCollection = 'users';
const _plannedEntriesCollection = 'planned_entries';

/// Stores the food a user plans to eat, apart from the calorie entries, so no
/// sum ever counts a plan.
///
/// A plan has the shape of a calorie entry, and its `loggedAt` is the planned
/// day and time. Plans are encrypted with the data key of the user; only
/// `logged_at` stays readable, for the range queries.
class PlannedEntryRepository {
  /// Creates the repository for the signed-in user of [dataCipher].
  const new({required this.dataCipher, required this.firestore});

  /// The signed-in user and the cipher for their data, or `null` while the
  /// data key is not ready.
  final UserDataCipher? dataCipher;

  /// The Firestore instance, or `null` during sign-out.
  final FirebaseFirestore? firestore;

  /// The plans of [day] in time order, or none while signed out.
  Future<List<CalorieEntry>> loadPlannedEntriesForDay(DateTime day) async {
    final dataCipher = this.dataCipher;
    final firestore = this.firestore;
    if (dataCipher == null || firestore == null) {
      return const <CalorieEntry>[];
    }
    final bounds = diaryDayBounds(day);
    final snapshot = await _collection(firestore, dataCipher.uid)
        .where(
          calorieEntryLoggedAtField,
          isGreaterThanOrEqualTo: bounds.startInclusive,
        )
        .where(calorieEntryLoggedAtField, isLessThan: bounds.endExclusive)
        .orderBy(calorieEntryLoggedAtField)
        .get();
    return await decodeCalorieEntrySnapshot(
      snapshot,
      cipher: dataCipher.cipher,
    );
  }

  /// Saves [entry] as a plan. Throws while signed out.
  ///
  /// Firestore applies the write to its local cache at once and queues it for
  /// the server, so this does not wait for the server.
  Future<void> savePlannedEntry(CalorieEntry entry) async {
    final (firestore, dataCipher) = _requireSignedIn();
    final plan = prepareCalorieEntryForSave(
      entry,
      userId: dataCipher.uid,
      updatedAt: DateTime.now(),
    );
    final reference = _collection(firestore, dataCipher.uid).doc(plan.id);
    final document = await encodeCalorieEntryDocument(
      plan,
      reference: reference,
      cipher: dataCipher.cipher,
    );
    unawaited(
      reference.set(document).catchError((Object error, StackTrace stack) {
        log(
          'The server rejected plan ${plan.id}.',
          name: _logName,
          error: error,
          stackTrace: stack,
        );
      }),
    );
  }

  /// Deletes the plan [entryId]. Throws while signed out.
  ///
  /// Like [savePlannedEntry], this does not wait for the server.
  Future<void> deletePlannedEntry(String entryId) async {
    final (firestore, dataCipher) = _requireSignedIn();
    unawaited(
      _collection(firestore, dataCipher.uid).doc(entryId).delete().catchError((
        Object error,
        StackTrace stack,
      ) {
        log(
          'The server rejected deleting plan $entryId.',
          name: _logName,
          error: error,
          stackTrace: stack,
        );
      }),
    );
  }

  (FirebaseFirestore, UserDataCipher) _requireSignedIn() {
    final dataCipher = this.dataCipher;
    final firestore = this.firestore;
    if (dataCipher == null || firestore == null) {
      throw StateError('No signed-in user with a data key for plans.');
    }
    return (firestore, dataCipher);
  }

  static CollectionReference<Map<String, dynamic>> _collection(
    FirebaseFirestore firestore,
    String userId,
  ) => firestore
      .collection(_usersCollection)
      .doc(userId)
      .collection(_plannedEntriesCollection);
}

/// Planned entry repository of the signed-in user.
@riverpod
PlannedEntryRepository plannedEntryRepository(Ref ref) =>
    PlannedEntryRepository(
      dataCipher: ref.watch(userDataCipherProvider),
      firestore: ref.watch(firebaseFirestoreProvider),
    );
