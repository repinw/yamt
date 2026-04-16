import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test-api-key',
          appId: 'test-app-id',
          messagingSenderId: 'test-sender-id',
          projectId: 'test-project-id',
        ),
      );
    } on FirebaseException catch (error) {
      if (error.code != 'duplicate-app') rethrow;
    }
  });

  test(
    'authStateChangesProvider forwards FirebaseAuth.userChanges stream',
    () async {
      final mockAuth = _MockFirebaseAuth();
      final controller = StreamController<User?>();

      when(mockAuth.userChanges).thenAnswer((_) => controller.stream);

      final container = ProviderContainer(
        overrides: [firebaseAuthProvider.overrideWithValue(mockAuth)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        authStateChangesProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final firstValueFuture = container.read(authStateChangesProvider.future);
      controller.add(null);
      await controller.close();
      expect(await firstValueFuture, isNull);

      verify(mockAuth.userChanges).called(1);
    },
  );

  test('firebaseAuthProvider creates FirebaseAuth instance', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final auth = container.read(firebaseAuthProvider);
    expect(auth, isA<FirebaseAuth>());
  });

  test('generated provider hash methods are callable', () {
    expect(firebaseAuthProvider.debugGetCreateSourceHash(), isA<String>());
    expect(authStateChangesProvider.debugGetCreateSourceHash(), isA<String>());
  });
}
