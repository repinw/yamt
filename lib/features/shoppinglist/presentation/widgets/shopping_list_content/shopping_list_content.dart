import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_scope.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_ticks_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_view.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_private_list_status.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_entry_flow.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shelf/shopping_list_shelf_grid.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_cart_section.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_content/shopping_list_empty_state.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_entry_sheet.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_progress_header.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_saved_products.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The switch between the lists, the suggestions strip, the list as tiles
/// with the cart under them, then the saved products. Only the tiles in
/// view are built.
class ShoppingListContent extends ConsumerWidget {
  /// The shopping list content.
  const new({
    required this.view,
    this.suggestionStrip,
    this.scopeBar,
    super.key,
  });

  /// The list as it shows.
  final ShoppingListView view;

  /// Optional slot over the tiles, for the suggestions strip.
  final Widget? suggestionStrip;

  /// Optional slot at the top, for the switch between the lists.
  final Widget? scopeBar;

  void _toggle(BuildContext context, WidgetRef ref, ShoppingListItem item) =>
      unawaited(
        ref
            .read(shoppingListTicksControllerProvider.notifier)
            .toggle(
              item,
              save: ({required done}) => ShoppingListEntryFlow.run(
                context,
                ref,
                (controller) => controller.setDone(item.id, done: done),
              ),
            ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = view.sections;
    final l10n = AppLocalizations.of(context)!;
    // Keyed by their child, so a section that comes or goes above keeps
    // the state of the ones below.
    Widget box(Widget child) =>
        SliverToBoxAdapter(key: child.key, child: child);
    const gap = SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md));
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xs,
            AppSpacing.xxl,
            AppSpacing.xxxl,
          ),
          sliver: SliverMainAxisGroup(
            slivers: [
              if (scopeBar case final bar?) ...[box(bar), gap],
              if (view.scope != ShoppingListScope.household &&
                  ref.watch(shoppingPrivateListFailedProvider)) ...[
                box(
                  AppErrorRetryView(
                    message: l10n.shoppingPrivateListLoadFailed,
                    retryLabel: l10n.shoppingListRetryAction,
                    retryButtonKey: ShoppingListPageKeys.privateRetryButton,
                    onRetry: () => unawaited(
                      ref
                          .read(shoppingListControllerProvider.notifier)
                          .refresh(),
                    ),
                  ),
                ),
                gap,
              ],
              if (sections.entryCount > 0) ...[
                box(
                  ShoppingListProgressHeader(
                    doneCount: sections.doneCount,
                    entryCount: sections.entryCount,
                  ),
                ),
                gap,
              ],
              if (suggestionStrip case final strip?) box(strip),
              if (sections.entryCount == 0)
                box(const ShoppingListEmptyState())
              else
                ShoppingListShelfGrid(
                  groups: sections.tileGroups,
                  markPrivate:
                      scopeBar != null && view.scope == ShoppingListScope.both,
                  onTap: (item) => _toggle(context, ref, item),
                  onLongPress: (item) =>
                      unawaited(showShoppingListEntrySheet(context, item.id)),
                ),
              if (sections.cart.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xs),
                ),
                box(
                  ShoppingListCartSection(
                    items: sections.cart,
                    onPutBack: (item) => _toggle(context, ref, item),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
              box(
                ShoppingListSavedProducts(
                  key: const ValueKey('saved-products'),
                  items: sections.saved,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
