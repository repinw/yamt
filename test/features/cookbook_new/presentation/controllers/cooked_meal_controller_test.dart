import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cooked_meal_controller.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_cooking_service.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';

class _FakeCookingService implements PreparedMealCookingService {
  new({this.fails = false});

  final bool fails;
  final calls = <(String, int, bool, int?, int?)>[];

  @override
  Future<PreparedMealCreationResult> cook({
    required String name,
    required List<String> ingredients,
    required Map<String, List<String>> assignments,
  }) => throw UnimplementedError();

  @override
  Future<PreparedMealCreationResult> cookRecipe({
    required PreparedMeal recipe,
    required int portions,
    required Map<String, List<String>> assignments,
  }) => throw UnimplementedError();

  @override
  Future<PreparedMeal> finishCooking({
    required String mealId,
    required int totalPortions,
    required bool servedInPieces,
    required int? potTareWeight,
    required int? finalNetWeight,
  }) async {
    if (fails) {
      throw StateError('offline');
    }
    calls.add((
      mealId,
      totalPortions,
      servedInPieces,
      potTareWeight,
      finalNetWeight,
    ));
    return _meal(mealId, totalPortions);
  }

  final discarded = <String>[];

  @override
  Future<void> discard(String mealId) async {
    if (fails) {
      throw StateError('offline');
    }
    discarded.add(mealId);
  }
}

class _FakeTemplateRepository implements PreparedMealTemplateRepository {
  new({this.fails = false});

  final bool fails;
  List<PreparedMeal> saved = <PreparedMeal>[];

  @override
  Stream<List<PreparedMeal>> watchAll() => Stream.value(saved);

  @override
  Future<List<PreparedMeal>> readAll() async => saved;

  @override
  Future<bool> save(PreparedMeal template) => _replaceAll([
    for (final stored in saved)
      if (stored.id != template.id) stored,
    template,
  ]);

  @override
  Future<bool> delete(String templateId) => _replaceAll([
    for (final stored in saved)
      if (stored.id != templateId) stored,
  ]);

  Future<bool> _replaceAll(List<PreparedMeal> templates) async {
    if (fails) {
      return false;
    }
    saved = templates;
    return true;
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
  _FakeCookingService service, {
  _FakeTemplateRepository? templates,
}) {
  final container = ProviderContainer(
    overrides: [
      preparedMealCookingServiceProvider.overrideWithValue(service),
      preparedMealTemplateRepositoryProvider.overrideWithValue(
        templates ?? _FakeTemplateRepository(),
      ),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 9, 18)),
    ],
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
        .save(
          totalPortions: 4,
          servedInPieces: false,
          potTareWeight: 1240,
          netWeight: 1180,
        );

    expect(saved?.id, 'pan');
    expect(service.calls.single, ('pan', 4, false, 1240, 1180));
    expect(states, [isA<AsyncLoading<void>>(), isA<AsyncData<void>>()]);
  });

  test('save passes pieces and keeps no pot weight without weighing', () async {
    final service = _FakeCookingService();
    final (container, _) = _container(service);

    await container
        .read(cookedMealControllerProvider('pan').notifier)
        .save(
          totalPortions: 6,
          servedInPieces: true,
          potTareWeight: 1240,
          netWeight: null,
        );

    expect(service.calls.single, ('pan', 6, true, null, null));
  });

  test('discard gives the meal back and reports success', () async {
    final service = _FakeCookingService();
    final (container, states) = _container(service);

    final done = await container
        .read(cookedMealControllerProvider('pan').notifier)
        .discard();

    expect(done, isTrue);
    expect(service.discarded, ['pan']);
    expect(states, [isA<AsyncLoading<void>>(), isA<AsyncData<void>>()]);
  });

  test('a failed discard reports an error state', () async {
    final (container, states) = _container(_FakeCookingService(fails: true));

    final done = await container
        .read(cookedMealControllerProvider('pan').notifier)
        .discard();

    expect(done, isFalse);
    expect(states, [isA<AsyncLoading<void>>(), isA<AsyncError<void>>()]);
  });

  test('save reports a failure as an error state', () async {
    final (container, states) = _container(_FakeCookingService(fails: true));

    final saved = await container
        .read(cookedMealControllerProvider('pan').notifier)
        .save(
          totalPortions: 2,
          servedInPieces: false,
          potTareWeight: null,
          netWeight: null,
        );

    expect(saved, isNull);
    expect(states, [isA<AsyncLoading<void>>(), isA<AsyncError<void>>()]);
  });

  test('addToCookbook saves the meal as a template', () async {
    final templates = _FakeTemplateRepository();
    final (container, states) = _container(
      _FakeCookingService(),
      templates: templates,
    );

    final added = await container
        .read(cookedMealControllerProvider('pan').notifier)
        .addToCookbook(_meal('pan', 4));

    expect(added, isTrue);
    expect(templates.saved.single.name, 'Pfanne');
    expect(templates.saved.single.createdAt, DateTime.utc(2026, 10, 9, 18));
    expect(states, [isA<AsyncLoading<void>>(), isA<AsyncData<void>>()]);
  });

  test('addToCookbook reports a failed template', () async {
    final (container, states) = _container(
      _FakeCookingService(),
      templates: _FakeTemplateRepository(fails: true),
    );

    final added = await container
        .read(cookedMealControllerProvider('pan').notifier)
        .addToCookbook(_meal('pan', 4));

    expect(added, isFalse);
    expect(states, [isA<AsyncLoading<void>>(), isA<AsyncData<void>>()]);
  });
}
