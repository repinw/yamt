import 'dart:async';

import 'package:collection/collection.dart';
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

  /// Holds the writes back until completed, when set. [failWrites] is read
  /// after the hold, so a held write can be made to fail.
  Completer<void>? writeHold;

  /// Holds back what [readAll] and [watchAll] show of a write until completed,
  /// when set: the write itself returns at once, as a Firestore write does
  /// that commits in the background and shows up a moment later.
  Completer<void>? showHold;

  /// How often a template was saved or deleted.
  int writeCount = 0;

  final _watchers = <StreamController<List<PreparedMeal>>>{};

  /// How many [watchAll] streams are listened to right now.
  int get watcherCount => _watchers.length;

  /// Ends every [watchAll] stream that is listened to right now, as a lost
  /// connection that gives up would.
  Future<void> endWatchers() async {
    for (final watcher in _watchers.toList()) {
      await watcher.close();
    }
  }

  @override
  Stream<List<PreparedMeal>> watchAll() {
    late final StreamController<List<PreparedMeal>> watcher;
    watcher = StreamController<List<PreparedMeal>>(
      onListen: () {
        _watchers.add(watcher);
        watcher.add(templates);
      },
      // A real subscription answers its cancel with a future of its own; one
      // from the zone keeps a test's fake clock in charge of it.
      onCancel: () async {
        _watchers.remove(watcher);
      },
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

  /// Like the transaction it stands for, this throws when it fails.
  @override
  Future<bool> update(
    String id,
    PreparedMeal? Function(PreparedMeal current) change,
  ) async {
    if (failWrites) {
      throw StateError('The template was not written.');
    }
    final current = templates.firstWhereOrNull((stored) => stored.id == id);
    final next = current == null ? null : change(current);
    return next != null && await save(next);
  }

  @override
  Future<bool> delete(String templateId) => _write([
    for (final stored in templates)
      if (stored.id != templateId) stored,
  ]);

  Future<bool> _write(List<PreparedMeal> next) async {
    writeCount += 1;
    final hold = writeHold;
    if (hold != null) await hold.future;
    if (failWrites) {
      return false;
    }
    final show = showHold;
    if (show == null) {
      _show(next);
    } else {
      unawaited(show.future.then((_) => _show(next)));
    }
    return true;
  }

  void _show(List<PreparedMeal> next) {
    templates = List<PreparedMeal>.unmodifiable(next);
    for (final watcher in _watchers) {
      watcher.add(templates);
    }
  }
}
