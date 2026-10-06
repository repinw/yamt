import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cooked_meal_controller.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_cooking_service.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

class _FakeCookingService implements PreparedMealCookingService {
  new({this.fails = false});

  final bool fails;
  final calls = <(String, int, int?, int?)>[];

  @override
  Future<PreparedMealCreationResult> cook({
    required String name,
    required List<String> ingredients,
    required Map<String, List<String>> assignments,
  }) => throw UnimplementedError();

  @override
  Future<PreparedMeal> finishCooking({
    required String mealId,
    required int totalPortions,
    required int? potTareWeight,
    required int? finalNetWeight,
  }) async {
    if (fails) {
      throw StateError('offline');
    }
    calls.add((mealId, totalPortions, potTareWeight, finalNetWeight));
    return _meal(mealId, totalPortions);
  }
}

PreparedMeal _meal(String id, int portions) {
  final now = DateTime.utc(2026, 10, 6);
  return PreparedMeal(
    id: id,
    name: 'Pfanne',
    totalPortions: portions,
    remainingPortions: portions,
    totalKcal: 800,
    totalProtein: 40,
    totalCarbs: 80,
    totalFat: 30,
    createdAt: now,
    updatedAt: now,
    components: const <PreparedMealComponent>[],
  );
}

/// The container and the states that the controller goes through.
(ProviderContainer, List<AsyncValue<void>>) _container(
  _FakeCookingService service,
) {
  final container = ProviderContainer(
    overrides: [preparedMealCookingServiceProvider.overrideWithValue(service)],
  );
  addTearDown(container.dispose);
  final states = <AsyncValue<void>>[];
  container.listen(
    cookedMealControllerProvider('pan'),
    (_, next) => states.add(next),
  );
  return (container, states);
}

void main() {
  test('save passes portions and weights and returns the meal', () async {
    final service = _FakeCookingService();
    final (container, states) = _container(service);

    final saved = await container
        .read(cookedMealControllerProvider('pan').notifier)
        .save(totalPortions: 4, potTareWeight: 1240, netWeight: 1180);

    expect(saved?.id, 'pan');
    expect(service.calls.single, ('pan', 4, 1240, 1180));
    expect(states, [isA<AsyncLoading<void>>(), isA<AsyncData<void>>()]);
  });

  test('save keeps no pot weight when the pot was not weighed', () async {
    final service = _FakeCookingService();
    final (container, _) = _container(service);

    await container
        .read(cookedMealControllerProvider('pan').notifier)
        .save(totalPortions: 2, potTareWeight: 1240, netWeight: null);

    expect(service.calls.single, ('pan', 2, null, null));
  });

  test('save reports a failure as an error state', () async {
    final (container, states) = _container(_FakeCookingService(fails: true));

    final saved = await container
        .read(cookedMealControllerProvider('pan').notifier)
        .save(totalPortions: 2, potTareWeight: null, netWeight: null);

    expect(saved, isNull);
    expect(states, [isA<AsyncLoading<void>>(), isA<AsyncError<void>>()]);
  });
}
