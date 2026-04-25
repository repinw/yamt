import 'package:intl/intl.dart';
import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory receipt group.
class InventoryReceiptGroup {
  /// The inventory receipt group.
  const InventoryReceiptGroup({
    required this.key,
    required this.receiptId,
    required this.receiptDate,
    required this.storeName,
    required this.items,
    required this.totalValue,
    required this.currencyCode,
  });

  /// Creates a [InventoryReceiptGroup] for from items.
  factory InventoryReceiptGroup.fromItems(
    String key,
    List<InventoryItem> items,
  ) {
    final sortedItems = List<InventoryItem>.from(items)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    DateTime? latestReceiptDate;
    String? firstReceiptId;
    for (final item in sortedItems) {
      final candidateDate = item.receiptDate;
      if (candidateDate != null) {
        if (latestReceiptDate == null ||
            candidateDate.isAfter(latestReceiptDate)) {
          latestReceiptDate = candidateDate;
        }
      }

      final candidateId = item.receiptId?.trim();
      if (firstReceiptId == null &&
          candidateId != null &&
          candidateId.isNotEmpty) {
        firstReceiptId = candidateId;
      }
    }

    final store = sortedItems.isEmpty ? '' : sortedItems.first.storeName;
    final value = sortedItems.fold<double>(0, (sum, item) {
      return sum + (item.quantity * item.unitPrice);
    });
    final currencyCode = resolveSharedCurrencyCode(
      sortedItems.map((item) => item.currencyCode),
    );

    return InventoryReceiptGroup(
      key: key,
      receiptId: firstReceiptId,
      receiptDate: latestReceiptDate,
      storeName: store,
      items: sortedItems,
      totalValue: value,
      currencyCode: currencyCode,
    );
  }

  /// The key.
  final String key;

  /// The receipt id.
  final String? receiptId;

  /// The receipt date.
  final DateTime? receiptDate;

  /// The store name.
  final String storeName;

  /// The items.
  final List<InventoryItem> items;

  /// The total value.
  final double totalValue;

  /// The currency code.
  final String? currencyCode;

  /// Whether receipt.
  bool get hasReceipt {
    final id = receiptId;
    return id != null && id.isNotEmpty;
  }

  /// Title.
  String title({
    required AppLocalizations l10n,
    required DateFormat dateFormat,
  }) {
    if (!hasReceipt) {
      return l10n.inventoryReceiptGroupNoReceipt;
    }

    final date = receiptDate;
    if (date != null) {
      return '${l10n.inventoryReceiptGroupTitle} ${dateFormat.format(date)}';
    }

    final id = receiptId;
    if (id == null || id.isEmpty) {
      return l10n.inventoryReceiptGroupTitle;
    }

    final shortId = id.length <= 6 ? id : id.substring(0, 6);
    return '${l10n.inventoryReceiptGroupTitle} #$shortId';
  }

  /// Subtitle.
  String subtitle({
    required AppLocalizations l10n,
    required String localeName,
  }) {
    final safeStore = storeName.trim().isEmpty ? '-' : storeName;
    final itemCount = items.length;
    final currency = buildCurrencyFormat(
      locale: localeName,
      currencyCode: currencyCode,
    );
    final total = currency.format(totalValue);
    return '$safeStore · $itemCount ${l10n.inventoryReceiptGroupItems} · '
        '$total';
  }
}

/// Group inventory items by receipt.
List<InventoryReceiptGroup> groupInventoryItemsByReceipt(
  List<InventoryItem> source,
) {
  final grouped = <String, List<InventoryItem>>{};

  for (final item in source) {
    final key = _groupKey(item);
    grouped.putIfAbsent(key, () => <InventoryItem>[]).add(item);
  }

  final groups = grouped.entries
      .map((entry) {
        return InventoryReceiptGroup.fromItems(entry.key, entry.value);
      })
      .toList(growable: false);

  return groups..sort(_compareGroups);
}

int _compareGroups(InventoryReceiptGroup a, InventoryReceiptGroup b) {
  if (a.hasReceipt != b.hasReceipt) {
    return a.hasReceipt ? -1 : 1;
  }

  final aDate = a.receiptDate;
  final bDate = b.receiptDate;
  if (aDate != null && bDate != null) {
    final dateCompare = bDate.compareTo(aDate);
    if (dateCompare != 0) {
      return dateCompare;
    }
  }
  if (aDate != null && bDate == null) {
    return -1;
  }
  if (aDate == null && bDate != null) {
    return 1;
  }

  return a.storeName.toLowerCase().compareTo(b.storeName.toLowerCase());
}

String _groupKey(InventoryItem item) {
  final receiptId = item.receiptId?.trim();
  if (receiptId != null && receiptId.isNotEmpty) {
    return 'receipt:$receiptId';
  }
  return 'store:${item.storeName.trim().toLowerCase()}';
}
