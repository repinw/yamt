import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/auth/data/auth_service.dart';

part 'session_sign_out_service.g.dart';

/// Signs the current user out.
class SessionSignOutService {
  /// Creates the service.
  const new({required this._auth, required this._shutdown});

  final FirebaseAuth _auth;
  final SessionShutdownController _shutdown;

  /// Pauses the Firestore-backed streams, so none of them reads with the
  /// session that ends, and signs out. Throws when the sign-out fails.
  Future<void> signOut() async {
    _shutdown.begin();
    try {
      await Future<void>.delayed(Duration.zero);
      await _auth.signOut();
    } finally {
      _shutdown.finish();
    }
  }
}

/// Provides the sign-out service.
@riverpod
SessionSignOutService sessionSignOutService(Ref ref) {
  return SessionSignOutService(
    auth: ref.watch(firebaseAuthProvider),
    shutdown: ref.watch(sessionShutdownControllerProvider.notifier),
  );
}
