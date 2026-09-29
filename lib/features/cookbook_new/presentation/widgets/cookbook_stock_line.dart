import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One square per food, filled in ink when the Vorrat holds it and in the low
/// color when it is missing, followed by "Alles da" or the missing count.
class CookbookStockLine extends StatelessWidget {
  /// Creates the line for the foods of [entry].
  const new({required this.entry, super.key});

  /// The Vorlage or recipe whose foods are shown.
  final CookbookEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final inStock = entry.inStock;
    final missing = entry.missingCount;

    return Row(
      spacing: AppSpacing.sm,
      children: [
        if (inStock.length <= AppGraphit.stockSquareMaxCount)
          Row(
            spacing: AppSpacing.xxs,
            children: [
              for (final isInStock in inStock)
                SizedBox.square(
                  dimension: AppGraphit.stockSquare,
                  child: ColoredBox(color: isInStock ? colors.ink : colors.low),
                ),
            ],
          ),
        Flexible(
          child: Text(
            missing == 0
                ? l10n.cookbookStockComplete
                : l10n.cookbookStockMissing(missing),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: missing == 0 ? colors.muted : colors.low,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
