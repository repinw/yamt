import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';

bool _readSupportedFor(TargetPlatform platform) {
  debugDefaultTargetPlatformOverride = platform;
  final container = ProviderContainer();
  final value = container.read(receiptCameraSupportedProvider);
  container.dispose();
  return value;
}

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('camera is supported on android', () {
    expect(_readSupportedFor(TargetPlatform.android), isTrue);
  });

  test('camera is supported on iOS', () {
    expect(_readSupportedFor(TargetPlatform.iOS), isTrue);
  });

  test('camera is not supported on desktop and fuchsia', () {
    expect(_readSupportedFor(TargetPlatform.macOS), isFalse);
    expect(_readSupportedFor(TargetPlatform.windows), isFalse);
    expect(_readSupportedFor(TargetPlatform.linux), isFalse);
    expect(_readSupportedFor(TargetPlatform.fuchsia), isFalse);
  });
}
