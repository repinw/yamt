import 'dart:async';
import 'dart:developer' show log;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/application/'
    'calorie_inventory_entry_save_handler.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_prefill.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_editor_draft.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_view.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_dialogs.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_form_scaffold.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _editorLogName = 'CalorieEntryEditorPage';

/// Stateful editor content used by calorie entry route.
class CalorieEntryEditorContent extends ConsumerStatefulWidget {
  /// Creates editor content.
  const CalorieEntryEditorContent({
    required this.user,
    this.entryId,
    this.prefilledProfile,
    this.scannedSourceRef,
    this.inventoryContext,
    this.preselectedMealType,
    this.preselectedLoggedAt,
    super.key,
  });

  /// Signed-in user.
  final User user;

  /// Existing entry id.
  final String? entryId;

  /// Optional prefilled product profile.
  final CalorieProductProfile? prefilledProfile;

  /// Optional scanned source reference.
  final CalorieScannedSourceRef? scannedSourceRef;

  /// Optional inventory create context.
  final CalorieInventoryCreateContext? inventoryContext;

  /// Optional preselected meal type.
  final MealType? preselectedMealType;

  /// Optional preselected logged-at value.
  final DateTime? preselectedLoggedAt;

  @override
  ConsumerState<CalorieEntryEditorContent> createState() {
    return _CalorieEntryEditorContentState();
  }
}

