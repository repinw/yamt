import 'package:firebase_auth/firebase_auth.dart';

extension AuthUserGuestSetupX on User {
  bool get requiresGuestNameSetup {
    return isAnonymous && (displayName?.trim().isEmpty ?? true);
  }
}
