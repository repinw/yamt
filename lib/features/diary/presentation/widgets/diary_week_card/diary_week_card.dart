import 'dart:async';

import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_week_card_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';
import 'package:yamt/features/calories/presentation/widgets/week_balance_menu.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_card_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_details_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_day_field.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The week of the goal run that holds [day] as a strip of seven day fields
/// (#911; fewer for a run that a new goal cut short), between the budget card
/// and the steps card. Each finished day's field fills like the kcal line
/// against that day's budget; with the budget card's details open, numbers
/// stand under the finished days. A long press opens the menu with the mode;
/// a tap does nothing. Shows nothing while the mode is off or the day has no
/// run.
class DiaryWeekCard extends ConsumerWidget {
  /// Creates the card for [day].
  const new({required this.day, super.key});

  /// Normalized diary day, which gets the frame.
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(diaryWeekBalanceProvider(day));
    if (balance == null || balance.mode == WeekBalanceMode.off) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final today = ref.watch(diaryTodayProvider);
    final showDetails = ref.watch(diaryBalanceDetailsControllerProvider);
    void openMenu() => unawaited(showWeekBalanceMenu(context));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        container: true,
        label: l10n.weekBalanceTitle,
        customSemanticsActions: {
          CustomSemanticsAction(label: l10n.diaryWeekCardMenuOpen): openMenu,
        },
        child: GestureDetector(
          onLongPress: () {
            AppHapticFeedback.mediumImpact();
            openMenu();
          },
          child: DecoratedBox(
            key: DiaryWeekCardKeys.card,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(AppWeekCard.radius),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppWeekCard.horizontalPadding,
                AppWeekCard.topPadding,
                AppWeekCard.horizontalPadding,
                AppWeekCard.bottomPadding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppWeekCard.fieldGap,
                children: [
                  for (final (index, field) in balance.days.indexed)
                    Expanded(
                      child: DiaryWeekDayField(
                        key: DiaryWeekCardKeys.day(index),
                        index: index,
                        day: field,
                        balance: balance,
                        today: today,
                        isShown: isSameLocalDay(field.date, day),
                        showNumber: showDetails,
                      ),
                    ),
                  // A run cut short by a new goal has fewer fields; they keep
                  // the width they have with seven and start at the left.
                  for (
                    var empty = balance.days.length;
                    empty < calorieGoalRunLengthDays;
                    empty += 1
                  )
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
