import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  tearDown(resetFirebaseFirestoreProviderDebugHooks);

  test('firebaseFirestoreProvider returns configured instance', () {
    final firestore = _MockFirebaseFirestore();
    var didLog = false;
    debugFirebaseFirestoreInstanceGetter = () => firestore;
    debugFirebaseFirestoreLogWriter =
        (message, {name = '', error, stackTrace}) {
          expect(message, isNotEmpty);
          expect(name, isNotEmpty);
          didLog = true;
        };

    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(firebaseFirestoreProvider), same(firestore));
    expect(didLog, isFalse);
  });

  test('firebaseFirestoreProvider logs and falls back to null on failure', () {
    final fallbackError = StateError('firestore unavailable');
    String? loggedMessage;
    String? loggedName;
    Object? loggedError;
    StackTrace? loggedStackTrace;
    debugFirebaseFirestoreInstanceGetter = () => throw fallbackError;
    debugFirebaseFirestoreLogWriter =
        (message, {name = '', error, stackTrace}) {
          loggedMessage = message;
          loggedName = name;
          loggedError = error;
          loggedStackTrace = stackTrace;
        };

    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(firebaseFirestoreProvider), isNull);
    expect(loggedMessage, 'Falling back to unavailable Firestore instance.');
    expect(loggedName, 'FirebaseFirestoreProvider');
    expect(loggedError, same(fallbackError));
    expect(loggedStackTrace, isNotNull);
  });
}
