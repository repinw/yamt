import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_steps_card_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/health/application/health_steps_goal_raise.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Takes the place of the steps card's content once the week before met
/// the goal on average: asks whether the user takes the challenge of more
/// steps a day, with a no and a yes, as high as its text needs. Either
/// answer brings the card back until the next met week.
class DiaryStepsGoalRaisePrompt extends ConsumerWidget {
  /// Creates the prompt of the week starting at [weekStart].
  const new({required this.weekStart, super.key});

  /// Key of the prompt.
  static const promptKey = ValueKey<String>('diary_steps_goal_raise');

  /// Key of the button that raises the goal.
  static const yesKey = ValueKey<String>('diary_steps_goal_raise_yes');

  /// Key of the button that keeps the goal.
  static const noKey = ValueKey<String>('diary_steps_goal_raise_no');

  /// First day of the run week that shows the prompt.
  final DateTime weekStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final more = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(healthStepsGoalRaise);
    final messenger = ScaffoldMessenger.of(context);

    void answer({required bool raise}) {
      AppHapticFeedback.selectionClick();
      unawaited(() async {
        try {
          await ref
              .read(healthStepsGoalRaiseAnswerProvider.notifier)
              .answer(weekStart, raise: raise);
        } on Object {
          messenger.showAppSnackBar(
            l10n.diaryStepsMenuGoalFailed,
            tone: AppSnackBarTone.error,
          );
        }
      }());
    }

    return DecoratedBox(
      key: promptKey,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppStepsCard.radius),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppStepsCard.horizontalPadding,
          AppStepsCard.verticalPadding,
          AppSpacing.xs,
          AppSpacing.xxs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                end: AppStepsCard.horizontalPadding - AppSpacing.xs,
              ),
              child: Text(
                l10n.diaryStepsRaiseText(more),
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: AppFonts.geist,
                  color: colors.ink,
                ),
              ),
            ),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: AppSpacing.xs,
              children: [
                TextButton(
                  key: noKey,
                  onPressed: () => answer(raise: false),
                  child: Text(l10n.diaryStepsRaiseNo),
                ),
                FilledButton(
                  key: yesKey,
                  onPressed: () => answer(raise: true),
                  child: Text(l10n.diaryStepsRaiseYes),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
