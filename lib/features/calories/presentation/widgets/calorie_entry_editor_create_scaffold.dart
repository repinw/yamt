import 'package:flutter/material.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_editor_draft.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_form_scaffold.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Scaffold and PopScope wrapper for creating or editing entry via form.
class CalorieEntryEditorCreateScaffold extends StatelessWidget {
  /// Creates form scaffold wrapper.
  const CalorieEntryEditorCreateScaffold({
    required this.draft,
    required this.isEditing,
    required this.isSaving,
    required this.onPopDiscardPending,
    required this.onSave,
    required this.onMealTypeChanged,
    required this.onConsumedUnitChanged,
    required this.onPickDate,
    required this.onPickTime,
    super.key,
  });

  /// The active draft.
  final CalorieEntryEditorDraft draft;

  /// Whether editing existing or creating new.
  final bool isEditing;

  /// Whether currently saving.
  final bool isSaving;

  /// Callback when popped to discard pending consumption.
  final VoidCallback onPopDiscardPending;

  /// Callback to save form.
  final VoidCallback onSave;

  /// Callback when meal type changes.
  final ValueChanged<MealType> onMealTypeChanged;

  /// Callback when consumed unit changes.
  final ValueChanged<ConsumedUnit> onConsumedUnitChanged;

  /// Callback to pick date.
  final VoidCallback onPickDate;

  /// Callback to pick time.
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope<void>(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          onPopDiscardPending();
        }
      },
      child: CalorieEntryEditorFormScaffold(
        formKey: draft.formKey,
        isEditing: isEditing,
        isSaving: isSaving,
        nameController: draft.nameController,
        brandController: draft.brandController,
        amountController: draft.amountController,
        per100KcalController: draft.per100KcalController,
        per100ProteinController: draft.per100ProteinController,
        per100CarbsController: draft.per100CarbsController,
        per100FatController: draft.per100FatController,
        selectedMealType: draft.mealType,
        selectedConsumedUnit: draft.consumedUnit,
        loggedAt: draft.loggedAt,
        onSave: onSave,
        onMealTypeChanged: onMealTypeChanged,
        onConsumedUnitChanged: onConsumedUnitChanged,
        onPickDate: onPickDate,
        onPickTime: onPickTime,
        positiveNumberValidator: (value) =>
            draft.positiveNumberValidator(value, l10n),
        nonNegativeNumberValidator: (value) =>
            draft.nonNegativeNumberValidator(value, l10n),
      ),
    );
  }
}
