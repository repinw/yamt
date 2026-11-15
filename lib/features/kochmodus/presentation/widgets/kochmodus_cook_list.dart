import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_cook_row.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_step_foot.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_timer_bar.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_timer_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_to_weigh.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_voice_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Kochen" without the guide: the lines still to weigh, then every line
/// with what it brings into the pot,
/// ignored ones dimmed, new ones dashed with "Entfernen"; "Wiegen" where
/// the weight is estimated or missing. Below: timers, voice and
/// "Fertig · Portionieren".
class KochmodusCookList extends StatelessWidget {
  /// Creates the list of [view] for the cooking of [target].
  const new({required this.target, required this.view, super.key});

  /// Key of "Fertig · Portionieren".
  static const portionKey = ValueKey<String>('kochmodus-cook-portion');

  /// Key of "Timer".
  static const timerKey = ValueKey<String>('kochmodus-cook-timer');

  /// Key of the button that turns the guide on.
  static const guideKey = ValueKey<String>('kochmodus-cook-guide');

  /// What the page cooks; actions go to its controller.
  final KochmodusTarget target;

  /// The cooking as it is now.
  final KochmodusView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lines = view.lines;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.builder(
            padding: AppInsets.page,
            itemCount: lines.length + 1,
            itemBuilder: (context, index) => index == 0
                ? _CookHead(target: target, view: view)
                : KochmodusCookRow(
                    key: ValueKey<String>(lines[index - 1].id),
                    target: target,
                    line: lines[index - 1],
                  ),
          ),
        ),
        KochmodusStepFoot(
          children: [
            if (view.timers.isNotEmpty)
              KochmodusTimerBar(target: target, timers: view.timers),
            KochmodusVoiceBar(target: target, view: view),
            FilledButton(
              key: portionKey,
              onPressed: () => unawaited(
                KochmodusActionFlow.run(
                  context,
                  target,
                  (controller) => controller.toPortion(),
                ),
              ),
              style: KochmodusStepFoot.mainButtonStyle(context),
              child: Text(l10n.kochmodusToPortion),
            ),
          ],
        ),
      ],
    );
  }
}

// Title, "Timer", the guide switch, the count, the lines still to weigh and
// the empty state.
class _CookHead extends StatelessWidget {
  const new({required this.target, required this.view});

  final KochmodusTarget target;
  final KochmodusView view;

  // "Timer N" with the lowest number no running timer carries.
  Future<void> _startTimer(BuildContext context) =>
      KochmodusActionFlow.startTimer(
        context,
        target,
        name: KochmodusActionFlow.freeTimerName(
          AppLocalizations.of(context)!,
          view,
        ),
        choices: kochmodusTimerChoices,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: colors.muted);
    final run = view.run;
    final count = view.lines.length - view.ignored.length;
    final added = view.newLines.length;
    // At a large text scale "Timer" is an icon, so the title keeps its room.
    final large =
        MediaQuery.textScalerOf(context).scale(1) > kochmodusLargeText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: AppSpacing.xs,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (run.name.isNotEmpty)
                    Text(
                      l10n
                          .kochmodusRunKicker(run.name, run.portions)
                          .toUpperCase(),
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.muted,
                        letterSpacing: AppGraphit.kickerTracking,
                      ),
                    ),
                  Text(
                    l10n.cookStepCooking,
                    style: textTheme.headlineSmall?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (view.guideVisible)
              IconButton(
                key: KochmodusCookList.guideKey,
                tooltip: l10n.kochmodusShowGuide,
                onPressed: () => unawaited(
                  KochmodusActionFlow.run(
                    context,
                    target,
                    (controller) => controller.setGuide(on: true),
                  ),
                ),
                icon: const Icon(Icons.menu_book_outlined),
              ),
            if (large)
              IconButton(
                key: KochmodusCookList.timerKey,
                tooltip: l10n.kochmodusTimerAction,
                onPressed: () => unawaited(_startTimer(context)),
                icon: const Icon(Icons.timer_outlined),
              )
            else
              OutlinedButton.icon(
                key: KochmodusCookList.timerKey,
                onPressed: () => unawaited(_startTimer(context)),
                icon: const Icon(Icons.timer_outlined),
                label: Text(l10n.kochmodusTimerAction),
              ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          children: [
            Text(
              added == 0
                  ? l10n.kochmodusCookCount(count)
                  : l10n.kochmodusCookCountAdded(count, added),
              style: muted,
            ),
            Text(l10n.cookingGuideKeepsScreenOn, style: muted),
          ],
        ),
        if (view.toWeigh.isNotEmpty)
          KochmodusToWeigh(target: target, lines: view.toWeigh),
        if (view.lines.isEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.kochmodusCookEmptyTitle,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: colors.ink),
          ),
          Text(
            l10n.kochmodusCookEmptyHint,
            textAlign: TextAlign.center,
            style: muted,
          ),
        ],
      ],
    );
  }
}
