import 'dart:async';
import 'dart:math' show min;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_step_foot.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_timer_bar.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_timer_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_to_weigh.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_voice_bar.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The guide ("Kochhelfer"): one instruction per page ("Schritt N von M"),
/// each time it names as a button that starts a timer (a span asks which end)
/// with the hint when timers may not ring ([KochmodusTimerHint]), the lines
/// still to weigh, the lines that came in while cooking, then timers, voice
/// and "Zurück" | "Nächster Schritt"; the last step ends with "Fertig ·
/// Portionieren". "Zurück" on the first step shows the tab "Töpfe".
class KochmodusGuideStep extends StatelessWidget {
  /// Creates the guide of [view] for the cooking of [target].
  const new({required this.target, required this.view, super.key});

  /// Key of "Zurück".
  static const backKey = ValueKey<String>('kochmodus-guide-back');

  /// Key of "Nächster Schritt".
  static const nextKey = ValueKey<String>('kochmodus-guide-next');

  /// Key of "Fertig · Portionieren" on the last step.
  static const portionKey = ValueKey<String>('kochmodus-guide-portion');

  /// Key of the button that shows the list instead.
  static const listKey = ValueKey<String>('kochmodus-guide-list');

  /// Key of the timer button of the time at [index] in the instruction.
  static ValueKey<String> timerKey(int index) =>
      ValueKey<String>('kochmodus-guide-timer-$index');

  /// Key of "Entfernen" of the new line [lineId].
  static ValueKey<String> removeKey(String lineId) =>
      ValueKey<String>('kochmodus-guide-remove-$lineId');

  /// What the page cooks; actions go to its controller.
  final KochmodusTarget target;

  /// The cooking as it is now; [KochmodusView.guide] is not empty.
  final KochmodusView view;

  void _act(
    BuildContext context,
    Future<bool> Function(KochmodusController controller) action,
  ) => unawaited(KochmodusActionFlow.run(context, target, action));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: colors.muted);
    final count = view.guide.length;
    final index = min(view.run.guideStep, count - 1);
    final step = view.guide[index];
    final last = index == count - 1;
    // A step with several times numbers its timers.
    String timerName(int at) => step.timerSteps.length > 1
        ? l10n.kochmodusGuideTimerLabelNumbered(index + 1, at + 1)
        : l10n.kochmodusGuideTimerLabel(index + 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: AppInsets.page,
            children: [
              Row(
                spacing: AppSpacing.xs,
                children: [
                  Expanded(
                    child: Text(
                      l10n
                          .kochmodusGuideProgress(index + 1, count)
                          .toUpperCase(),
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.muted,
                        letterSpacing: AppGraphit.kickerTracking,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      l10n.cookingGuideKeepsScreenOn,
                      textAlign: TextAlign.end,
                      style: muted,
                    ),
                  ),
                  IconButton(
                    key: listKey,
                    tooltip: l10n.kochmodusShowList,
                    onPressed: () => _act(
                      context,
                      (controller) => controller.setGuide(on: false),
                    ),
                    icon: const Icon(Icons.list_rounded),
                  ),
                ],
              ),
              _GuideProgress(index: index, count: count),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                step.text,
                style: textTheme.headlineSmall?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (step.timerSteps.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final (at, choices) in step.timerSteps.indexed)
                      FilledButton.icon(
                        key: timerKey(at),
                        onPressed: () => unawaited(
                          KochmodusActionFlow.startTimer(
                            context,
                            target,
                            name: timerName(at),
                            choices: choices,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.ink,
                          foregroundColor: colors.paper,
                        ),
                        icon: const Icon(Icons.timer_outlined),
                        label: Text(
                          KochmodusTimerSheet.choicesText(l10n, choices),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.kochmodusGuideTimerHint, style: muted),
                const KochmodusTimerHint(),
              ],
              if (view.toWeigh.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                KochmodusToWeigh(target: target, lines: view.toWeigh),
              ],
              if (view.newLines.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                // Portion clears up only the lines that are still open.
                Text(
                  view.newLines.any((line) => line.settlement is LineOpen)
                      ? l10n.kochmodusGuideAdded
                      : l10n.kochmodusGuideAddedSettled,
                  style: muted,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final line in view.newLines)
                      InputChip(
                        key: ValueKey<String>(line.id),
                        label: Text(line.text),
                        deleteButtonTooltipMessage: l10n.kochmodusRemoveLine,
                        deleteIcon: Icon(
                          Icons.close_rounded,
                          key: removeKey(line.id),
                        ),
                        onDeleted: () => _act(
                          context,
                          (controller) => controller.removeLine(line.id),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        KochmodusStepFoot(
          children: [
            if (view.timers.isNotEmpty)
              KochmodusTimerBar(target: target, timers: view.timers),
            KochmodusVoiceBar(target: target, view: view),
            Row(
              spacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  key: backKey,
                  onPressed: () => _act(
                    context,
                    (controller) => index > 0
                        ? controller.guideTo(index - 1)
                        : controller.goTo(KochmodusStep.pots),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppGraphit.buttonHeight),
                  ),
                  child: Text(l10n.kochmodusGuideBack),
                ),
                Expanded(
                  child: FilledButton(
                    key: last ? portionKey : nextKey,
                    onPressed: () => _act(
                      context,
                      (controller) => last
                          ? controller.toPortion()
                          : controller.guideTo(index + 1),
                    ),
                    style: KochmodusStepFoot.mainButtonStyle(context),
                    child: Text(
                      last ? l10n.kochmodusToPortion : l10n.kochmodusGuideNext,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// One segment per instruction; the done ones and the shown one filled.
class _GuideProgress extends StatelessWidget {
  const new({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return Row(
      spacing: AppGraphit.progressSegmentGap,
      children: [
        for (var at = 0; at < count; at++)
          Expanded(
            child: SizedBox(
              height: AppGraphit.progressSegmentHeight,
              child: ColoredBox(color: at <= index ? colors.ink : colors.track),
            ),
          ),
      ],
    );
  }
}
