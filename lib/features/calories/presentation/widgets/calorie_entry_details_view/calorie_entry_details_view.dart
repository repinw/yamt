import 'package:material_ui/material_ui.dart';
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
    'calorie_entry_details_view/calorie_entry_nutrition_context.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_nutrition_table.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_overview_card.dart';

/// Details view for an existing diary entry. Every change saves at once.
class CalorieEntryDetailsView extends StatelessWidget {
  /// The calorie entry details view.
  const new({
    required this.entry,
    required this.isSaving,
    required this.canEatAgain,
    required this.onClose,
    required this.onMealTypeChanged,
    required this.onPickLoggedAt,
    required this.onPickAmount,
    required this.onEatAgain,
    required this.onReturnToInventory,
    super.key,
  });

  /// The displayed entry.
  final CalorieEntry entry;

  /// Whether a mutation is in flight.
  final bool isSaving;

  /// Whether the entry can be logged again.
  final bool canEatAgain;

  /// Called when closing the view.
  final VoidCallback onClose;

  /// Called when the meal type changes.
  final ValueChanged<MealType> onMealTypeChanged;

  /// Called when changing the logged day and time.
  final VoidCallback onPickLoggedAt;

  /// Called when tapping the amount, or `null` when it is not editable.
  final VoidCallback? onPickAmount;

  /// Called when logging the same food again.
  final VoidCallback onEatAgain;

  /// Called when removing the entry, returning its stock when it has some.
  final VoidCallback onReturnToInventory;

  @override
  Widget build(BuildContext context) {
    return CalorieEntryDetailsSheetChrome(
      isSaving: isSaving,
      onClose: onClose,
      footer: CalorieEntryDetailsSheetFooter(
        canEatAgain: canEatAgain,
        isSaving: isSaving,
        onReturnToInventory: onReturnToInventory,
        onEatAgain: onEatAgain,
      ),
      children: [
        CalorieEntryOverviewCard(
          entry: entry,
          isSaving: isSaving,
          onPickLoggedAt: onPickLoggedAt,
          onMealTypeChanged: onMealTypeChanged,
          onPickAmount: onPickAmount,
        ),
        const SizedBox(height: AppSpacing.lg),
        CalorieEntryNutritionTable(entry: entry),
        CalorieEntryNutritionContext(entry: entry),
        if (entry.isBundle && entry.bundleComponents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          CalorieEntryIngredientsSection(entry: entry),
        ],
      ],
    );
  }
}
