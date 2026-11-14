import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_entry_flow.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_letter_disc.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_schedule_dialog/shopping_list_schedule_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the details of the entry with [itemId]: quantity, schedule,
/// favorite, and the two ways off the list.
Future<void> showShoppingListEntrySheet(BuildContext context, String itemId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _EntrySheet(itemId: itemId),
    );

class _EntrySheet extends ConsumerWidget {
  const new({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(
      shoppingListControllerProvider.select(
        (state) => state.asData?.value.where(_isShown).firstOrNull,
      ),
    );
    ref.listen(
      shoppingListControllerProvider.select(
        (state) => state.asData?.value.any(_isShown) ?? true,
      ),
      (_, onList) {
        // Gone from another device: nothing is left to show.
        if (!onList && (ModalRoute.of(context)?.isCurrent ?? false)) {
          Navigator.of(context).pop();
        }
      },
    );
    if (item == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final schedule = shoppingScheduleSummary(context, item);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        0,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(item: item),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            key: ShoppingListPageKeys.sheetSchedule,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_repeat),
            title: Text(l10n.shoppingListSchedule),
            subtitle: schedule == null ? null : Text(schedule),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ShoppingListEntryFlow.editSchedule(context, ref, item),
          ),
          AppSwitchListTile(
            key: ShoppingListPageKeys.sheetFavorite,
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.star_rounded),
            title: Text(l10n.shoppingListFavorite),
            value: item.isFavorite,
            onChanged: (_) =>
                ShoppingListEntryFlow.toggleFavorite(context, ref, item),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            key: ShoppingListPageKeys.sheetCartButton,
            onPressed: () => _leave(
              context,
              ref,
              (controller) => controller.setDone(item.id, done: !item.isDone),
            ),
            child: Text(
              item.isDone
                  ? l10n.shoppingListPutBackAction
                  : l10n.shoppingListMoveToCartAction,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            key: ShoppingListPageKeys.sheetRemoveButton,
            onPressed: () => _leave(context, ref, (c) => c.removeItem(item.id)),
            child: Text(l10n.shoppingListRemoveFromListAction),
          ),
        ],
      ),
    );
  }

  bool _isShown(ShoppingListItem item) => item.id == itemId && !item.isArchived;

  void _leave(
    BuildContext context,
    WidgetRef ref,
    Future<bool> Function(ShoppingListController controller) action,
  ) {
    unawaited(ShoppingListEntryFlow.run(context, ref, action));
    Navigator.of(context).pop();
  }
}

class _Header extends ConsumerWidget {
  const new({required this.item});

  final ShoppingListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = item.brand ?? '';
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShoppingListLetterDisc(
              name: item.name,
              size: AppShopping.sheetLetterDisc,
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.name, style: theme.textTheme.titleLarge),
                  if (brand.isNotEmpty)
                    Text(
                      brand,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.shoppingListDecreaseQuantityAction,
              onPressed: item.quantity > 1
                  ? () => ShoppingListEntryFlow.run(
                      context,
                      ref,
                      (controller) => controller.decrementQuantity(item.id),
                    )
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '${item.quantity}',
              key: ShoppingListPageKeys.sheetQuantity,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              tooltip: l10n.shoppingListIncreaseQuantityAction,
              onPressed: () => ShoppingListEntryFlow.run(
                context,
                ref,
                (controller) => controller.incrementQuantity(item.id),
              ),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}
