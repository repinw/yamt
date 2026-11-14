import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_suggestion_queue_controller.dart';

import '../../../../helpers/memory_app_preferences.dart';

const _milk = ShoppingSuggestion(name: 'Milk');
const _oats = ShoppingSuggestion(name: 'Oats');

void main() {
  ProviderContainer containerWith(MemoryAppPreferences preferences) {
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('starts empty when nothing is saved', () {
    final container = containerWith(MemoryAppPreferences());

    expect(container.read(shoppingSuggestionQueueControllerProvider), isEmpty);
  });

  test('pushBack keeps the order and a new container reads it again', () async {
    final preferences = MemoryAppPreferences();
    final container = containerWith(preferences);
    final subscription = container.listen(
      shoppingSuggestionQueueControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(
      shoppingSuggestionQueueControllerProvider.notifier,
    );

    await controller.pushBack(_milk, current: [_milk, _oats]);
    await controller.pushBack(_oats, current: [_milk, _oats]);

    expect(subscription.read(), ['milk|', 'oats|']);
    expect(
      containerWith(preferences)
          .read(shoppingSuggestionQueueControllerProvider),
      ['milk|', 'oats|'],
    );
  });

  test('starts empty when the saved value cannot be read', () {
    final container = containerWith(
      MemoryAppPreferences(
        initialStrings: {'shopping_suggestions_pushed_back_v1': 'not json'},
      ),
    );

    expect(container.read(shoppingSuggestionQueueControllerProvider), isEmpty);
  });
}
