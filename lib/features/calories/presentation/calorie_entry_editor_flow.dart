import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/calorie_entry_editor_page.dart';

/// Opens the editor for a new calorie entry on the root navigator. Completes
/// with the entry when the user saves, and with null when the editor closes
/// any other way. The caller saves the entry.
Future<CalorieEntry?> showCalorieEntryEditor(
  BuildContext context, {
  CalorieProductProfile? prefilledProfile,
  double? prefilledAmount,
  ConsumedUnit? prefilledUnit,
  MealType? preselectedMealType,
  DateTime? preselectedLoggedAt,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<CalorieEntry>(
      builder: (_) => CalorieEntryEditorPage(
        prefilledProfile: prefilledProfile,
        prefilledAmount: prefilledAmount,
        prefilledUnit: prefilledUnit,
        preselectedMealType: preselectedMealType,
        preselectedLoggedAt: preselectedLoggedAt,
      ),
    ),
  );
}
