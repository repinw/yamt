import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calorie_balance_now_provider.g.dart';

/// Defines calorie balance now typedef.
typedef CalorieBalanceNow = DateTime Function();

/// Calorie balance now.
@Riverpod(keepAlive: true)
CalorieBalanceNow calorieBalanceNow(Ref ref) {
  return DateTime.now;
}
