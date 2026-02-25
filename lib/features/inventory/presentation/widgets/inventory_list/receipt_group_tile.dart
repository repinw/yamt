import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _receiptGroupBorderAlphaLight = 0.14;
const _receiptGroupBorderAlphaDark = 0.24;
const _receiptGroupBorderWidth = 0.7;
const _receiptGroupElevation = 0.0;

class ReceiptGroupTile extends StatelessWidget {
  const ReceiptGroupTile({
    super.key,
    required this.group,
    required this.currency,
    required this.dateFormat,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
  });

  final InventoryReceiptGroup group;
  final NumberFormat currency;
  final DateFormat dateFormat;
  final Future<bool> Function(String itemId) onDeleteItem;
  final Future<bool> Function(String itemId, int amount) onEatItem;
  final Future<bool> Function(String itemId, int amount) onThrowAwayItem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final borderColor = _resolveBorderColor(colors);
    final title = group.title(l10n: l10n, dateFormat: dateFormat);
    final subtitle = group.subtitle(l10n: l10n, currency: currency);

    return Card(
      margin: EdgeInsets.zero,
      elevation: _receiptGroupElevation,
      surfaceTintColor: Colors.transparent,
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: borderColor, width: _receiptGroupBorderWidth),
      ),
      child: ExpansionTile(
        key: PageStorageKey<String>('receipt_group_${group.key}'),
        initiallyExpanded: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        children: group.items
            .map((item) {
              return InventoryItemRowListEntry(
                item: item,
                keyPrefix: 'receipt_item_row',
                bottomSpacing: AppSpacing.sm,
                l10n: l10n,
                currency: currency,
                onDeleteItem: onDeleteItem,
                onEatItem: onEatItem,
                onThrowAwayItem: onThrowAwayItem,
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Color _resolveBorderColor(ColorScheme colors) {
    final alpha = colors.brightness == Brightness.dark
        ? _receiptGroupBorderAlphaDark
        : _receiptGroupBorderAlphaLight;

    return Color.alphaBlend(
      colors.outlineVariant.withValues(alpha: alpha),
      colors.surface,
    );
  }
}
