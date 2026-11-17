import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_week_card_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/calories/domain/calorie_week_balance.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_card_painters.dart';

/// The field of a day in the week card: its track, its parts, and with
/// [isShown] the frame. The parts are told apart by their keys in
/// `DiaryWeekCardKeys`.
class DiaryWeekDayBar extends StatelessWidget {
  /// Creates the bar of [day].
  const new({
    required this.day,
    required this.balance,
    required this.today,
    required this.isShown,
    super.key,
  });

  /// The day and its budget.
  final WeekBalanceDay day;

  /// The week the day belongs to.
  final WeekBalance balance;

  /// The real today.
  final DateTime today;

  /// Whether the diary shows this day, which gets the frame.
  final bool isShown;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final error = Theme.of(context).colorScheme.error;
    final radius = BorderRadius.circular(AppWeekCard.fieldRadius);
    final normalizedToday = normalizeLocalDay(today);
    final isComing = day.date.isAfter(normalizedToday);
    final isFinished = day.date.isBefore(normalizedToday);
    final isEmpty =
        !day.isPauseDay && !isComing && !day.hasEntries && isFinished;
    final difference = day.eatenKcal - day.budgetKcal;
    final fellShort =
        isFinished &&
        day.hasEntries &&
        !day.isPauseDay &&
        !balance.overIsMiss &&
        -difference >= AppWeekCard.numberThresholdKcal;

    return ClipRRect(
      borderRadius: radius,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          Widget piece(double from, double length, Widget child) => Positioned(
            left: from * width,
            top: 0,
            bottom: 0,
            width: length * width,
            child: child,
          );
          final debt = math.max<double>(0, -day.carryoverKcal);
          final extra = math.max<double>(0, day.carryoverKcal);
          final shows = !day.isPauseDay && !isEmpty;
          // A field spans the goal, or the whole day when it is over it.
          final span = isComing
              ? day.goalKcal + extra
              : math.max(
                  math.max(day.goalKcal, day.budgetKcal),
                  debt + day.eatenKcal,
                );
          final eaten = math.min(day.eatenKcal, day.budgetKcal);
          final over = math.max<double>(0, day.eatenKcal - day.budgetKcal);
          final overColor = balance.overIsMiss ? error : colors.ink;

          return Stack(
            fit: StackFit.expand,
            children: [
              if (isComing)
                CustomPaint(
                  key: DiaryWeekCardKeys.comingOutline,
                  painter: DiaryWeekDashedPainter(
                    color: colors.muted,
                    radius: AppWeekCard.fieldRadius,
                  ),
                )
              else if (day.isPauseDay)
                CustomPaint(
                  key: DiaryWeekCardKeys.pauseHatch,
                  painter: DiaryWeekHatchPainter(
                    color: colors.muted,
                    background: colors.track,
                  ),
                )
              else
                DecoratedBox(
                  key: isEmpty ? DiaryWeekCardKeys.emptyTrack : null,
                  decoration: BoxDecoration(
                    color: fellShort ? error : colors.track,
                  ),
                ),
              if (shows && debt > 0)
                piece(
                  0,
                  debt / span,
                  DecoratedBox(
                    key: DiaryWeekCardKeys.debtPiece,
                    decoration: BoxDecoration(color: colors.accentText),
                  ),
                ),
              if (shows && extra > 0)
                piece(
                  day.goalKcal / span,
                  extra / span,
                  CustomPaint(
                    key: DiaryWeekCardKeys.extraPiece,
                    painter: DiaryWeekDashedPainter(
                      color: colors.ink,
                      radius: AppWeekCard.fieldRadius,
                    ),
                  ),
                ),
              if (shows && !isComing)
                piece(
                  debt / span,
                  eaten / span,
                  DecoratedBox(
                    key: DiaryWeekCardKeys.eatenPart,
                    decoration: BoxDecoration(color: colors.accent),
                  ),
                ),
              if (shows && !isComing && over >= 1)
                piece(
                  (debt + day.budgetKcal) / span,
                  over / span,
                  DecoratedBox(
                    key: DiaryWeekCardKeys.overPart,
                    decoration: BoxDecoration(
                      color: overColor,
                      border: Border(
                        left: BorderSide(
                          color: colors.card,
                          width: AppWeekCard.outlineWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              if (isShown)
                DecoratedBox(
                  key: DiaryWeekCardKeys.frame,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      AppWeekCard.fieldRadius,
                    ),
                    border: Border.all(
                      color: colors.ink,
                      width: AppWeekCard.frameWidth,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