class _CalorieEntryEditorContentState
    extends ConsumerState<CalorieEntryEditorContent> {
  static const _uuid = Uuid();

  final _draft = CalorieEntryEditorDraft();
  ProviderSubscription<AsyncValue<CalorieEntry?>>? _entrySubscription;
  CalorieInventoryPendingConsumptionDiscarder? _discardPendingConsumption;
  bool _isSaving = false;
  bool _didCommitPendingConsumption = false;
  bool _didDiscardPendingConsumption = false;
  bool _allowDirtyDetailsDismiss = false;
  bool _isShowingDiscardDialog = false;

  @override
  void initState() {
    super.initState();
    _discardPendingConsumption = ref.read(
      calorieInventoryPendingConsumptionDiscarderProvider,
    );
    _initializeForCreate();
    _subscribeToEntry();
  }

  @override
  void didUpdateWidget(covariant CalorieEntryEditorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final didEntryIdChange = oldWidget.entryId != widget.entryId;
    final oldBarcode = oldWidget.prefilledProfile?.barcode;
    final nextBarcode = widget.prefilledProfile?.barcode;
    final didPrefillChange = oldBarcode != nextBarcode;
    final didInventoryContextChange =
        oldWidget.inventoryContext?.inventoryItemId !=
            widget.inventoryContext?.inventoryItemId ||
        oldWidget.inventoryContext?.pendingConsumptionId !=
            widget.inventoryContext?.pendingConsumptionId ||
        oldWidget.inventoryContext?.consumedAmount !=
            widget.inventoryContext?.consumedAmount ||
        oldWidget.inventoryContext?.consumedUnit !=
            widget.inventoryContext?.consumedUnit;
    final didMealPrefillChange =
        oldWidget.preselectedMealType != widget.preselectedMealType ||
        oldWidget.preselectedLoggedAt != widget.preselectedLoggedAt;
    if (!didEntryIdChange &&
        !didPrefillChange &&
        !didInventoryContextChange &&
        !didMealPrefillChange) {
      return;
    }

    _entrySubscription?.close();
    _entrySubscription = null;
    _initializeForCreate();
    _subscribeToEntry();
    _didCommitPendingConsumption = false;
    _didDiscardPendingConsumption = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _discardPendingInventoryConsumptionIfNeeded();
    _entrySubscription?.close();
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entryId = widget.entryId;
    if (entryId == null) {
      return _buildEditorScaffold(context, initialEntry: null);
    }

    final entryState = ref.watch(calorieEntryByIdProvider(entryId));
    return entryState.when(
      data: (entry) {
        if (entry == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.caloriesEntryDetailsTitle)),
            body: Center(child: Text(l10n.caloriesEntryNotFound)),
          );
        }
        _initializeFromEntry(entry);
        return _buildExistingEntryScaffold(context, entry: entry);
      },
      loading: () => const Scaffold(
        body: Center(
          child: SizedBox.square(
            dimension: AppSizes.inlineProgressIndicator,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.progressStrokeWidth,
            ),
          ),
        ),
      ),
      error: (error, stackTrace) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.caloriesEntryDetailsTitle)),
          body: Center(child: Text(l10n.caloriesLoadFailed)),
        );
      },
    );
  }

  bool _initializeFromEntry(CalorieEntry? entry) {
    final changed = _draft.initializeFromEntry(entry);
    if (changed) {
      _allowDirtyDetailsDismiss = false;
    }
    return changed;
  }

  bool _initializeForCreate() {
    if (widget.entryId != null) {
      return false;
    }

    final createPrefill = CalorieEntryCreatePrefill.fromArgs(
      prefilledProfile: widget.prefilledProfile,
      inventoryContext: widget.inventoryContext,
      preselectedMealType: widget.preselectedMealType,
      preselectedLoggedAt: widget.preselectedLoggedAt,
    );
    return _draft.initializeForCreate(createPrefill);
  }

  void _subscribeToEntry() {
    final entryId = widget.entryId;
    if (entryId == null) {
      return;
    }

    _entrySubscription = ref.listenManual<AsyncValue<CalorieEntry?>>(
      calorieEntryByIdProvider(entryId),
      (previous, next) {
        final entry = next.asData?.value;
        if (entry == null || !mounted) {
          return;
        }
        final changed = _initializeFromEntry(entry);
        if (!changed) {
          return;
        }
        setState(() {});
      },
      fireImmediately: true,
    );
  }

  Widget _buildExistingEntryScaffold(
    BuildContext context, {
    required CalorieEntry entry,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final hasPendingChanges = _draft.hasPendingChangesForEntry(entry);

    return PopScope<void>(
      canPop: !_isSaving && (!hasPendingChanges || _allowDirtyDetailsDismiss),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _isSaving || !hasPendingChanges) {
          return;
        }
        unawaited(_requestCloseExistingEntry(context, entry: entry));
      },
      child: CalorieEntryDetailsView(
        title: l10n.caloriesEntryDetailsTitle,
        entry: entry,
        selectedMealType: _draft.mealType,
        selectedLoggedAt: _draft.loggedAt,
        isSaving: _isSaving,
        onClose: () {
          unawaited(_requestCloseExistingEntry(context, entry: entry));
        },
        onMealTypeChanged: (mealType) {
          setState(() {
            _draft.mealType = mealType;
          });
        },
        onPickLoggedAt: () => _pickDate(context),
        onSave: () => _saveExistingEntry(context, entry: entry),
        onReturnToInventory: () =>
            _returnEntryToInventory(context, entry: entry),
      ),
    );
  }

  Widget _buildEditorScaffold(
    BuildContext context, {
    required CalorieEntry? initialEntry,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = initialEntry != null;

    return PopScope<void>(
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: CalorieEntryEditorFormScaffold(
        formKey: _draft.formKey,
        isEditing: isEditing,
        isSaving: _isSaving,
        nameController: _draft.nameController,
        brandController: _draft.brandController,
        amountController: _draft.amountController,
        per100KcalController: _draft.per100KcalController,
        per100ProteinController: _draft.per100ProteinController,
        per100CarbsController: _draft.per100CarbsController,
        per100FatController: _draft.per100FatController,
        selectedMealType: _draft.mealType,
        selectedConsumedUnit: _draft.consumedUnit,
        loggedAt: _draft.loggedAt,
        onSave: () => _save(context, initialEntry: initialEntry),
        onMealTypeChanged: (mealType) {
          setState(() {
            _draft.mealType = mealType;
          });
        },
        onConsumedUnitChanged: (unit) {
          setState(() {
            _draft.consumedUnit = unit;
          });
        },
        onPickDate: () => _pickDate(context),
        onPickTime: () => _pickTime(context),
        positiveNumberValidator: (value) =>
            _draft.positiveNumberValidator(value, l10n),
        nonNegativeNumberValidator: (value) =>
            _draft.nonNegativeNumberValidator(value, l10n),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _draft.loggedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !context.mounted) {
      return;
    }

    setState(() {
      _draft.loggedAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _draft.loggedAt.hour,
        _draft.loggedAt.minute,
      );
    });
  }

  Future<void> _pickTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_draft.loggedAt),
    );
    if (pickedTime == null || !context.mounted) {
      return;
    }

    setState(() {
      _draft.loggedAt = DateTime(
        _draft.loggedAt.year,
        _draft.loggedAt.month,
        _draft.loggedAt.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _save(
    BuildContext context, {
    required CalorieEntry? initialEntry,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final formState = _draft.formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final parsedDraft = _draft.tryParse();
    if (parsedDraft == null) {
      _showFailureSnackBar(
        ScaffoldMessenger.of(context),
        l10n.caloriesInvalidNumber,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final inventoryContext = widget.inventoryContext;
    final pendingConsumptionId = inventoryContext?.pendingConsumptionId;
    final now = DateTime.now();
    final entry = initialEntry == null
        ? CalorieEntry.create(
            id: _uuid.v4(),
            userId: widget.user.uid,
            name: parsedDraft.name,
            brand: parsedDraft.brand,
            imageUrl: widget.prefilledProfile?.imageUrl,
            mealType: parsedDraft.mealType,
            consumedAmount: parsedDraft.amount,
            consumedUnit: parsedDraft.consumedUnit,
            per100Kcal: parsedDraft.per100Kcal,
            per100Protein: parsedDraft.per100Protein,
            per100Carbs: parsedDraft.per100Carbs,
            per100Fat: parsedDraft.per100Fat,
            sourceInventoryItemId: inventoryContext?.inventoryItemId,
            sourceInventoryAmountToRestore:
                inventoryContext?.inventoryAmountToRestore,
            loggedAt: parsedDraft.loggedAt,
            createdAt: now,
            updatedAt: now,
          )
        : initialEntry
              .copyWith(
                name: parsedDraft.name,
                brand: parsedDraft.brand,
                mealType: parsedDraft.mealType,
                consumedAmount: parsedDraft.amount,
                consumedUnit: parsedDraft.consumedUnit,
                per100Kcal: parsedDraft.per100Kcal,
                per100Protein: parsedDraft.per100Protein,
                per100Carbs: parsedDraft.per100Carbs,
                per100Fat: parsedDraft.per100Fat,
                loggedAt: parsedDraft.loggedAt,
                updatedAt: now,
              )
              .recalculateTotals(updatedAt: now);

    final inventoryBackedPendingConsumptionId = initialEntry == null
        ? pendingConsumptionId
        : null;
    final inventoryBackedSaveHandler =
        inventoryBackedPendingConsumptionId == null
        ? null
        : ref.read(calorieInventoryEntrySaveHandlerProvider);
    final calorieEntriesController = ref.read(
      calorieEntriesControllerProvider.notifier,
    );
    Future<bool> persistInventoryBackedEntry(CalorieEntry entry) {
      final saveHandler = inventoryBackedSaveHandler;
      final pendingConsumptionId = inventoryBackedPendingConsumptionId;
      if (saveHandler == null || pendingConsumptionId == null) {
        return Future<bool>.value(false);
      }
      return saveHandler(
        entry: entry,
        pendingConsumptionId: pendingConsumptionId,
      );
    }

    final persistEntry = inventoryBackedSaveHandler == null
        ? null
        : persistInventoryBackedEntry;

    log(
      'Saving calorie entry ${entry.id} '
      '(edit=${initialEntry != null}, '
      'inventoryBacked=${inventoryBackedSaveHandler != null}, '
      'pendingConsumptionId=${inventoryBackedPendingConsumptionId ?? 'none'}, '
      'inventoryItemId=${inventoryContext?.inventoryItemId ?? 'none'}).',
      name: _editorLogName,
    );

    final saved = await calorieEntriesController.saveEntry(
      entry,
      inventoryContext: inventoryContext,
      scannedSourceRef: initialEntry == null ? widget.scannedSourceRef : null,
      persistEntry: persistEntry,
    );

    log(
      'Calorie entry save completed for ${entry.id} with result=$saved.',
      name: _editorLogName,
    );

    if (!mounted || !context.mounted) {
      log(
        'Calorie entry editor unmounted before save UI handling for '
        '${entry.id}.',
        name: _editorLogName,
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final mountedL10n = AppLocalizations.of(context)!;

    setState(() {
      _isSaving = false;
    });

    if (saved) {
      _didCommitPendingConsumption = true;
      log(
        'Calorie entry ${entry.id} saved successfully. Closing editor.',
        name: _editorLogName,
      );
      _maybePopRootNavigator(context, result: true);
      return;
    }

    log(
      'Calorie entry ${entry.id} save failed. Showing failure snackbar.',
      name: _editorLogName,
    );
    _showFailureSnackBar(messenger, mountedL10n.caloriesSaveFailed);
  }

  Future<void> _saveExistingEntry(
    BuildContext context, {
    required CalorieEntry entry,
  }) async {
    if (_draft.mealType == entry.mealType &&
        _draft.loggedAt == entry.loggedAt) {
      return;
    }

    final controller = ref.read(calorieEntriesControllerProvider.notifier);
    final updatedAt = DateTime.now();
    final updatedEntry = entry
        .copyWith(
          mealType: _draft.mealType,
          loggedAt: _draft.loggedAt,
          updatedAt: updatedAt,
        )
        .recalculateTotals(updatedAt: updatedAt);

    setState(() {
      _isSaving = true;
    });

    final saved = await controller.saveEntry(updatedEntry);
    if (!mounted || !context.mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (saved) {
      _maybePopRootNavigator(context, result: true);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    _showFailureSnackBar(messenger, l10n.caloriesSaveFailed);
  }

  Future<void> _returnEntryToInventory(
    BuildContext context, {
    required CalorieEntry entry,
  }) async {
    final deleteFlow = ref.read(calorieEntryDeleteFlowProvider);
    final sourceCanBeRestored = await deleteFlow.canRestoreSource(entry);
    if (!context.mounted) {
      return;
    }
    if (!mounted) {
      return;
    }

    final bool? confirmed;
    if (sourceCanBeRestored) {
      confirmed = await showCalorieEntryReturnToInventoryDialog(
        context,
        entry: entry,
      );
    } else {
      confirmed = await showCalorieEntryMissingInventorySourceDialog(
        context,
        entry: entry,
      );
    }
    if (confirmed != true || !mounted) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    await _deleteEntryFromDetails(
      context,
      entry: entry,
      deleteFlow: deleteFlow,
      restoreToInventory: sourceCanBeRestored,
    );
  }

  Future<void> _deleteEntryFromDetails(
    BuildContext context, {
    required CalorieEntry entry,
    required CalorieEntryDeleteFlow deleteFlow,
    required bool restoreToInventory,
  }) async {
    setState(() {
      _isSaving = true;
    });

    final result = await deleteFlow.deleteEntry(
      entry: entry,
      restoreToInventory: restoreToInventory,
    );
    if (!mounted || !context.mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (result.isSuccess) {
      _maybePopRootNavigator(context);
      return;
    }

    if (restoreToInventory &&
        result.failureReason == CalorieEntryDeleteFailureReason.sourceMissing) {
      await _confirmDeleteEntryOnly(
        context,
        entry: entry,
        deleteFlow: deleteFlow,
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final l10n = AppLocalizations.of(context)!;
    final message = switch (result.failureReason) {
      CalorieEntryDeleteFailureReason.restoreFailed =>
        entry.canReturnPreparedMealToInventory
            ? l10n.caloriesReturnPreparedMealFailed
            : l10n.caloriesDeleteRestoreFailed,
      CalorieEntryDeleteFailureReason.sourceMissing =>
        l10n.caloriesDeleteFailed,
      CalorieEntryDeleteFailureReason.deleteFailed ||
      null => l10n.caloriesDeleteFailed,
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDeleteEntryOnly(
    BuildContext context, {
    required CalorieEntry entry,
    required CalorieEntryDeleteFlow deleteFlow,
  }) async {
    final confirmed = await showCalorieEntryMissingInventorySourceDialog(
      context,
      entry: entry,
    );
    if (confirmed != true || !mounted || !context.mounted) {
      return;
    }

    await _deleteEntryFromDetails(
      context,
      entry: entry,
      deleteFlow: deleteFlow,
      restoreToInventory: false,
    );
  }

  Future<void> _requestCloseExistingEntry(
    BuildContext context, {
    required CalorieEntry entry,
  }) async {
    if (_isSaving) {
      return;
    }
    if (!_draft.hasPendingChangesForEntry(entry)) {
      _maybePopRootNavigator(context);
      return;
    }
    if (_isShowingDiscardDialog) {
      return;
    }

    _isShowingDiscardDialog = true;
    try {
      final shouldDiscard = await showCalorieEntryDiscardChangesDialog(
        context,
      );
      if (shouldDiscard != true || !mounted || !context.mounted) {
        return;
      }

      setState(() {
        _allowDirtyDetailsDismiss = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !context.mounted) {
          return;
        }
        _maybePopRootNavigator(context);
      });
    } finally {
      _isShowingDiscardDialog = false;
    }
  }

  void _maybePopRootNavigator(BuildContext context, {Object? result}) {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.canPop()) {
      rootNavigator.pop(result);
      return;
    }

    final localNavigator = Navigator.of(context);
    if (!identical(localNavigator, rootNavigator) && localNavigator.canPop()) {
      localNavigator.pop(result);
      return;
    }

    GoRouter.of(context).go(_fallbackCloseRoute);
  }

  String get _fallbackCloseRoute {
    return widget.entryId == null
        ? AppRoutes.homeInventory
        : AppRoutes.homeCalories;
  }

  void _showFailureSnackBar(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onPopInvokedWithResult(bool didPop, Object? result) {
    if (!didPop) {
      return;
    }

    _discardPendingInventoryConsumptionIfNeeded();
  }

  void _discardPendingInventoryConsumptionIfNeeded() {
    if (_didCommitPendingConsumption || _didDiscardPendingConsumption) {
      return;
    }
    final pendingConsumptionId = widget.inventoryContext?.pendingConsumptionId;
    if (widget.entryId != null || pendingConsumptionId == null) {
      return;
    }

    final discardPendingConsumption = _discardPendingConsumption;
    if (discardPendingConsumption == null) {
      return;
    }
    _didDiscardPendingConsumption = true;
    unawaited(
      _discardPendingInventoryConsumption(
        discardPendingConsumption: discardPendingConsumption,
        pendingConsumptionId: pendingConsumptionId,
      ),
    );
  }

  Future<void> _discardPendingInventoryConsumption({
    required CalorieInventoryPendingConsumptionDiscarder
    discardPendingConsumption,
    required String pendingConsumptionId,
  }) async {
    try {
      await discardPendingConsumption(pendingConsumptionId);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to discard pending inventory consumption '
        '$pendingConsumptionId after editor disposal.',
        name: _editorLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
