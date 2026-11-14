import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_import_review.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shelf/shopping_shelf_labels.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_import/shopping_import_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One product of the import review: the checkbox that keeps it, its shelf
/// picture, the name to tap for a new one, where it goes, and how many.
class ShoppingImportRowTile extends StatelessWidget {
  /// Creates the tile of [row], the product at [index].
  const new({
    required this.index,
    required this.row,
    required this.onToggle,
    required this.onRename,
    super.key,
  });

  /// The position of the product in the review.
  final int index;

  /// The product.
  final ShoppingImportRow row;

  /// Selects or unselects the product.
  final VoidCallback onToggle;

  /// Asks for a new name.
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final line = row.line;
    final listed = row.listedQuantity;
    final place = listed != null
        ? l10n.shoppingImportAlreadyListed(listed)
        : row.isShelfKnown
        ? shoppingShelfLabel(l10n, row.shelf)
        : l10n.shoppingImportNotInCatalog;
    final note = line.note;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Checkbox(
            key: ShoppingImportKeys.rowCheckbox(index),
            value: row.isSelected,
            onChanged: (_) => onToggle(),
            semanticLabel: line.name,
          ),
          Icon(
            shoppingItemIconData(row.icon),
            color: row.isSelected ? colors.primary : colors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppInkWell(
              key: ShoppingImportKeys.rowName(index),
              onTap: onRename,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: row.isSelected
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      note == null
                          ? place
                          : l10n.shoppingImportRowWithNote(place, note),
                      key: ShoppingImportKeys.rowDetail(index),
                      style: muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // On an entry already listed, the amount only goes on top when
          // the row is ticked; unticked it would read as added anyway.
          if (listed == null || row.isSelected) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              listed != null
                  ? l10n.shoppingImportQuantityOnTop(line.quantity)
                  : l10n.shoppingImportQuantity(line.quantity),
              key: ShoppingImportKeys.rowQuantity(index),
              style: theme.textTheme.titleSmall,
            ),
          ],
        ],
      ),
    );
  }
}
