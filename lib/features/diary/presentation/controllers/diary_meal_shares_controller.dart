import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/diary/data/diary_meal_shares_repository.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';

part 'diary_meal_shares_controller.g.dart';

/// How the user splits the day's kcal over the meals, saved on the device.
@riverpod
class DiaryMealSharesController extends _$DiaryMealSharesController {
  @override
  DiaryMealShares build() =>
      ref.watch(diaryMealSharesRepositoryProvider).loadShares();

  /// Switches to [shares] and saves them.
  Future<void> select(DiaryMealShares shares) async {
    state = shares;
    await ref.read(diaryMealSharesRepositoryProvider).saveShares(shares);
  }

  /// Goes back to [DiaryMealShares.standard].
  Future<void> reset() async {
    state = DiaryMealShares.standard;
    await ref.read(diaryMealSharesRepositoryProvider).deleteShares();
  }
}
