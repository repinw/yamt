import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The entries in the cart as chips; a tap puts one back on the list.
class ShoppingListCartSection extends StatelessWidget {
  /// Creates the section.
  const new({required this.items, required this.onPutBack, super.key});

  /// The entries in the cart.
  final List<ShoppingListItem> items;

  /// Called with the tapped entry.
  final ValueChanged<ShoppingListItem> onPutBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.shoppingListCartTitle,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final item in items)
              ActionChip(
                key: ShoppingListPageKeys.cartChip(item.id),
                avatar: Icon(
                  Icons.check_rounded,
                  color: colors.onPrimaryContainer,
                ),
                label: Text(
                  item.quantity > 1
                      ? l10n.shoppingListCartEntry(item.quantity, item.name)
                      : item.name,
                  overflow: TextOverflow.ellipsis,
                ),
                backgroundColor: colors.primaryContainer,
                side: BorderSide.none,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onPressed: () => onPutBack(item),
              ),
          ],
        ),
      ],
    );
  }
}
