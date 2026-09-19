import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
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
    'calorie_entry_editor_dialogs.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_flow_handler.dart';

/// Create form content of the calorie entry route.
class CalorieEntryEditorContent extends ConsumerStatefulWidget {
  /// Creates editor content.
  const new({
    required this.user,
    this.prefilledProfile,
    this.scannedSourceRef,
    this.inventoryContext,
    this.preselectedMealType,
    this.preselectedLoggedAt,
    super.key,
  });

  /// Signed-in user.
  final User user;

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
  bool _didCommitPendingConsumption = false;
  bool _didDiscardPendingConsumption = false;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(calorieEntryEditorControllerProvider.notifier);
    _initializeForCreate();
  }

  @override
  void didUpdateWidget(covariant CalorieEntryEditorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_initializeForCreate()) {
      return;
    }

    _didCommitPendingConsumption = false;
    _didDiscardPendingConsumption = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _discardPendingInventoryConsumptionIfNeeded();
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(calorieEntryEditorControllerProvider);
    return CalorieEntryEditorCreateScaffold(
      draft: _draft,
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
        onCommitted: () => _didCommitPendingConsumption = true,
      ),
      onMealTypeChanged: (type) => setState(() => _draft.mealType = type),
      onConsumedUnitChanged: (unit) =>
          setState(() => _draft.consumedUnit = unit),
      onPickDate: () => _pickDate(context),
      onPickTime: () => _pickTime(context),
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
    if (pendingConsumptionId == null) {
      return;
    }

    _didDiscardPendingConsumption = true;
    unawaited(_controller.discardPendingInventory(pendingConsumptionId));
  }

  bool _initializeForCreate() {
    final createPrefill = CalorieEntryCreatePrefill.fromArgs(
      prefilledProfile: widget.prefilledProfile,
      inventoryContext: widget.inventoryContext,
      preselectedMealType: widget.preselectedMealType,
      preselectedLoggedAt: widget.preselectedLoggedAt,
    );
    return _draft.initializeForCreate(createPrefill);
  }
}
