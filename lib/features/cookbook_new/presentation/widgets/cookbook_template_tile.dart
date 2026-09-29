import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_stock_line.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Most letter tiles on a Vorlage tile.
const int _maxLetterTiles = 3;

/// Framed tile of a Vorlage: overlapping letter tiles for its foods, its name,
/// the energy of one portion, and the stock line.
class CookbookTemplateTile extends StatelessWidget {
  /// Creates the tile for [entry].
  const new({required this.entry, required this.onOpen, super.key});

  /// The Vorlage with its stock flags.
  final CookbookEntry entry;

  /// Opens the Vorlage.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final meal = entry.meal;
    final portions = meal.totalPortions < 1 ? 1 : meal.totalPortions;

    return SizedBox(
      width: AppGraphit.stripTileWidth,
      child: AppInkWell(
        onTap: onOpen,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(
              color: colors.rule,
              width: AppFoodLabel.chipOutline,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xs,
              children: [
                _LetterTiles(
                  names: [
                    for (final component in meal.components.take(
                      _maxLetterTiles,
                    ))
                      component.name,
                  ],
                ),
                Text(
                  meal.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  l10n.cookbookKcal((meal.totalKcal / portions).round()),
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.muted,
                    fontFamily: AppFonts.mono,
                  ),
                ),
                if (entry.inStock.isNotEmpty) CookbookStockLine(entry: entry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterTiles extends StatelessWidget {
  const new({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final style = Theme.of(context).textTheme.titleSmall
        ?.copyWith(color: colors.paper, fontWeight: FontWeight.w800);
    return SizedBox(
      height: AppGraphit.letterTile,
      child: Stack(
        children: [
          for (final (index, name) in names.indexed)
            Positioned(
              left:
                  index *
                  (AppGraphit.letterTile - AppGraphit.letterTileOverlap),
              child: Transform.rotate(
                angle: index.isEven
                    ? AppFoodLabel.imageTilt
                    : -AppFoodLabel.imageTilt,
                child: Container(
                  width: AppGraphit.letterTile,
                  height: AppGraphit.letterTile,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.ink,
                    border: Border.all(
                      color: colors.card,
                      width: AppFoodLabel.outline,
                    ),
                  ),
                  // Large text shrinks into the fixed tile instead of clipping.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      name.isEmpty ? '' : name.characters.first.toUpperCase(),
                      style: style,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
