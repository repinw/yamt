import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/network_connectivity.dart';

import '../../helpers/fake_connectivity.dart';

void main() {
  group('isOfflineConnectivity', () {
    test('no connection is offline', () {
      expect(isOfflineConnectivity(const [ConnectivityResult.none]), isTrue);
      expect(isOfflineConnectivity(const []), isTrue);
    });

    test('any connection is online', () {
      for (final result in ConnectivityResult.values) {
        if (result == ConnectivityResult.none) continue;
        expect(isOfflineConnectivity([result]), isFalse, reason: '$result');
      }
      expect(
        isOfflineConnectivity(const [
          ConnectivityResult.wifi,
          ConnectivityResult.vpn,
        ]),
        isFalse,
      );
    });
  });

  group('deviceOfflineProvider', () {
    ({FakeConnectivity connectivity, List<AsyncValue<bool>> states}) listen({
      bool offline = false,
      bool failCheck = false,
    }) {
      final connectivity = FakeConnectivity(offline: offline)
        ..failCheck = failCheck;
      addTearDown(connectivity.dispose);
      final container = ProviderContainer(
        overrides: [connectivityProvider.overrideWithValue(connectivity)],
      );
      addTearDown(container.dispose);
      final states = <AsyncValue<bool>>[];
      container.listen(
        deviceOfflineProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );
      return (connectivity: connectivity, states: states);
    }

    testWidgets('starts with the checked state and follows every lasting '
        'change', (tester) async {
      final device = listen(offline: true);

      await tester.pump();
      device.connectivity.goOnline();
      await tester.pump(connectivitySettleDelay);
      device.connectivity.goOffline();
      await tester.pump(connectivitySettleDelay);

      expect(device.states.first, isA<AsyncLoading<bool>>());
      expect(device.states.skip(1), const [
        AsyncData(true),
        AsyncData(false),
        AsyncData(true),
      ]);
    });

    testWidgets('an online start is not offline', (tester) async {
      final device = listen();

      await tester.pump();

      expect(device.states.skip(1), const [AsyncData(false)]);
    });

    testWidgets('a short loss, as in a handover to mobile data, is ignored', (
      tester,
    ) async {
      final device = listen();
      await tester.pump();

      device.connectivity.goOffline();
      await tester.pump(connectivitySettleDelay ~/ 2);
      device.connectivity.goOnline();
      await tester.pump(connectivitySettleDelay);

      expect(device.states.skip(1), const [AsyncData(false)]);
    });

    testWidgets('a provider gone before the first check ends stays quiet', (
      tester,
    ) async {
      final connectivity = FakeConnectivity();
      addTearDown(connectivity.dispose);
      final container = ProviderContainer(
        overrides: [connectivityProvider.overrideWithValue(connectivity)],
      );
      container.listen(deviceOfflineProvider, (_, _) {}).close();
      container.dispose();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed first check still follows the changes', (
      tester,
    ) async {
      final device = listen(failCheck: true);
      await tester.pump();

      device.connectivity.goOffline();
      await tester.pump(connectivitySettleDelay);

      expect(device.states.skip(1), const [AsyncData(true)]);
    });
  });
}
