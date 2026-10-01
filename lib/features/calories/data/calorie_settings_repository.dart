import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/encrypted_payload.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

part 'calorie_settings_repository.g.dart';

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
  Future<void> saveSettings(CalorieGoalSettings settings);
}

/// Defines firestore calorie settings repository.
///
/// The settings hold body data, so the document is stored encrypted with the
/// data key of the user. Reads and writes throw on failure, so an offline
/// read never looks like a user without a goal.
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

    return _document(userId).snapshots().asyncMap(_decodeSnapshot);
  }

  @override
  Future<CalorieGoalSettings> readSettings() async {
    final userId = _dataCipher?.uid;
    if (userId == null) {
      return const CalorieGoalSettings.empty();
    }

    return await _decodeSnapshot(await _document(userId).get());
  }

  @override
  Future<void> saveSettings(CalorieGoalSettings settings) async {
    final dataCipher = _dataCipher;
    if (dataCipher == null) {
      throw StateError('Cannot save calorie settings while signed out.');
    }

    final normalizedSettings = settings.copyWith(updatedAt: DateTime.now());
    final reference = _document(dataCipher.uid);
    await reference.set(<String, dynamic>{
      encryptedPayloadField: await dataCipher.cipher.encryptJson(
        normalizedSettings.toJson(),
        aad: reference.path,
      ),
    });
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

    final payload = snapshot.data()?[encryptedPayloadField];
    if (payload is! String) {
      throw FormatException('Calorie settings ${snapshot.id} has no payload.');
    }
    return CalorieGoalSettings.fromJson(
      await _dataCipher!.cipher.decryptJson(
        payload,
        aad: snapshot.reference.path,
      ),
    );
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
  Future<void> saveSettings(CalorieGoalSettings settings) async {
    throw StateError('Cannot save calorie settings while signed out.');
  }
}
