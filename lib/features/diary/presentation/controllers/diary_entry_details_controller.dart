import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_entry_details_state.dart';

part 'diary_entry_details_controller.g.dart';

/// Controller of the details page of one logged diary entry.
///
/// Holds the entry and the amount typed on the ruler. The page saves
/// changes through the Calories details flow and hands the result back
/// here. The state is null when the entry does not exist.
@riverpod
class DiaryEntryDetailsController extends _$DiaryEntryDetailsController {
  @override
  FutureOr<DiaryEntryDetailsState?> build(String entryId) {
    final repository = ref.watch(calorieLogRepositoryProvider);
    final today = ref.watch(clockProvider)();
    // The cached copy renders on the first frame, so the image from the
    // diary row has a place to land.
    final cached = repository.cachedById(entryId);
    if (cached != null) {
      return _initialState(cached, today);
    }
    return repository
        .getById(entryId)
        .then((entry) => entry == null ? null : _initialState(entry, today));
  }

  /// Takes a typed amount.
  void setAmountText(String text) {
    _update((current) => current.copyWith(amountText: text));
  }

  /// Takes an amount picked on the ruler.
  void pickAmount(double amount) {
    _update(
      (current) => current.copyWith(amountText: diaryEntryAmountText(amount)),
    );
  }

  /// Shows the entry in [mealType] while the move saves. Returns the move to
  /// save, or null when the entry is already in that meal.
  DiaryEntryMove? moveToMeal(MealType mealType) {
    final entry = state.value?.entry;
    if (entry == null || entry.mealType == mealType) {
      return null;
    }
    return _move(entry, entry.copyWith(mealType: mealType));
  }

  /// Shows the entry on [day], at its old time of day, while the move saves.
  /// Returns the move to save, or null when the entry is already on that
  /// day.
  DiaryEntryMove? moveToDay(DateTime day) {
    final entry = state.value?.entry;
    if (entry == null || isSameCalendarDay(entry.loggedAt, day)) {
      return null;
    }
    final time = entry.loggedAt;
    return _move(
      entry,
      entry.copyWith(
        loggedAt: DateTime(
          day.year,
          day.month,
          day.day,
          time.hour,
          time.minute,
          time.second,
        ),
      ),
    );
  }

  /// Shows [entry], for example the stored one again after a failed move.
  void showEntry(CalorieEntry entry) {
    _update((current) => current.copyWith(entry: entry));
  }

  DiaryEntryMove _move(CalorieEntry previous, CalorieEntry moved) {
    final updated = moved.copyWith(updatedAt: ref.read(clockProvider)());
    showEntry(updated);
    return (previous: previous, updated: updated);
  }

  void _update(
    DiaryEntryDetailsState Function(DiaryEntryDetailsState current) change,
  ) {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(change(current));
  }

  static DiaryEntryDetailsState _initialState(
    CalorieEntry entry,
    DateTime today,
  ) {
    return DiaryEntryDetailsState(
      entry: entry,
      amountText: diaryEntryAmountText(entry.consumedAmount),
      today: today,
    );
  }
}
