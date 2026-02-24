import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_item_tile.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_stats_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({super.key});

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final currency = NumberFormat.currency(locale: locale, symbol: '€');
    final items = ref.watch(shoppingListControllerProvider);
    final estimatedTotal = items.fold<double>(0.0, (sum, item) {
      return sum + item.estimatedTotal;
    });
    final totalQuantity = items.fold<int>(0, (sum, item) {
      return sum + item.quantity;
    });

    return Column(
      children: [
        Padding(
          padding: AppInsets.page,
          child: ShoppingListStatsCard(
            entryCount: items.length,
            totalQuantity: totalQuantity,
            estimatedTotal: estimatedTotal,
            currency: currency,
            l10n: l10n,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: _ShoppingListAddCard(
            nameController: _nameController,
            brandController: _brandController,
            l10n: l10n,
            onSubmit: _onSubmit,
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    l10n.shoppingListEmptyState,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.xxxxl + AppSpacing.xxxxl,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ShoppingListItemTile(
                      item: item,
                      l10n: l10n,
                      currency: currency,
                      onDismissed: _onDismissed,
                      onIncrement: _onIncrement,
                      onDecrement: _onDecrement,
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _onSubmit(AppLocalizations l10n) {
    final controller = ref.read(shoppingListControllerProvider.notifier);
    final added = controller.addItem(
      name: _nameController.text,
      brand: _brandController.text,
    );
    if (!added) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.shoppingListInvalidNameError)),
      );
      return;
    }

    _nameController.clear();
    _brandController.clear();
  }

  void _onDismissed(String itemId) {
    ref.read(shoppingListControllerProvider.notifier).removeItem(itemId);
  }

  void _onIncrement(String itemId) {
    ref.read(shoppingListControllerProvider.notifier).incrementQuantity(itemId);
  }

  void _onDecrement(String itemId) {
    ref.read(shoppingListControllerProvider.notifier).decrementQuantity(itemId);
  }
}

class _ShoppingListAddCard extends StatelessWidget {
  const _ShoppingListAddCard({
    required this.nameController,
    required this.brandController,
    required this.l10n,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController brandController;
  final AppLocalizations l10n;
  final ValueChanged<AppLocalizations> onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          children: [
            TextField(
              key: const Key('shopping_list_name_field'),
              controller: nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.shoppingListNameFieldLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('shopping_list_brand_field'),
              controller: brandController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(l10n),
              decoration: InputDecoration(
                labelText: l10n.shoppingListBrandFieldLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const Key('shopping_list_add_button'),
                onPressed: () => onSubmit(l10n),
                icon: const Icon(Icons.add),
                label: Text(l10n.shoppingListAddAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
