import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// A signed-in member that knows its [uid], and optionally a [displayName]
/// and an [email].
class FakeSignedInUser extends Fake implements User {
  /// Creates the member with [uid].
  new(this.uid, {this.displayName, this.email});

  @override
  final String uid;

  @override
  final String? displayName;

  @override
  final String? email;
}

/// A Firebase auth whose current user is [currentUser], or nobody.
class FakeSignedInAuth extends Fake implements FirebaseAuth {
  /// Creates the auth with [currentUser].
  new(this.currentUser);

  @override
  final User? currentUser;
}
