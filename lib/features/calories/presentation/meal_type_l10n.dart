import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/l10n/app_localizations.dart';

extension MealTypeL10n on MealType {
  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      MealType.breakfast => l10n.caloriesMealBreakfast,
      MealType.lunch => l10n.caloriesMealLunch,
      MealType.dinner => l10n.caloriesMealDinner,
      MealType.snack => l10n.caloriesMealSnack,
    };
  }
}
