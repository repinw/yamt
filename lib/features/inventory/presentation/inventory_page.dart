import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/provider/fridge_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(fridgeItemsControllerProvider.notifier);
    final itemsAsync = ref.watch(fridgeItemsControllerProvider);

    return itemsAsync.when(
      data: (items) => _InventoryListView(
        items: items,
        onRefresh: controller.refresh,
        emptyMessage: l10n.inventoryEmptyState,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _InventoryErrorView(
        onRetry: () {
          controller.refresh();
        },
        message: l10n.inventoryLoadFailed,
        retryLabel: l10n.inventoryRetryAction,
      ),
    );
  }
}

class _InventoryErrorView extends StatelessWidget {
  const _InventoryErrorView({
    required this.onRetry,
    required this.message,
    required this.retryLabel,
  });

  final VoidCallback onRetry;
  final String message;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}

class _InventoryListView extends StatelessWidget {
  const _InventoryListView({
    required this.items,
    required this.onRefresh,
    required this.emptyMessage,
  });

  final List<FridgeItem> items;
  final Future<void> Function() onRefresh;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyMessage, textAlign: TextAlign.center),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: const Icon(Icons.kitchen_outlined),
            title: Text(item.name),
            subtitle: Text(item.brand ?? item.storeName),
            trailing: Text('${item.quantity}'),
          );
        },
      ),
    );
  }
}
