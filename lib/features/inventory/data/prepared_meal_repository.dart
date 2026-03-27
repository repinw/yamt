import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

import 'firestore_prepared_meal_repository.dart';
import 'inventory_user_session.dart';
import 'prepared_meal_repository_contract.dart';
import 'prepared_meal_store.dart';

export 'firestore_prepared_meal_repository.dart';
export 'prepared_meal_repository_contract.dart';
export 'prepared_meal_store.dart';

part 'prepared_meal_repository.g.dart';

@riverpod
PreparedMealRepository preparedMealRepository(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  final currentUserId = authState.asData?.value?.uid;
  final store = _resolveStore();
  return FirestorePreparedMealRepository(
    session: _CurrentPreparedMealUserSession(currentUserId: currentUserId),
    store: store,
  );
}

PreparedMealStore _resolveStore() {
  try {
    return FirestorePreparedMealStore(firestore: FirebaseFirestore.instance);
  } catch (error, stackTrace) {
    log(
      'Falling back to unavailable prepared meal store.',
      name: 'PreparedMealRepositoryProvider',
      error: error,
      stackTrace: stackTrace,
    );
    return const _UnavailablePreparedMealStore();
  }
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
