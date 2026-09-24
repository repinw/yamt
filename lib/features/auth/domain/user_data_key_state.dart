import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/recovery_key.dart';

/// State of the data key that encrypts the private data of the current user.
sealed class UserDataKeyState {
  const new();
}

/// No user is signed in, or Firestore is unavailable.
final class UserDataKeySignedOut extends UserDataKeyState {
  /// Creates the state.
  const new();
}

/// The account has a key backup, but this device has no key and the platform
/// backup has none either. The user must enter the recovery key or start
/// fresh.
final class UserDataKeyRecoveryRequired extends UserDataKeyState {
  /// Creates the state.
  const new({required this.uid});

  /// The user id.
  final String uid;
}

/// The data key is available and old plaintext data is encrypted.
final class UserDataKeyReady extends UserDataKeyState {
  /// Creates the state.
  const new({
    required this.uid,
    required this.cipher,
    required this.recoveryKey,
    required this.recoveryKeyConfirmed,
  });

  /// The user id.
  final String uid;

  /// Encrypts and decrypts the private documents of [uid].
  final PayloadCipher cipher;

  /// The recovery key of a real account; `null` for a guest.
  final RecoveryKey? recoveryKey;

  /// Whether the user confirmed that the recovery key is saved.
  final bool recoveryKeyConfirmed;

  /// Whether the account has a recovery key that the user has not saved yet.
  bool get needsRecoveryKeyConfirmation =>
      recoveryKey != null && !recoveryKeyConfirmed;
}
