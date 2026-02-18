import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  test('authStateChangesProvider forwards FirebaseAuth.userChanges stream', () async {
    final mockAuth = _MockFirebaseAuth();
    final controller = StreamController<User?>();

    when(() => mockAuth.userChanges()).thenAnswer((_) => controller.stream);

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

    verify(() => mockAuth.userChanges()).called(1);
  });
}
