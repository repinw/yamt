import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_entry_mutation.dart';
import 'package:yamt/features/calories/provider/calorie_entry_mutations.dart';
import 'package:yamt/features/diary/domain/diary_food_log_session.dart';

part 'diary_food_log_mutation_adapter.g.dart';

/// Adapts calorie mutations for a single Diary input session.
@Riverpod(keepAlive: true)
DiaryFoodLogMutationAdapter diaryFoodLogMutationAdapter(Ref ref) {
  return DiaryFoodLogMutationAdapter(
    mutations: ref.read(calorieEntryMutationsProvider),
  );
}

/// Listens to the Calories mutation stream without exposing it to Diary UI.
class DiaryFoodLogMutationAdapter {
  /// Creates a Diary mutation adapter.
  const DiaryFoodLogMutationAdapter({required CalorieEntryMutations mutations})
    : _mutations = mutations;

  final CalorieEntryMutations _mutations;

  /// Records mutations in the supplied Diary input session.
  StreamSubscription<CalorieEntryMutation> listen(
    DiaryFoodLogSession session,
  ) {
    return _mutations.events.listen(session.record);
  }
}
