import 'package:firebase_auth/firebase_auth.dart';

extension AuthUserGuestSetupX on User {
  bool get isLikelyFirstSignIn {
    final creationTime = metadata.creationTime;
    final lastSignInTime = metadata.lastSignInTime;
    if (creationTime == null || lastSignInTime == null) {
      return false;
    }
    final firstSignInThreshold = creationTime.add(const Duration(seconds: 1));
    return !lastSignInTime.isAfter(firstSignInThreshold);
  }

  bool requiresGuestNameSetup({required bool hasCompletedProfileSetup}) {
    return !hasCompletedProfileSetup;
  }
}
