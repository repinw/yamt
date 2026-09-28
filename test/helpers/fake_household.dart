import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/provider/firebase_storage_provider.dart';
import 'package:yamt/features/auth/data/auth_repository.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_repository.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';

import 'fake_auth_repository.dart';
import 'fake_firebase_storage.dart';
import 'fake_key_backup.dart';
import 'memory_app_preferences.dart';

class _MockUser extends Mock implements User;

/// Households in an in-memory Firestore and Storage, for UI tests that run
/// the real household repositories and providers.
class FakeHousehold {
  new _(this.firestore, this.storage);

  /// Creates an empty backend.
  factory create() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    return FakeHousehold._(FakeFirebaseFirestore(), FakeFirebaseStorage());
  }

  /// The Firestore that holds the households.
  final FakeFirebaseFirestore firestore;

  /// The Storage that holds the household images.
  final FakeFirebaseStorage storage;

  final _ciphers = <String, PayloadCipher>{};
  final _householdKeys = <String, SecretKey>{};

  /// The keys of the households, by household id.
  Map<String, SecretKey> get householdKeys => _householdKeys;

  /// The data key cipher of [uid].
  Future<PayloadCipher> cipherFor(String uid) async {
    return _ciphers[uid] ??= PayloadCipher(await PayloadCipher.newDataKey());
  }

  /// Adds the profile of [uid] with the active and the own household.
  Future<void> addUser(
    String uid, {
    required String householdId,
    required String ownHouseholdId,
    String? displayName,
  }) {
    return firestore.doc('users/$uid').set(<String, dynamic>{
      'uid': uid,
      'householdId': householdId,
      'ownHouseholdId': ownHouseholdId,
      'displayName': ?displayName,
    });
  }

  /// Adds [uid] to [householdId] with a key entry. The first member of a
  /// household creates its key.
  Future<void> addMember(
    String householdId,
    String uid, {
    required DateTime joinedAt,
    bool admin = false,
  }) async {
    await firestore.doc('households/$householdId').set(<String, dynamic>{
      'created_at': Timestamp.fromDate(DateTime(2026)),
    });
    await firestore.doc('households/$householdId/members/$uid').set(
      <String, dynamic>{
        'uid': uid,
        'role': admin ? 'admin' : 'member',
        'joined_at': Timestamp.fromDate(joinedAt),
      },
    );
    final key = _householdKeys[householdId] ??=
        await PayloadCipher.newDataKey();
    await _keys.saveKey(
      householdId: householdId,
      memberUid: uid,
      householdKey: key,
      dataCipher: await cipherFor(uid),
    );
  }

  /// Removes the key entry of [uid] and asks the others for the key, like a
  /// fresh start does.
  Future<void> loseKey(String householdId, String uid) async {
    await _keys.deleteKey(householdId: householdId, memberUid: uid);
    await _keys.requestKeyRestore(householdId: householdId, memberUid: uid);
  }

  /// Reads the document at [path].
  Future<Map<String, dynamic>?> read(String path) async {
    return (await firestore.doc(path).get()).data();
  }

  /// The overrides that sign in [uid] against this backend.
  Future<List<Override>> overrides(
    String uid, {
    bool isAnonymous = false,
    String? displayName,
  }) async {
    final user = _MockUser();
    when(() => user.uid).thenReturn(uid);
    when(() => user.isAnonymous).thenReturn(isAnonymous);
    when(() => user.email).thenReturn(null);
    when(() => user.displayName).thenReturn(displayName);
    final cipher = await cipherFor(uid);
    return <Override>[
      firebaseFirestoreProvider.overrideWith((ref) => firestore),
      firebaseStorageProvider.overrideWith((ref) => storage),
      authStateChangesProvider.overrideWith((ref) => Stream.value(user)),
      userDataCipherProvider.overrideWithValue((uid: uid, cipher: cipher)),
      userDataKeyRepositoryProvider.overrideWithValue(
        UserDataKeyRepository(
          storage: const FlutterSecureStorage(),
          firestore: firestore,
          keyBackup: FakeKeyBackup(),
        ),
      ),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
    ];
  }

  HouseholdKeyRepository get _keys => HouseholdKeyRepository(
    firestore: firestore,
    storage: const FlutterSecureStorage(),
  );
}
