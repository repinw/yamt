import 'package:yamt/features/calories/domain/calorie_entry.dart';

/// Kind of a successfully persisted local change.
enum CalorieEntryMutationKind {
  /// A newly recorded food.
  created,

  /// An existing entry was edited.
  updated,

  /// An entry was removed.
  deleted,
}

/// A local commit, independent of optimistic state and remote subscriptions.
class CalorieEntryMutation {
  /// Creates a committed mutation.
  const CalorieEntryMutation({
    required this.kind,
    required this.entryId,
    this.entry,
  });

  /// Operation that completed successfully.
  final CalorieEntryMutationKind kind;

  /// Stable entry identifier, including for deletions.
  final String entryId;

  /// Saved values, when this is not a deletion.
  final CalorieEntry? entry;
}
