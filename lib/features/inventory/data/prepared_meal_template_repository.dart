import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

import 'firestore_prepared_meal_template_repository.dart';
import 'inventory_user_session.dart';
import 'prepared_meal_template_repository_contract.dart';
import 'prepared_meal_template_store.dart';

export 'firestore_prepared_meal_template_repository.dart';
export 'prepared_meal_template_repository_contract.dart';
export 'prepared_meal_template_store.dart';

part 'prepared_meal_template_repository.g.dart';

@riverpod
PreparedMealTemplateRepository preparedMealTemplateRepository(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  final currentUserId = authState.asData?.value?.uid;
  final store = _resolveStore();
  return FirestorePreparedMealTemplateRepository(
    session: _CurrentPreparedMealTemplateUserSession(
      currentUserId: currentUserId,
    ),
    store: store,
  );
}

PreparedMealTemplateStore _resolveStore() {
  try {
    return FirestorePreparedMealTemplateStore(
      firestore: FirebaseFirestore.instance,
    );
  } catch (error, stackTrace) {
    log(
      'Falling back to unavailable prepared meal template store.',
      name: 'PreparedMealTemplateRepositoryProvider',
      error: error,
      stackTrace: stackTrace,
    );
    return const _UnavailablePreparedMealTemplateStore();
  }
}

class _CurrentPreparedMealTemplateUserSession implements InventoryUserSession {
  const _CurrentPreparedMealTemplateUserSession({
    required String? currentUserId,
  }) : _currentUserId = currentUserId;

  final String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;
}

class _UnavailablePreparedMealTemplateStore
    implements PreparedMealTemplateStore {
  const _UnavailablePreparedMealTemplateStore();

  @override
  Future<List<PreparedMealTemplateDocument>> readAll({
    required String userId,
  }) async {
    return const <PreparedMealTemplateDocument>[];
  }

  @override
  Stream<List<PreparedMealTemplateDocument>> watchAll({
    required String userId,
  }) {
    return Stream<List<PreparedMealTemplateDocument>>.value(
      const <PreparedMealTemplateDocument>[],
    );
  }

  @override
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    return false;
  }
}
