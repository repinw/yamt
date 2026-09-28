import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/auth/data/auth_repository.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/domain/user_data_key_state.dart';

import 'fake_auth_repository.dart';

/// A signed-out visitor who gets a guest account on anonymous sign-in, with a
/// data key that becomes ready right after, like the real session.
class FakeGuestAccount {
  new({this.userId, this.signInError, this.dataKeyError});

  /// The uid a guest sign-in creates.
  static const guestUserId = 'guest-user';

  /// The signed-in user, or `null` while nobody is signed in.
  String? userId;

  /// Thrown by the next guest sign-ins while set.
  Exception? signInError;

  /// Thrown by the data key session while set.
  Exception? dataKeyError;

  /// Counts the sign-in calls.
  final repository = FakeAuthRepository();

  final _changes = StreamController<void>.broadcast();

  /// Overrides for the auth repository and the data key session.
  List<Override> get overrides => [
    authRepositoryProvider.overrideWithValue(_SignInForwardingRepository(this)),
    userDataKeySessionProvider.overrideWith(() => _GuestDataKeySession(this)),
  ];

  /// Closes the change stream.
  Future<void> dispose() => _changes.close();

  Future<void> _signInAnonymously() async {
    await repository.signInAnonymously();
    final signInError = this.signInError;
    if (signInError != null) {
      throw signInError;
    }
    userId = guestUserId;
    _changes.add(null);
  }
}

class _SignInForwardingRepository implements AuthRepository {
  new(this._account);

  final FakeGuestAccount _account;

  @override
  String? get currentUserId => _account.userId;

  @override
  Future<void> signInAnonymously() => _account._signInAnonymously();

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _account.repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _account.repository.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> updateCurrentUserDisplayName({required String displayName}) {
    return _account.repository.updateCurrentUserDisplayName(
      displayName: displayName,
    );
  }
}

class _GuestDataKeySession extends UserDataKeySession {
  new(this._account);

  final FakeGuestAccount _account;

  @override
  Future<UserDataKeyState> build() async {
    final subscription = _account._changes.stream.listen(
      (_) => ref.invalidateSelf(),
    );
    ref.onDispose(subscription.cancel);
    final dataKeyError = _account.dataKeyError;
    if (dataKeyError != null) {
      throw dataKeyError;
    }
    final userId = _account.userId;
    if (userId == null) {
      return const UserDataKeySignedOut();
    }
    return UserDataKeyReady(
      uid: userId,
      cipher: PayloadCipher(SecretKey(List<int>.filled(32, 1))),
      recoveryKey: null,
      recoveryKeyConfirmed: true,
    );
  }
}
