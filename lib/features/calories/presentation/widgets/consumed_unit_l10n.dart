import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines consumed unit l10n extension.
extension ConsumedUnitL10n on ConsumedUnit {
  /// Localized name.
  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      ConsumedUnit.grams => l10n.caloriesUnitGram,
      ConsumedUnit.milliliters => l10n.caloriesUnitMilliliter,
    };
  }
}
