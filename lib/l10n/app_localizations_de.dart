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
  String get homeTitle => 'Startseite';

  @override
  String get homeInventory => 'Vorrat';

  @override
  String get homeShopping => 'Einkauf';

  @override
  String get homeCalories => 'Kalorien';

  @override
  String get homeSettings => 'Einstellungen';

  @override
  String get homeQuickActionTooltip => 'Schnellaktion';

  @override
  String get homeQuickActionTapped => 'Schnellaktion ausgeführt';

  @override
  String get inventoryFabTooltip => 'Belegaktionen';

  @override
  String get inventoryActionScanCamera => 'Beleg scannen (Kamera)';

  @override
  String get inventoryActionUploadFile => 'Beleg hochladen (Bild/PDF)';

  @override
  String get inventoryActionCameraUnsupported => 'Kamera wird auf dieser Plattform nicht unterstützt.';

  @override
  String get inventoryReceiptSelectedCamera => 'Belegbild aufgenommen.';

  @override
  String get inventoryReceiptSelectedFile => 'Belegdatei ausgewählt.';

  @override
  String get inventoryReceiptSelectionFailed => 'Beleg konnte nicht ausgewählt werden. Bitte erneut versuchen.';

  @override
  String get inventoryReceiptAnalysisSucceeded => 'Beleg erfolgreich analysiert.';

  @override
  String get inventoryReceiptAnalysisFailed => 'Beleganalyse fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get homeShoppingActionContextPlaceholder => 'Einkaufsaktion folgt bald.';

  @override
  String get homeCaloriesActionContextPlaceholder => 'Kalorienaktion folgt bald.';

  @override
  String get homeSettingsActionContextPlaceholder => 'Einstellungsaktion folgt bald.';

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsLanguageSubtitle => 'App-Sprache auswählen';

  @override
  String get settingsThemeTitle => 'Design';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsColorTitle => 'Akzentfarbe';

  @override
  String get settingsColorLime => 'Limette';

  @override
  String get settingsColorBlue => 'Blau';

  @override
  String get settingsColorTeal => 'Türkis';

  @override
  String get settingsColorPink => 'Pink';

  @override
  String get settingsColorOrange => 'Orange';

  @override
  String get settingsNotificationsTitle => 'Benachrichtigungen';

  @override
  String get settingsNotificationsSubtitle => 'Erinnerungen und Hinweise verwalten';

  @override
  String get settingsAccountTitle => 'Konto';

  @override
  String get settingsAccountSubtitle => 'Profil und Anmeldung verwalten';

  @override
  String get accountPageNoSession => 'Keine aktive Kontositzung.';

  @override
  String get accountPageGuestTitle => 'Gastkonto';

  @override
  String get accountPageGuestDescription => 'Verknüpfe dein Gastkonto mit Google, um den Zugriff geräteübergreifend zu behalten.';

  @override
  String get accountPageLinkGoogle => 'Mit Google verknüpfen';

  @override
  String get accountPageLinkSuccess => 'Konto erfolgreich verknüpft.';

  @override
  String get accountPageLinkNotCompleted => 'Die Kontoverknüpfung wurde nicht abgeschlossen. Bitte erneut versuchen.';

  @override
  String get accountPageLinkConflictTitle => 'Google-Konto bereits vergeben';

  @override
  String get accountPageLinkConflictDescription => 'Dieses Google-Konto ist bereits mit einem anderen Profil verknüpft. Wähle, wie du fortfahren möchtest.';

  @override
  String get accountPageLinkConflictOverwriteAction => 'Mit diesem Gastkonto überschreiben';

  @override
  String get accountPageLinkConflictOverwriteSubtitle => 'Dieses Gastkonto behalten und das alte Google-verknüpfte Konto ersetzen.';

  @override
  String get accountPageLinkConflictDeleteGuestAction => 'Gastkonto löschen und anmelden';

  @override
  String get accountPageLinkConflictDeleteGuestSubtitle => 'Dieses Gastkonto löschen und mit dem bestehenden Google-Konto weitermachen.';

  @override
  String get accountPageLinkConflictOverwriteDone => 'Google-Konto wurde auf dieses Gastkonto übertragen.';

  @override
  String get accountPageLinkConflictDeleteGuestDone => 'Gastkonto gelöscht. Mit Google angemeldet.';

  @override
  String get accountPageGuestSessionRequired => 'Diese Aktion ist nur für Gastkonten verfügbar.';

  @override
  String get accountPageSignOut => 'Abmelden';

  @override
  String get accountPageDisplayName => 'Anzeigename';

  @override
  String get accountPageEmail => 'E-Mail';

  @override
  String get accountPageUserId => 'Benutzer-ID';

  @override
  String get accountPageNotSet => 'Nicht gesetzt';

  @override
  String get settingsAboutTitle => 'Über die App';

  @override
  String get settingsAboutSubtitle => 'App-Version und Informationen';

  @override
  String get appSubtitle => 'Yet Another Meal Tracker';

  @override
  String get login => 'Login';

  @override
  String get register => 'Registrieren';

  @override
  String get loginAsGuest => 'Als Gast anmelden';

  @override
  String get loginWithGoogle => 'Mit Google anmelden';

  @override
  String get registerWithGoogle => 'Mit Google registrieren';

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
  String get confirmPasswordLabel => 'Passwort bestätigen';

  @override
  String get validationPasswordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get authFailed => 'Authentifizierung fehlgeschlagen';

  @override
  String get authErrorInvalidEmail => 'Die E-Mail-Adresse ist ungültig.';

  @override
  String get authErrorUserDisabled => 'Dieses Benutzerkonto wurde deaktiviert.';

  @override
  String get authErrorUserNotFound => 'Kein Konto mit dieser E-Mail gefunden.';

  @override
  String get authErrorWrongPassword => 'Das Passwort ist falsch.';

  @override
  String get authErrorInvalidCredential => 'Die Anmeldedaten sind ungültig.';

  @override
  String get authErrorEmailAlreadyInUse => 'Für diese E-Mail existiert bereits ein Konto.';

  @override
  String get authErrorWeakPassword => 'Das Passwort ist zu schwach.';

  @override
  String get authErrorOperationNotAllowed => 'Diese Anmeldemethode ist nicht aktiviert.';

  @override
  String get authErrorTooManyRequests => 'Zu viele Anfragen. Bitte später erneut versuchen.';

  @override
  String get authErrorNetworkRequestFailed => 'Netzwerkfehler. Bitte Internetverbindung prüfen.';

  @override
  String get authErrorRequiresRecentLogin => 'Bitte melde dich erneut an, um fortzufahren.';

  @override
  String get authErrorAccountExistsWithDifferentCredential => 'Es existiert bereits ein Konto mit einer anderen Anmeldemethode.';

  @override
  String get authErrorCredentialAlreadyInUse => 'Diese Anmeldeinformation wird bereits von einem anderen Konto verwendet.';

  @override
  String get authErrorProviderAlreadyLinked => 'Dieser Anmeldeanbieter ist bereits mit deinem Konto verknüpft.';

  @override
  String get authErrorGoogleSignInCanceled => 'Google-Anmeldung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get authErrorGoogleIdTokenMissing => 'Google-Anmeldung hat kein gültiges Token geliefert.';

  @override
  String get commonNotImplementedYet => 'Noch nicht implementiert';
}
