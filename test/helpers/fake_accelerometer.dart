import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _methodChannel = MethodChannel(
  'dev.fluttercommunity.plus/sensors/method',
);
const _eventChannel = EventChannel(
  'dev.fluttercommunity.plus/sensors/accelerometer',
);

TestDefaultBinaryMessenger get _messenger =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

/// Stands in for the sensors_plus plugin, which has no host in tests: its
/// method channel answers, and its accelerometer channel records listens and
/// pushes the events the test sends.
class FakeAccelerometer {
  /// Installs the fake and removes it when the test ends.
  new() {
    _messenger
      ..setMockMethodCallHandler(_methodChannel, (call) async => null)
      ..setMockStreamHandler(
        _eventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            listens++;
            _sink = events;
          },
          onCancel: (arguments) {
            cancels++;
            _sink = null;
          },
        ),
      );
    addTearDown(() {
      _messenger
        ..setMockMethodCallHandler(_methodChannel, null)
        ..setMockStreamHandler(_eventChannel, null);
    });
  }

  MockStreamHandlerEventSink? _sink;

  /// How often a stream started listening.
  int listens = 0;

  /// How often a stream stopped listening.
  int cancels = 0;

  /// Whether a stream is listening now.
  bool get isListening => _sink != null;

  /// Sends one reading in m/s², like the sensor does.
  void send(double x, double y, double z) => _sink!.success(<double>[
    x,
    y,
    z,
    DateTime(2026).microsecondsSinceEpoch.toDouble(),
  ]);
}
