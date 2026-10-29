import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diary_budget_eaten_view_controller.g.dart';

/// Whether the budget card's numbers show what was eaten instead of what is
/// left ("Übrig | Gegessen"). Starts on what is left whenever the diary
/// opens.
@riverpod
class DiaryBudgetEatenViewController extends _$DiaryBudgetEatenViewController {
  @override
  bool build() => false;

  /// Shows what was eaten.
  void showEaten() => state = true;

  /// Shows what is left.
  void showLeft() => state = false;
}
