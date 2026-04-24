import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_weekly_checkin_messages.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_provider.dart';
import 'package:yamt/l10n/app_localizations_en.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  test('returns fallback when no blocked reason exists', () {
    final l10n = AppLocalizationsEn();

    final message = resolveCalorieWeeklyCheckInBlockedMessage(
      l10n: l10n,
      viewModel: _viewModel(blockedReason: null),
      locale: 'en',
      fallbackMessage: 'Fallback',
    );

    expect(message, 'Fallback');
  });

  test('formats multiple missing weight dates', () {
    final l10n = AppLocalizationsEn();
    final missingWeightDays = <DateTime>[
      DateTime(2026, 4, 1),
      DateTime(2026, 4, 7),
    ];

    final message = resolveCalorieWeeklyCheckInBlockedMessage(
      l10n: l10n,
      viewModel: _viewModel(
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

  test('formats single missing end weight from pending window', () {
    final l10n = AppLocalizationsEn();
    final pending = PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: DateTime(2026, 4),
      windowEndDate: DateTime(2026, 4, 7),
      dueDate: DateTime(2026, 4, 8),
    );

    final message = resolveCalorieWeeklyCheckInBlockedMessage(
      l10n: l10n,
      viewModel: _viewModel(
        blockedReason: CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight,
        missingWeightDays: <DateTime>[DateTime(2026, 4, 5)],
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

CalorieWeeklyCheckInViewModel _viewModel({
  required CalorieWeeklyCheckInBlockedReason? blockedReason,
  List<DateTime> missingWeightDays = const <DateTime>[],
  PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn,
}) {
  return CalorieWeeklyCheckInViewModel(
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
