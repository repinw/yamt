import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/core/device/key_backup.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/domain/auth_exceptions.dart';
import 'package:yamt/features/auth/domain/user_data_key_state.dart';

import '../../../helpers/fake_key_backup.dart';

class _MockUser extends Mock implements User;

const _backupPath = 'users/u1/private/data_key';

User _user({required bool isAnonymous}) {
  final user = _MockUser();
  when(() => user.uid).thenReturn('u1');
  when(() => user.isAnonymous).thenReturn(isAnonymous);
  return user;
}

void main() {
  late FakeFirebaseFirestore firestore;
  late StreamController<User?> authChanges;
  late FakeKeyBackup keyBackup;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    firestore = FakeFirebaseFirestore();
    keyBackup = FakeKeyBackup();
    authChanges = StreamController<User?>.broadcast();
    addTearDown(authChanges.close);
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => authChanges.stream),
        firebaseFirestoreProvider.overrideWith((ref) => firestore),
        keyBackupProvider.overrideWithValue(keyBackup),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      userDataKeySessionProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    return container;
  }

  Future<UserDataKeyState> signIn(
    ProviderContainer container, {
    required bool isAnonymous,
  }) async {
    authChanges.add(_user(isAnonymous: isAnonymous));
    await pumpEventQueue();
    return await container.read(userDataKeySessionProvider.future);
  }

  Future<String> encryptedSample(PayloadCipher cipher) {
    return cipher.encryptJson(<String, dynamic>{'kcal': 250}, aad: 'sample');
  }

  test('a guest gets a device key without a backup', () async {
    final container = createContainer();

    final state = await signIn(container, isAnonymous: true);

    expect(state, isA<UserDataKeyReady>());
    final ready = state as UserDataKeyReady;
    expect(ready.recoveryKey, isNull);
    expect(ready.needsRecoveryKeyConfirmation, isFalse);
    expect((await firestore.doc(_backupPath).get()).exists, isFalse);
    expect(container.read(userDataCipherProvider)?.uid, 'u1');
  });

  test('a new account gets a backup that its recovery key opens', () async {
    final container = createContainer();

    final state = await signIn(container, isAnonymous: false);

    final ready = state as UserDataKeyReady;
    expect(ready.needsRecoveryKeyConfirmation, isTrue);
    final backup = await firestore.doc(_backupPath).get();
    final dataKey = await ready.recoveryKey!.unwrapDataKey(
      backup.data()!['wrapped_key'] as String,
      uid: 'u1',
    );
    final payload = await encryptedSample(ready.cipher);
    expect(
      await PayloadCipher(dataKey).decryptJson(payload, aad: 'sample'),
      <String, dynamic>{'kcal': 250},
    );
    expect(keyBackup.values['recovery_key_u1'], ready.recoveryKey!.formatted);
  });

  test('a guest key is not backed up with the platform', () async {
    final container = createContainer();

    await signIn(container, isAnonymous: true);

    expect(keyBackup.values, isEmpty);
  });

  test('saving in the password manager confirms the recovery key', () async {
    final container = createContainer();
    final state = await signIn(container, isAnonymous: false);

    final saved = await container
        .read(userDataKeySessionProvider.notifier)
        .saveRecoveryKeyToPasswordManager(accountName: 'jane@example.com');

    expect(saved, isTrue);
    expect(
      keyBackup.savedPasswords['jane@example.com'],
      (state as UserDataKeyReady).recoveryKey!.formatted,
    );
    final confirmed = container.read(userDataKeySessionProvider).requireValue;
    expect(
      (confirmed as UserDataKeyReady).needsRecoveryKeyConfirmation,
      isFalse,
    );
  });

  test('linking a guest keeps the key and creates the backup', () async {
    final container = createContainer();
    final guest = await signIn(container, isAnonymous: true);
    final payload = await encryptedSample((guest as UserDataKeyReady).cipher);

    final linked = await signIn(container, isAnonymous: false);

    final ready = linked as UserDataKeyReady;
    expect(ready.recoveryKey, isNotNull);
    expect(
      await ready.cipher.decryptJson(payload, aad: 'sample'),
      <String, dynamic>{'kcal': 250},
    );
    expect((await firestore.doc(_backupPath).get()).exists, isTrue);
  });

  test('confirming the recovery key survives a restart', () async {
    final container = createContainer();
    await signIn(container, isAnonymous: false);

    await container
        .read(userDataKeySessionProvider.notifier)
        .confirmRecoveryKeySaved();
    container.invalidate(userDataKeySessionProvider);
    final restarted = await container.read(userDataKeySessionProvider.future);

    expect(
      (restarted as UserDataKeyReady).needsRecoveryKeyConfirmation,
      isFalse,
    );
  });

  group('on a new device', () {
    late RecoveryKey recoveryKey;
    late PayloadCipher originalCipher;

    setUp(() async {
      recoveryKey = RecoveryKey.generate();
      final dataKey = await PayloadCipher.newDataKey();
      originalCipher = PayloadCipher(dataKey);
      await firestore.doc(_backupPath).set(<String, dynamic>{
        'wrapped_key': await recoveryKey.wrapDataKey(dataKey, uid: 'u1'),
      });
    });

    test('recovery is required', () async {
      final container = createContainer();

      final state = await signIn(container, isAnonymous: false);

      expect(state, isA<UserDataKeyRecoveryRequired>());
      expect(container.read(userDataCipherProvider), isNull);
    });

    test('the platform backup restores the key without asking', () async {
      keyBackup.values['recovery_key_u1'] = recoveryKey.formatted;
      final container = createContainer();
      final payload = await encryptedSample(originalCipher);

      final state = await signIn(container, isAnonymous: false);

      final ready = state as UserDataKeyReady;
      expect(ready.needsRecoveryKeyConfirmation, isFalse);
      expect(
        await ready.cipher.decryptJson(payload, aad: 'sample'),
        <String, dynamic>{'kcal': 250},
      );
    });

    test('a stale platform backup still asks for the key', () async {
      keyBackup.values['recovery_key_u1'] = RecoveryKey.generate().formatted;
      final container = createContainer();

      final state = await signIn(container, isAnonymous: false);

      expect(state, isA<UserDataKeyRecoveryRequired>());
    });

    test('a wrong or malformed recovery key is rejected', () async {
      final container = createContainer();
      await signIn(container, isAnonymous: false);
      final session = container.read(userDataKeySessionProvider.notifier);

      await expectLater(
        session.restore(RecoveryKey.generate().formatted),
        throwsA(isA<InvalidRecoveryKeyException>()),
      );
      await expectLater(
        session.restore('not a key'),
        throwsA(isA<InvalidRecoveryKeyException>()),
      );
    });

    test('the right recovery key restores the original key', () async {
      final container = createContainer();
      await signIn(container, isAnonymous: false);
      final payload = await encryptedSample(originalCipher);

      await container
          .read(userDataKeySessionProvider.notifier)
          .restore(recoveryKey.formatted.toLowerCase());
      final state = await container.read(userDataKeySessionProvider.future);

      final ready = state as UserDataKeyReady;
      expect(ready.needsRecoveryKeyConfirmation, isFalse);
      expect(
        await ready.cipher.decryptJson(payload, aad: 'sample'),
        <String, dynamic>{'kcal': 250},
      );
    });

    test(
      'starting fresh deletes private data and writes a new backup',
      () async {
        await firestore.doc('users/u1/calorie_entries/e1').set(
          <String, dynamic>{'payload': 'old', 'logged_at': DateTime(2026)},
        );
        await firestore.doc('users/u1').set(<String, dynamic>{
          'uid': 'u1',
          'burn_week_run_state': 'old',
        });
        final container = createContainer();
        await signIn(container, isAnonymous: false);
        final oldBackup = (await firestore.doc(_backupPath).get()).data();

        await container.read(userDataKeySessionProvider.notifier).startFresh();
        final state = await container.read(userDataKeySessionProvider.future);

        final ready = state as UserDataKeyReady;
        expect(ready.needsRecoveryKeyConfirmation, isTrue);
        expect(
          (await firestore.collection('users/u1/calorie_entries').get()).docs,
          isEmpty,
        );
        expect(
          (await firestore.doc('users/u1').get()).data(),
          <String, dynamic>{'uid': 'u1'},
        );
        final newBackup = (await firestore.doc(_backupPath).get()).data()!;
        expect(newBackup, isNot(oldBackup));
        await expectLater(
          recoveryKey.unwrapDataKey(
            newBackup['wrapped_key'] as String,
            uid: 'u1',
          ),
          throwsA(anything),
        );
      },
    );
  });

  test('plaintext private data is encrypted before the key is ready', () async {
    await firestore.doc('users/u1/health_weights/2026-09-24').set(
      <String, dynamic>{'day': '2026-09-24', 'weightKg': 80.5},
    );
    final container = createContainer();

    final state = await signIn(container, isAnonymous: true);

    final stored =
        (await firestore.doc('users/u1/health_weights/2026-09-24').get())
            .data()!;
    expect(stored.keys, <String>['payload']);
    expect(
      await (state as UserDataKeyReady).cipher.decryptJson(
        stored['payload'] as String,
        aad: 'users/u1/health_weights/2026-09-24',
      ),
      <String, dynamic>{'day': '2026-09-24', 'weightKg': 80.5},
    );
  });

  test('signed out without a user', () async {
    final container = createContainer();
    authChanges.add(null);
    await pumpEventQueue();

    final state = await container.read(userDataKeySessionProvider.future);

    expect(state, isA<UserDataKeySignedOut>());
  });
}
