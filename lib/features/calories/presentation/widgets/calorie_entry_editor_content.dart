import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/controllers/'
    'calorie_entry_editor_controller.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_prefill.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_editor_draft.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_create_scaffold.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_details_scaffold.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_dialogs.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_flow_handler.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

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
  late final CalorieEntryEditorController _controller;
  final _draft = CalorieEntryEditorDraft();
  ProviderSubscription<AsyncValue<CalorieEntry?>>? _entrySubscription;
  bool _didCommitPendingConsumption = false;
  bool _didDiscardPendingConsumption = false;
  bool _allowDirtyDetailsDismiss = false;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(calorieEntryEditorControllerProvider.notifier);
    _initializeForCreate();
    _subscribeToEntry();
  }

  @override
  void didUpdateWidget(covariant CalorieEntryEditorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final didEntryIdChange = oldWidget.entryId != widget.entryId;
    final didInit = _initializeForCreate();
    if (!didEntryIdChange && !didInit) {
      return;
    }

    _entrySubscription?.close();
    _entrySubscription = null;
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
      return _buildCreateScaffold(context, initialEntry: null);
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
        return _buildDetailsScaffold(context, entry: entry);
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
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: Text(l10n.caloriesEntryDetailsTitle)),
        body: Center(child: Text(l10n.caloriesLoadFailed)),
      ),
    );
  }

  Widget _buildDetailsScaffold(
    BuildContext context, {
    required CalorieEntry entry,
  }) {
    final isSaving = ref.watch(calorieEntryEditorControllerProvider);
    return CalorieEntryEditorDetailsScaffold(
      entry: entry,
      draft: _draft,
      isSaving: isSaving,
      allowDirtyDismiss: _allowDirtyDetailsDismiss,
      onRequestClose: () => _requestCloseExistingEntry(context, entry: entry),
      onMealTypeChanged: (type) => setState(() => _draft.mealType = type),
      onPickLoggedAt: () => _pickDate(context),
      onSave: () => CalorieEntryEditorFlowHandler.saveExistingEntry(
        context,
        draft: _draft,
        entry: entry,
        controller: _controller,
      ),
      onReturnToInventory: () => _returnEntryToInventory(context, entry: entry),
    );
  }

  Widget _buildCreateScaffold(
    BuildContext context, {
    required CalorieEntry? initialEntry,
  }) {
    final isSaving = ref.watch(calorieEntryEditorControllerProvider);
    return CalorieEntryEditorCreateScaffold(
      draft: _draft,
      isEditing: initialEntry != null,
      isSaving: isSaving,
      onPopDiscardPending: _discardPendingInventoryConsumptionIfNeeded,
      onSave: () => CalorieEntryEditorFlowHandler.saveNewEntry(
        context,
        draft: _draft,
        userId: widget.user.uid,
        controller: _controller,
        prefilledProfile: widget.prefilledProfile,
        inventoryContext: widget.inventoryContext,
        scannedSourceRef: widget.scannedSourceRef,
        initialEntry: initialEntry,
        onCommitted: () => _didCommitPendingConsumption = true,
      ),
      onMealTypeChanged: (type) => setState(() => _draft.mealType = type),
      onConsumedUnitChanged: (unit) =>
          setState(() => _draft.consumedUnit = unit),
      onPickDate: () => _pickDate(context),
      onPickTime: () => _pickTime(context),
    );
  }

  Future<void> _returnEntryToInventory(
    BuildContext context, {
    required CalorieEntry entry,
  }) async {
    await CalorieEntryEditorFlowHandler.returnEntryToInventory(
      context,
      entry: entry,
      controller: _controller,
      onDeleted: () {
        if (!mounted || !context.mounted) {
          return;
        }
        CalorieEntryEditorFlowHandler.maybePopRootNavigator(
          context,
          isEditing: true,
        );
      },
    );
  }

  Future<void> _requestCloseExistingEntry(
    BuildContext context, {
    required CalorieEntry entry,
  }) async {
    final isSaving = ref.read(calorieEntryEditorControllerProvider);
    final hasPendingChanges = _draft.hasPendingChangesForEntry(entry);
    await CalorieEntryEditorFlowHandler.requestCloseExistingEntry(
      context,
      entry: entry,
      hasPendingChanges: hasPendingChanges,
      isSaving: isSaving,
      onDismissConfirmed: () {
        if (mounted) {
          setState(() => _allowDirtyDetailsDismiss = true);
        }
      },
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showCalorieEntryDatePicker(
      context,
      initialDate: _draft.loggedAt,
    );
    if (pickedDate != null && mounted) {
      setState(() => _draft.updateDate(pickedDate));
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final pickedTime = await showCalorieEntryTimePicker(
      context,
      initialTime: _draft.loggedAt,
    );
    if (pickedTime != null && mounted) {
      setState(() => _draft.updateTime(pickedTime));
    }
  }

  void _discardPendingInventoryConsumptionIfNeeded() {
    if (_didCommitPendingConsumption || _didDiscardPendingConsumption) {
      return;
    }
    final pendingConsumptionId = widget.inventoryContext?.pendingConsumptionId;
    if (widget.entryId != null || pendingConsumptionId == null) {
      return;
    }

    _didDiscardPendingConsumption = true;
    unawaited(_controller.discardPendingInventory(pendingConsumptionId));
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
        if (changed) {
          setState(() {});
        }
      },
      fireImmediately: true,
    );
  }
}
