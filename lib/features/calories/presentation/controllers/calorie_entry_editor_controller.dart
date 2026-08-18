import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/application/'
    'calorie_inventory_entry_save_handler.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';

part 'calorie_entry_editor_controller.g.dart';

const _controllerLogName = 'CalorieEntryEditorController';

/// Controller managing save, delete, and pending inventory cleanup for
/// calorie entry editor.
@riverpod
class CalorieEntryEditorController extends _$CalorieEntryEditorController {
  @override
  bool build() {
    ref.keepAlive();
    return false;
  }

  /// Saves a newly created or edited calorie entry.
  Future<bool> saveEntry({
    required CalorieEntry entry,
    CalorieInventoryCreateContext? inventoryContext,
    CalorieScannedSourceRef? scannedSourceRef,
    String? pendingConsumptionId,
    bool isEditing = false,
  }) async {
    state = true;
    try {
      final saveHandler = _resolveSaveHandler(
        isEditing: isEditing,
        pendingConsumptionId: pendingConsumptionId,
      );
      final persistCallback = _buildPersistCallback(
        saveHandler: saveHandler,
        pendingConsumptionId: pendingConsumptionId,
      );

      _logSaveStart(
        entry: entry,
        isEditing: isEditing,
        hasSaveHandler: saveHandler != null,
        pendingConsumptionId: pendingConsumptionId,
        inventoryItemId: inventoryContext?.inventoryItemId,
      );

      final notifier = ref.read(calorieEntriesControllerProvider.notifier);
      final saved = await notifier.saveEntry(
        entry,
        inventoryContext: inventoryContext,
        scannedSourceRef: !isEditing ? scannedSourceRef : null,
        persistEntry: persistCallback,
      );

      log(
        'Calorie entry save completed for ${entry.id} with result=$saved.',
        name: _controllerLogName,
      );
      return saved;
    } finally {
      if (ref.mounted) {
        state = false;
      }
    }
  }

  /// Checks if entry source can be restored to inventory.
  Future<bool> canRestoreSource(CalorieEntry entry) async {
    final deleteFlow = ref.read(calorieEntryDeleteFlowProvider);
    return deleteFlow.canRestoreSource(entry);
  }

  /// Deletes or returns entry to inventory.
  Future<CalorieEntryDeleteResult> deleteEntry({
    required CalorieEntry entry,
    required bool restoreToInventory,
  }) async {
    state = true;
    try {
      final deleteFlow = ref.read(calorieEntryDeleteFlowProvider);
      return await deleteFlow.deleteEntry(
        entry: entry,
        restoreToInventory: restoreToInventory,
      );
    } finally {
      if (ref.mounted) {
        state = false;
      }
    }
  }

  /// Discards uncommitted pending inventory consumption.
  Future<void> discardPendingInventory(String pendingConsumptionId) async {
    final discarder = ref.read(
      calorieInventoryPendingConsumptionDiscarderProvider,
    );
    if (discarder == null) {
      return;
    }
    try {
      await discarder(pendingConsumptionId);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to discard pending inventory consumption '
        '$pendingConsumptionId.',
        name: _controllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  CalorieInventoryEntrySaveHandler? _resolveSaveHandler({
    required bool isEditing,
    required String? pendingConsumptionId,
  }) {
    if (isEditing || pendingConsumptionId == null) {
      return null;
    }
    return ref.read(calorieInventoryEntrySaveHandlerProvider);
  }

  Future<bool> Function(CalorieEntry)? _buildPersistCallback({
    required CalorieInventoryEntrySaveHandler? saveHandler,
    required String? pendingConsumptionId,
  }) {
    if (saveHandler == null || pendingConsumptionId == null) {
      return null;
    }
    return (entry) => saveHandler(
          entry: entry,
          pendingConsumptionId: pendingConsumptionId,
        );
  }

  void _logSaveStart({
    required CalorieEntry entry,
    required bool isEditing,
    required bool hasSaveHandler,
    required String? pendingConsumptionId,
    required String? inventoryItemId,
  }) {
    log(
      'Saving calorie entry ${entry.id} '
      '(edit=$isEditing, '
      'inventoryBacked=$hasSaveHandler, '
      'pendingConsumptionId=${pendingConsumptionId ?? 'none'}, '
      'inventoryItemId=${inventoryItemId ?? 'none'}).',
      name: _controllerLogName,
    );
  }
}
