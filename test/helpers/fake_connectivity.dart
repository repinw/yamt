import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity plugin for tests whose connection the test switches.
class FakeConnectivity implements Connectivity {
  /// Creates the plugin, online unless [offline].
  new({bool offline = false})
    : _results = offline ? _offlineResults : _onlineResults;

  static const List<ConnectivityResult> _offlineResults = [
    ConnectivityResult.none,
  ];
  static const List<ConnectivityResult> _onlineResults = [
    ConnectivityResult.wifi,
  ];

  final _changes = StreamController<List<ConnectivityResult>>.broadcast();
  List<ConnectivityResult> _results;

  /// Whether [checkConnectivity] throws, like a plugin that fails at start.
  bool failCheck = false;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    if (failCheck) throw StateError('No connectivity plugin.');
    return _results;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _changes.stream;

  /// Loses every connection, like flight mode.
  void goOffline() => _change(_offlineResults);

  /// Gets a Wi-Fi connection.
  void goOnline() => _change(_onlineResults);

  void _change(List<ConnectivityResult> results) {
    _results = results;
    _changes.add(results);
  }

  /// Closes the change stream.
  Future<void> dispose() => _changes.close();
}
