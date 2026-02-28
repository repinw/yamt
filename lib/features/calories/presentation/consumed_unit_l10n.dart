import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/l10n/app_localizations.dart';

extension ConsumedUnitL10n on ConsumedUnit {
  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      ConsumedUnit.grams => l10n.caloriesUnitGram,
      ConsumedUnit.milliliters => l10n.caloriesUnitMilliliter,
    };
  }
}
