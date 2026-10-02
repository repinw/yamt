import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/domain/product_missing_values.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_missing_values_hint.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Quiet line on a receipt item that names what its matched product lacks,
/// such as "Still missing: Package size, Salt". Shows nothing when the
/// product is complete, missing, or the item is ignored.
class ReceiptItemMissingValuesLine extends StatelessWidget {
  /// Creates the line for [item].
  const new({required this.item, super.key});

  /// The receipt item.
  final ReceiptLineItem item;

  @override
  Widget build(BuildContext context) {
    final product = item.matchedProduct;
    if (product == null || item.status == ReceiptItemStatus.ignored) {
      return const SizedBox.shrink();
    }
    // A receipt product carries no serving, so grams per piece are unknown
    // here, not missing. The Vorrat pages name them.
    final size = missingPackageSize(
      packageSize: item.packageWeight ?? product.packageSize,
      servingQuantity: null,
      servingQuantityUnit: null,
    );
    final missing = [
      if (size == ProductMissingValue.packageSize) size!,
      ...missingNutritionValues(product.nutrition),
    ];
    if (missing.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l10n.productEditorMissing(productMissingValuesText(l10n, missing)),
          key: Key('receipt_item_missing_values_${item.id}'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
