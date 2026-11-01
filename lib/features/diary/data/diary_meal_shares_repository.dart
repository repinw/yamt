import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';

part 'diary_meal_shares_repository.g.dart';

const _mealSharesKey = 'diary_meal_shares_v1';

/// Stores how the user splits the day's kcal over the meals, in the app
/// preferences of this device.
class DiaryMealSharesRepository {
  /// Creates the repository on the given app preferences.
  const new(this._preferences);

  final AppPreferences _preferences;

  /// The saved shares; [DiaryMealShares.standard] when none or broken ones
  /// are saved.
  DiaryMealShares loadShares() {
    final stored = _preferences.getStringSync(_mealSharesKey);
    return (stored == null ? null : DiaryMealShares.decode(stored)) ??
        DiaryMealShares.standard;
  }

  /// Saves [shares].
  Future<void> saveShares(DiaryMealShares shares) async {
    await _preferences.setString(_mealSharesKey, shares.encode());
  }

  /// Deletes the saved shares, so [loadShares] gives the standard ones.
  Future<void> deleteShares() async {
    await _preferences.remove(_mealSharesKey);
  }
}

/// Provides the meal shares repository.
@riverpod
DiaryMealSharesRepository diaryMealSharesRepository(Ref ref) {
  return DiaryMealSharesRepository(ref.watch(appPreferencesProvider));
}
