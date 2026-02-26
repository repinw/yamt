import 'package:firebase_auth/firebase_auth.dart';

extension AuthUserGuestSetupX on User {
  // Heuristic based on Firebase metadata for first-sign-in prefill only.
  // Routing must not depend on this because timestamps can be imprecise.
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
