import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/core/widgets/app_selection_list_tiles.dart';
import 'package:yamt/features/inventory/application/pending_ingredient_stock.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _PendingIngredientPreview extends StatelessWidget {
  const new({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalizedImageUrl = normalizeProductImageUrl(imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: 44,
        child: normalizedImageUrl == null
            ? ColoredBox(
                color: colors.surfaceContainerHighest,
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: colors.onSurfaceVariant,
                ),
              )
            : AppCachedNetworkImage(
                imageUrl: normalizedImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) {
                  return ColoredBox(
                    color: colors.surfaceContainerHighest,
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Key of the option for the Vorrat item [itemId] in the picker.
ValueKey<String> pendingIngredientOptionKey(String itemId) =>
    ValueKey<String>('pending-ingredient-option-$itemId');

/// Key of the picker's save button.
const pendingIngredientSaveKey = ValueKey<String>('pending-ingredient-save');

/// Key of the hint that items in another unit are left out.
const pendingIngredientUnitHintKey = ValueKey<String>(
  'pending-ingredient-unit-hint',
);

/// Lets the user pick the Vorrat foods that fill the missing recipe
/// [ingredient] from the candidates of its [stock], the items that can supply
/// its amount, best first, with a hint when items in another unit are left
/// out. Returns the picked ids.
Future<List<String>?> showPendingIngredientSelectionSheet({
  required BuildContext context,
  required String ingredient,
  required PendingIngredientStock stock,
}) {
  final (best: _, :candidates, :hidesByUnit) = stock;
  final l10n = AppLocalizations.of(context)!;
  final emptySelectionMessage =
      l10n.preparedMealPendingIngredientSelectionEmpty;

  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (sheetContext) {
      final draftSelection = <String>{};
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.8;
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;

      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.preparedMealPendingIngredientSelectionTitle,
                      style: Theme.of(dialogContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      ingredient,
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),
                    if (hidesByUnit)
                      Text(
                        key: pendingIngredientUnitHintKey,
                        l10n.preparedMealPendingIngredientSelectionUnitHint,
                        style: Theme.of(dialogContext).textTheme.bodySmall,
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: candidates.isEmpty
                          ? Center(child: Text(emptySelectionMessage))
                          : ListView.builder(
                              itemCount: candidates.length,
                              itemBuilder: (context, index) {
                                final item = candidates[index];
                                final isSelected = draftSelection.contains(
                                  item.id,
                                );
                                return AppCheckboxListTile(
                                  key: pendingIngredientOptionKey(item.id),
                                  value: isSelected,
                                  contentPadding: EdgeInsets.zero,
                                  secondary: _PendingIngredientPreview(
                                    imageUrl: item.imageUrl,
                                  ),
                                  title: Text(item.name),
                                  subtitle: Text(
                                    pendingIngredientInventoryAmount(item),
                                  ),
                                  onChanged: (checked) {
                                    setDialogState(() {
                                      if (checked ?? false) {
                                        draftSelection.add(item.id);
                                      } else {
                                        draftSelection.remove(item.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(l10n.inventoryReceiptReviewCancelAction),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton(
                          key: pendingIngredientSaveKey,
                          onPressed: () =>
                              Navigator.of(dialogContext)
                                  .pop(draftSelection.toList(growable: false)),
                          child: Text(
                            l10n.inventoryReceiptReviewManualDataSaveAction,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// How much of [item] is left, such as "600 g" or "2x".
String pendingIngredientInventoryAmount(InventoryItem item) {
  if (item.usesAmountProgress && item.amountUnit != null) {
    final amount = formatInventoryAmountValue(
      amount: item.currentAmount,
      unit: item.amountUnit!,
      scale: item.amountScale,
    );
    return '$amount ${item.amountUnit!.code}';
  }
  return '${item.quantity}x';
}
