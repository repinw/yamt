import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/plan_shortage_reminders.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';

void main() {
  final now = DateTime(2026, 10, 18, 12);
  final tomorrow = DateTime(2026, 10, 19);

  test('a plan day gets a reminder the day before at the set time', () {
    final reminders = planShortageReminders(
      {tomorrow: 2, DateTime(2026, 10, 22): 1},
      now: now,
      minuteOfDay: 17 * 60 + 30,
      quietDays: const {},
    );

    expect(reminders, [
      (day: tomorrow, at: DateTime(2026, 10, 18, 17, 30), count: 2),
      (
        day: DateTime(2026, 10, 22),
        at: DateTime(2026, 10, 21, 17, 30),
        count: 1,
      ),
    ]);
  });

  test('no reminder for today, a passed time, quiet days, or none missing', () {
    final reminders = planShortageReminders(
      {
        DateTime(2026, 10, 18): 3,
        tomorrow: 2,
        DateTime(2026, 10, 20): 1,
        DateTime(2026, 10, 21): 0,
      },
      now: DateTime(2026, 10, 18, 18, 1),
      minuteOfDay: 17 * 60,
      quietDays: {DateTime(2026, 10, 20)},
    );

    expect(reminders, isEmpty);
  });

  test('a reminder that passed within the hour stays for the pending one', () {
    final reminders = planShortageReminders(
      {tomorrow: 2},
      now: DateTime(2026, 10, 18, 17, 30),
      minuteOfDay: 17 * 60,
      quietDays: const {},
    );

    expect(reminders, [
      (day: tomorrow, at: DateTime(2026, 10, 18, 17), count: 2),
    ]);
  });

  test('missingByDay counts the needs of all meals of a day', () {
    ShoppingPlanNeed need(String name, MealType meal) => ShoppingPlanNeed(
      name: name,
      day: tomorrow,
      mealType: meal,
      amount: null,
      inMilliliters: false,
      isPartial: false,
    );

    final counts = missingByDay([
      (
        day: DateTime(2026, 10, 19, 8),
        mealType: MealType.breakfast,
        needs: [need('Milch', MealType.breakfast)],
      ),
      (
        day: DateTime(2026, 10, 19, 19),
        mealType: MealType.dinner,
        needs: [need('Reis', MealType.dinner), need('Ei', MealType.dinner)],
      ),
    ]);

    expect(counts, {tomorrow: 3});
  });

  test('ids and payloads name the plan day', () {
    expect(planShortageNotificationId(tomorrow), 120261019);
    expect(isPlanShortageNotificationId(120261019), isTrue);
    expect(isPlanShortageNotificationId(7), isFalse);
    expect(
      planShortageReminderDay(planShortageReminderPayload(tomorrow)),
      tomorrow,
    );
    expect(planShortageReminderDay('weigh-in:2026-10-19'), isNull);
  });
}
