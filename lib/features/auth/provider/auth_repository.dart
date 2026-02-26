import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

part 'auth_repository.g.dart';

abstract interface class AuthRepository {
  String? get currentUserId;

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signInAnonymously();

  Future<void> updateCurrentUserDisplayName({required String displayName});
}

class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
  }

  @override
  Future<void> updateCurrentUserDisplayName({
    required String displayName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found.',
      );
    }

    await user.updateDisplayName(displayName);
    await user.reload();
  }
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return FirebaseAuthRepository(ref.watch(firebaseAuthProvider));
}
