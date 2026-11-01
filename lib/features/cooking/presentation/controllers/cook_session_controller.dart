import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';

part 'cook_session_controller.g.dart';

/// Holds one cooking of the recipe `recipeId` while its page is open.
@riverpod
class CookSessionController extends _$CookSessionController {
  @override
  CookSession build(String recipeId) => const CookSession();

  /// Cooks [portions] portions; every line opens again.
  void setPortions(int portions) {
    if (portions < 1) return;
    state = state.withPortions(portions);
  }

  /// Settles the line [lineId] with [takes] from the Vorrat; on the second
  /// page when [onSecondPage].
  void assign(
    String lineId,
    List<ItemTake> takes, {
    bool onSecondPage = false,
  }) {
    state = state.withLine(
      lineId,
      LineAssigned(List.unmodifiable(takes)),
      onSecondPage: onSecondPage,
    );
  }

  /// Turns the suggestion of the line [lineId] down: the second page asks
  /// about it.
  void reject(String lineId) {
    state = state.withLine(lineId, const LineRejected());
  }

  /// Leaves the line [lineId] out of this cooking.
  void omit(String lineId) {
    state = state.withLine(lineId, const LineOmitted(), onSecondPage: true);
  }

  /// Opens the line [lineId] again.
  void reopen(String lineId) {
    state = state.withLine(lineId, const LineOpen());
  }

  /// Moves to [step].
  void goTo(CookStep step) {
    state = state.at(step);
  }

  /// Chooses [pot] for the meal.
  void choosePot(CookPot pot) {
    state = state.withPot(pot);
  }
}
