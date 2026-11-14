import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_sections.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_entry_flow.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_cart_section.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_content/shopping_list_empty_state.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_entry_grid.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_entry_sheet.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_progress_header.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_saved_products.dart';

/// The suggestions strip, the list as tiles with the cart under them, then
/// the saved products and what the plans need.
class ShoppingListContent extends ConsumerStatefulWidget {
  /// The shopping list content.
  const new({
    required this.items,
    this.suggestionStrip,
    this.planNeedsSection,
    super.key,
  });

  /// The items.
  final List<ShoppingListItem> items;

  /// Optional slot over the tiles, for the suggestions strip.
  final Widget? suggestionStrip;

  /// Optional slot under the list, for what the plans need.
  final Widget? planNeedsSection;

  @override
  ConsumerState<ShoppingListContent> createState() =>
      _ShoppingListContentState();
}

class _ShoppingListContentState extends ConsumerState<ShoppingListContent> {
  /// Entries ticked a moment ago, each with the timer that lets it go.
  final _justTicked = <String, Timer>{};

  /// The done state of taps whose save has not finished, by entry id. Saves
  /// run one after another, so the list state can lag behind the finger.
  final _pendingDone = <String, ({bool done, int change})>{};
  var _changes = 0;

  @override
  void dispose() {
    for (final timer in _justTicked.values) {
      timer.cancel();
    }
    super.dispose();
  }

  /// Sections work on [ShoppingListSections], which already applied
  /// [_pendingDone], so [item] carries the state the user sees.
  void _toggle(ShoppingListItem item) {
    final done = !item.isDone;
    final change = ++_changes;
    setState(() {
      _pendingDone[item.id] = (done: done, change: change);
      _justTicked.remove(item.id)?.cancel();
      if (done) {
        _justTicked[item.id] = Timer(AppShopping.tickLinger, () {
          if (mounted) setState(() => _justTicked.remove(item.id));
        });
      }
    });
    unawaited(_save(item.id, done: done, change: change));
  }

  Future<void> _save(
    String id, {
    required bool done,
    required int change,
  }) async {
    await ShoppingListEntryFlow.run(
      context,
      ref,
      (controller) => controller.setDone(id, done: done),
    );
    // Saved or failed: the list state is right again, unless a later tap on
    // the same entry is still on its way.
    if (mounted && _pendingDone[id]?.change == change) {
      setState(() => _pendingDone.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = ShoppingListSections(
      widget.items,
      justTicked: _justTicked.keys.toSet(),
      pendingDone: {
        for (final MapEntry(:key, :value) in _pendingDone.entries)
          key: value.done,
      },
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xs,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ),
      children: [
        if (sections.entryCount > 0) ...[
          ShoppingListProgressHeader(
            doneCount: sections.doneCount,
            entryCount: sections.entryCount,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        ?widget.suggestionStrip,
        if (sections.entryCount == 0)
          const ShoppingListEmptyState()
        else
          ShoppingListEntryGrid(
            items: sections.tiles,
            onTap: _toggle,
            onLongPress: (item) =>
                unawaited(showShoppingListEntrySheet(context, item.id)),
          ),
        if (sections.cart.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          ShoppingListCartSection(items: sections.cart, onPutBack: _toggle),
        ],
        const SizedBox(height: AppSpacing.xl),
        ShoppingListSavedProducts(
          key: const ValueKey('saved-products'),
          items: sections.saved,
        ),
        ?widget.planNeedsSection,
      ],
    );
  }
}
