import 'package:material_ui/material_ui.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// App and `material_ui` localization delegates.
///
/// Use instead of the generated `AppLocalizations.localizationsDelegates`,
/// which still registers the legacy `flutter_localizations` Material
/// delegates that `material_ui` widgets do not read.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];
