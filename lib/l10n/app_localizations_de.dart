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
  String get inventoryReceiptBatchTitle => 'Belege werden verarbeitet';

  @override
  String inventoryReceiptBatchProgress(int processed, int total) {
    return '$processed/$total';
  }

  @override
  String get inventoryReceiptBatchQueued => 'Wartend';

  @override
  String get inventoryReceiptBatchProcessing => 'Verarbeitung';

  @override
  String get inventoryReceiptBatchSucceeded => 'Fertig';

  @override
  String get inventoryReceiptBatchFailed => 'Fehlgeschlagen';

  @override
  String get inventoryReceiptReviewTitle => 'Belegpositionen prüfen';

  @override
  String get inventoryReceiptReviewPriceTitle => 'Preisübersicht';

  @override
  String get inventoryReceiptReviewPriceTotal => 'Beleg gesamt';

  @override
  String get inventoryReceiptReviewPriceSavable => 'Im Vorrat gespeichert';

  @override
  String get inventoryReceiptReviewPriceExcluded => 'Ausgeschlossene Positionen';

  @override
  String get inventoryReceiptReviewEmpty => 'Keine Positionen im Beleg gefunden.';

  @override
  String get inventoryReceiptReviewExcludedTag => 'Nur prüfen';

  @override
  String get inventoryReceiptReviewEditAction => 'Bearbeiten';

  @override
  String get inventoryReceiptReviewEditTitle => 'Belegposition bearbeiten';

  @override
  String get inventoryReceiptReviewApplyItemAction => 'Änderungen übernehmen';

  @override
  String get inventoryReceiptReviewFieldId => 'ID';

  @override
  String get inventoryReceiptReviewFieldName => 'Name';

  @override
  String get inventoryReceiptReviewFieldEntryDate => 'Erfassungsdatum';

  @override
  String get inventoryReceiptReviewFieldStoreName => 'Geschäft';

  @override
  String get inventoryReceiptReviewFieldQuantity => 'Menge';

  @override
  String get inventoryReceiptReviewFieldInitialQuantity => 'Anfangsmenge';

  @override
  String get inventoryReceiptReviewFieldUnitPrice => 'Stückpreis';

  @override
  String get inventoryReceiptReviewFieldWeight => 'Gewicht';

  @override
  String get inventoryReceiptReviewFieldWeightUnitFallback => 'Fallback-Einheit';

  @override
  String get inventoryReceiptReviewWeightUnitAuto => 'Automatisch';

  @override
  String get inventoryReceiptReviewWeightUnitGram => 'Gramm (g)';

  @override
  String get inventoryReceiptReviewWeightUnitMilliliter => 'Milliliter (ml)';

  @override
  String get inventoryReceiptReviewWeightUnitPiece => 'Stück';

  @override
  String get inventoryReceiptReviewFieldBrand => 'Marke';

  @override
  String get inventoryReceiptReviewFieldCategory => 'Kategorie';

  @override
  String get inventoryReceiptReviewFieldDiscounts => 'Rabatte (JSON)';

  @override
  String get inventoryReceiptReviewDiscountsHint => 'JSON oder Paare: coupon=-1.50';

  @override
  String get inventoryReceiptReviewFieldReceiptId => 'Beleg-ID';

  @override
  String get inventoryReceiptReviewFieldReceiptDate => 'Belegdatum';

  @override
  String get inventoryReceiptReviewFieldLanguage => 'Sprache';

  @override
  String get inventoryReceiptReviewFieldIsDeposit => 'Ist Pfandartikel';

  @override
  String get inventoryReceiptReviewFieldIsDiscount => 'Ist Rabattposition';

  @override
  String get inventoryReceiptReviewSelectDateAction => 'Datum wählen';

  @override
  String get inventoryReceiptReviewClearDateAction => 'Datum löschen';

  @override
  String get inventoryReceiptReviewNoDate => 'Kein Datum';

  @override
  String get inventoryReceiptReviewInvalidNumber => 'Bitte gültige Zahlen eingeben.';

  @override
  String get inventoryReceiptReviewInvalidWeightUnit => 'Bitte eine Einheit angeben (z. B. g oder ml).';

  @override
  String get inventoryReceiptReviewInvalidDiscounts => 'JSON oder key=value verwenden.';

  @override
  String get inventoryReceiptReviewCancelAction => 'Abbrechen';

  @override
  String get inventoryReceiptReviewSaveAction => 'Im Vorrat speichern';

  @override
  String get inventoryReceiptSaveSucceeded => 'Positionen zum Vorrat hinzugefügt.';

  @override
  String get inventoryReceiptSaveFailed => 'Positionen konnten nicht gespeichert werden.';

  @override
  String get inventorySummaryTitle => 'Übersicht';

  @override
  String get inventorySummaryEntries => 'Positionen';

  @override
  String get inventorySummaryQuantity => 'Gesamtmenge';

  @override
  String get inventorySummaryEstimatedValue => 'Geschätzter Wert';

  @override
  String get inventoryListSectionTitle => 'Artikel';

  @override
  String get inventoryListModeByReceipt => 'Nach Beleg';

  @override
  String get inventoryListModeAllItems => 'Alle Artikel';

  @override
  String get inventoryFilterConsumed => 'Verbraucht';

  @override
  String get inventoryFilterNotConsumed => 'Nicht verbraucht';

  @override
  String get inventoryReceiptGroupTitle => 'Beleg';

  @override
  String get inventoryReceiptGroupNoReceipt => 'Ohne Beleg';

  @override
  String get inventoryReceiptGroupItems => 'Artikel';

  @override
  String get inventoryItemNoPrice => 'Kein Preis';

  @override
  String get inventoryItemDeleteAction => 'Löschen';

  @override
  String get inventoryItemEatAction => 'Essen';

  @override
  String get inventoryItemBuyAgainAction => 'Erneut kaufen';

  @override
  String get inventoryItemBuyAgainSucceeded => 'Artikel zur Einkaufsliste hinzugefügt.';

  @override
  String get inventoryItemThrowAwayAction => 'Wegwerfen';

  @override
  String get inventoryItemActionFailed => 'Aktion fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get inventoryEmptyState => 'Noch keine Vorratsartikel vorhanden. Scanne einen Beleg, um zu starten.';

  @override
  String get inventoryFilteredEmptyState => 'Keine Artikel entsprechen den ausgewählten Filtern.';

  @override
  String get inventoryLoadFailed => 'Vorratsartikel konnten nicht geladen werden.';

  @override
  String get inventoryRetryAction => 'Erneut versuchen';

  @override
  String get homeShoppingActionContextPlaceholder => 'Einkaufsaktion folgt bald.';

  @override
  String get shoppingListStatsEntries => 'Positionen';

  @override
  String get shoppingListStatsQuantity => 'Gesamtmenge';

  @override
  String get shoppingListStatsEstimatedTotal => 'Geschätzte Summe';

  @override
  String get shoppingListNameFieldLabel => 'Name';

  @override
  String get shoppingListBrandFieldLabel => 'Marke (optional)';

  @override
  String get shoppingListAddAction => 'Artikel hinzufügen';

  @override
  String get shoppingListEmptyState => 'Deine Einkaufsliste ist leer.';

  @override
  String get shoppingListInvalidNameError => 'Bitte einen Artikelnamen eingeben.';

  @override
  String get shoppingListAddFailedError => 'Artikel konnte nicht hinzugefügt werden. Bitte erneut versuchen.';

  @override
  String get shoppingListLoadFailed => 'Einkaufsartikel konnten nicht geladen werden.';

  @override
  String get shoppingListRetryAction => 'Erneut versuchen';

  @override
  String get shoppingListQuantityLabel => 'Menge';

  @override
  String get shoppingListIncreaseQuantityAction => 'Menge erhöhen';

  @override
  String get shoppingListDecreaseQuantityAction => 'Menge verringern';

  @override
  String shoppingListClearCrossedOffAction(int count) {
    return 'Durchgestrichene löschen ($count)';
  }

  @override
  String get shoppingListClearCrossedOffDialogTitle => 'Durchgestrichene Artikel löschen?';

  @override
  String get shoppingListClearCrossedOffDialogMessage => 'Alle durchgestrichenen Artikel werden von der Einkaufsliste entfernt.';

  @override
  String get shoppingListClearCrossedOffConfirmAction => 'Löschen';

  @override
  String get homeCaloriesActionContextPlaceholder => 'Kalorienaktion folgt bald.';

  @override
  String get caloriesAddOptionManual => 'Manueller Eintrag';

  @override
  String get caloriesAddOptionBarcode => 'Barcode scannen';

  @override
  String get caloriesFabTooltip => 'Kalorien-Eintrag hinzufügen';

  @override
  String get caloriesBarcodeScannerTitle => 'Barcode scannen';

  @override
  String get caloriesBarcodeResolving => 'Produkt wird gesucht...';

  @override
  String get caloriesBarcodeLookupFailed => 'Barcode-Suche fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get caloriesBarcodeCandidateTitle => 'Produkt auswählen';

  @override
  String get caloriesBarcodeCandidateSubtitle => 'Für diesen Barcode wurden mehrere Produkte gefunden.';

  @override
  String get caloriesBarcodeUnknownBrand => 'Unbekannte Marke';

  @override
  String get caloriesBarcodeNotFoundTitle => 'Produkt nicht gefunden';

  @override
  String get caloriesBarcodeNotFoundMessage => 'Für diesen Barcode wurde kein Produkt gefunden.';

  @override
  String get caloriesBarcodeNotFoundManualAction => 'Manueller Eintrag';

  @override
  String get caloriesBarcodeNotFoundOcrAction => 'Nährwertetikett scannen';

  @override
  String get caloriesOcrFailed => 'Nährwertetikett konnte nicht erkannt werden.';

  @override
  String get caloriesLoadFailed => 'Kalorien-Einträge konnten nicht geladen werden.';

  @override
  String get caloriesRetryAction => 'Erneut versuchen';

  @override
  String get caloriesAuthRequired => 'Bitte melde dich an, um Kalorien zu verwalten.';

  @override
  String get caloriesTodayTitle => 'Heute';

  @override
  String get caloriesTodayAction => 'Heute';

  @override
  String get caloriesPreviousDayAction => 'Vorheriger Tag';

  @override
  String get caloriesNextDayAction => 'Nächster Tag';

  @override
  String get caloriesSetGoalAction => 'Ziel setzen';

  @override
  String get caloriesGoalDialogTitle => 'Tagesziel setzen';

  @override
  String get caloriesGoalFieldLabel => 'Tagesziel in kcal';

  @override
  String get caloriesGoalSaveAction => 'Ziel speichern';

  @override
  String get caloriesGoalClearAction => 'Ziel löschen';

  @override
  String get caloriesGoalInvalidValue => 'Bitte eine Zahl größer als null eingeben.';

  @override
  String get caloriesGoalSaveFailed => 'Kalorienziel konnte nicht gespeichert werden.';

  @override
  String get caloriesConsumedLabel => 'Verbraucht';

  @override
  String get caloriesGoalLabel => 'Ziel';

  @override
  String get caloriesRemainingLabel => 'Verbleibend';

  @override
  String get caloriesProteinLabel => 'Eiweiß';

  @override
  String get caloriesCarbsLabel => 'Kohlenhydrate';

  @override
  String get caloriesFatLabel => 'Fett';

  @override
  String get caloriesSectionEmptyState => 'Noch keine Einträge.';

  @override
  String get caloriesDeleteEntryAction => 'Eintrag löschen';

  @override
  String get caloriesDeleteEntryDialogTitle => 'Eintrag löschen?';

  @override
  String caloriesDeleteEntryDialogMessage(String name) {
    return '\"$name\" für diesen Tag löschen?';
  }

  @override
  String get caloriesDeleteEntryConfirmAction => 'Löschen';

  @override
  String get caloriesDeleteFailed => 'Eintrag konnte nicht gelöscht werden.';

  @override
  String get caloriesAddEntryTitle => 'Kalorien-Eintrag hinzufügen';

  @override
  String get caloriesEditEntryTitle => 'Kalorien-Eintrag bearbeiten';

  @override
  String get caloriesEntryNotFound => 'Eintrag wurde nicht gefunden.';

  @override
  String get caloriesEntryNameLabel => 'Name';

  @override
  String get caloriesEntryBrandLabel => 'Marke (optional)';

  @override
  String get caloriesEntryMealLabel => 'Mahlzeit';

  @override
  String get caloriesEntryAmountLabel => 'Verzehrte Menge';

  @override
  String get caloriesEntryUnitLabel => 'Einheit';

  @override
  String get caloriesPer100SectionTitle => 'Nährwerte pro 100';

  @override
  String get caloriesPer100KcalLabel => 'Brennwert (kcal)';

  @override
  String get caloriesPer100ProteinLabel => 'Eiweiß (g)';

  @override
  String get caloriesPer100CarbsLabel => 'Kohlenhydrate (g)';

  @override
  String get caloriesPer100FatLabel => 'Fett (g)';

  @override
  String get caloriesEntryDateTimeLabel => 'Datum und Uhrzeit';

  @override
  String get caloriesSaveEntryAction => 'Speichern';

  @override
  String get caloriesSaveFailed => 'Eintrag konnte nicht gespeichert werden.';

  @override
  String get caloriesRequiredField => 'Pflichtfeld';

  @override
  String get caloriesInvalidNumber => 'Bitte gültige Zahlen eingeben.';

  @override
  String get caloriesPositiveNumberValidation => 'Bitte eine Zahl größer als null eingeben.';

  @override
  String get caloriesNonNegativeNumberValidation => 'Bitte eine Zahl größer oder gleich null eingeben.';

  @override
  String get caloriesMealBreakfast => 'Frühstück';

  @override
  String get caloriesMealLunch => 'Mittagessen';

  @override
  String get caloriesMealDinner => 'Abendessen';

  @override
  String get caloriesMealSnack => 'Snack';

  @override
  String get caloriesUnitGram => 'g';

  @override
  String get caloriesUnitMilliliter => 'ml';

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
