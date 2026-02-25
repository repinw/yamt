import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

void main() {
  test('empty settings have no goal', () {
    const settings = CalorieGoalSettings.empty();

    expect(settings.hasGoal, isFalse);
    expect(settings.dailyKcalGoal, isNull);
    expect(settings.updatedAt, isNull);
  });

  test('json conversion preserves goal values', () {
    final settings = CalorieGoalSettings(
      dailyKcalGoal: 2300,
      updatedAt: DateTime(2026, 2, 25, 11),
    );

    final decoded = CalorieGoalSettings.fromJson(settings.toJson());

    expect(decoded.dailyKcalGoal, 2300);
    expect(decoded.updatedAt, DateTime(2026, 2, 25, 11));
  });
}
