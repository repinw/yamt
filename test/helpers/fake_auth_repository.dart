import 'package:yamt/features/auth/data/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  new({this.shouldFailSignIn = false});

  final bool shouldFailSignIn;

  int signInCalls = 0;
  int guestCalls = 0;
  int guestNameUpdateCalls = 0;
  String? lastGuestDisplayName;

  @override
  String? get currentUserId => 'test-user-id';

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    if (shouldFailSignIn) {
      throw Exception('sign-in failed');
    }
  }

  @override
  Future<void> signInAnonymously() async {
    guestCalls++;
  }

  @override
  Future<void> updateCurrentUserDisplayName({
    required String displayName,
  }) async {
    guestNameUpdateCalls++;
    lastGuestDisplayName = displayName;
  }
}
