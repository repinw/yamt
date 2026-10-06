import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/app_version_config_repository.dart';
import 'package:yamt/core/domain/app_update_status.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';

ProviderContainer _container(
  FakeFirebaseFirestore firestore, {
  String appVersion = '3.5.0+37',
}) {
  final container = ProviderContainer(
    overrides: [
      firebaseFirestoreProvider.overrideWithValue(firestore),
      appVersionProvider.overrideWith((ref) async => appVersion),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _setConfig(
  FakeFirebaseFirestore firestore, {
  required String min,
  required String latest,
}) => firestore.doc('config/app_version').set({
  'min_version': min,
  'latest_version': latest,
});

void main() {
  test('watchConfig gives null while no config is set', () async {
    final repository = AppVersionConfigRepository(FakeFirebaseFirestore());

    expect(await repository.watchConfig().first, isNull);
  });

  test('appUpdateStatus follows the stored config', () async {
    final firestore = FakeFirebaseFirestore();
    final container = _container(firestore);
    final statuses = <AppUpdateStatus>[];
    container.listen(
      appUpdateStatusProvider,
      (_, next) => next.whenData(statuses.add),
    );

    await container.read(appUpdateStatusProvider.future);
    await _setConfig(firestore, min: '3.5.0', latest: '3.6.0');
    await pumpEventQueue();
    await _setConfig(firestore, min: '3.6.0', latest: '3.6.0');
    await pumpEventQueue();

    expect(statuses.map((status) => status.runtimeType), [
      AppUpToDate,
      AppUpdateAvailable,
      AppUpdateRequired,
    ]);
  });

  test('an invalid config counts as missing and a fixed one applies', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.doc('config/app_version').set({'latest_version': '3.6.0'});
    final container = _container(firestore);
    final statuses = <AppUpdateStatus>[];
    container.listen(
      appUpdateStatusProvider,
      (_, next) => next.whenData(statuses.add),
    );

    await container.read(appUpdateStatusProvider.future);
    await _setConfig(firestore, min: '3.6.0', latest: '3.6.0');
    await pumpEventQueue();

    expect(statuses, [const AppUpToDate(), const AppUpdateRequired()]);
  });
}
