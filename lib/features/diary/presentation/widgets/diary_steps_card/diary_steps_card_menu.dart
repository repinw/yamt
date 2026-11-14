import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_steps_card_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_sheet_frame.dart';
import 'package:yamt/features/health/application/health_steps_controller.dart';
import 'package:yamt/features/health/application/health_steps_goal_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the steps card's menu.
Future<void> showDiaryStepsCardMenu(BuildContext context) =>
    showDiaryDashboardSheet(context, (_) => const DiaryStepsCardMenu());

/// Content of the steps card's menu: the steps goal per day as a big number
/// between a minus and a plus, the usual goals to pick with one tap, and the
/// switch that takes the steps out of the diary again. No keyboard.
class DiaryStepsCardMenu extends ConsumerWidget {
  /// Creates the menu.
  const new({super.key});

  /// Key of the menu.
  static const menuKey = ValueKey<String>('diary-steps-menu');

  /// Key of the goal number.
  static const goalKey = ValueKey<String>('diary-steps-menu-goal');

  /// Key of the button that lowers the goal.
  static const lessKey = ValueKey<String>('diary-steps-menu-less');

  /// Key of the button that raises the goal.
  static const moreKey = ValueKey<String>('diary-steps-menu-more');

  /// Key of the chip that removes the goal.
  static const noGoalKey = ValueKey<String>('diary-steps-menu-no-goal');

  /// Key of the chip that picks [goal].
  static ValueKey<String> presetKey(int goal) =>
      ValueKey<String>('diary-steps-menu-preset-$goal');

  /// Key of the switch that shows the steps in the diary.
  static const showSwitchKey = ValueKey<String>('diary-steps-menu-show');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final goal = ref.watch(healthStepsGoalControllerProvider);
    final messenger = ScaffoldMessenger.of(context);

    Future<void> guarded(Future<void> Function() change, String failed) async {
      try {
        await change();
      } on Object {
        messenger.showAppSnackBar(failed, tone: AppSnackBarTone.error);
      }
    }

    void save(int? next) {
      AppHapticFeedback.selectionClick();
      unawaited(
        guarded(
          () => ref.read(healthStepsGoalControllerProvider.notifier).save(next),
          l10n.diaryStepsMenuGoalFailed,
        ),
      );
    }

    final step = numberFormat.format(AppStepsCard.goalStep);
    // The goal as it is at the tap, so quick taps build on each other.
    int? current() => ref.read(healthStepsGoalControllerProvider);
    // Below one step there is no goal; the plus then starts at the first
    // usual goal.
    final less = goal == null
        ? null
        : () {
            final now = current() ?? 0;
            save(
              now > AppStepsCard.goalStep ? now - AppStepsCard.goalStep : null,
            );
          };
    final more = goal != null && goal >= healthStepsGoalMax
        ? null
        : () {
            final now = current();
            save(
              now == null
                  ? AppStepsCard.goalPresets.first
                  : math.min(now + AppStepsCard.goalStep, healthStepsGoalMax),
            );
          };

    return Column(
      key: menuKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        DiaryDashboardSheetHeading(
          icon: Icons.directions_walk_rounded,
          label: l10n.diaryStepsMenuTitle,
        ),
        Text(
          l10n.diaryStepsMenuGoal.toUpperCase(),
          style: context.graphitKickerStyle,
        ),
        Row(
          children: [
            IconButton.filledTonal(
              key: lessKey,
              tooltip: l10n.diaryStepsMenuLess(step),
              onPressed: less,
              icon: const Icon(Icons.remove_rounded),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      goal == null
                          ? l10n.diaryStepsMenuGoalNone
                          : numberFormat.format(goal),
                      key: goalKey,
                      style: textTheme.displaySmall?.copyWith(
                        fontFamily: AppFonts.geist,
                        fontWeight: FontWeight.w700,
                        color: goal == null ? colors.muted : colors.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  if (goal != null)
                    Text(
                      l10n.diaryStepsMenuPerDay,
                      style: textTheme.bodyMedium?.copyWith(
                        fontFamily: AppFonts.geist,
                        color: colors.muted,
                      ),
                    ),
                ],
              ),
            ),
            IconButton.filledTonal(
              key: moreKey,
              tooltip: l10n.diaryStepsMenuMore(step),
              onPressed: more,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            ChoiceChip(
              key: noGoalKey,
              label: Text(l10n.diaryStepsMenuGoalNone),
              selected: goal == null,
              showCheckmark: false,
              onSelected: (_) => save(null),
            ),
            for (final preset in AppStepsCard.goalPresets)
              ChoiceChip(
                key: presetKey(preset),
                label: Text(numberFormat.format(preset)),
                selected: goal == preset,
                showCheckmark: false,
                onSelected: (_) => save(preset),
              ),
          ],
        ),
        const Divider(height: 1),
        AppSwitchListTile(
          key: showSwitchKey,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.diaryStepsMenuShow),
          subtitle: Text(l10n.diaryStepsMenuShowHint),
          value: ref.watch(healthStepsControllerProvider),
          onChanged: (_) {
            final navigator = Navigator.of(context);
            unawaited(
              guarded(() async {
                await ref
                    .read(healthStepsControllerProvider.notifier)
                    .disable();
                // Its card is gone, so the menu closes, unless it already
                // did.
                if (context.mounted) {
                  navigator.pop();
                }
              }, l10n.settingsStepsFailed),
            );
          },
        ),
      ],
    );
  }
}
