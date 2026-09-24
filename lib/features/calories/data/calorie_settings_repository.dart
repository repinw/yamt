import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';

part 'calorie_settings_repository.g.dart';

const _repositoryLogName = 'FirestoreCalorieSettingsRepository';
const _usersCollection = 'users';
const _calorieSettingsCollection = 'calorie_settings';
const _defaultSettingsDocumentId = 'default';

/// Defines calorie settings repository.
abstract interface class CalorieSettingsRepository {
  /// Watch settings.
  Stream<CalorieGoalSettings> watchSettings();

  /// Read settings.
  Future<CalorieGoalSettings> readSettings();

  /// Save settings.
  Future<bool> saveSettings(CalorieGoalSettings settings);

  /// Set daily goal.
  Future<bool> setDailyGoal(double dailyKcalGoal);

  /// Clear daily goal.
  Future<bool> clearDailyGoal();
}

/// Defines firestore calorie settings repository.
///
/// The settings hold body data, so the document is stored encrypted with the
/// data key of the user.
class FirestoreCalorieSettingsRepository implements CalorieSettingsRepository {
  /// Creates an instance.
  new({required this._dataCipher, required this._firestore});

  final UserDataCipher? _dataCipher;
  final FirebaseFirestore _firestore;

  @override
  Stream<CalorieGoalSettings> watchSettings() {
    final userId = _dataCipher?.uid;
    if (userId == null) {
      return Stream<CalorieGoalSettings>.value(
        const CalorieGoalSettings.empty(),
      );
    }

    return Stream<CalorieGoalSettings>.multi((controller) {
      final subscription = _document(userId)
          .snapshots()
          .asyncMap(_decodeSnapshot)
          .listen(
            controller.add,
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
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<CalorieGoalSettings> readSettings() async {
    final userId = _dataCipher?.uid;
    if (userId == null) {
      return const CalorieGoalSettings.empty();
    }

    try {
      final snapshot = await _document(userId).get();
      return await _decodeSnapshot(snapshot);
    } on Object catch (error, stackTrace) {
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
    final dataCipher = _dataCipher;
    if (dataCipher == null) {
      return false;
    }

    try {
      final normalizedSettings = settings.copyWith(updatedAt: DateTime.now());
      final reference = _document(dataCipher.uid);
      await reference.set(<String, dynamic>{
        encryptedPayloadField: await dataCipher.cipher.encryptJson(
          normalizedSettings.toJson(),
          aad: reference.path,
        ),
      });
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save calorie settings for user ${dataCipher.uid}',
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
    return await saveSettings(
      CalorieGoalSettings.single(
        dailyKcalGoal: dailyKcalGoal,
        calculatorProfile: null,
        effectiveDate: DateTime.now(),
      ),
    );
  }

  @override
  Future<bool> clearDailyGoal() {
    return saveSettings(
      const CalorieGoalSettings.empty().applyGoalChange(
        changedAt: DateTime.now(),
        dailyKcalGoal: null,
        calculatorProfile: null,
      ),
    );
  }

  DocumentReference<Map<String, dynamic>> _document(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_calorieSettingsCollection)
        .doc(_defaultSettingsDocumentId);
  }

  Future<CalorieGoalSettings> _decodeSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (!snapshot.exists) {
      return const CalorieGoalSettings.empty();
    }

    try {
      final payload = snapshot.data()?[encryptedPayloadField];
      if (payload is! String) {
        throw FormatException(
          'Calorie settings ${snapshot.id} has no payload.',
        );
      }
      return CalorieGoalSettings.fromJson(
        await _dataCipher!.cipher.decryptJson(
          payload,
          aad: snapshot.reference.path,
        ),
      );
    } on Object catch (error, stackTrace) {
      log(
        'Malformed calorie settings document ${snapshot.id}',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const CalorieGoalSettings.empty();
    }
  }
}

/// Calorie settings repository.
@Riverpod(keepAlive: true)
CalorieSettingsRepository calorieSettingsRepository(Ref ref) {
  final dataCipher = ref.watch(userDataCipherProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    return const _UnavailableCalorieSettingsRepository();
  }
  return FirestoreCalorieSettingsRepository(
    dataCipher: dataCipher,
    firestore: firestore,
  );
}

class _UnavailableCalorieSettingsRepository
    implements CalorieSettingsRepository {
  const new();

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
