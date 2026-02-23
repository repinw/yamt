import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/provider/fridge_items_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(fridgeItemsControllerProvider, _logLoadErrorOnce);

    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(fridgeItemsControllerProvider.notifier);
    final itemsAsync = ref.watch(fridgeItemsControllerProvider);

    return itemsAsync.when(
      data: (items) => InventoryList(
        items: items,
        onDeleteItem: controller.deleteItem,
        onEatItem: controller.eatItem,
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
    AsyncValue<List<dynamic>>? previous,
    AsyncValue<List<dynamic>> next,
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
