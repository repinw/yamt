import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_config.dart';

void main() {
  test('wait completes superseded wait instead of hanging', () async {
    final delay = ProductSearchHubSearchDelay();
    addTearDown(delay.dispose);

    final firstWait = delay.wait(const Duration(days: 1));
    final secondWait = delay.wait(Duration.zero);

    await expectLater(
      firstWait.timeout(const Duration(milliseconds: 50)),
      completes,
    );
    await expectLater(secondWait, completes);
  });

  test('dispose completes pending wait instead of hanging', () async {
    final delay = ProductSearchHubSearchDelay();

    final wait = delay.wait(const Duration(days: 1));
    delay.dispose();

    await expectLater(
      wait.timeout(const Duration(milliseconds: 50)),
      completes,
    );
  });
}
