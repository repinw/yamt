import 'dart:async';

import 'package:yamt/features/ai_chef/data/ai_chef_exclusions_repository.dart';
import 'package:yamt/features/ai_chef/domain/ai_chef_exclusions.dart';

/// Holds the "Bloß nicht" list in memory: it emits the stored list at once
/// and every save after it.
class FakeAiChefExclusionsRepository implements AiChefExclusionsRepository {
  /// Creates the list with [ingredients].
  new([List<String> ingredients = const <String>[]])
    : stored = AiChefExclusions(ingredients: ingredients);

  /// The stored list.
  AiChefExclusions stored;

  /// Whether saving fails.
  bool saveFails = false;

  final _saves = StreamController<AiChefExclusions>.broadcast();

  @override
  Stream<AiChefExclusions> watchExclusions() async* {
    yield stored;
    yield* _saves.stream;
  }

  @override
  Future<void> saveExclusions(AiChefExclusions exclusions) async {
    if (saveFails) throw StateError('offline');
    stored = exclusions;
    _saves.add(exclusions);
  }
}
