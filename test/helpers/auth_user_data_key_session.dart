import 'package:cryptography/cryptography.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/domain/user_data_key_state.dart';

/// Follows the auth state like the real session, without key storage: a
/// signed-in user gets a ready data key at once.
class AuthUserDataKeySession extends UserDataKeySession {
  @override
  Future<UserDataKeyState> build() async {
    final user = await ref.watch(authStateChangesProvider.future);
    if (user == null) {
      return const UserDataKeySignedOut();
    }
    return UserDataKeyReady(
      uid: user.uid,
      cipher: PayloadCipher(SecretKey(List<int>.filled(32, 1))),
      recoveryKey: null,
      recoveryKeyConfirmed: true,
    );
  }
}
