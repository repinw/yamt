import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/presentation/shared/pending_shared_receipt_paths.dart';

void main() {
  group('PendingSharedReceiptPaths', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(pendingSharedReceiptPathsProvider);
      expect(state, isNull);
    });

    test('setPaths filters out empty strings and updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(pendingSharedReceiptPathsProvider.notifier).setPaths([
        ' /path/one.pdf ',
        ' ',
        '/path/two.jpg',
      ]);

      expect(container.read(pendingSharedReceiptPathsProvider), [
        '/path/one.pdf',
        '/path/two.jpg',
      ]);
    });

    test('setPaths with only empty paths does not change state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(pendingSharedReceiptPathsProvider.notifier).setPaths([
        ' ',
        '',
      ]);

      expect(container.read(pendingSharedReceiptPathsProvider), isNull);
    });

    test('consume resets state to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        pendingSharedReceiptPathsProvider.notifier,
      )..setPaths(['/receipt.pdf']);
      expect(container.read(pendingSharedReceiptPathsProvider), isNotNull);

      notifier.consume();
      expect(container.read(pendingSharedReceiptPathsProvider), isNull);
    });
  });
}
