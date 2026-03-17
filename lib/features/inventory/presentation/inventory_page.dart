import 'dart:developer' as developer;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_calorie_bridge_flow.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(inventoryItemsControllerProvider, _logLoadErrorOnce);

    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final itemsAsync = ref.watch(inventoryItemsControllerProvider);

    return itemsAsync.when(
      data: (items) => InventoryList(
        items: items,
        onDeleteItem: controller.deleteItem,
        onEatItem: (itemId, amount) => _eatItemWithCalorieBridge(
          context: context,
          ref: ref,
          itemId: itemId,
          amount: amount,
          itemsSnapshot: items,
        ),
        onThrowAwayItem: controller.throwAwayItem,
      ),
      loading: () => const _InventoryLoadingView(),
      error: (error, stackTrace) => _InventoryErrorView(
        onRetry: controller.refresh,
        message: l10n.inventoryLoadFailed,
        retryLabel: l10n.inventoryRetryAction,
      ),
    );
  }

  void _logLoadErrorOnce(
    AsyncValue<List<InventoryItem>>? previous,
    AsyncValue<List<InventoryItem>> next,
  ) {
    final nextError = next.asError;
    if (nextError == null) {
      return;
    }

    final previousError = previous?.asError;
    final unchangedError = identical(previousError?.error, nextError.error);
    final unchangedStack = previousError?.stackTrace == nextError.stackTrace;
    if (unchangedError && unchangedStack) {
      return;
    }

    developer.log(
      'Failed to load inventory items.',
      name: 'InventoryPage',
      error: nextError.error,
      stackTrace: nextError.stackTrace,
    );
  }

  Future<bool> _eatItemWithCalorieBridge({
    required BuildContext context,
    required WidgetRef ref,
    required String itemId,
    required int amount,
    required List<InventoryItem> itemsSnapshot,
  }) async {
    InventoryItem? selectedItem;
    for (final item in itemsSnapshot) {
      if (item.id == itemId) {
        selectedItem = item;
        break;
      }
    }

    final saved = await ref
        .read(inventoryItemsControllerProvider.notifier)
        .eatItem(itemId, amount);
    if (!saved || selectedItem == null || !context.mounted) {
      return saved;
    }

    unawaited(
      InventoryCalorieBridgeFlow.onEatCompleted(
        context: context,
        ref: ref,
        itemBeforeMutation: selectedItem,
        consumedAmount: amount,
      ),
    );
    return true;
  }
}

class _InventoryLoadingView extends StatelessWidget {
  const _InventoryLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: AppSizes.inlineProgressIndicator,
        child: CircularProgressIndicator(
          strokeWidth: AppSizes.progressStrokeWidth,
        ),
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
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: AppInsets.pageLarge,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: AppInsets.card,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_tethering_error_rounded,
                  color: colors.error,
                  size: AppSizes.welcomeIcon * 0.45,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(retryLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
