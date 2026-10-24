import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/provider/network_connectivity.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/product_search_hub/application/pending_photo_upload_retry.dart';
import 'package:yamt/features/product_search_hub/data/photo_upload_repository.dart';

import '../../../helpers/fake_connectivity.dart';

class _MockUser extends Mock implements User;

class _FakeUploads extends Fake implements PhotoUploadRepository {
  final calls = <String>[];

  @override
  Future<void> uploadPendingPhotos({required DateTime now}) async =>
      calls.add('upload');

  @override
  Future<void> deletePendingPhotos() async => calls.add('delete');
}

/// Starts the retry like `lib/app.dart` and returns the repository calls.
List<String> _start(User? user, FakeConnectivity device) {
  addTearDown(device.dispose);
  final uploads = _FakeUploads();
  final container = ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWith((ref) => Stream.value(user)),
      connectivityProvider.overrideWithValue(device),
      photoUploadRepositoryProvider.overrideWithValue(uploads),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 24)),
    ],
  );
  addTearDown(container.dispose);
  container.listen(pendingPhotoUploadRetryProvider, (_, _) {});
  return uploads.calls;
}

User _user() {
  final user = _MockUser();
  when(() => user.uid).thenReturn('u1');
  return user;
}

void main() {
  testWidgets('uploads the pending photos at start', (tester) async {
    final calls = _start(_user(), FakeConnectivity());

    await tester.pump();

    expect(calls, ['upload']);
  });

  testWidgets('waits offline and uploads once the device is back online', (
    tester,
  ) async {
    final device = FakeConnectivity(offline: true);
    final calls = _start(_user(), device);

    await tester.pump();
    expect(calls, isEmpty);

    device.goOnline();
    await tester.pump(connectivitySettleDelay);

    expect(calls, ['upload']);
  });

  testWidgets('tries again when the app comes back to the foreground', (
    tester,
  ) async {
    final calls = _start(_user(), FakeConnectivity());
    await tester.pump();

    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    // The container rebuilds the invalidated provider on a later tick.
    await tester.pump(const Duration(seconds: 1));

    expect(calls, ['upload', 'upload']);
  });

  testWidgets('signing out deletes the pending photos', (tester) async {
    final calls = _start(null, FakeConnectivity());

    await tester.pump();

    expect(calls, ['delete']);
  });
}
