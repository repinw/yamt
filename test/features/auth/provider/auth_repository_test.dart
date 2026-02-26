import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/features/auth/provider/auth_repository.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockUser extends Mock implements User {}

void main() {
  test('authRepository forwards email sign-in to FirebaseAuth', () async {
    final mockAuth = _MockFirebaseAuth();
    final mockCredential = _MockUserCredential();

    when(
      () => mockAuth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => mockCredential);

    final container = ProviderContainer(
      overrides: [firebaseAuthProvider.overrideWithValue(mockAuth)],
    );
    addTearDown(container.dispose);

    final repository = container.read(authRepositoryProvider);

    await repository.signInWithEmailAndPassword(
      email: 'demo@test.com',
      password: 'secret',
    );

    verify(
      () => mockAuth.signInWithEmailAndPassword(
        email: 'demo@test.com',
        password: 'secret',
      ),
    ).called(1);
  });

  test('authRepository forwards account creation to FirebaseAuth', () async {
    final mockAuth = _MockFirebaseAuth();
    final mockCredential = _MockUserCredential();

    when(
      () => mockAuth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => mockCredential);

    final container = ProviderContainer(
      overrides: [firebaseAuthProvider.overrideWithValue(mockAuth)],
    );
    addTearDown(container.dispose);

    final repository = container.read(authRepositoryProvider);

    await repository.createUserWithEmailAndPassword(
      email: 'demo@test.com',
      password: 'secret',
    );

    verify(
      () => mockAuth.createUserWithEmailAndPassword(
        email: 'demo@test.com',
        password: 'secret',
      ),
    ).called(1);
  });

  test('authRepository forwards anonymous sign-in to FirebaseAuth', () async {
    final mockAuth = _MockFirebaseAuth();
    final mockCredential = _MockUserCredential();

    when(
      () => mockAuth.signInAnonymously(),
    ).thenAnswer((_) async => mockCredential);

    final container = ProviderContainer(
      overrides: [firebaseAuthProvider.overrideWithValue(mockAuth)],
    );
    addTearDown(container.dispose);

    final repository = container.read(authRepositoryProvider);

    await repository.signInAnonymously();

    verify(() => mockAuth.signInAnonymously()).called(1);
  });

  test('authRepository updates current user display name', () async {
    final mockAuth = _MockFirebaseAuth();
    final mockUser = _MockUser();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async {});
    when(() => mockUser.reload()).thenAnswer((_) async {});

    final container = ProviderContainer(
      overrides: [firebaseAuthProvider.overrideWithValue(mockAuth)],
    );
    addTearDown(container.dispose);

    final repository = container.read(authRepositoryProvider);
    await repository.updateCurrentUserDisplayName(displayName: 'Wlad');

    verify(() => mockUser.updateDisplayName('Wlad')).called(1);
    verify(() => mockUser.reload()).called(1);
  });
}
