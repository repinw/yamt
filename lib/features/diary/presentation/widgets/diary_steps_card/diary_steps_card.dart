import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_steps_card_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';
import 'package:yamt/core/widgets/holo_foil_card.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card/diary_steps_card_fire.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card/diary_steps_card_menu.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card/diary_steps_card_parts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card/diary_steps_goal_raise_prompt.dart';
import 'package:yamt/features/health/application/daily_steps_provider.dart';
import 'package:yamt/features/health/application/health_steps_controller.dart';
import 'package:yamt/features/health/application/health_steps_goal_controller.dart';
import 'package:yamt/features/health/application/health_steps_goal_raise.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The steps of [day] under the budget card, next to one bar per day of its
/// run week, which fill day by day. With a steps goal it names the goal, and
/// a line fills up to it, a day at its goal shines as a holo trophy, and at
/// twice the goal the card burns: a flame replaces the walker, its rim glows
/// and fire runs through the line. A tap opens the card's menu.
/// Shows nothing while steps are off, on a day ahead, or once the day
/// turns out to have no steps to show; a failed read shows a dash. While the
/// steps load the card is there without a number, so the page below it does
/// not jump.
class DiaryStepsCard extends ConsumerWidget {
  /// Creates the card for [day].
  const new({required this.day, required this.weekStart, super.key});

  /// Key of the card.
  static const cardKey = ValueKey<String>('diary_steps_card');

  /// Key of the steps number.
  static const valueKey = ValueKey<String>('diary_steps_card_value');

  /// Key of the glowing rim of a card on fire.
  static const emberKey = ValueKey<String>('diary_steps_card_ember');

  /// Key of the flame that replaces the walker at twice the goal.
  static const fireKey = ValueKey<String>('diary_steps_card_fire');

  /// Key of the line that fills up to the goal.
  static const goalLineKey = ValueKey<String>('diary_steps_card_goal_line');

  /// Normalized diary day.
  final DateTime day;

  /// First day of the run week of [day]; null draws no week bars.
  final DateTime? weekStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(healthStepsControllerProvider) ||
        day.isAfter(ref.watch(diaryTodayProvider))) {
      return const SizedBox.shrink();
    }
    final today = ref.watch(dailyStepsProvider(day));
    final steps = today.value;
    final failed = today.hasError && !today.isLoading;
    if (steps == null && !failed && !today.isLoading) {
      return const SizedBox.shrink();
    }
    final weekStart = this.weekStart;
    final dayIndex = weekStart == null
        ? null
        : localDaysBetween(weekStart, day);
    final days = weekStart == null
        ? null
        : ref.watch(weekDailyStepsProvider(weekStart)).value;
    final goal = ref.watch(healthStepsGoalControllerProvider);

    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final value = steps == null
        ? (failed ? l10n.diaryStepsUnknown : '')
        : numberFormat.format(steps);
    final label = goal == null
        ? l10n.diaryStepsLabel
        : l10n.diaryStepsOfGoal(numberFormat.format(goal));
    final radius = BorderRadius.circular(AppStepsCard.radius);
    final reached = goal != null && steps != null && steps >= goal;
    // Twice the goal sets the card on fire.
    final onFire =
        goal != null &&
        steps != null &&
        steps >= goal * AppStepsCard.fireGoalFactor;

    final surface = DecoratedBox(
      key: cardKey,
      decoration: BoxDecoration(color: colors.card, borderRadius: radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStepsCard.horizontalPadding,
          vertical: AppStepsCard.verticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppStepsCard.goalLineGap,
          children: [
            Row(
              spacing: AppSpacing.sm,
              children: [
                if (onFire)
                  const DiaryStepsFlame(key: fireKey)
                else
                  Icon(
                    Icons.directions_walk_rounded,
                    size: AppStepsCard.icon,
                    color: colors.muted,
                  ),
                // One line that shrinks as a whole, so large text or a
                // long goal never cuts it off or pushes the bars out.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text.rich(
                      key: valueKey,
                      TextSpan(
                        text: value,
                        style: textTheme.titleLarge?.copyWith(
                          fontFamily: AppFonts.geist,
                          fontSize: AppStepsCard.value,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        children: [
                          TextSpan(
                            text: ' $label',
                            style: textTheme.bodyMedium?.copyWith(
                              fontFamily: AppFonts.geist,
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                if (days != null && dayIndex != null)
                  DiaryStepsWeekBars(
                    days: days,
                    dayIndex: dayIndex,
                    goal: goal,
                    burning: onFire,
                  ),
              ],
            ),
            if (goal != null)
              DiaryStepsGoalLine(
                key: goalLineKey,
                steps: steps ?? 0,
                goal: goal,
                burning: onFire,
              ),
          ],
        ),
      ),
    );

    final card = Semantics(
      container: true,
      button: true,
      onTap: () => unawaited(showDiaryStepsCardMenu(context)),
      label: steps == null
          ? (failed ? l10n.diaryStepsLoadFailed : l10n.diaryStepsLabel)
          : goal == null
          ? l10n.diaryStepsSemantics(steps)
          : l10n.diaryStepsGoalSemantics(steps, goal),
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppHapticFeedback.selectionClick();
            unawaited(showDiaryStepsCardMenu(context));
          },
          // A day at its goal turns the card into a holo trophy, like the
          // budget card; at twice the goal the fire takes the gold's place.
          child: onFire
              ? DiaryStepsEmberFrame(
                  key: emberKey,
                  borderRadius: radius,
                  child: surface,
                )
              : HoloFoilCard(
                  enabled: reached,
                  borderRadius: radius,
                  surface: colors.card,
                  child: surface,
                ),
        ),
      ),
    );
    // Only today asks; an answer belongs to the running week.
    final offer = weekStart != null && day == ref.watch(diaryTodayProvider)
        ? ref.watch(healthStepsGoalRaiseOfferProvider(weekStart)).value
        : null;
    if (weekStart == null || offer == null) {
      return card;
    }
    // The question takes the card's place and is as high as its text.
    return DiaryStepsGoalRaisePrompt(weekStart: weekStart);
  }
}
