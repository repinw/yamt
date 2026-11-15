import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/pending_unreadable_share.dart';

void main() {
  ProviderContainer newContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('holds nothing at first', () {
    expect(newContainer().read(pendingUnreadableShareProvider), isFalse);
  });

  test('holds the signal until a page takes it, once', () {
    final container = newContainer();
    final notifier = container.read(pendingUnreadableShareProvider.notifier)
      ..raise();

    expect(container.read(pendingUnreadableShareProvider), isTrue);
    expect(notifier.take(), isTrue);
    expect(container.read(pendingUnreadableShareProvider), isFalse);
    expect(notifier.take(), isFalse);
  });
}
