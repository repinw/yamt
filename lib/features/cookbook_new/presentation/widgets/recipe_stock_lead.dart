import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_image_tile.dart';

/// The start of an ingredient row: the photo of the Vorrat item that
/// supplies it, an empty square when the Vorrat lacks it, a half filled one
/// for the missing part of an ingredient, or a dash when it is ignored.
class RecipeStockLead extends StatelessWidget {
  /// Creates the lead for [item].
  const new({
    this.item,
    this.isIgnored = false,
    this.isRest = false,
    super.key,
  });

  /// The Vorrat item, or `null` when the Vorrat lacks the ingredient.
  final InventoryItem? item;

  /// Whether the recipe ignores the ingredient.
  final bool isIgnored;

  /// Whether the row is the missing part of a partly stocked ingredient.
  final bool isRest;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final item = this.item;
    final Widget lead;
    if (isIgnored) {
      lead = SizedBox(
        width: AppGraphit.stockSquare,
        height: AppFoodLabel.chipOutline,
        child: ColoredBox(color: colors.muted),
      );
    } else if (item != null && !isRest) {
      lead = EatImageTile(
        imageUrl: item.imageUrl,
        size: AppGraphit.rowTile,
        angle: -AppGraphit.pictureTilt,
        fallbackLetter: inventoryPictureLetter(item.name),
      );
    } else {
      lead = SizedBox.square(
        dimension: AppGraphit.stockSquare,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: colors.low,
              width: AppFoodLabel.chipOutline,
            ),
            gradient: isRest
                ? LinearGradient(
                    colors: [
                      colors.low,
                      colors.low,
                      colors.paper.withValues(alpha: 0),
                    ],
                    stops: const [
                      0,
                      AppGraphit.restSquareFill,
                      AppGraphit.restSquareFill,
                    ],
                  )
                : null,
          ),
        ),
      );
    }
    return SizedBox(
      width: AppGraphit.rowTile,
      child: Center(child: lead),
    );
  }
}
