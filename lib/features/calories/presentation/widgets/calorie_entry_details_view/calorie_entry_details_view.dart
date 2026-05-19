import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_sections.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_sheet_chrome.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_sheet_footer.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_overview_card.dart';

/// Read-only details view for an existing diary entry.
class CalorieEntryDetailsView extends StatelessWidget {
  /// The calorie entry details view.
  const CalorieEntryDetailsView({
    required this.title,
    required this.entry,
    required this.selectedMealType,
    required this.selectedLoggedAt,
    required this.isSaving,
    required this.onClose,
    required this.onMealTypeChanged,
    required this.onPickLoggedAt,
    required this.onSave,
    required this.onReturnToInventory,
    super.key,
  });

  /// The visible sheet title.
  final String title;

  /// The displayed entry.
  final CalorieEntry entry;

  /// The currently selected meal type.
  final MealType selectedMealType;

  /// The currently selected logged day/time.
  final DateTime selectedLoggedAt;

  /// Whether a mutation is in flight.
  final bool isSaving;

  /// Called when closing the view.
  final VoidCallback onClose;

  /// Called when the meal type changes.
  final ValueChanged<MealType> onMealTypeChanged;

  /// Called when changing the logged day.
  final VoidCallback onPickLoggedAt;

  /// Called when saving the changed meal type.
  final VoidCallback onSave;

  /// Called when returning the entry to inventory.
  final VoidCallback onReturnToInventory;

  @override
  Widget build(BuildContext context) {
    final hasMealChanges = selectedMealType != entry.mealType;
    final hasLoggedAtChanges = selectedLoggedAt != entry.loggedAt;
    final hasPendingChanges = hasMealChanges || hasLoggedAtChanges;
    final canReturn =
        entry.canRestoreToInventory || entry.canReturnPreparedMealToInventory;

    return CalorieEntryDetailsSheetChrome(
      title: title,
      isSaving: isSaving,
      onClose: onClose,
      footer: CalorieEntryDetailsSheetFooter(
        canReturn: canReturn,
        isSaving: isSaving,
        hasPendingChanges: hasPendingChanges,
        onSave: onSave,
        onReturnToInventory: onReturnToInventory,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        children: [
          CalorieEntryOverviewCard(
            entry: entry,
            isSaving: isSaving,
            selectedMealType: selectedMealType,
            selectedLoggedAt: selectedLoggedAt,
            onPickLoggedAt: onPickLoggedAt,
            onMealTypeChanged: onMealTypeChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          CalorieEntryNutritionSummaryCard(entry: entry),
          if (entry.isBundle && entry.bundleComponents.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            CalorieEntryIngredientsSection(entry: entry),
          ],
        ],
      ),
    );
  }
}
