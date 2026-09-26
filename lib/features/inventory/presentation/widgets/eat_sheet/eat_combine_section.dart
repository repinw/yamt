import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/application/inventory_combined_eat_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_manual_add_amount_service.dart';
import 'package:yamt/features/inventory/domain/inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_combine_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_combine_pick_page.dart';
import 'package:yamt/features/inventory/presentation/inventory_manual_add_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_framed_box.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_label_title.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_text_link.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Hub section to log other stock items together with [hubItem].
///
/// Shows a link while nothing is picked, then the list of foods to log
/// together.
class EatCombineSection extends ConsumerWidget {
  /// Creates the section.
  const new({required this.hubItem, super.key});

  /// Key of the link that adds a food.
  static const addKey = Key('eat_combine_add');

  /// The hub's item.
  final InventoryItem hubItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final picks = ref.watch(inventoryItemCombineControllerProvider(hubItem.id));
    final addLink = EatTextLink(
      buttonKey: addKey,
      label: picks.isEmpty ? l10n.eatPageCombineLink : l10n.eatPageCombineAdd,
      onPressed: () => _add(context, ref),
    );
    if (picks.isEmpty) {
      return addLink;
    }
    return EatFramedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EatLabelTitle(text: l10n.eatPageCombineTitle),
          _FoodLine(name: hubItem.name, amount: l10n.eatPageCombineAmountAbove),
          for (final pick in picks)
            _FoodLine(
              name: pick.item.name,
              amount: pick.component.amountLabel,
              kcal: l10n.eatPageKcal(pick.component.totalKcal.round()),
              onRemove: () => ref
                  .read(
                    inventoryItemCombineControllerProvider(hubItem.id).notifier,
                  )
                  .remove(pick.item.id),
            ),
          addLink,
        ],
      ),
    );
  }

  /// Opens the inventory to pick foods, then asks the amount of each.
  /// A food whose amount page is closed is left out.
  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(
      inventoryItemCombineControllerProvider(hubItem.id).notifier,
    );
    final items = ref.read(inventoryItemsControllerProvider).value;
    final picked = await showInventoryCombinePickPage(
      context,
      candidates: notifier.candidatesFrom(items ?? const <InventoryItem>[]),
    );
    if (picked == null) {
      return;
    }
    final searched = picked.searched;
    for (final (item, searchResult) in [
      for (final item in picked.stock) (item, null),
      if (searched != null) (searched.item, searched),
    ]) {
      if (!context.mounted) {
        return;
      }
      final request = await _askAmount(context, item, searchResult);
      if (request == null || !context.mounted) {
        continue;
      }
      if (!InventoryCombinedEatService.canCombine(item) ||
          !canDirectlySaveInventoryItemEatRequest(item, request)) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          AppLocalizations.of(context)!.inventoryItemActionFailed,
          tone: AppSnackBarTone.error,
        );
        continue;
      }
      notifier.add(item, request, searchResult: searchResult);
    }
  }

  /// A food found by search has no stock yet, so its amount is open.
  static Future<InventoryItemEatRequest?> _askAmount(
    BuildContext context,
    InventoryItem item,
    InventoryReceiptManualProductResult? searchResult,
  ) async {
    if (searchResult == null) {
      return await showInventoryItemEatSheet(context: context, item: item);
    }
    final selected = inventoryManualAddEatRequestFromSelection(
      searchResult.eatSelection,
    );
    if (selected != null) {
      return selected;
    }
    final result = await showInventoryItemEatSheetResult(
      context: context,
      item: item,
      initialInventoryAmount: resolveInventoryManualAddInitialConsumedAmount(
        item: item,
        rawWeight: item.weight,
      ),
      hasOpenStock: true,
    );
    return result?.request;
  }
}

class _FoodLine extends StatelessWidget {
  const new({
    required this.name,
    required this.amount,
    this.kcal,
    this.onRemove,
  });

  final String name;
  final String amount;
  final String? kcal;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontFamily: AppFonts.mono, color: colors.ink);
    final kcalText = kcal;
    final remove = onRemove;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.ink)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
        child: Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(
              child: Text(
                '$name · $amount',
                style: style?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (kcalText != null) Text(kcalText, style: style),
            if (remove != null)
              IconButton(
                tooltip: l10n.eatPageCombineRemove,
                onPressed: remove,
                icon: Icon(Icons.close_rounded, color: colors.muted),
              ),
          ],
        ),
      ),
    );
  }
}
