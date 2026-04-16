import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';

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
  final currentUserId = ref.watch(effectiveHouseholdDataOwnerUserIdProvider);
  final store = _resolveStore(ref);
  return FirestorePreparedMealRepository(
    session: _CurrentPreparedMealUserSession(currentUserId: currentUserId),
    sessionShutdownSignal: ref.watch(sessionShutdownSignalProvider),
    store: store,
  );
}

PreparedMealStore _resolveStore(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    log(
      'Falling back to unavailable prepared meal store.',
      name: 'PreparedMealRepositoryProvider',
    );
    return const _UnavailablePreparedMealStore();
  }
  return FirestorePreparedMealStore(firestore: firestore);
}

class _CurrentPreparedMealUserSession implements InventoryUserSession {
  const _CurrentPreparedMealUserSession({required String? currentUserId})
    : _currentUserId = currentUserId;

  final String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;
}

class _UnavailablePreparedMealStore implements PreparedMealStore {
  const _UnavailablePreparedMealStore();

  @override
  Future<List<PreparedMealDocument>> readAll({required String userId}) async {
    return const <PreparedMealDocument>[];
  }

  @override
  Stream<List<PreparedMealDocument>> watchAll({required String userId}) {
    return const Stream<List<PreparedMealDocument>>.empty();
  }

  @override
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    return false;
  }
}
