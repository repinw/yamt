import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service.g.dart';

@riverpod
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

@riverpod
Stream<User?> authStateChanges(Ref ref) {
  return ref.watch(firebaseAuthProvider).userChanges();
}
