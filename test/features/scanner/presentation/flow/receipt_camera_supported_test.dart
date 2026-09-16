import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_camera_supported.dart';

void main() {
  group('receiptCameraSupportedProvider', () {
    test('returns expected platform support boolean', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isSupported = container.read(receiptCameraSupportedProvider);
      expect(isSupported, isA<bool>());
    });
  });
}
