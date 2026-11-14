import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/shoppinglist/data/shopping_shelf_choice_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_catalog.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf_placement.dart';

part 'shopping_shelf_choices_controller.g.dart';

/// The shelf the household chose per product, live. A read error is logged
/// and passed on; the views fall back to the catalog then.
@riverpod
class ShoppingShelfChoicesController extends _$ShoppingShelfChoicesController {
  @override
  Stream<ShoppingShelfChoices> build() => ref
      .watch(shoppingShelfChoiceRepositoryProvider)
      .watchChoices()
      .handleError((Object error, StackTrace stackTrace) {
        _log('Failed to read shelf choices.', error, stackTrace);
        Error.throwWithStackTrace(error, stackTrace);
      });

  /// Remembers [shelf] for every entry called [name] in the household.
  /// Returns `false` when the save fails; the choice then stays as it was.
  Future<bool> choose(String name, ShoppingShelf shelf) =>
      chooseAll({name: shelf});

  /// Remembers the shelf of each product name in [shelves] at once. With
  /// [keepStored] a product that has a shelf already keeps it.
  Future<bool> chooseAll(
    Map<String, ShoppingShelf> shelves, {
    bool keepStored = false,
  }) async {
    final link = ref.keepAlive();
    try {
      final changes = {
        for (final MapEntry(:key, :value) in shelves.entries)
          shoppingCatalogKey(key): value,
      };
      // Without the stored choices (still loading or failed), nothing is
      // shown early: a partial map would hide the others.
      final previous = state.value;
      if (previous != null) {
        state = AsyncData(
          keepStored ? {...changes, ...previous} : {...previous, ...changes},
        );
      }
      try {
        await ref
            .read(shoppingShelfChoiceRepositoryProvider)
            .addChoices(changes, keepStored: keepStored);
        return true;
      } on Object catch (error, stackTrace) {
        _log('Failed to save shelf choices.', error, stackTrace);
        if (ref.mounted && previous != null) state = AsyncData(previous);
        return false;
      }
    } finally {
      link.close();
    }
  }

  void _log(String message, Object error, StackTrace stackTrace) => log(
    message,
    name: 'ShoppingShelfChoicesController',
    error: error,
    stackTrace: stackTrace,
  );
}
