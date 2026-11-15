import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_ready_card.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The head of "Was hast du da?": one segment per line (the one on the card
/// bright, open ones dim, "Hab ich" in the accent colour, a line on the
/// shopping list or left out in a quiet grey that still reads as answered),
/// "N von M
/// geklärt" with "Später" beside it while a line is open, and "Zurück vom
/// Einkauf" after the shopping lines of a paused run came back to open.
class KochmodusAssignHead extends StatelessWidget {
  /// Creates the head of [view]; [onCard] is the id of the line on the card.
  const new({required this.view, required this.onCard, super.key});

  /// The cooking as it is now.
  final KochmodusView view;

  /// The id of the line on the card, `null` when every line is answered.
  final String? onCard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final open = {for (final line in view.toAnswer) line.id};
    final total = view.lines.length;
    final muted = textTheme.bodySmall?.copyWith(color: colors.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        Row(
          spacing: AppGraphit.progressSegmentGap,
          children: [
            for (final line in view.lines)
              Expanded(
                child: SizedBox(
                  height: AppGraphit.progressSegmentHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      color: line.id == onCard
                          ? colors.ink
                          : open.contains(line.id)
                          ? colors.track
                          : line.settlement is LineAssigned
                          ? colors.accent
                          : colors.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.kochmodusAssignProgress(total - open.length, total),
                style: muted?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            // "Später" stays one tap away; once all is answered, the card
            // has it.
            if (open.isNotEmpty)
              TextButton(
                key: KochmodusReadyCard.laterKey,
                onPressed: () => KochmodusReadyCard.later(context),
                child: Text(l10n.kochmodusAssignLater),
              ),
          ],
        ),
        if (view.reopened) Text(l10n.kochmodusAssignReopenedHint, style: muted),
      ],
    );
  }
}
