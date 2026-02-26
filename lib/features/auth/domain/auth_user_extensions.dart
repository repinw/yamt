import 'package:firebase_auth/firebase_auth.dart';

extension AuthUserGuestSetupX on User {
  bool get _hasEmptyDisplayName {
    return displayName?.trim().isEmpty ?? true;
  }

  bool get _isLikelyFirstSignIn {
    final creationTime = metadata.creationTime;
    final lastSignInTime = metadata.lastSignInTime;
    if (creationTime == null || lastSignInTime == null) {
      return false;
    }
    final firstSignInThreshold = creationTime.add(const Duration(seconds: 1));
    return !lastSignInTime.isAfter(firstSignInThreshold);
  }

  bool requiresGuestNameSetup({required bool hasCompletedProfileSetup}) {
    if (hasCompletedProfileSetup) {
      return false;
    }
    if (_hasEmptyDisplayName) {
      return true;
    }
    if (isAnonymous) {
      return false;
    }
    return _isLikelyFirstSignIn;
  }
}
