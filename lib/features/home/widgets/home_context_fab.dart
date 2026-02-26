import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/home/home_tab_page.dart';
import 'package:yamt/features/home/widgets/home_inventory_fab_flow.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_add_options_sheet.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_quick_add_dialog.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class HomeContextFab extends ConsumerWidget {
  const HomeContextFab({super.key, required this.currentTab});

  final HomeTabType currentTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final flowState = ref.watch(receiptCaptureFlowControllerProvider);
    final batchState = ref.watch(receiptBatchFlowControllerProvider);
    final isBusy =
        currentTab == HomeTabType.inventory &&
        (flowState.isLoading ||
            batchState.status == ReceiptBatchFlowStatus.running);

    return FloatingActionButton.small(
      tooltip: _fabTooltip(l10n),
      onPressed: isBusy ? null : () => _onPressed(context, ref, l10n),
      child: _fabChild(isBusy),
    );
  }

  Widget _fabChild(bool isBusy) {
    if (!isBusy) {
      return const Icon(Icons.add);
    }
    return const SizedBox.square(
      dimension: AppSizes.inlineProgressIndicator,
      child: CircularProgressIndicator(
        strokeWidth: AppSizes.progressStrokeWidth,
      ),
    );
  }

  String _fabTooltip(AppLocalizations l10n) {
    return switch (currentTab) {
      HomeTabType.inventory => l10n.inventoryFabTooltip,
      HomeTabType.shopping => l10n.shoppingListAddAction,
      HomeTabType.calories => l10n.caloriesFabTooltip,
      HomeTabType.settings => l10n.homeQuickActionTooltip,
    };
  }

  Future<void> _onPressed(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    switch (currentTab) {
      case HomeTabType.inventory:
        await HomeInventoryFabFlow.openActionSheet(
          context: context,
          ref: ref,
          l10n: l10n,
        );
        return;
      case HomeTabType.shopping:
        await _openShoppingAddDialog(context, ref, l10n);
        return;
      case HomeTabType.calories:
        await _openCaloriesAddOptions(context);
        return;
      case HomeTabType.settings:
        _showSnackBar(context, l10n.homeSettingsActionContextPlaceholder);
        return;
    }
  }

  Future<void> _openShoppingAddDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return showShoppingQuickAddDialog(
      context: context,
      l10n: l10n,
      onSubmit: ({required name, required brand}) async {
        final controller = ref.read(shoppingListControllerProvider.notifier);
        return controller.addItem(name: name, brand: brand);
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCaloriesAddOptions(BuildContext context) async {
    final action = await showModalBottomSheet<_CaloriesAddAction>(
      context: context,
      builder: (sheetContext) {
        return CalorieAddOptionsSheet(
          onManualTap: () => sheetContext.pop(_CaloriesAddAction.manual),
          onBarcodeTap: () => sheetContext.pop(_CaloriesAddAction.barcode),
        );
      },
    );
    if (!context.mounted || action == null) {
      return;
    }

    switch (action) {
      case _CaloriesAddAction.manual:
        context.push(AppRoutes.homeCaloriesEntryCreate);
        return;
      case _CaloriesAddAction.barcode:
        context.push(AppRoutes.homeCaloriesBarcodeScan);
        return;
    }
  }
}

enum _CaloriesAddAction { manual, barcode }
