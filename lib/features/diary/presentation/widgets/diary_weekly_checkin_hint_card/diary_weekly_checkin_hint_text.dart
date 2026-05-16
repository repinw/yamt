import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_weekly_checkin_messages.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Title text for the diary weekly check-in hint.
class DiaryWeeklyCheckInHintTitle extends StatelessWidget {
  /// Creates diary weekly check-in hint title text.
  const DiaryWeeklyCheckInHintTitle({required this.checkInData, super.key});

  /// Weekly check-in data.
  final DiaryWeeklyCheckInData checkInData;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Text(
      _title(l10n),
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  String _title(AppLocalizations l10n) {
    if (checkInData.hasPending) {
      return checkInData.isBlocked
          ? l10n.caloriesWeeklyCheckInHintBlockedTitle
          : l10n.caloriesWeeklyCheckInHintReadyTitle;
    }
    return switch (checkInData.freshness) {
      CalorieLearnedTdeeFreshness.urgent =>
        l10n.caloriesWeeklyCheckInHintUrgentTitle,
      _ => l10n.caloriesWeeklyCheckInHintStaleTitle,
    };
  }
}

/// Body text for the diary weekly check-in hint.
class DiaryWeeklyCheckInHintBody extends StatelessWidget {
  /// Creates diary weekly check-in hint body text.
  const DiaryWeeklyCheckInHintBody({required this.checkInData, super.key});

  /// Weekly check-in data.
  final DiaryWeeklyCheckInData checkInData;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Text(_body(l10n, locale));
  }

  String _body(AppLocalizations l10n, String locale) {
    if (checkInData.hasPending) {
      final pending = checkInData.pendingWeeklyCheckIn;
      final baseMessage = checkInData.isBlocked
          ? resolveDiaryWeeklyCheckInBlockedMessage(
              l10n: l10n,
              checkInData: checkInData,
              locale: locale,
              fallbackMessage: l10n.caloriesWeeklyCheckInHintBlockedBody,
            )
          : l10n.caloriesWeeklyCheckInHintReadyBody;
      if (pending == null) {
        return baseMessage;
      }
      final rangeFormat = DateFormat.MMMd(locale);
      return '$baseMessage '
          '${rangeFormat.format(pending.windowStartDate)} - '
          '${rangeFormat.format(pending.windowEndDate)}.';
    }
    return switch (checkInData.freshness) {
      CalorieLearnedTdeeFreshness.urgent =>
        l10n.caloriesWeeklyCheckInHintUrgentBody,
      _ => l10n.caloriesWeeklyCheckInHintStaleBody,
    };
  }
}
