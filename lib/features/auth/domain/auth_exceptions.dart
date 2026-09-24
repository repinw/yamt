/// Auth failures that the UI must tell apart.
sealed class AuthException implements Exception {
  const new();
}

/// The typed recovery key is malformed or does not open the key backup.
final class InvalidRecoveryKeyException extends AuthException {
  /// Creates the exception.
  const new();
}
