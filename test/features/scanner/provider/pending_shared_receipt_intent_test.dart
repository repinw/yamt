import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/provider/pending_shared_receipt_intent.dart';

ReceiptInputSelection _selection(String name) {
  return ReceiptInputSelection(
    source: ReceiptInputSource.file,
    name: name,
    mimeType: 'image/jpeg',
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
  );
}

void main() {
  test('replace stores pending intent and consume clears matching request', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(pendingSharedReceiptIntentProvider.notifier).replace(
      <ReceiptInputSelection>[_selection('shared.jpg')],
    );

    final pendingIntent = container.read(pendingSharedReceiptIntentProvider);
    expect(pendingIntent, isNotNull);
    expect(pendingIntent!.selections, hasLength(1));
    expect(
      () => pendingIntent.selections.add(_selection('another.jpg')),
      throwsUnsupportedError,
    );

    container
        .read(pendingSharedReceiptIntentProvider.notifier)
        .consume(pendingIntent.requestId + 1);
    expect(
      container.read(pendingSharedReceiptIntentProvider),
      same(pendingIntent),
    );

    container
        .read(pendingSharedReceiptIntentProvider.notifier)
        .consume(pendingIntent.requestId);
    expect(container.read(pendingSharedReceiptIntentProvider), isNull);
  });

  test('replace ignores empty selections', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(pendingSharedReceiptIntentProvider.notifier)
        .replace(const <ReceiptInputSelection>[]);

    expect(container.read(pendingSharedReceiptIntentProvider), isNull);
  });
}
