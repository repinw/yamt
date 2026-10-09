import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_template_writer.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository_contract.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_pot_weighing.dart';

class _FakeTemplateRepository implements PreparedMealTemplateRepository {
  new(this.saved, {this.fails = false});

  List<PreparedMeal> saved;
  final bool fails;

  @override
  Stream<List<PreparedMeal>> watchAll() => Stream.value(saved);

  int reads = 0;

  @override
  Future<List<PreparedMeal>> readAll() async {
    reads += 1;
    return saved;
  }

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

final _now = DateTime.utc(2026, 10, 9, 18);

PreparedMeal _meal(String id) {
  final cooked = DateTime.utc(2026, 10, 9, 12);
  return PreparedMeal(
    id: id,
    name: ' Pfanne ',
    totalPortions: 4,
    remainingPortions: 1,
    totalKcal: 800,
    totalProtein: 40,
    totalCarbs: 80,
    totalFat: 30,
    createdAt: cooked,
    updatedAt: cooked,
    components: const <PreparedMealComponent>[],
    recipeIngredients: const ['200 g Reis'],
    potWeighing: PreparedMealPotWeighing(
      netWeight: 900,
      weighedAt: cooked,
      remainingPortions: 2,
    ),
  );
}

void main() {
  test('adds the meal as a new template without touching the others', () async {
    final repository = _FakeTemplateRepository([_meal('old')]);
    final writer = PreparedMealTemplateWriter(
      repository: repository,
      clock: () => _now,
    );

    final template = await writer.addFromMeal(_meal('pan'));

    expect(repository.saved.map((meal) => meal.id), ['old', template.id]);
    expect(repository.reads, 0);
    expect(template.id, isNot('pan'));
    expect(template.name, 'Pfanne');
    expect(template.recipeIngredients, ['200 g Reis']);
    expect(template.remainingPortions, 4);
    expect(template.potWeighing, isNull);
    expect(template.createdAt, _now);
    expect(template.updatedAt, _now);
  });

  test('throws when the templates are not saved', () async {
    final writer = PreparedMealTemplateWriter(
      repository: _FakeTemplateRepository([], fails: true),
      clock: () => _now,
    );

    await expectLater(writer.addFromMeal(_meal('pan')), throwsStateError);
  });
}
