import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_details_controller.dart';

import '../../../../helpers/memory_app_preferences.dart';

void main() {
  ProviderContainer containerWith(MemoryAppPreferences preferences) {
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('starts quiet when nothing is saved', () {
    final container = containerWith(MemoryAppPreferences());

    expect(container.read(diaryBalanceDetailsControllerProvider), isFalse);
  });

  test('toggle saves the choice for the next start', () async {
    final preferences = MemoryAppPreferences();
    final container = containerWith(preferences);
    final subscription = container.listen(
      diaryBalanceDetailsControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(
      diaryBalanceDetailsControllerProvider.notifier,
    );

    await controller.toggle();
    expect(subscription.read(), isTrue);
    expect(
      containerWith(preferences).read(diaryBalanceDetailsControllerProvider),
      isTrue,
    );

    await controller.toggle();
    expect(subscription.read(), isFalse);
    expect(
      containerWith(preferences).read(diaryBalanceDetailsControllerProvider),
      isFalse,
    );
  });
}
