import 'dart:async';

import 'package:yamt/features/shoppinglist/data/shopping_shelf_choice_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf_placement.dart';

/// Keeps shelf choices in memory and emits every save.
class FakeShoppingShelfChoiceRepository
    implements ShoppingShelfChoiceRepository {
  /// Starts with [initial] choices.
  new({ShoppingShelfChoices initial = const {}}) : choices = initial;

  /// The last stored choices.
  ShoppingShelfChoices choices;

  /// Whether a save fails.
  bool failSaves = false;

  /// The error the watch fails with, after a turn of the event loop.
  Error? watchError;

  final _changes = StreamController<ShoppingShelfChoices>.broadcast();

  @override
  Stream<ShoppingShelfChoices> watchChoices() async* {
    if (watchError case final error?) {
      await Future<void>.delayed(Duration.zero);
      throw error;
    }
    yield choices;
    yield* _changes.stream;
  }

  @override
  Future<void> addChoices(
    ShoppingShelfChoices changes, {
    bool keepStored = false,
  }) async {
    if (failSaves) throw StateError('Save failed.');
    final next = keepStored
        ? {...changes, ...choices}
        : {...choices, ...changes};
    choices = next;
    _changes.add(next);
  }

  /// Closes the stream.
  Future<void> dispose() => _changes.close();
}
