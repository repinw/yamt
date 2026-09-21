import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/firebase_options.dart';

part 'secondary_auth_client.g.dart';

/// Secondary auth client provider.
@riverpod
SecondaryAuthClient secondaryAuthClient(Ref ref) {
  return const _FirebaseSecondaryAuthClient();
}

/// Defines secondary auth client.
abstract interface class SecondaryAuthClient {
  /// Create app.
  Future<FirebaseApp> createApp(String appName);

  /// Auth for app.
  FirebaseAuth authForApp(FirebaseApp app);

  /// Dispose app.
  Future<void> disposeApp(FirebaseApp app);
}

// coverage:ignore-start
class _FirebaseSecondaryAuthClient implements SecondaryAuthClient {
  const new();

  @override
  Future<FirebaseApp> createApp(String appName) {
    return Firebase.initializeApp(
      name: appName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  FirebaseAuth authForApp(FirebaseApp app) {
    return FirebaseAuth.instanceFor(app: app);
  }

  @override
  Future<void> disposeApp(FirebaseApp app) async {
    try {
      await authForApp(app).signOut();
      await app.delete();
    } on Object catch (_) {}
  }
}
// coverage:ignore-end
