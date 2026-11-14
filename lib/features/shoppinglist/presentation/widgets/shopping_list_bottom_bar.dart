import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The bar under the list: add an entry, finish the shopping trip.
class ShoppingListBottomBar extends StatelessWidget {
  /// Creates the bar.
  const new({required this.onAdd, required this.onFinish, super.key});

  /// Opens the add dialog.
  final VoidCallback onAdd;

  /// Finishes the trip; null while nothing is in the cart.
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xs,
        AppSpacing.xxl,
        AppSpacing.xl,
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              key: ShoppingListPageKeys.addButton,
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(
                l10n.shoppingListAddAction,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            key: ShoppingListPageKeys.finishButton,
            onPressed: onFinish,
            child: Text(l10n.shoppingListFinishAction),
          ),
        ],
      ),
    );
  }
}
