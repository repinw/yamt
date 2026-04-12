import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';

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
  ref.watch(authStateChangesProvider);
  final currentUserId = ref.watch(effectiveHouseholdDataOwnerUserIdProvider);
  final store = _resolveStore(ref);
  return FirestorePreparedMealTemplateRepository(
    session: _CurrentPreparedMealTemplateUserSession(
      currentUserId: currentUserId,
    ),
    sessionShutdownSignal: ref.watch(sessionShutdownSignalProvider),
    store: store,
  );
}

PreparedMealTemplateStore _resolveStore(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    log(
      'Falling back to unavailable prepared meal template store.',
      name: 'PreparedMealTemplateRepositoryProvider',
    );
    return const _UnavailablePreparedMealTemplateStore();
  }
  return FirestorePreparedMealTemplateStore(firestore: firestore);
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
