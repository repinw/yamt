import 'dart:async';
import 'dart:developer' show log;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_connectivity.g.dart';

/// How long a connection change must last before the app reacts to it.
///
/// A handover from Wi-Fi to mobile data can report no connection for a
/// moment, and a new Wi-Fi connection is reported before it carries
/// requests.
const connectivitySettleDelay = Duration(seconds: 2);

/// The platform's connectivity plugin. Tests replace it with a fake.
@Riverpod(keepAlive: true)
Connectivity connectivity(Ref ref) => Connectivity();

/// Whether the device is offline, first as checked at start and then on
/// every change that lasts [connectivitySettleDelay]. It emits only when
/// the state flips.
///
/// The platform reports the network connections of the device (Wi-Fi,
/// mobile data, Ethernet, ...), not whether a server answers. Wi-Fi without
/// internet therefore counts as online; flight mode without Wi-Fi is
/// offline.
@Riverpod(keepAlive: true)
Stream<bool> deviceOffline(Ref ref) {
  final connectivity = ref.watch(connectivityProvider);
  final states = StreamController<bool>();
  bool? reported;
  Timer? settle;

  void report({required bool offline}) {
    // The first check can end after the provider went away.
    if (offline == reported || states.isClosed) return;
    reported = offline;
    states.add(offline);
  }

  final changes = connectivity.onConnectivityChanged.listen((results) {
    settle?.cancel();
    settle = Timer(
      connectivitySettleDelay,
      () => report(offline: isOfflineConnectivity(results)),
    );
  });
  unawaited(
    connectivity.checkConnectivity().then(
      (results) {
        // A settled change is newer than the check.
        if (reported == null) report(offline: isOfflineConnectivity(results));
      },
      // The changes still follow; until then the state stays unknown.
      onError: (Object error, StackTrace stackTrace) => log(
        'Checking the connectivity failed.',
        name: 'yamt.connectivity',
        error: error,
        stackTrace: stackTrace,
      ),
    ),
  );
  ref.onDispose(() {
    settle?.cancel();
    unawaited(changes.cancel());
    unawaited(states.close());
  });
  return states.stream;
}

/// Whether [results] name no network connection at all.
bool isOfflineConnectivity(List<ConnectivityResult> results) {
  return results.every((result) => result == ConnectivityResult.none);
}
