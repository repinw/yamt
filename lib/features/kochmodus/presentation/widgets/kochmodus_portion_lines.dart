import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_line_assign_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_portion_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_portion_line.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The lines of "Portion" ([KochmodusPortionLine]); a removed recipe line
/// stays below, where it can be assigned again. Lines that came in while
/// cooking and are still open stand above with "Übernehmen".
class KochmodusPortionLines extends StatelessWidget {
  /// Creates the lines of [portion] for the cooking of [target].
  const new({required this.target, required this.portion, super.key});

  /// Key of "Übernehmen" of the new lines.
  static const takeNewKey = ValueKey<String>('kochmodus-portion-take-new');

  /// What the page cooks.
  final KochmodusTarget target;

  /// "Portion" as it is now.
  final KochmodusPortionView portion;

  // Each new line that is still open, in turn, through the sheet that
  // settles it; backing out of one stops.
  Future<void> _takeNew(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final offered = <String>{};
    while (context.mounted) {
      final line = container
          .read(kochmodusControllerProvider(target))
          .value
          ?.portion
          .openNewLines
          .firstWhereOrNull((line) => !offered.contains(line.id));
      if (line == null) return;
      offered.add(line.id);
      final settled = await KochmodusLineAssignFlow.assign(
        context: context,
        target: target,
        line: line,
      );
      if (!settled) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final pots = portion.potMeals;
    final newLines = portion.openNewLines;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (newLines.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Padding(
                padding: AppInsets.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.xs,
                  children: [
                    Text(
                      l10n.kochmodusNewLines(newLines.length),
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    for (final line in newLines)
                      Text(
                        line.text,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.muted,
                        ),
                      ),
                    OutlinedButton(
                      key: takeNewKey,
                      onPressed: () => unawaited(_takeNew(context)),
                      child: Text(l10n.cookPickerApply),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Text(
          (pots.length > 1
                  ? l10n.kochmodusPortionLinesSwitch
                  : l10n.cookIngredients)
              .toUpperCase(),
          style: textTheme.labelMedium?.copyWith(
            color: colors.muted,
            letterSpacing: AppGraphit.kickerTracking,
          ),
        ),
        for (final line in portion.lines)
          KochmodusPortionLine(
            target: target,
            line: line,
            pots: pots.length > 1 ? pots : const [],
          ),
        for (final line in portion.ignoredLines)
          KochmodusPortionLine(target: target, line: line, pots: const []),
      ],
    );
  }
}
