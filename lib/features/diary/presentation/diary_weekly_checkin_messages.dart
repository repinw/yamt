import 'package:intl/intl.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Resolves localized blocked reason text for diary weekly check-in UI.
String resolveDiaryWeeklyCheckInBlockedMessage({
  required AppLocalizations l10n,
  required DiaryWeeklyCheckInData checkInData,
  required String locale,
  required String fallbackMessage,
}) {
  final reason = checkInData.blockedReason;
  final pending = checkInData.pendingWeeklyCheckIn;
  final dateFormat = DateFormat.yMMMd(locale);
  final missingWeightDates = checkInData.missingWeightDays
      .map(dateFormat.format)
      .toList(growable: false);
  return switch (reason) {
    CalorieWeeklyCheckInBlockedReason.missingIntakeDays =>
      l10n.caloriesWeeklyCheckInBlockedMissingIntake,
    CalorieWeeklyCheckInBlockedReason.tooManyMissingIntakeDays =>
      l10n.caloriesWeeklyCheckInBlockedTooManyMissingIntake,
    CalorieWeeklyCheckInBlockedReason.skippedDayWithoutPriorAverage =>
      l10n.caloriesWeeklyCheckInBlockedSkippedWithoutAverage,
    CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight
        when missingWeightDates.length > 1 =>
      l10n.caloriesWeeklyCheckInBlockedMissingWeightDates(
        missingWeightDates.join(', '),
      ),
    CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight =>
      l10n.caloriesWeeklyCheckInBlockedMissingStartWeightOn(
        dateFormat.format(
          checkInData.missingWeightDays.isNotEmpty
              ? checkInData.missingWeightDays.first
              : pending?.windowStartDate ?? DateTime.now(),
        ),
      ),
    CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight
        when missingWeightDates.length > 1 =>
      l10n.caloriesWeeklyCheckInBlockedMissingWeightDates(
        missingWeightDates.join(', '),
      ),
    CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight =>
      l10n.caloriesWeeklyCheckInBlockedMissingEndWeightOn(
        dateFormat.format(
          checkInData.missingWeightDays.isNotEmpty
              ? checkInData.missingWeightDays.last
              : pending?.windowEndDate ?? DateTime.now(),
        ),
      ),
    CalorieWeeklyCheckInBlockedReason.unstableWeightData =>
      l10n.caloriesWeeklyCheckInBlockedUnstableWeight,
    null => fallbackMessage,
  };
}
