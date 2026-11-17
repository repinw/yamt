import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_week_card_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/calories/domain/calorie_week_balance.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_day_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One day of the week card: its field, its name, and with [showNumber] the
/// number under it.
///
/// A finished day's field and today's fill from the left like the budget
/// card's kcal line, against the budget of that day: what was eaten up to the
/// budget, and the part above it in the miss color. The field then spans the
/// whole day, so a day far over shows its overage in proportion. A day with
/// less budget starts with a dark piece for the carryover, a day with more
/// ends with a dashed one. A coming day is a dashed outline, a pause day is
/// hatched, and a day without entries is an empty track.
class DiaryWeekDayField extends StatelessWidget {
  /// Creates the field of [day], the day at [index] of the run.
  const new({
    required this.index,
    required this.day,
    required this.balance,
    required this.today,
    required this.isShown,
    required this.showNumber,
    super.key,
  });

  /// Position of the day in the run, from 0.
  final int index;

  /// The day and its budget.
  final WeekBalanceDay day;

  /// The week the day belongs to.
  final WeekBalance balance;

  /// The real today.
  final DateTime today;

  /// Whether the diary shows this day, which gets the frame.
  final bool isShown;

  /// Whether the number under a finished day shows.
  final bool showNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final isToday = isSameLocalDay(day.date, today);
    // German short weekdays end with a dot, which the card leaves out.
    final name = isToday
        ? l10n.diaryWeekToday
        : DateFormat.E(locale).format(day.date).replaceAll('.', '');
    final small = textTheme.labelSmall?.copyWith(fontFamily: AppFonts.geist);
    final number = showNumber && day.date.isBefore(normalizeLocalDay(today))
        ? _number(l10n, colors, Theme.of(context).colorScheme.error, locale)
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppWeekCard.textGap,
      children: [
        SizedBox(
          height: AppWeekCard.fieldHeight,
          width: double.infinity,
          child: DiaryWeekDayBar(
            day: day,
            balance: balance,
            today: today,
            isShown: isShown,
          ),
        ),
        _Caption(
          name,
          textKey: DiaryWeekCardKeys.dayName(index),
          style: small?.copyWith(
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
            color: isToday ? colors.ink : colors.muted,
          ),
        ),
        if (number != null)
          _Caption(
            number.text,
            textKey: DiaryWeekCardKeys.dayNumber(index),
            style: small?.copyWith(
              fontWeight: FontWeight.w600,
              color: number.color,
            ),
          ),
      ],
    );
  }

  /// The number under a finished day, or null when the day is within
  /// [AppWeekCard.numberThresholdKcal] of its budget.
  ({String text, Color color})? _number(
    AppLocalizations l10n,
    FoodLabelColors colors,
    Color error,
    String locale,
  ) {
    if (day.isPauseDay) {
      return (text: l10n.diaryWeekDayPause, color: colors.muted);
    }
    if (!day.hasEntries) {
      return (text: l10n.diaryWeekDayEmpty, color: colors.muted);
    }
    final difference = day.eatenKcal - day.budgetKcal;
    if (difference.abs() < AppWeekCard.numberThresholdKcal) {
      return null;
    }
    final kcal = NumberFormat.decimalPattern(locale)
        .format(difference.abs().round());
    final over = difference > 0;
    // The miss is going over, or for a weight goal of gaining, falling short.
    final isMiss = over == balance.overIsMiss;
    return (
      text: over ? l10n.diaryWeekDayOver(kcal) : l10n.diaryWeekDayUnder(kcal),
      color: isMiss
          ? error
          : over
          ? colors.ink
          : colors.muted,
    );
  }
}

/// A line of text under a field, shrunk to fit its narrow column.
class _Caption extends StatelessWidget {
  const new(this.text, {required this.textKey, required this.style});

  final String text;
  final Key textKey;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, key: textKey, style: style, maxLines: 1),
    );
  }
}
