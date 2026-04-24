import 'package:intl/intl.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Resolves localized blocked reason text for weekly check-in UI.
String resolveCalorieWeeklyCheckInBlockedMessage({
  required AppLocalizations l10n,
  required CalorieWeeklyCheckInViewModel viewModel,
  required String locale,
  required String fallbackMessage,
}) {
  final reason = viewModel.blockedReason;
  final pending = viewModel.pendingWeeklyCheckIn;
  final dateFormat = DateFormat.yMMMd(locale);
  final missingWeightDates = viewModel.missingWeightDays
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
          pending?.windowStartDate ?? viewModel.missingWeightDays.first,
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
          pending?.windowEndDate ?? viewModel.missingWeightDays.last,
        ),
      ),
    CalorieWeeklyCheckInBlockedReason.unstableWeightData =>
      l10n.caloriesWeeklyCheckInBlockedUnstableWeight,
    null => fallbackMessage,
  };
}
