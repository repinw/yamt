import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

part 'auth_repository.g.dart';

/// Defines auth repository.
abstract interface class AuthRepository {
  /// The current user id.
  String? get currentUserId;

  /// Sign in with email and password.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Create user with email and password.
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign in anonymously.
  Future<void> signInAnonymously();

  /// Update current user display name.
  Future<void> updateCurrentUserDisplayName({required String displayName});
}

/// Defines firebase auth repository.
class FirebaseAuthRepository implements AuthRepository {
  /// The firebase auth repository.
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
    try {
      await _auth.signInAnonymously().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw FirebaseAuthException(
        code: 'network-request-failed',
        message: 'Anonymous sign-in timed out after 15 seconds.',
      );
    }
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

/// Auth repository.
@riverpod
AuthRepository authRepository(Ref ref) {
  return FirebaseAuthRepository(ref.watch(firebaseAuthProvider));
}
