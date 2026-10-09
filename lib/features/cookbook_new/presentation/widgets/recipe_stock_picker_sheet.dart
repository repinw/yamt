import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_controller.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_image_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The cook's pick for one ingredient: a Vorrat item, or none for "not from
/// the Vorrat".
typedef RecipeStockPick = ({String? itemId});

/// Asks which Vorrat item supplies [line]. Returns `null` when the cook
/// closes the sheet without a pick.
Future<RecipeStockPick?> showRecipeStockPicker({
  required BuildContext context,
  required RecipeIngredientLine line,
}) => showModalBottomSheet<RecipeStockPick>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => RecipeStockPickerSheet(line: line),
);

/// The list of [line]'s Vorrat candidates and "Nicht aus dem Vorrat".
class RecipeStockPickerSheet extends StatelessWidget {
  /// Creates the sheet.
  const new({required this.line, super.key});

  /// Key of the option for the Vorrat item [itemId].
  static ValueKey<String> optionKey(String itemId) =>
      ValueKey<String>('recipe-stock-option-$itemId');

  /// Key of the "Nicht aus dem Vorrat" option.
  static const noneKey = ValueKey<String>('recipe-stock-option-none');

  /// The ingredient to pick for.
  final RecipeIngredientLine line;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final selectedId = line.row.stockItem?.id;
    final check = Icon(Icons.check_rounded, color: colors.ink);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(context).height *
              AppGraphit.pickerSheetHeightFactor,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                l10n.recipePickTitle(line.row.foodName),
                style: textTheme.titleMedium?.copyWith(color: colors.ink),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final item in line.candidates)
              ListTile(
                key: optionKey(item.id),
                leading: EatImageTile(
                  imageUrl: item.imageUrl,
                  size: AppGraphit.rowTile,
                  angle: -AppGraphit.pictureTilt,
                  fallbackLetter: inventoryPictureLetter(item.name),
                ),
                title: Text(item.name),
                trailing: item.id == selectedId ? check : null,
                onTap: () => Navigator.of(context).pop((itemId: item.id)),
              ),
            ListTile(
              key: noneKey,
              leading: const SizedBox(
                width: AppGraphit.rowTile,
                child: Icon(Icons.block_rounded),
              ),
              title: Text(l10n.recipeNotFromStock),
              trailing: selectedId == null ? check : null,
              onTap: () => Navigator.of(context).pop((itemId: null)),
            ),
          ],
        ),
      ),
    );
  }
}
