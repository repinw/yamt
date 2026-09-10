import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/shoppinglist/application/shopping_suggestions.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_content/shopping_list_content.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_quick_add_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines shopping list page.
@Dependencies([shoppingSuggestions, shoppingSuggestionRetry])
class ShoppingListPage extends ConsumerStatefulWidget {
  /// The shopping list page.
  const ShoppingListPage({super.key});

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  late final AppLifecycleListener _lifecycle;
  late final Timer _scheduleTimer;
  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _processDue);
    _scheduleTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _processDue(),
    );
  }

  @override
  void dispose() {
    _scheduleTimer.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _processDue() =>
      unawaited(ref.read(shoppingListControllerProvider.notifier).processDue());

  @override
  Widget build(BuildContext context) {
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openShoppingAddDialog(
          context: context,
          controller: controller,
          l10n: l10n,
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.shoppingListAddAction),
      ),
      body: itemsAsync.when(
        data: (items) => ShoppingListContent(
          items: items,
          controller: controller,
          l10n: l10n,
          currency: currency,
        ),
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorRetryView(
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
