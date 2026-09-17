import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/diary/application/'
    'diary_quick_eat_inventory_provider.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_quick_eat_flow_support.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_calorie_bridge_flow.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_picker.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _diaryQuickEatFlowLogName = 'DiaryQuickEatFlow';

/// Eats an inventory item from the diary quick-eat flow.
Future<void> eatDiaryQuickEatInventoryItem({
  required BuildContext context,
  required InventoryItem item,
  required MealType mealType,
  required DateTime loggedAt,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final container = ProviderScope.containerOf(context, listen: false);
  final maxAmount = maxDiaryQuickEatInventoryAmount(item);
  if (maxAmount == null) {
    return;
  }
  final request = await container
      .read(inventoryQuickEatPickerProvider)
      .pickItem(
        context: context,
        item: item,
        maxAmount: maxAmount,
        invalidAmountMessage: l10n.inventoryReceiptReviewInvalidNumber,
        initialLoggedAt: loggedAt,
        initialMealType: mealType,
      );
  if (!context.mounted || request == null) {
    return;
  }
  await _completeInventoryItemEatFlow(
    context: context,
    item: item,
    request: request,
  );
}

Future<void> _completeInventoryItemEatFlow({
  required BuildContext context,
  required InventoryItem item,
  required InventoryItemEatRequest request,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  try {
    await withDiaryQuickEatActions(
      container: container,
      action: () => _runInventoryItemEatMutation(
        context: context,
        container: container,
        item: item,
        request: request,
        messenger: messenger,
        failureMessage: l10n.inventoryItemActionFailed,
      ),
    );
  } on Object catch (error, stackTrace) {
    log(
      'Diary inventory item eat flow failed.',
      name: _diaryQuickEatFlowLogName,
      error: error,
      stackTrace: stackTrace,
    );
    if (context.mounted) {
      showDiaryQuickEatSnackBarWithMessenger(
        messenger,
        l10n.inventoryItemActionFailed,
      );
    }
  }
}

Future<void> _runInventoryItemEatMutation({
  required BuildContext context,
  required ProviderContainer container,
  required InventoryItem item,
  required InventoryItemEatRequest request,
  required ScaffoldMessengerState messenger,
  required String failureMessage,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final pendingConsumptionId = await _stageInventoryItemConsumption(
    context: context,
    container: container,
    item: item,
    amount: request.inventoryAmount,
  );
  if (!context.mounted) {
    if (pendingConsumptionId != null) {
      await _discardInventoryItemConsumption(container, pendingConsumptionId);
    }
    return;
  }
  if (pendingConsumptionId == null) {
    showDiaryQuickEatSnackBarWithMessenger(messenger, failureMessage);
    return;
  }

  final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
    item,
  );
  if (profile == null) {
    await _discardInventoryItemConsumption(container, pendingConsumptionId);
    if (context.mounted) {
      showDiaryQuickEatSnackBarWithMessenger(messenger, failureMessage);
    }
    return;
  }

  final inventoryContext = InventoryCalorieBridgeFlow.buildInventoryContext(
    item: item,
    pendingConsumptionId: pendingConsumptionId,
    request: request,
  );
  final scannedSourceRef = InventoryCalorieBridgeFlow.buildScannedSourceRef(
    item: item,
    profile: profile,
  );

  final bool saved;
  if (canDirectlySaveInventoryItemEatRequest(item, request)) {
    saved = await InventoryCalorieBridgeFlow.saveDirectEntry(
      container: container,
      profile: profile,
      inventoryContext: inventoryContext,
      scannedSourceRef: scannedSourceRef,
      loggedAt: request.loggedAt,
      mealType: request.mealType,
    );
  } else {
    if (!context.mounted) {
      await _discardInventoryItemConsumption(container, pendingConsumptionId);
      return;
    }
    final result = await context.push<bool>(
      AppRoutes.homeCaloriesEntryCreate,
      extra: CalorieEntryCreateArgs(
        prefilledProfile: profile,
        scannedSourceRef: scannedSourceRef,
        inventoryContext: inventoryContext,
        preselectedMealType: request.mealType,
        preselectedLoggedAt: request.loggedAt,
      ),
    );
    saved = result == true;
  }

  if (!saved) {
    await _discardInventoryItemConsumption(container, pendingConsumptionId);
    if (context.mounted) {
      showDiaryQuickEatSnackBarWithMessenger(messenger, failureMessage);
    }
    return;
  }

  if (context.mounted) {
    showDiaryQuickEatSnackBarWithMessenger(
      messenger,
      l10n.inventoryManualAddEatSucceeded,
    );
  }
  refreshDiaryAfterQuickEat(container, request.loggedAt);
}

Future<String?> _stageInventoryItemConsumption({
  required BuildContext context,
  required ProviderContainer container,
  required InventoryItem item,
  required int amount,
}) async {
  if (!context.mounted) {
    return null;
  }
  return container
      .read(diaryQuickEatInventoryActionsProvider)
      .stageInventoryItemConsumption(itemId: item.id, amount: amount);
}

Future<void> _discardInventoryItemConsumption(
  ProviderContainer container,
  String pendingConsumptionId,
) {
  return container
      .read(diaryQuickEatInventoryActionsProvider)
      .discardInventoryItemConsumption(pendingConsumptionId);
}
