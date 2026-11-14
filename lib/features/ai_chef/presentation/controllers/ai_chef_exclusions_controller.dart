import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_exclusions_repository.dart';
import 'package:yamt/features/ai_chef/domain/ai_chef_exclusions.dart';

part 'ai_chef_exclusions_controller.g.dart';

/// Holds the ingredients the user never wants in an AI recipe.
@riverpod
class AiChefExclusionsController extends _$AiChefExclusionsController {
  Future<bool> _lastChange = Future<bool>.value(true);

  /// The list the last change saved, until the stream brings it. A snapshot
  /// of an older save can still arrive before; it must neither show nor be
  /// the base of the next change.
  AiChefExclusions? _lastSaved;

  @override
  Stream<AiChefExclusions> build() {
    return ref.watch(aiChefExclusionsRepositoryProvider).watchExclusions().map((
      stored,
    ) {
      final saved = _lastSaved;
      if (saved == null || stored == saved) {
        _lastSaved = null;
        return stored;
      }
      return saved;
    });
  }

  /// Adds [ingredient] to the list.
  ///
  /// Returns false when the list is not loaded yet or saving fails. A blank
  /// or repeated [ingredient] changes nothing and returns true.
  Future<bool> addIngredient(String ingredient) {
    return _change((exclusions) => exclusions.add(ingredient));
  }

  /// Removes [ingredient] from the list. Returns false when saving fails.
  Future<bool> removeIngredient(String ingredient) {
    return _change((exclusions) => exclusions.remove(ingredient));
  }

  /// Runs changes one after the other, so each starts from the list the one
  /// before saved.
  Future<bool> _change(
    AiChefExclusions Function(AiChefExclusions exclusions) change,
  ) {
    final next = _lastChange.then((_) => _apply(change));
    _lastChange = next;
    return next;
  }

  Future<bool> _apply(
    AiChefExclusions Function(AiChefExclusions exclusions) change,
  ) async {
    if (!ref.mounted) {
      return false;
    }
    final current = _lastSaved ?? state.value;
    if (current == null) {
      return false;
    }
    final next = change(current);
    if (next == current) {
      return true;
    }
    try {
      await ref.read(aiChefExclusionsRepositoryProvider).saveExclusions(next);
      _lastSaved = next;
      // The stream follows soon; until then a request already sends [next].
      if (ref.mounted) {
        state = AsyncData(next);
      }
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save AI Chef exclusions.',
        name: 'AiChefExclusionsController',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
