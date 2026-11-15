import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Defines prepared meal template repository.
abstract interface class PreparedMealTemplateRepository {
  /// Watch all.
  Stream<List<PreparedMeal>> watchAll();

  /// Reads all templates of the household and skips the ones that do
  /// not parse. Throws when they cannot be read.
  Future<List<PreparedMeal>> readAll();

  /// Writes [template] alone; the other templates stay untouched.
  Future<bool> save(PreparedMeal template);

  /// Changes the template [id] in a transaction, so that nothing written
  /// since [change] looked at it gets lost: [change] gets the template as it
  /// is on the server and returns what to write, or `null` to write nothing.
  /// It can run several times. Returns whether the template was written;
  /// one that is gone stays gone. Throws when the transaction fails, as it
  /// does offline.
  Future<bool> update(
    String id,
    PreparedMeal? Function(PreparedMeal current) change,
  );

  /// Deletes the template [templateId] alone.
  Future<bool> delete(String templateId);
}

/// Writes a list change one template at a time.
extension PreparedMealTemplateListChanges on PreparedMealTemplateRepository {
  /// Saves the templates of [next] that differ from [previous] and deletes
  /// the ones that [next] leaves out. Templates in neither list stay
  /// untouched, so a stale list cannot overwrite another writer's template.
  Future<bool> saveChanges({
    required List<PreparedMeal> previous,
    required List<PreparedMeal> next,
  }) async {
    final before = {for (final template in previous) template.id: template};
    final nextIds = {for (final template in next) template.id};
    var saved = true;
    for (final template in next) {
      if (before[template.id] != template) {
        saved = await save(template) && saved;
      }
    }
    for (final id in before.keys) {
      if (!nextIds.contains(id)) {
        saved = await delete(id) && saved;
      }
    }
    return saved;
  }
}
