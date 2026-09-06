import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_entry_mutation.dart';

part 'calorie_entry_mutations.g.dart';

/// Local commit notifications. No history is replayed to new listeners.
class CalorieEntryMutations {
  final _controller = StreamController<CalorieEntryMutation>.broadcast(
    sync: true,
  );

  /// Only changes committed in this running application.
  Stream<CalorieEntryMutation> get events => _controller.stream;

  /// Publishes a successful persistence operation.
  void record(CalorieEntryMutation mutation) => _controller.add(mutation);

  /// Releases listeners when the provider container is disposed.
  void dispose() => unawaited(_controller.close());
}

/// Shared local mutation stream, owned by Calories rather than Diary UI.
@Riverpod(keepAlive: true)
CalorieEntryMutations calorieEntryMutations(Ref ref) {
  final mutations = CalorieEntryMutations();
  ref.onDispose(mutations.dispose);
  return mutations;
}
