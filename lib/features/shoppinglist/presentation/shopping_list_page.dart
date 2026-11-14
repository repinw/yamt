import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_entry_flow.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_add_sheet.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_bottom_bar.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_content/shopping_list_content.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_finish_dialog.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_suggestions.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines shopping list page.
class ShoppingListPage extends ConsumerStatefulWidget {
  /// The shopping list page.
  const new({
    this.suggestions = const AsyncData([]),
    this.onRetrySuggestions,
    this.planNeedsSection,
    super.key,
  });

  /// Products a later feature suggests. They show as a strip over the tiles
  /// and as hits in the add sheet.
  final AsyncValue<List<ShoppingSuggestion>> suggestions;

  /// Loads [suggestions] again after they failed to load.
  final VoidCallback? onRetrySuggestions;

  /// Optional slot under the list, for what the plans need.
  final Widget? planNeedsSection;

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
    final controller = ref.read(shoppingListControllerProvider.notifier);
    final itemsAsync = ref.watch(shoppingListControllerProvider);
    final cartCount =
        itemsAsync.asData?.value.where((item) => item.isInCart).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => _onBackPressed(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.homeShopping),
      ),
      bottomNavigationBar: ShoppingListBottomBar(
        onAdd: () => unawaited(
          showShoppingAddSheet(
            context,
            suggestions: widget.suggestions.asData?.value ?? const [],
          ),
        ),
        onFinish: cartCount == 0 ? null : () => _finish(cartCount),
      ),
      body: itemsAsync.when(
        data: (items) => ShoppingListContent(
          items: items,
          suggestionStrip: ShoppingListSuggestions(
            key: const ValueKey('shopping-suggestions'),
            suggestions: widget.suggestions,
            onRetry: widget.onRetrySuggestions,
          ),
          planNeedsSection: widget.planNeedsSection,
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

  Future<void> _finish(int cartCount) async {
    final confirmed = await showShoppingListFinishDialog(
      context,
      cartCount: cartCount,
    );
    if (!confirmed || !mounted) return;
    await ShoppingListEntryFlow.run(
      context,
      ref,
      (controller) => controller.finishTrip(),
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
