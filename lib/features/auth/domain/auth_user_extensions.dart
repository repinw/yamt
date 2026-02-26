import 'package:firebase_auth/firebase_auth.dart';

const _firstSignInTolerance = Duration(seconds: 15);

extension AuthUserGuestSetupX on User {
  // Heuristic based on Firebase metadata for first-sign-in prefill only.
  // Routing must not depend on this because timestamps can be imprecise.
  // Tolerates minor server/client timestamp jitter.
  bool get isLikelyFirstSignIn {
    final creationTime = metadata.creationTime;
    final lastSignInTime = metadata.lastSignInTime;
    if (creationTime == null || lastSignInTime == null) {
      return false;
    }
    final firstSignInThreshold = creationTime.add(_firstSignInTolerance);
    return !lastSignInTime.isAfter(firstSignInThreshold);
  }
}
