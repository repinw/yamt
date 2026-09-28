import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kitchen_utensils/application/'
    'kitchen_utensil_list_provider.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository_contract.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';

class _StreamKitchenUtensilRepository implements KitchenUtensilRepository {
  final controller = StreamController<List<KitchenUtensil>>();

  @override
  Stream<List<KitchenUtensil>> watchAll() => controller.stream;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

KitchenUtensil _utensil(String id, DateTime updatedAt) {
  return KitchenUtensil(
    id: id,
    name: id,
    weightGrams: 500,
    createdAt: DateTime(2026),
    updatedAt: updatedAt,
  );
}

void main() {
  test('kitchenUtensilListProvider emits utensils newest first', () async {
    final repository = _StreamKitchenUtensilRepository();
    addTearDown(repository.controller.close);
    final container = ProviderContainer(
      overrides: [
        kitchenUtensilRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      kitchenUtensilListProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    repository.controller.add(<KitchenUtensil>[
      _utensil('old', DateTime(2026)),
      _utensil('new', DateTime(2026, 2)),
    ]);
    await pumpEventQueue();

    final utensils = container.read(kitchenUtensilListProvider).requireValue;
    expect(utensils.map((utensil) => utensil.id), <String>['new', 'old']);
  });
}
