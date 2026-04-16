import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_content.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_state_views.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_quick_add_dialog.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines shopping list page.
class ShoppingListPage extends ConsumerWidget {
  /// The shopping list page.
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final currency = NumberFormat.currency(locale: locale, symbol: '€');
    final controller = ref.read(shoppingListControllerProvider.notifier);
    final itemsAsync = ref.watch(shoppingListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => _onBackPressed(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.homeShopping),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openShoppingAddDialog(
          context: context,
          controller: controller,
          l10n: l10n,
        ),
        child: const Icon(Icons.add),
      ),
      body: itemsAsync.when(
        data: (items) => ShoppingListContent(
          items: items,
          controller: controller,
          l10n: l10n,
          currency: currency,
        ),
        loading: () => const ShoppingListLoadingView(),
        error: (error, stackTrace) => ShoppingListErrorView(
          onRetry: controller.refresh,
          message: l10n.shoppingListLoadFailed,
          retryLabel: l10n.shoppingListRetryAction,
        ),
      ),
    );
  }

  Future<void> _openShoppingAddDialog({
    required BuildContext context,
    required ShoppingListController controller,
    required AppLocalizations l10n,
  }) {
    return showShoppingQuickAddDialog(
      context: context,
      l10n: l10n,
      onSubmit: ({required name, required brand}) {
        return controller.addItem(name: name, brand: brand);
      },
    );
  }

  void _onBackPressed(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.homeInventory);
  }
}
