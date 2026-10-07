import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/household/application/household_key_session.dart';

import 'package:yamt/features/inventory/data/firestore_prepared_meal_repository.dart';
import 'package:yamt/features/inventory/data/inventory_user_session.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository_contract.dart';
import 'package:yamt/features/inventory/data/prepared_meal_store.dart';

export 'firestore_prepared_meal_repository.dart';
export 'prepared_meal_repository_contract.dart';
export 'prepared_meal_store.dart';

part 'prepared_meal_repository.g.dart';

/// Prepared meal repository.
@riverpod
PreparedMealRepository preparedMealRepository(Ref ref) {
  ref.watch(authStateChangesProvider);
  final householdCipher = ref.watch(householdCipherProvider);
  final householdId = householdCipher?.householdId;
  final store = _resolveStore(ref, householdCipher);
  return FirestorePreparedMealRepository(
    session: _CurrentPreparedMealUserSession(householdId: householdId),
    sessionShutdownSignal: ref.watch(sessionShutdownSignalProvider),
    store: store,
  );
}

PreparedMealStore _resolveStore(Ref ref, HouseholdCipher? householdCipher) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null || householdCipher == null) {
    log(
      'Falling back to unavailable prepared meal store.',
      name: 'PreparedMealRepositoryProvider',
    );
    return const _UnavailablePreparedMealStore();
  }
  return FirestorePreparedMealStore(
    firestore: firestore,
    cipher: householdCipher.cipher,
  );
}

class _CurrentPreparedMealUserSession implements InventoryUserSession {
  const new({required this._householdId});

  final String? _householdId;

  @override
  String? get householdId => _householdId;
}

class _UnavailablePreparedMealStore implements PreparedMealStore {
  const new();

  @override
  Future<List<PreparedMealDocument>> readAll({
    required String householdId,
  }) async {
    return const <PreparedMealDocument>[];
  }

  @override
  Stream<List<PreparedMealDocument>> watchAll({required String householdId}) {
    return const Stream<List<PreparedMealDocument>>.empty();
  }

  @override
  Future<bool> save({
    required String householdId,
    required String id,
    required Map<String, dynamic> data,
  }) async => false;

  @override
  Future<bool> delete({
    required String householdId,
    required String id,
  }) async => false;
}
