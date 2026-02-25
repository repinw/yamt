import 'package:yamt/features/auth/provider/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.shouldFailSignIn = false,
    this.shouldFailRegister = false,
    this.shouldFailGuest = false,
  });

  final bool shouldFailSignIn;
  final bool shouldFailRegister;
  final bool shouldFailGuest;

  int signInCalls = 0;
  int registerCalls = 0;
  int guestCalls = 0;
  int guestNameUpdateCalls = 0;
  String? lastGuestDisplayName;

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
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    registerCalls++;
    if (shouldFailRegister) {
      throw Exception('register failed');
    }
  }

  @override
  Future<void> signInAnonymously() async {
    guestCalls++;
    if (shouldFailGuest) {
      throw Exception('guest failed');
    }
  }

  @override
  Future<void> updateCurrentUserDisplayName({
    required String displayName,
  }) async {
    guestNameUpdateCalls++;
    lastGuestDisplayName = displayName;
  }
}
