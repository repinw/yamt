import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/app_update/application/app_client_version_record.dart';
import 'package:yamt/features/auth/data/auth_service.dart';

import '../../../helpers/memory_app_preferences.dart';

class _MockUser extends Mock implements User;

ProviderContainer _container(FakeFirebaseFirestore firestore, User? user) {
  final container = ProviderContainer(
    overrides: [
      firebaseFirestoreProvider.overrideWithValue(firestore),
      appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      appVersionProvider.overrideWith((ref) async => '3.6.0+38'),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 7, 8)),
      authStateChangesProvider.overrideWith((ref) => Stream.value(user)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _record(ProviderContainer container) async {
  container.listen(appClientVersionRecordProvider, (_, _) {});
  await container.read(appClientVersionRecordProvider.future);
}

void main() {
  test('saves the version of this device for the signed-in user', () async {
    final firestore = FakeFirebaseFirestore();
    final user = _MockUser();
    when(() => user.uid).thenReturn('u1');

    await _record(_container(firestore, user));

    final clients = await firestore.collection('users/u1/clients').get();
    expect(clients.docs.single.data()['app_version'], '3.6.0+38');
  });

  test('saves nothing while signed out', () async {
    final firestore = FakeFirebaseFirestore();

    await _record(_container(firestore, null));

    expect(firestore.dump(), '{}');
  });
}
