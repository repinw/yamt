import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';

part 'diary_meal_shares_controller.g.dart';

const _mealSharesKey = 'diary_meal_shares_v1';

/// How the user splits the day's kcal over the meals, saved on the device.
@riverpod
class DiaryMealSharesController extends _$DiaryMealSharesController {
  @override
  DiaryMealShares build() {
    final stored = ref
        .watch(appPreferencesProvider)
        .getStringSync(_mealSharesKey);
    return (stored == null ? null : DiaryMealShares.decode(stored)) ??
        DiaryMealShares.standard;
  }

  /// Switches to [shares] and saves them.
  Future<void> select(DiaryMealShares shares) async {
    state = shares;
    await ref
        .read(appPreferencesProvider)
        .setString(_mealSharesKey, shares.encode());
  }

  /// Goes back to [DiaryMealShares.standard].
  Future<void> reset() async {
    state = DiaryMealShares.standard;
    await ref.read(appPreferencesProvider).remove(_mealSharesKey);
  }
}
