import 'package:firebase_auth/firebase_auth.dart';

abstract interface class InventoryUserSession {
  String? get currentUserId;
}

class FirebaseInventoryUserSession implements InventoryUserSession {
  const FirebaseInventoryUserSession({required FirebaseAuth auth})
    : _auth = auth;

  final FirebaseAuth _auth;

  @override
  String? get currentUserId {
    return _auth.currentUser?.uid;
  }
}
