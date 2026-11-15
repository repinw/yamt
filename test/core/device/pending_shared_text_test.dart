import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/pending_shared_text.dart';

void main() {
  ProviderContainer newContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('holds nothing at first', () {
    expect(newContainer().read(pendingSharedTextProvider), isNull);
  });

  test('holds the put text until a page takes it', () {
    final container = newContainer();

    container.read(pendingSharedTextProvider.notifier).put('200 g Mehl\nSalz');

    expect(container.read(pendingSharedTextProvider), '200 g Mehl\nSalz');
    expect(
      container.read(pendingSharedTextProvider.notifier).take(),
      '200 g Mehl\nSalz',
    );
    expect(container.read(pendingSharedTextProvider), isNull);
    // Taken once.
    expect(container.read(pendingSharedTextProvider.notifier).take(), isNull);
  });

  test('empty text is left out and keeps what is held', () {
    final container = newContainer();
    final notifier = container.read(pendingSharedTextProvider.notifier)
      ..put('   ')
      ..put('');

    expect(container.read(pendingSharedTextProvider), isNull);

    notifier
      ..put('Mehl')
      ..put('  ');

    expect(container.read(pendingSharedTextProvider), 'Mehl');
  });

  test('a later text replaces the one that was not taken', () {
    final container = newContainer();

    container.read(pendingSharedTextProvider.notifier)
      ..put('erste')
      ..put('zweite');

    expect(container.read(pendingSharedTextProvider), 'zweite');
  });
}
