import 'package:flutter/material.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_editor_draft.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_view.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Wraps the existing calorie entry details view with PopScope.
class CalorieEntryEditorDetailsScaffold extends StatelessWidget {
  /// Creates details scaffold.
  const CalorieEntryEditorDetailsScaffold({
    required this.entry,
    required this.draft,
    required this.isSaving,
    required this.allowDirtyDismiss,
    required this.onRequestClose,
    required this.onMealTypeChanged,
    required this.onPickLoggedAt,
    required this.onSave,
    required this.onReturnToInventory,
    super.key,
  });

  /// The entry being inspected/edited.
  final CalorieEntry entry;

  /// Active draft.
  final CalorieEntryEditorDraft draft;

  /// Whether a save or delete operation is in progress.
  final bool isSaving;

  /// Whether user confirmed discarding unsaved changes.
  final bool allowDirtyDismiss;

  /// Callback when user wants to close.
  final VoidCallback onRequestClose;

  /// Callback when meal type changes.
  final ValueChanged<MealType> onMealTypeChanged;

  /// Callback to open date/time picker.
  final VoidCallback onPickLoggedAt;

  /// Callback to save changes.
  final VoidCallback onSave;

  /// Callback to return entry to inventory.
  final VoidCallback onReturnToInventory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasPendingChanges = draft.hasPendingChangesForEntry(entry);

    return PopScope<void>(
      canPop: !isSaving && (!hasPendingChanges || allowDirtyDismiss),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || isSaving || !hasPendingChanges) {
          return;
        }
        onRequestClose();
      },
      child: CalorieEntryDetailsView(
        title: l10n.caloriesEntryDetailsTitle,
        entry: entry,
        selectedMealType: draft.mealType,
        selectedLoggedAt: draft.loggedAt,
        isSaving: isSaving,
        onClose: onRequestClose,
        onMealTypeChanged: onMealTypeChanged,
        onPickLoggedAt: onPickLoggedAt,
        onSave: onSave,
        onReturnToInventory: onReturnToInventory,
      ),
    );
  }
}
