import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

part 'calorie_settings_repository.g.dart';

const _repositoryLogName = 'FirestoreCalorieSettingsRepository';
const _usersCollection = 'users';
const _calorieSettingsCollection = 'calorie_settings';
const _defaultSettingsDocumentId = 'default';

abstract interface class CalorieSettingsRepository {
  Stream<CalorieGoalSettings> watchSettings();

  Future<CalorieGoalSettings> readSettings();

  Future<bool> saveSettings(CalorieGoalSettings settings);

  Future<bool> setDailyGoal(double dailyKcalGoal);

  Future<bool> clearDailyGoal();
}

abstract interface class CalorieSettingsUserSession {
  String? get currentUserId;
}

class FirestoreCalorieSettingsRepository implements CalorieSettingsRepository {
  FirestoreCalorieSettingsRepository({
    required CalorieSettingsUserSession session,
    required FirebaseFirestore firestore,
  }) : _session = session,
       _firestore = firestore;

  final CalorieSettingsUserSession _session;
  final FirebaseFirestore _firestore;

  @override
  Stream<CalorieGoalSettings> watchSettings() {
    final userId = _currentUserId();
    if (userId == null) {
      return Stream<CalorieGoalSettings>.value(
        const CalorieGoalSettings.empty(),
      );
    }

    return Stream<CalorieGoalSettings>.multi((controller) {
      final subscription = _document(userId).snapshots().listen(
        (snapshot) {
          controller.add(_decodeSnapshot(snapshot));
        },
        onError: (Object error, StackTrace stackTrace) {
          log(
            'Failed to watch calorie settings for user $userId',
            name: _repositoryLogName,
            error: error,
            stackTrace: stackTrace,
          );
          controller.add(const CalorieGoalSettings.empty());
        },
        onDone: controller.close,
      );
      controller.onCancel = () {
        subscription.cancel();
      };
    });
  }

  @override
  Future<CalorieGoalSettings> readSettings() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const CalorieGoalSettings.empty();
    }

    try {
      final snapshot = await _document(userId).get();
      return _decodeSnapshot(snapshot);
    } catch (error, stackTrace) {
      log(
        'Failed to read calorie settings for user $userId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const CalorieGoalSettings.empty();
    }
  }

  @override
  Future<bool> saveSettings(CalorieGoalSettings settings) async {
    final userId = _currentUserId();
    if (userId == null) {
      return false;
    }

    try {
      final normalizedSettings = settings.copyWith(updatedAt: DateTime.now());
      await _document(userId).set(normalizedSettings.toJson());
      return true;
    } catch (error, stackTrace) {
      log(
        'Failed to save calorie settings for user $userId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> setDailyGoal(double dailyKcalGoal) async {
    if (dailyKcalGoal <= 0) {
      return false;
    }
    return saveSettings(
      CalorieGoalSettings(
        dailyKcalGoal: dailyKcalGoal,
        calculatorProfile: null,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<bool> clearDailyGoal() {
    return saveSettings(const CalorieGoalSettings.empty());
  }

  String? _currentUserId() {
    final userId = _session.currentUserId;
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }
    return null;
  }

  DocumentReference<Map<String, dynamic>> _document(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_calorieSettingsCollection)
        .doc(_defaultSettingsDocumentId);
  }

  CalorieGoalSettings _decodeSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists) {
      return const CalorieGoalSettings.empty();
    }

    final rawData = snapshot.data() ?? const <String, dynamic>{};
    final normalizedData = _normalizeFirestoreJson(rawData);
    try {
      return CalorieGoalSettings.fromJson(normalizedData);
    } catch (error, stackTrace) {
      log(
        'Malformed calorie settings document ${snapshot.id}',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const CalorieGoalSettings.empty();
    }
  }

  Map<String, dynamic> _normalizeFirestoreJson(Map<String, dynamic> rawData) {
    return rawData.map(
      (key, value) =>
          MapEntry<String, dynamic>(key, _normalizeFirestoreValue(value)),
    );
  }

  dynamic _normalizeFirestoreValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return value;
  }
}

@riverpod
CalorieSettingsRepository calorieSettingsRepository(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  final currentUserId = authState.asData?.value?.uid;
  final firestore = _resolveFirestore();
  if (firestore == null) {
    return const _UnavailableCalorieSettingsRepository();
  }
  return FirestoreCalorieSettingsRepository(
    session: _CurrentCalorieSettingsUserSession(currentUserId: currentUserId),
    firestore: firestore,
  );
}

class _CurrentCalorieSettingsUserSession implements CalorieSettingsUserSession {
  const _CurrentCalorieSettingsUserSession({required String? currentUserId})
    : _currentUserId = currentUserId;

  final String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;
}

FirebaseFirestore? _resolveFirestore() {
  try {
    return FirebaseFirestore.instance;
  } catch (error, stackTrace) {
    log(
      'Falling back to unavailable calorie settings repository.',
      name: _repositoryLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

class _UnavailableCalorieSettingsRepository
    implements CalorieSettingsRepository {
  const _UnavailableCalorieSettingsRepository();

  @override
  Stream<CalorieGoalSettings> watchSettings() {
    return Stream<CalorieGoalSettings>.value(const CalorieGoalSettings.empty());
  }

  @override
  Future<CalorieGoalSettings> readSettings() async {
    return const CalorieGoalSettings.empty();
  }

  @override
  Future<bool> saveSettings(CalorieGoalSettings settings) async {
    return false;
  }

  @override
  Future<bool> setDailyGoal(double dailyKcalGoal) async {
    return false;
  }

  @override
  Future<bool> clearDailyGoal() async {
    return false;
  }
}
