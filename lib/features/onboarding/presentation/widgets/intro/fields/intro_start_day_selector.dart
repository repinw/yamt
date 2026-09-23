import 'dart:async';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/onboarding/domain/tracking_start_day.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_choice_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Lets the user choose the day the first tracked week starts.
///
/// Days before the start stay practice days: food can be logged, but nothing
/// counts for the first week.
class IntroStartDaySelector extends StatelessWidget {
  /// Creates the start day selector.
  const new({
    required this.today,
    required this.startDate,
    required this.onChanged,
    super.key,
  });

  /// Current day.
  final DateTime today;

  /// Selected start day.
  final DateTime startDate;

  /// Called with the newly selected start day.
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.MMMEd(locale);
    final normalizedToday = normalizeDiaryDay(today);
    final tomorrow = nextDiaryDay(normalizedToday);
    final startsToday = isSameDiaryDay(startDate, normalizedToday);
    final startsTomorrow = isSameDiaryDay(startDate, tomorrow);
    final startsOnOtherDay = !startsToday && !startsTomorrow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.introStartDayTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        IntroChoiceCard(
          key: CalorieGoalOnboardingKeys.introStartTodayChoice,
          icon: Icons.today_outlined,
          title: l10n.introStartDayToday,
          subtitle: l10n.introStartDayTodayHint,
          trailingLabel: dateFormat.format(normalizedToday),
          isSelected: startsToday,
          onTap: () => onChanged(normalizedToday),
        ),
        const SizedBox(height: AppSpacing.xs),
        IntroChoiceCard(
          key: CalorieGoalOnboardingKeys.introStartTomorrowChoice,
          icon: Icons.wb_twilight_outlined,
          title: l10n.introStartDayTomorrow,
          subtitle: l10n.introStartDayTomorrowHint,
          trailingLabel: dateFormat.format(tomorrow),
          isSelected: startsTomorrow,
          onTap: () => onChanged(tomorrow),
        ),
        const SizedBox(height: AppSpacing.xs),
        IntroChoiceCard(
          key: CalorieGoalOnboardingKeys.introStartOtherDayChoice,
          icon: Icons.edit_calendar_outlined,
          title: l10n.introStartDayOther,
          subtitle: l10n.introStartDayOtherHint,
          trailingLabel: startsOnOtherDay ? dateFormat.format(startDate) : null,
          isSelected: startsOnOtherDay,
          onTap: () => unawaited(_pickOtherDay(context)),
        ),
      ],
    );
  }

  Future<void> _pickOtherDay(BuildContext context) async {
    final firstDate = normalizeDiaryDay(today);
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: firstDate,
      lastDate: latestTrackingStartDay(today),
    );
    if (picked == null || !context.mounted) {
      return;
    }
    onChanged(picked);
  }
}

/// Label of the finish action for a start on [startDate].
String introStartActionLabel(
  AppLocalizations l10n, {
  required DateTime today,
  required DateTime startDate,
  required String locale,
}) {
  final normalizedToday = normalizeDiaryDay(today);
  if (isSameDiaryDay(startDate, normalizedToday)) {
    return l10n.introStartTodayAction;
  }
  if (isSameDiaryDay(startDate, nextDiaryDay(normalizedToday))) {
    return l10n.introStartTomorrowAction;
  }
  return l10n.introStartOnDateAction(DateFormat.MMMd(locale).format(startDate));
}
