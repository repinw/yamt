import 'package:yamt/l10n/app_localizations.dart';

/// Small cookflow-specific localization helpers.
extension CookingFlowLocalizations on AppLocalizations {
  /// Returns the localized inventory conflict message.
  String cookflowInventoryConflictText({
    required String availableAmount,
    required String missingAmount,
  }) {
    return cookflowInventoryConflictMessage(availableAmount, missingAmount);
  }
}
