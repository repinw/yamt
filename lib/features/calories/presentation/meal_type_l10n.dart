import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines meal type l10n extension.
extension MealTypeL10n on MealType {
  /// Localized name.
  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      MealType.breakfast => l10n.caloriesMealBreakfast,
      MealType.lunch => l10n.caloriesMealLunch,
      MealType.dinner => l10n.caloriesMealDinner,
      MealType.snack => l10n.caloriesMealSnack,
    };
  }
}
