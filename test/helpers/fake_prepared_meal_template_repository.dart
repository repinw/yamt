import 'dart:async';

import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Keeps the household's cookbook templates in memory and sends every change
/// to each [watchAll] stream asynchronously, like Firestore does.
class FakePreparedMealTemplateRepository
    implements PreparedMealTemplateRepository {
  /// Starts with [templates].
  new({List<PreparedMeal> templates = const <PreparedMeal>[]})
    : templates = List<PreparedMeal>.unmodifiable(templates);

  /// The stored templates.
  List<PreparedMeal> templates;

  /// Whether the next writes fail.
  bool failWrites = false;

  /// How often a template was saved or deleted.
  int writeCount = 0;

  final _watchers = <StreamController<List<PreparedMeal>>>{};

  @override
  Stream<List<PreparedMeal>> watchAll() {
    late final StreamController<List<PreparedMeal>> watcher;
    watcher = StreamController<List<PreparedMeal>>(
      onListen: () {
        _watchers.add(watcher);
        watcher.add(templates);
      },
      onCancel: () => _watchers.remove(watcher),
    );
    return watcher.stream;
  }

  @override
  Future<List<PreparedMeal>> readAll() async => templates;

  @override
  Future<bool> save(PreparedMeal template) => _write([
    for (final stored in templates)
      if (stored.id != template.id) stored,
    template,
  ]);

  @override
  Future<bool> delete(String templateId) => _write([
    for (final stored in templates)
      if (stored.id != templateId) stored,
  ]);

  Future<bool> _write(List<PreparedMeal> next) async {
    writeCount += 1;
    if (failWrites) {
      return false;
    }
    templates = List<PreparedMeal>.unmodifiable(next);
    for (final watcher in _watchers) {
      watcher.add(templates);
    }
    return true;
  }
}
