import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_content.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_state_views.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

export 'widgets/shopping_list_page_keys.dart';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final currency = NumberFormat.currency(locale: locale, symbol: '€');
    final controller = ref.read(shoppingListControllerProvider.notifier);
    final itemsAsync = ref.watch(shoppingListControllerProvider);

    return itemsAsync.when(
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
    );
  }
}
