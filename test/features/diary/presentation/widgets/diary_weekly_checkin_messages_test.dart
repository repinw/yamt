import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart'
    show DiaryWeeklyCheckInData;
import 'package:yamt/features/diary/presentation/diary_weekly_checkin_messages.dart';
import 'package:yamt/l10n/app_localizations_en.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  test('returns fallback when no blocked reason exists', () {
    final l10n = AppLocalizationsEn();

    final message = resolveDiaryWeeklyCheckInBlockedMessage(
      l10n: l10n,
      checkInData: _checkInData(blockedReason: null),
      locale: 'en',
      fallbackMessage: 'Fallback',
    );

    expect(message, 'Fallback');
  });

  test('returns direct blocked reason messages', () {
    final l10n = AppLocalizationsEn();
    final cases = <(CalorieWeeklyCheckInBlockedReason, String)>[
      (
        CalorieWeeklyCheckInBlockedReason.missingIntakeDays,
        l10n.caloriesWeeklyCheckInBlockedMissingIntake,
      ),
      (
        CalorieWeeklyCheckInBlockedReason.tooManyMissingIntakeDays,
        l10n.caloriesWeeklyCheckInBlockedTooManyMissingIntake,
      ),
      (
        CalorieWeeklyCheckInBlockedReason.skippedDayWithoutPriorAverage,
        l10n.caloriesWeeklyCheckInBlockedSkippedWithoutAverage,
      ),
      (
        CalorieWeeklyCheckInBlockedReason.unstableWeightData,
        l10n.caloriesWeeklyCheckInBlockedUnstableWeight,
      ),
    ];

    for (final (reason, expectedMessage) in cases) {
      final message = resolveDiaryWeeklyCheckInBlockedMessage(
        l10n: l10n,
        checkInData: _checkInData(blockedReason: reason),
        locale: 'en',
        fallbackMessage: 'Fallback',
      );

      expect(message, expectedMessage);
    }
  });

  test('formats multiple missing weight dates', () {
    final l10n = AppLocalizationsEn();
    final missingWeightDays = <DateTime>[
      DateTime(2026, 4),
      DateTime(2026, 4, 7),
    ];

    final message = resolveDiaryWeeklyCheckInBlockedMessage(
      l10n: l10n,
      checkInData: _checkInData(
        blockedReason:
            CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight,
        missingWeightDays: missingWeightDays,
      ),
      locale: 'en',
      fallbackMessage: 'Fallback',
    );

    expect(
      message,
      l10n.caloriesWeeklyCheckInBlockedMissingWeightDates(
        'Apr 1, 2026, Apr 7, 2026',
      ),
    );
  });

  test('formats single missing start weight from pending window', () {
    final l10n = AppLocalizationsEn();
    final pending = PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: DateTime(2026, 4),
      windowEndDate: DateTime(2026, 4, 7),
      dueDate: DateTime(2026, 4, 8),
    );

    final message = resolveDiaryWeeklyCheckInBlockedMessage(
      l10n: l10n,
      checkInData: _checkInData(
        blockedReason:
            CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight,
        pendingWeeklyCheckIn: pending,
      ),
      locale: 'en',
      fallbackMessage: 'Fallback',
    );

    expect(
      message,
      l10n.caloriesWeeklyCheckInBlockedMissingStartWeightOn('Apr 1, 2026'),
    );
  });

  test('formats multiple missing end weight dates', () {
    final l10n = AppLocalizationsEn();
    final missingWeightDays = <DateTime>[
      DateTime(2026, 4, 6),
      DateTime(2026, 4, 7),
    ];

    final message = resolveDiaryWeeklyCheckInBlockedMessage(
      l10n: l10n,
      checkInData: _checkInData(
        blockedReason: CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight,
        missingWeightDays: missingWeightDays,
      ),
      locale: 'en',
      fallbackMessage: 'Fallback',
    );

    expect(
      message,
      l10n.caloriesWeeklyCheckInBlockedMissingWeightDates(
        'Apr 6, 2026, Apr 7, 2026',
      ),
    );
  });

  test('formats single missing end weight from missing date', () {
    final l10n = AppLocalizationsEn();
    final pending = PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: DateTime(2026, 4),
      windowEndDate: DateTime(2026, 4, 7),
      dueDate: DateTime(2026, 4, 8),
    );

    final message = resolveDiaryWeeklyCheckInBlockedMessage(
      l10n: l10n,
      checkInData: _checkInData(
        blockedReason: CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight,
        missingWeightDays: <DateTime>[DateTime(2026, 4, 5)],
        pendingWeeklyCheckIn: pending,
      ),
      locale: 'en',
      fallbackMessage: 'Fallback',
    );

    expect(
      message,
      l10n.caloriesWeeklyCheckInBlockedMissingEndWeightOn('Apr 5, 2026'),
    );
  });

  test('formats single missing end weight from pending window', () {
    final l10n = AppLocalizationsEn();
    final pending = PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: DateTime(2026, 4),
      windowEndDate: DateTime(2026, 4, 7),
      dueDate: DateTime(2026, 4, 8),
    );

    final message = resolveDiaryWeeklyCheckInBlockedMessage(
      l10n: l10n,
      checkInData: _checkInData(
        blockedReason: CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight,
        pendingWeeklyCheckIn: pending,
      ),
      locale: 'en',
      fallbackMessage: 'Fallback',
    );

    expect(
      message,
      l10n.caloriesWeeklyCheckInBlockedMissingEndWeightOn('Apr 7, 2026'),
    );
  });
}

DiaryWeeklyCheckInData _checkInData({
  required CalorieWeeklyCheckInBlockedReason? blockedReason,
  List<DateTime> missingWeightDays = const <DateTime>[],
  PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn,
}) {
  return DiaryWeeklyCheckInData(
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
    shouldAutoOpen: false,
    days: const <CalorieWeeklyCheckInWindowDay>[],
    calculation: null,
    blockedReason: blockedReason,
    missingIntakeDays: const <DateTime>[],
    missingWeightDays: missingWeightDays,
    freshness: CalorieLearnedTdeeFreshness.fresh,
    latestLearnedTdeeAt: null,
    lowConfidence: false,
  );
}
