import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/auth_exceptions.dart';

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

  /// Sign in anonymously.
  ///
  /// Throws [AuthOfflineException] without a connection.
  Future<void> signInAnonymously();

  /// Update current user display name.
  Future<void> updateCurrentUserDisplayName({required String displayName});
}

/// Defines firebase auth repository.
class FirebaseAuthRepository implements AuthRepository {
  /// The firebase auth repository.
  const new(this._auth);

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
  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const AuthOfflineException();
    } on FirebaseAuthException catch (error) {
      if (error.code == 'network-request-failed') {
        throw const AuthOfflineException();
      }
      rethrow;
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
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return FirebaseAuthRepository(ref.watch(firebaseAuthProvider));
}
