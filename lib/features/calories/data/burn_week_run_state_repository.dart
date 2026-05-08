import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';

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
  const _UnavailableBurnWeekRunStateRepository();

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
class FirestoreBurnWeekRunStateRepository
    implements BurnWeekRunStateRepository {
  /// Creates repository.
  const FirestoreBurnWeekRunStateRepository({
    required FirebaseFirestore firestore,
    required String? currentUserId,
  }) : _firestore = firestore,
       _currentUserId = currentUserId;

  final FirebaseFirestore _firestore;
  final String? _currentUserId;

  @override
  Future<BurnWeekRunState> readState() async {
    final userId = _normalizedUserId();
    if (userId == null) {
      return const BurnWeekRunState.initial();
    }

    try {
      final snapshot = await _document(userId).get();
      final rawState = snapshot.data()?[_burnWeekRunStateField];
      if (rawState is! Map) {
        return const BurnWeekRunState.initial();
      }
      final normalizedState = normalizeFirestoreValue(rawState);
      if (normalizedState is! Map<String, dynamic>) {
        return const BurnWeekRunState.initial();
      }
      return BurnWeekRunState.fromJson(normalizedState);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read Burn Week state for user $userId.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return const BurnWeekRunState.initial();
    }
  }

  @override
  Future<bool> saveState(BurnWeekRunState state) async {
    final userId = _normalizedUserId();
    if (userId == null) {
      return false;
    }

    try {
      await _document(userId).set(
        <String, dynamic>{
          'uid': userId,
          _burnWeekRunStateField: state.toJson(),
        },
        SetOptions(merge: true),
      );
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save Burn Week state for user $userId.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  String? _normalizedUserId() {
    final userId = _currentUserId?.trim();
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return userId;
  }

  DocumentReference<Map<String, dynamic>> _document(String userId) {
    return _firestore.collection(_usersCollection).doc(userId);
  }
}

/// Burn Week run state repository provider.
final burnWeekRunStateRepositoryProvider = Provider<BurnWeekRunStateRepository>(
  (ref) {
    final authState = ref.watch(authStateChangesProvider);
    final currentUserId =
        authState.asData?.value?.uid ??
        ref.watch(firebaseAuthProvider).currentUser?.uid;
    final firestore = ref.watch(firebaseFirestoreProvider);
    if (firestore == null) {
      return const _UnavailableBurnWeekRunStateRepository();
    }
    return FirestoreBurnWeekRunStateRepository(
      firestore: firestore,
      currentUserId: currentUserId,
    );
  },
);
