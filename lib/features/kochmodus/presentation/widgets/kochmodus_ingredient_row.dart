import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_card_texts.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_line_picture.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One line in "Alle Zutaten" of "Was hast du da?": its picture with the
/// state as a small badge at the top right (a check on the accent colour
/// when it is there, a cart while it is on the shopping list, a dash when it
/// is left out; none while it waits for an answer or for a weight), its text,
/// bold while it is on the card ([onCard]), and its state in a word or two,
/// as a warning while too little is there or the weight is missing. A tap
/// puts it on the card.
class KochmodusIngredientRow extends StatelessWidget {
  /// Creates the row of [line].
  const new({
    required this.line,
    required this.onCard,
    required this.onTap,
    super.key,
  });

  /// Key of the row of the line [lineId].
  static ValueKey<String> rowKey(String lineId) =>
      ValueKey<String>('kochmodus-assign-row-$lineId');

  /// The line.
  final KochmodusLineView line;

  /// Whether the line is on the card.
  final bool onCard;

  /// Called when the cook taps the row.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final short = line.shortBy != null;
    final warn = short || line.weighWhileCooking;
    final badge = switch (line.settlement) {
      LineAssigned() when warn || line.needsOtherFood => null,
      LineAssigned() => (Icons.check_rounded, colors.accent, colors.onAccent),
      LineShopping() => (
        Icons.shopping_cart_outlined,
        colors.ink,
        colors.paper,
      ),
      LineIgnored() => (Icons.remove_rounded, colors.muted, colors.paper),
      LineOpen() => null,
    };
    return AppInkWell(
      key: rowKey(line.id),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.rule)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  KochmodusLinePicture(line: line),
                  if (badge case (final icon, final fill, final ink))
                    Positioned(
                      top: -AppSpacing.xxs,
                      right: -AppSpacing.xxs,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: fill,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.paper,
                            width: AppSizes.badgeBorderWidth,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxs),
                          child: Icon(
                            icon,
                            size: AppGraphit.pictureBadgeIcon,
                            color: ink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Text(
                  line.approxText ? l10n.eatPageApprox(line.text) : line.text,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.ink,
                    fontWeight: onCard ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
              Text(
                kochmodusRowWord(l10n, line, onCard: onCard),
                style: textTheme.bodySmall?.copyWith(
                  color: warn ? colors.low : colors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
