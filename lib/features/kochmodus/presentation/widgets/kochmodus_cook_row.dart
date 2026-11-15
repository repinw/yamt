import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/food_label_dashed_line.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_text.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_line_picture.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One line on "Kochen": its picture, text and what it brings into the
/// pot; struck through and dimmed with "weggelassen" when the cook left it
/// out, plain with "zählt nicht mit" when it does not count in the nutrition
/// (a pinch of salt goes in all the same), dashed with "Entfernen" when it
/// came in while cooking, and "Wiegen" when its weight is estimated or
/// missing and weighing can help it. A line whose food left the Vorrat says
/// "Eintrag fehlt" and offers no weighing.
class KochmodusCookRow extends StatelessWidget {
  /// Creates the row of [line] for the cooking of [target].
  const new({required this.target, required this.line, super.key});

  /// Key of "Wiegen" or "Ändern" of the line [lineId].
  static ValueKey<String> weighKey(String lineId) =>
      ValueKey<String>('kochmodus-cook-weigh-$lineId');

  /// Key of "Entfernen" of the new line [lineId].
  static ValueKey<String> removeKey(String lineId) =>
      ValueKey<String>('kochmodus-cook-remove-$lineId');

  /// What the page cooks; actions go to its controller.
  final KochmodusTarget target;

  /// The line.
  final KochmodusLineView line;

  String _sub(AppLocalizations l10n) {
    if (line.isNew && line.settlement is LineOpen) {
      return l10n.kochmodusCookNewOpen;
    }
    if (line.entryMissing) return l10n.kochmodusEntryMissing;
    final weight = switch (line.weight) {
      CookWeightWeighed(:final grams) => l10n.kochmodusWeightWeighed(grams),
      CookWeightExact(:final grams) => kochmodusWeightText(
        l10n,
        grams,
        line.pictureItem,
      ),
      CookWeightEstimated(:final grams) => l10n.kochmodusWeightEstimated(
        kochmodusWeightText(l10n, grams, line.pictureItem),
      ),
      CookWeightMissing() when line.needsOtherFood =>
        l10n.kochmodusTakesNothing,
      CookWeightMissing() => l10n.kochmodusWeightMissing,
      CookWeightNotCounted() when line.notCounted =>
        l10n.kochmodusRowNotCounted,
      CookWeightNotCounted() => l10n.kochmodusRowIgnored,
    };
    final food = line.pictureItem?.name;
    return food == null || line.weight is CookWeightNotCounted
        ? weight
        : l10n.kochmodusCookLineSub(food, weight);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    // A line that does not count, such as a pinch of salt, still goes in.
    final ignored = line.weight is CookWeightNotCounted && !line.notCounted;
    final weighLabel = switch (line.weight) {
      _ when line.needsOtherFood || line.entryMissing => null,
      CookWeightEstimated() || CookWeightMissing() => l10n.kochmodusWeigh,
      CookWeightWeighed() => l10n.kochmodusChange,
      CookWeightExact() || CookWeightNotCounted() => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (line.isNew)
          FoodLabelDashedLine(color: colors.rule)
        else
          Divider(
            height: AppSizes.dividerThickness,
            thickness: AppSizes.dividerThickness,
            color: colors.rule,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              Opacity(
                opacity: ignored ? AppGraphit.pendingRowOpacity : 1,
                child: KochmodusLinePicture(line: line),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.text,
                      style: textTheme.bodyLarge?.copyWith(
                        color: ignored ? colors.muted : colors.ink,
                        fontWeight: FontWeight.w700,
                        decoration: ignored ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      _sub(l10n),
                      style: textTheme.bodySmall?.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
              if (weighLabel != null)
                OutlinedButton(
                  key: KochmodusCookRow.weighKey(line.id),
                  onPressed: () => unawaited(
                    KochmodusActionFlow.weigh(context, target, line),
                  ),
                  child: Text(weighLabel),
                ),
              if (line.isNew)
                IconButton(
                  key: KochmodusCookRow.removeKey(line.id),
                  tooltip: l10n.kochmodusRemoveLine,
                  onPressed: () => unawaited(
                    KochmodusActionFlow.run(
                      context,
                      target,
                      (controller) => controller.removeLine(line.id),
                    ),
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
