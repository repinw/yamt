// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get welcomeTitle => 'Willkommen';

  @override
  String get appSubtitle => 'Yet Another Meal Tracker';

  @override
  String get login => 'Login';

  @override
  String get register => 'Registrieren';

  @override
  String get loginAsGuest => 'Als Gast anmelden';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get authSwitchToRegister => 'Noch kein Konto? Registrieren';

  @override
  String get authSwitchToLogin => 'Bereits ein Konto? Login';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get confirmPasswordLabel => 'Passwort bestaetigen';

  @override
  String get validationPasswordsDoNotMatch =>
      'Passwoerter stimmen nicht ueberein';

  @override
  String get authFailed => 'Authentifizierung fehlgeschlagen';
}
