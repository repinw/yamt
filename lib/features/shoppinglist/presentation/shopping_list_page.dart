import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_scope.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_trip_summary.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_order_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_scope_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_view.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_import_flow.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_entry_flow.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_finish_page.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_add_sheet.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_bottom_bar.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_content/shopping_list_content.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_scope_bar.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_suggestions.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines shopping list page.
class ShoppingListPage extends ConsumerStatefulWidget {
  /// The shopping list page.
  const new({
    this.suggestions = const AsyncData([]),
    this.suggestionsError,
    super.key,
  });

  /// Products a later feature suggests. They show as a strip over the tiles
  /// and as hits in the add sheet.
  final AsyncValue<List<ShoppingSuggestion>> suggestions;

  /// What shows in place of the strip when [suggestions] failed to load,
  /// composed by the feature that owns them.
  final Widget? suggestionsError;

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
    final isShared = ref.watch(shoppingListIsSharedProvider);
    final viewAsync = ref.watch(shoppingListViewProvider);
    final trip = viewAsync.value?.trip;
    final scope = ref.watch(shoppingListScopeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => _onBackPressed(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.homeShopping),
        actions: [
          IconButton(
            key: ShoppingListPageKeys.importButton,
            tooltip: l10n.shoppingImportTitle,
            onPressed: () => unawaited(showShoppingListImport(context)),
            icon: const Icon(Icons.playlist_add_rounded),
          ),
          _OrderButton(),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      bottomNavigationBar: ShoppingListBottomBar(
        onAdd: () => unawaited(
          showShoppingAddSheet(
            context,
            suggestions: widget.suggestions.asData?.value ?? const [],
          ),
        ),
        addLabel: switch (scope) {
          ShoppingListScope.household => l10n.shoppingListAddHousehold,
          ShoppingListScope.private => l10n.shoppingListAddPrivate,
          ShoppingListScope.both => null,
        },
        onFinish: trip == null || trip.cart.isEmpty
            ? null
            : () => _finish(trip),
      ),
      body: viewAsync.when(
        data: (view) => ShoppingListContent(
          view: view,
          scopeBar: isShared
              ? ShoppingListScopeBar(counts: view.scopeCounts)
              : null,
          suggestionStrip: ShoppingListSuggestions(
            key: const ValueKey('shopping-suggestions'),
            suggestions: widget.suggestions,
            error: widget.suggestionsError,
          ),
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

  Future<void> _finish(ShoppingTripSummary trip) async {
    final finish = await showShoppingListFinishPage(context, trip: trip);
    if (finish != true || !mounted) return;
    await ShoppingListEntryFlow.run(
      context,
      ref,
      (controller) => controller.finishTrip(
        shows: ref.read(shoppingListScopeControllerProvider).shows,
      ),
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

/// Switches the list between "by shelf" and "as added"; shows the order in
/// use.
class _OrderButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final order = ref.watch(shoppingListOrderControllerProvider);
    return TextButton.icon(
      key: ShoppingListPageKeys.orderButton,
      onPressed: () => unawaited(
        ref.read(shoppingListOrderControllerProvider.notifier).toggle(),
      ),
      icon: const Icon(Icons.sort_rounded),
      label: Text(
        order == ShoppingListOrder.byShelf
            ? l10n.shoppingListOrderByShelf
            : l10n.shoppingListOrderByName,
      ),
    );
  }
}
