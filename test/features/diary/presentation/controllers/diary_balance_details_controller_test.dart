import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_details_controller.dart';

void main() {
  test('starts closed and toggle opens and closes the details', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(
      diaryBalanceDetailsControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(
      diaryBalanceDetailsControllerProvider.notifier,
    );

    expect(subscription.read(), isFalse);
    controller.toggle();
    expect(subscription.read(), isTrue);
    controller.toggle();
    expect(subscription.read(), isFalse);
  });

  test('a new start shows the details closed again', () {
    final first = ProviderContainer();
    addTearDown(first.dispose);
    first.read(diaryBalanceDetailsControllerProvider.notifier).toggle();
    final second = ProviderContainer();
    addTearDown(second.dispose);

    expect(second.read(diaryBalanceDetailsControllerProvider), isFalse);
  });
}
