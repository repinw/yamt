// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get homeInventory => 'Vorrat';

  @override
  String get homeShopping => 'Einkauf';

  @override
  String get homeStatistics => 'Statistik';

  @override
  String get homeCalories => 'Tagebuch';

  @override
  String get homeSettings => 'Einstellungen';

  @override
  String get homeQuickActionTooltip => 'Schnellaktion';

  @override
  String get inventoryFabTooltip => 'Belegaktionen';

  @override
  String get inventoryPageTitle => 'Mein Vorrat';

  @override
  String get inventoryActionScanCamera => 'Beleg scannen (Kamera)';

  @override
  String get inventoryActionUploadFile => 'Beleg hochladen (Bild/PDF)';

  @override
  String get inventoryActionCameraUnsupported => 'Kamera wird auf dieser Plattform nicht unterstützt.';

  @override
  String get inventoryActionManualAdd => 'Lebensmittel manuell hinzufügen';

  @override
  String get inventorySharedReceiptConfirmTitle => 'Geteilten Beleg scannen?';

  @override
  String get inventorySharedReceiptConfirmSingleMessage => 'Möchtest du diese geteilte Datei als Beleg scannen?';

  @override
  String inventorySharedReceiptConfirmMultipleMessage(int count) {
    return 'Möchtest du $count geteilte Dateien als Belege scannen?';
  }

  @override
  String get inventorySharedReceiptConfirmAction => 'Scannen';

  @override
  String get inventoryReceiptSelectionFailed => 'Beleg konnte nicht ausgewählt werden. Bitte erneut versuchen.';

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
  String get inventoryReceiptBatchReviewAction => 'Prüfen';

  @override
  String get inventoryReceiptBatchReviewed => 'Geprüft';

  @override
  String get inventoryReceiptBatchCloseAction => 'Schließen';

  @override
  String get inventoryReceiptReviewTitle => 'Beleg prüfen';

  @override
  String get inventoryReceiptReviewPriceTitle => 'Gesamtsumme';

  @override
  String get inventoryReceiptReviewPriceTotal => 'Gemäß erkanntem Beleg';

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
  String get inventoryReceiptReviewFieldName => 'Name';

  @override
  String get inventoryReceiptReviewFieldStoreName => 'Geschäft';

  @override
  String get inventoryReceiptReviewFieldQuantity => 'Menge';

  @override
  String get inventoryReceiptReviewFieldUnitPrice => 'Stückpreis';

  @override
  String get inventoryReceiptReviewFieldWeight => 'Gewicht';

  @override
  String get inventoryReceiptReviewFieldWeightUnit => 'Einheit';

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
  String get inventoryUnitGram => 'g';

  @override
  String get inventoryUnitMilliliter => 'ml';

  @override
  String get inventoryUnitPiece => 'Stk';

  @override
  String get inventoryReceiptReviewFieldBrand => 'Marke';

  @override
  String get inventoryReceiptReviewFieldCategory => 'Kategorie';

  @override
  String get inventoryReceiptReviewFieldDiscounts => 'Rabatte';

  @override
  String get inventoryReceiptReviewDiscountNameLabel => 'Rabattname';

  @override
  String get inventoryReceiptReviewDiscountAmountLabel => 'Betrag';

  @override
  String get inventoryReceiptReviewAddDiscountAction => 'Rabattzeile hinzufügen';

  @override
  String get inventoryReceiptReviewFieldIsDeposit => 'Ist Pfandartikel';

  @override
  String get inventoryReceiptReviewFieldIsDiscount => 'Ist Rabattposition';

  @override
  String get inventoryReceiptReviewNoDate => 'Kein Datum';

  @override
  String get inventoryReceiptReviewInvalidNumber => 'Bitte gültige Zahlen eingeben.';

  @override
  String get inventoryReceiptReviewInvalidWeightUnit => 'Bitte eine Einheit angeben (z. B. g oder ml).';

  @override
  String get inventoryReceiptReviewConfirmItemAction => 'Artikel bestätigen';

  @override
  String get inventoryReceiptReviewUndoConfirmAction => 'Bestätigung aufheben';

  @override
  String get inventoryReceiptReviewWeightMissingTag => 'Gewicht?';

  @override
  String get inventoryReceiptReviewInvalidDiscounts => 'JSON oder key=value verwenden.';

  @override
  String get inventoryReceiptReviewDetectedItems => 'Erkannte Artikel';

  @override
  String get inventoryReceiptReviewOriginalReceiptAction => 'Original-Beleg ansehen';

  @override
  String get inventoryReceiptReviewOriginalReceiptTitle => 'Original-Beleg Vorschau';

  @override
  String get inventoryReceiptReviewOriginalReceiptUnavailable => '(Hier würde das Foto angezeigt werden)';

  @override
  String get inventoryReceiptReviewReadAsPrefix => 'Gelesen als';

  @override
  String get inventoryReceiptReviewCandidatesAction => 'Kandidaten';

  @override
  String get inventoryReceiptReviewProductSelectionLabel => 'Produkt auswählen';

  @override
  String get inventoryReceiptReviewManualSearchLabel => 'Produkt suchen';

  @override
  String get inventoryReceiptReviewRecentProductsTitle => 'Zuletzt hinzugefügt';

  @override
  String get inventoryReceiptReviewManualDataAction => 'Produkt suchen oder Barcode scannen';

  @override
  String get inventoryReceiptReviewManualDataTitle => 'Produkt suchen oder Barcode scannen';

  @override
  String get inventoryReceiptReviewManualDataHint => 'Produkt suchen oder Barcode scannen. Nährwerte später ergänzen.';

  @override
  String get inventoryReceiptReviewManualDataSaveAction => 'Übernehmen';

  @override
  String get inventoryReceiptReviewManualDataBarcodeLabel => 'Barcode';

  @override
  String get inventoryReceiptReviewManualDataRequired => 'Bitte Produkt wählen, Barcode scannen oder Nährwerte angeben.';

  @override
  String get inventoryReceiptReviewRequestEnrichmentAction => 'Später per KI ermitteln lassen';

  @override
  String get inventoryReceiptReviewRequestEnrichmentHint => 'Speichert den Artikel jetzt und markiert ihn für spätere KI-Anreicherung.';

  @override
  String get inventoryReceiptReviewSwitchAction => 'Wechseln';

  @override
  String get inventoryReceiptReviewCancelAction => 'Abbrechen';

  @override
  String get inventoryReceiptReviewSaveAction => 'Speichern';

  @override
  String get inventoryReceiptSaveSucceeded => 'Positionen zum Vorrat hinzugefügt.';

  @override
  String get inventoryReceiptSaveFailed => 'Positionen konnten nicht gespeichert werden.';

  @override
  String get inventoryListModeByReceipt => 'Nach Beleg';

  @override
  String get inventoryListModeAllItems => 'Alle Lebensmittel';

  @override
  String get inventoryRecentSectionTitle => 'Kürzlich hinzugefügt';

  @override
  String get inventorySearchLabel => 'Im Vorrat suchen';

  @override
  String get inventorySearchClearAction => 'Suche leeren';

  @override
  String get inventoryFilterAction => 'Artikel filtern';

  @override
  String get inventoryFiltersTitle => 'Artikel filtern';

  @override
  String get inventoryNutritionCaloriesShortLabel => 'Kcal';

  @override
  String get inventoryNutritionCarbsShortLabel => 'KH';

  @override
  String get inventoryFilterConsumed => 'Verbraucht';

  @override
  String get inventoryFilterNotConsumed => 'Nicht verbraucht';

  @override
  String get inventoryHideFullyConsumedItemsToggle => 'Komplett verbrauchte Artikel ausblenden';

  @override
  String get preparedMealFilterAction => 'Filtern';

  @override
  String get preparedMealFiltersTitle => 'Filter';

  @override
  String get preparedMealSortNewestFirst => 'Neueste zuerst';

  @override
  String get preparedMealShowReadyOnlyToggle => 'Nur fertige anzeigen';

  @override
  String get preparedMealShowIncompleteOnlyToggle => 'Nur unvollständige anzeigen';

  @override
  String get preparedMealShowDepletedOnlyToggle => 'Nur aufgebrauchte anzeigen';

  @override
  String get preparedMealHideFullyConsumedItemsToggle => 'Komplett verbrauchte ausblenden';

  @override
  String get inventoryReceiptGroupTitle => 'Beleg';

  @override
  String get inventoryReceiptGroupNoReceipt => 'Ohne Beleg';

  @override
  String get inventoryReceiptGroupItems => 'Artikel';

  @override
  String get inventoryItemDeleteAction => 'Löschen';

  @override
  String get inventoryItemDeletedMessage => 'Artikel gelöscht.';

  @override
  String get inventoryItemEatAction => 'Essen';

  @override
  String get inventoryItemEatSheetEyebrow => 'Essen loggen';

  @override
  String inventoryItemEatSheetTitle(String name) {
    return 'Essen: $name';
  }

  @override
  String get inventoryItemEatSheetAmountLabel => 'Menge eingeben';

  @override
  String get inventoryItemEatSheetQuickSelectLabel => 'Schnellwahl';

  @override
  String get inventoryItemEatSheetAllAction => 'Alles';

  @override
  String get inventoryItemEatSheetInedibleAmountLabel => 'Nicht essbaren Anteil abziehen';

  @override
  String get inventoryItemEatSheetInedibleAmountHint => 'Optional, zum Beispiel Knochen oder Schalen. Kalorien werden nur für den essbaren Rest berechnet.';

  @override
  String get inventoryItemEatSheetInedibleAmountFieldLabel => 'Nicht essbarer Anteil';

  @override
  String get inventoryItemEatSheetInedibleAmountError => 'Der Abzug muss kleiner als die verzehrte Menge sein.';

  @override
  String get inventoryItemEatSheetWhenLabel => 'Wann?';

  @override
  String get inventoryItemEatSheetNowValue => 'Heute';

  @override
  String get inventoryItemEatSheetNutritionLabel => 'Nährwerte';

  @override
  String get inventoryItemEatSheetConfirmAction => 'Loggen';

  @override
  String get inventoryItemEatSheetClearAmountAction => 'Menge leeren';

  @override
  String get inventoryItemBuyAgainAction => 'Erneut kaufen';

  @override
  String get inventoryItemBuyAgainSucceeded => 'Artikel zur Einkaufsliste hinzugefügt.';

  @override
  String get inventoryItemThrowAwayAction => 'Wegwerfen';

  @override
  String get inventoryItemSwapCandidateAction => 'Kandidat tauschen';

  @override
  String get inventoryItemSwapCandidateRequiresFullItem => 'Du kannst den Kandidaten nur tauschen, solange der Artikel noch vollständig vorhanden ist.';

  @override
  String get inventoryItemActionFailed => 'Aktion fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get inventoryBarcodeStatusPending => 'Barcode-Abgleich läuft';

  @override
  String get inventoryBarcodeStatusUncertain => 'Nicht sicher';

  @override
  String get inventoryBarcodeStatusMissing => 'Barcode fehlt';

  @override
  String get inventoryBarcodeMissingPromptTitle => 'Barcode fehlt';

  @override
  String get inventoryBarcodeMissingPromptMessage => 'Jetzt scannen für sofortiges Kalorien-Logging oder später per KI ergänzen lassen.';

  @override
  String get inventoryBarcodeMissingPromptScanNow => 'Jetzt Barcode scannen';

  @override
  String get inventoryBarcodeMissingPromptLater => 'Später';

  @override
  String get inventoryBarcodeLookupQueued => 'Barcode-Suche wurde ausgeführt. Ergebnis steht direkt im Inventar-Item.';

  @override
  String get inventoryBarcodeScanUnsupported => 'Barcode-Scan wird aktuell auf Android und iOS unterstützt.';

  @override
  String get inventoryManualAddTitle => 'Lebensmittel manuell hinzufügen';

  @override
  String get inventoryManualAddHint => 'Scanne einen Barcode. Danach kannst du das Produkt prüfen, speichern oder Nährwerte ergänzen.';

  @override
  String get inventoryManualAddResolving => 'Barcode wird gesucht...';

  @override
  String get inventoryManualAddCandidateTitle => 'Produkt auswählen';

  @override
  String get inventoryManualAddCandidateSubtitle => 'Zu diesem Barcode wurden mehrere passende Produkte gefunden.';

  @override
  String get inventoryManualAddCandidateSourceLearned => 'Community';

  @override
  String get inventoryManualAddCandidateSourceOff => 'OFF';

  @override
  String get inventoryManualAddUnknownBrand => 'Unbekannte Marke';

  @override
  String get inventoryManualAddNotFound => 'Zu diesem Barcode wurde kein passendes Produkt gefunden.';

  @override
  String get inventoryManualAddLookupFailed => 'Barcode-Abfrage fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get inventoryManualAddSaveFailed => 'Das Produkt konnte nicht zum Inventar hinzugefügt werden.';

  @override
  String get inventoryManualAddSaved => 'Produkt zum Inventar hinzugefügt.';

  @override
  String get inventoryManualAddPackageSizeLabel => 'Packungsgröße';

  @override
  String get inventoryManualAddEatNowOption => 'Sofort essen';

  @override
  String get inventoryManualAddEatNowSizeLabel => 'Sofort essen Menge';

  @override
  String get inventoryManualAddEatNowRequiresNutrition => 'Nur verfügbar, wenn Nährwerte vorhanden sind.';

  @override
  String get inventoryManualAddVoiceSearchStartTooltip => 'Sprachsuche starten';

  @override
  String get inventoryManualAddVoiceSearchStopTooltip => 'Sprachsuche beenden';

  @override
  String get inventoryManualAddVoiceSearchUnavailable => 'Sprachsuche wird auf diesem Gerät aktuell nicht unterstützt.';

  @override
  String get inventoryManualAddVoiceSearchPermissionDenied => 'Bitte erlaube Mikrofonzugriff, um die Sprachsuche zu verwenden.';

  @override
  String get inventoryManualAddVoiceSearchFailed => 'Sprachsuche konnte nicht gestartet werden. Bitte versuche es erneut.';

  @override
  String get inventoryManualAddStoreName => 'Manuell hinzugefügt';

  @override
  String get inventoryBarcodePortionDialogTitle => 'Verzehrte Menge eingeben';

  @override
  String get inventoryBarcodePortionDialogConfirmAction => 'Weiter';

  @override
  String get inventoryEmptyState => 'Noch keine Vorratsartikel vorhanden. Scanne einen Beleg oder füge Lebensmittel manuell hinzu.';

  @override
  String get inventoryFilteredEmptyState => 'Keine Artikel passen zu deiner Suche oder den aktiven Filtern.';

  @override
  String get inventoryLoadFailed => 'Vorratsartikel konnten nicht geladen werden.';

  @override
  String get inventoryRetryAction => 'Erneut versuchen';

  @override
  String get preparedMealSectionTitle => 'Mahlzeiten';

  @override
  String get preparedMealCreateTitle => 'Mahlzeit erstellen';

  @override
  String get preparedMealEditTitle => 'Mahlzeit bearbeiten';

  @override
  String get preparedMealNameLabel => 'Mahlzeitname';

  @override
  String get preparedMealClearNameAction => 'Namen leeren';

  @override
  String get preparedMealInvalidName => 'Bitte gib einen Mahlzeitnamen ein.';

  @override
  String get preparedMealPortionsLabel => 'Portionen';

  @override
  String get preparedMealInvalidPortions => 'Bitte gib mindestens eine Portion ein.';

  @override
  String get preparedMealFixFormErrorsMessage => 'Bitte prüfe die markierten Felder.';

  @override
  String get preparedMealInvalidPortionsRange => 'Bitte gib eine gültige Portionsanzahl im verfügbaren Bereich ein.';

  @override
  String get preparedMealImageLabel => 'Titelbild';

  @override
  String get preparedMealAddImageAction => 'Bild hinzufügen';

  @override
  String get preparedMealChangeImageAction => 'Bild ändern';

  @override
  String get preparedMealRemoveImageAction => 'Bild entfernen';

  @override
  String get preparedMealImageHint => 'Füge ein Foto für diese Mahlzeit hinzu oder nutze das Standard-Cover.';

  @override
  String get preparedMealImageCameraAction => 'Foto aufnehmen';

  @override
  String get preparedMealImagePickFailed => 'Das Mahlzeitenbild konnte nicht ausgewählt werden.';

  @override
  String get preparedMealImageTooLarge => 'Das ausgewählte Bild ist zu groß.';

  @override
  String get preparedMealIngredientsTitle => 'Zutaten';

  @override
  String get preparedMealCreateAction => 'Mahlzeit erstellen';

  @override
  String get preparedMealBindAction => 'Als Mahlzeit binden';

  @override
  String get preparedMealUsedAmountLabel => 'Verwendete Menge';

  @override
  String preparedMealAvailableAmount(int amount, String unit) {
    return 'Verfügbar: $amount $unit';
  }

  @override
  String get preparedMealInvalidIngredientAmount => 'Bitte gib eine gültige Zutatenmenge ein.';

  @override
  String get preparedMealNutritionPerPieceHint => 'Bitte Nährwerte pro verwendetem Stück eintragen.';

  @override
  String get preparedMealNutritionPerHundredHint => 'Bitte Nährwerte pro 100 g/ml eintragen.';

  @override
  String get preparedMealNutritionModePerHundred => '100 g/ml';

  @override
  String get preparedMealNutritionModePerPortion => 'Portion';

  @override
  String get preparedMealNutritionModeTotal => 'Gesamt';

  @override
  String get preparedMealPricePerHundred => 'Preis pro 100 g/ml';

  @override
  String get preparedMealPricePerPortion => 'Preis pro Portion';

  @override
  String get preparedMealPriceTotal => 'Gesamtpreis';

  @override
  String preparedMealSelectionCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get preparedMealCreatedMessage => 'Mahlzeit wurde erstellt.';

  @override
  String get preparedMealUpdatedMessage => 'Mahlzeit wurde aktualisiert.';

  @override
  String get preparedMealInsufficientAmountMessage => 'Mindestens eine ausgewählte Zutat ist nicht mehr in ausreichender Menge verfügbar.';

  @override
  String get preparedMealMissingNutritionMessage => 'Mindestens einer ausgewählten Zutat fehlen vollständige Nährwerte.';

  @override
  String get preparedMealItemUnavailableMessage => 'Mindestens eine ausgewählte Zutat ist nicht mehr im Inventar verfügbar.';

  @override
  String get preparedMealActionFailed => 'Mahlzeit-Aktion fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String preparedMealIngredientsCount(int count) {
    return '$count Zutaten';
  }

  @override
  String get preparedMealIncompleteLabel => 'Unvollständig';

  @override
  String get preparedMealIncompleteHint => 'Diese Mahlzeit ist noch nicht vollständig und kann erst gegessen werden, wenn alle fehlenden Zutaten ergänzt wurden.';

  @override
  String get preparedMealPendingIngredientUnassigned => 'Noch nicht belegt';

  @override
  String get preparedMealPendingIngredientAddAction => 'Zutat ergänzen';

  @override
  String get preparedMealPendingIngredientIgnoreAction => 'Zutat ignorieren';

  @override
  String get preparedMealPendingIngredientSelectionTitle => 'Zutat aus Inventar ergänzen';

  @override
  String get preparedMealPendingIngredientSelectionEmpty => 'Keine Inventarartikel vorhanden.';

  @override
  String get preparedMealPendingIngredientFillFailed => 'Zutat konnte nicht zur Mahlzeit hinzugefügt werden.';

  @override
  String get preparedMealPendingIngredientIgnoreFailed => 'Zutat konnte nicht ignoriert werden.';

  @override
  String preparedMealPortionsRemaining(int remaining, int total) {
    return '$remaining/$total Portionen';
  }

  @override
  String get preparedMealUnbundleAction => 'Auflösen';

  @override
  String get preparedMealEatTitle => 'Mahlzeit essen';

  @override
  String get preparedMealDiaryDayLabel => 'Tagebuchtag';

  @override
  String get preparedMealThrowAwayTitle => 'Portionen wegwerfen';

  @override
  String get preparedMealPortionsToUseLabel => 'Portionen verwenden';

  @override
  String get preparedMealConfirmAction => 'Bestätigen';

  @override
  String get inventoryDiscardReasonTitle => 'Warum wirfst du das weg?';

  @override
  String get inventoryDiscardReasonExpired => 'Abgelaufen';

  @override
  String get inventoryDiscardReasonSpoiled => 'Verdorben';

  @override
  String get inventoryDiscardReasonCookedTooMuch => 'Zu viel gekocht';

  @override
  String get inventoryDiscardReasonOther => 'Sonstiges';

  @override
  String get preparedMealSaveTemplateAction => 'Als Rezept speichern';

  @override
  String get preparedMealTemplateSavedMessage => 'Rezept gespeichert.';

  @override
  String get preparedMealTemplatesPageTitle => 'Rezepte';

  @override
  String get preparedMealTemplatesEmptyState => 'Noch keine Rezepte gespeichert.';

  @override
  String get preparedMealTemplatesLoadFailed => 'Rezepte konnten nicht geladen werden.';

  @override
  String get preparedMealTemplateDeleteAction => 'Rezept löschen';

  @override
  String get preparedMealTemplateDeletedMessage => 'Rezept gelöscht.';

  @override
  String get preparedMealTemplateAddRecipeAction => 'Rezept hinzufügen';

  @override
  String get preparedMealTemplateCreateFromRecipeAction => 'Aus Rezept anlegen';

  @override
  String get preparedMealTemplateCreateFailedMessage => 'Rezept konnte nicht erstellt werden.';

  @override
  String get preparedMealTemplateRecipeImportFailedMessage => 'Rezeptdaten konnten nicht importiert werden.';

  @override
  String get preparedMealTemplateRecipeSheetTitle => 'Rezept anlegen';

  @override
  String get preparedMealTemplateRecipeEditSheetTitle => 'Rezept bearbeiten';

  @override
  String get preparedMealTemplateRecipeSheetSubtitle => 'Füge einen Rezept-Link ein, zum Beispiel von Chefkoch.';

  @override
  String get preparedMealTemplateRecipeUrlLabel => 'Rezept-Link';

  @override
  String get preparedMealTemplateRecipeUrlHint => 'https://www.chefkoch.de/...';

  @override
  String get preparedMealTemplateRecipeUrlInvalid => 'Bitte gib einen gültigen Rezept-Link ein.';

  @override
  String get preparedMealTemplateNameLabel => 'Rezeptname';

  @override
  String get preparedMealTemplateNameHelper => 'Optional. Wenn leer, wird der Name aus dem Link abgeleitet.';

  @override
  String get preparedMealTemplatePortionsLabel => 'Portionen';

  @override
  String get preparedMealTemplatePortionsHelper => 'Optional. Wenn leer, werden die Portionen aus dem Rezept übernommen.';

  @override
  String get preparedMealTemplateRecipePlaceholder => 'Rezept-Link';

  @override
  String get preparedMealTemplateNoIngredientsYet => 'Noch keine Zutaten verknüpft.';

  @override
  String get preparedMealTemplateOpenAction => 'Rezept öffnen';

  @override
  String get preparedMealTemplateUpdatedMessage => 'Rezept aktualisiert.';

  @override
  String get preparedMealTemplateImportReviewTitle => 'Rezept prüfen';

  @override
  String get preparedMealTemplateImportReviewInstructionsTitle => 'Kurze Anleitung';

  @override
  String get preparedMealTemplateImportReviewSavingAction => 'Speichert...';

  @override
  String preparedMealTemplateRecipeSource(String host) {
    return 'Rezept: $host';
  }

  @override
  String preparedMealTemplatePortions(int count) {
    return '$count Portionen';
  }

  @override
  String get preparedMealTemplateDetailTitle => 'Rezept';

  @override
  String preparedMealTemplateDetailMatchTitle(String name) {
    return 'Zutaten-Abgleich: $name';
  }

  @override
  String get preparedMealTemplateDetailNotFound => 'Rezept nicht gefunden.';

  @override
  String get preparedMealTemplateDetailLoadFailed => 'Rezept konnte nicht geladen werden.';

  @override
  String preparedMealTemplateDetailBasePortions(int count) {
    return 'Basis: $count Portionen';
  }

  @override
  String get preparedMealTemplateDetailScaleHint => 'Zutaten werden auf diese Portionszahl skaliert.';

  @override
  String get preparedMealTemplateDetailNoIngredients => 'Noch keine Zutaten vorhanden.';

  @override
  String get preparedMealTemplateDetailSaveAction => 'Rezept anpassen';

  @override
  String get preparedMealTemplateDetailSavingAction => 'Speichert...';

  @override
  String get preparedMealTemplateDetailIngredientsToShoppingListAction => 'Zutaten auf Einkaufsliste';

  @override
  String get preparedMealTemplateDetailCreateMealHint => 'Dieses Rezept braucht mindestens eine Zutat, bevor du eine Mahlzeit erstellst.';

  @override
  String get preparedMealTemplateDetailAssignAction => 'Zuordnen';

  @override
  String get preparedMealTemplateDetailChangeAssignmentAction => 'Zuordnung ändern';

  @override
  String get preparedMealTemplateDetailAssignedFromInventoryTitle => 'Aus dem Inventar belegt';

  @override
  String get preparedMealTemplateDetailMatchingInventoryItemsTitle => 'Passende Inventarartikel';

  @override
  String preparedMealTemplateDetailMissingAssignedItems(int count) {
    return '$count belegte Artikel sind nicht mehr im Inventar.';
  }

  @override
  String preparedMealTemplateDetailIgnoredAmount(String amount) {
    return 'Ignoriert • $amount';
  }

  @override
  String preparedMealTemplateDetailAssignedCount(int count) {
    return '$count Artikel belegt';
  }

  @override
  String get preparedMealTemplateDetailSelectionTitle => 'Inventarartikel wählen';

  @override
  String get preparedMealTemplateDetailSelectionEmpty => 'Keine Inventarartikel vorhanden.';

  @override
  String preparedMealTemplateDetailSelectionConversionLabel(String sourceUnit, String unit) {
    return 'Menge pro $sourceUnit ($unit)';
  }

  @override
  String preparedMealTemplateDetailSelectionConversionHint(String sourceUnit, String unit, String ingredient) {
    return 'Wie viel $unit entspricht 1 $sourceUnit von \"$ingredient\"?';
  }

  @override
  String get preparedMealTemplateDetailSelectionConversionError => 'Bitte gib eine Menge größer als 0 ein.';

  @override
  String preparedMealTemplateDetailConversionSummary(String sourceUnit, int amount, String unit) {
    return '1 $sourceUnit = $amount $unit';
  }

  @override
  String get preparedMealTemplateDetailListAction => 'Liste';

  @override
  String get preparedMealTemplateDetailSearchAction => 'Suchen';

  @override
  String get preparedMealTemplateDetailSwapAction => 'Tauschen';

  @override
  String get preparedMealTemplateDetailRestoreAction => 'Wiederherstellen';

  @override
  String get preparedMealTemplateDetailAddToShoppingListAction => 'Zur Einkaufsliste';

  @override
  String get preparedMealTemplateDetailIgnoreAction => 'Ignorieren';

  @override
  String get preparedMealTemplateDetailUnignoreAction => 'Nicht ignorieren';

  @override
  String get preparedMealTemplateDetailAddIngredientShoppingFailed => 'Zutat konnte nicht zur Einkaufsliste hinzugefügt werden.';

  @override
  String get preparedMealTemplateDetailAddIngredientsShoppingFailed => 'Zutaten konnten nicht zur Einkaufsliste hinzugefügt werden.';

  @override
  String preparedMealTemplateDetailAddIngredientsShoppingSucceeded(int count) {
    return '$count Zutaten wurden zur Einkaufsliste hinzugefügt.';
  }

  @override
  String get preparedMealTemplateDetailIgnoreSaveFailed => 'Zutatenstatus konnte nicht gespeichert werden.';

  @override
  String get preparedMealTemplateDetailInvalidMealMessage => 'Das Rezept braucht mindestens eine gültige Zutat.';

  @override
  String get preparedMealTemplateDetailSaveFailedMessage => 'Rezept konnte nicht angepasst werden.';

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
  String get caloriesTodayAction => 'Heute';

  @override
  String get caloriesSetGoalAction => 'Ziel manuell setzen';

  @override
  String get caloriesSetEatingWindowAction => 'Essensfenster setzen';

  @override
  String get caloriesShiftGoalStartAction => 'Zielstart verschieben';

  @override
  String get caloriesCalculatorAction => 'Ziel neu berechnen';

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
  String get caloriesGoalClearFailed => 'Kalorienziel konnte nicht gelöscht werden.';

  @override
  String get caloriesGoalStartDialogTitle => 'Zielstart verschieben';

  @override
  String get caloriesGoalStartDateLabel => 'Datum';

  @override
  String get caloriesGoalStartTimeLabel => 'Uhrzeit';

  @override
  String get caloriesGoalStartSaveFailed => 'Der Zielstart konnte nicht aktualisiert werden.';

  @override
  String get caloriesEatingWindowDialogTitle => 'Essensfenster setzen';

  @override
  String get caloriesEatingWindowStartLabel => 'Beginn';

  @override
  String get caloriesEatingWindowEndLabel => 'Ende';

  @override
  String get caloriesEatingWindowInvalidRange => 'Die Endzeit muss nach der Startzeit liegen.';

  @override
  String get caloriesEatingWindowSaveFailed => 'Das Essensfenster konnte nicht aktualisiert werden.';

  @override
  String get caloriesCalculatorSheetTitle => 'Kalorienrechner';

  @override
  String get caloriesCalculatorOnboardingTitle => 'Kalorienziel festlegen';

  @override
  String get caloriesCalculatorOnboardingSubtitle => 'Wir berechnen aus ein paar Angaben dein tägliches Kalorienziel.';

  @override
  String caloriesCalculatorStepProgress(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get caloriesCalculatorBackAction => 'Zurück';

  @override
  String get caloriesCalculatorNextAction => 'Weiter';

  @override
  String get caloriesCalculatorSexLabel => 'Geschlecht';

  @override
  String get caloriesCalculatorSexMale => 'Männlich';

  @override
  String get caloriesCalculatorSexFemale => 'Weiblich';

  @override
  String get caloriesCalculatorWeightLabel => 'Gewicht (kg)';

  @override
  String get caloriesCalculatorWeightEmpty => 'Bitte gib dein Gewicht ein.';

  @override
  String get caloriesCalculatorWeightInvalid => 'Bitte gib ein gültiges Gewicht ein.';

  @override
  String get caloriesCalculatorHeightLabel => 'Größe (cm)';

  @override
  String get caloriesCalculatorHeightEmpty => 'Bitte gib deine Größe ein.';

  @override
  String get caloriesCalculatorHeightInvalid => 'Bitte gib eine gültige Größe ein.';

  @override
  String get caloriesCalculatorAgeLabel => 'Alter (Jahre)';

  @override
  String get caloriesCalculatorAgeEmpty => 'Bitte gib dein Alter ein.';

  @override
  String get caloriesCalculatorAgeInvalid => 'Bitte gib ein gültiges Alter ein.';

  @override
  String get caloriesCalculatorActivityLevelLabel => 'Aktivitätslevel (PAL)';

  @override
  String get caloriesCalculatorActivityLevelHelp => 'Wähle die Option, die am besten zu deiner typischen Woche passt.';

  @override
  String get caloriesCalculatorActivityLevelNoneTitle => 'Kaum aktiv';

  @override
  String get caloriesCalculatorActivityLevelNoneDescription => 'Büro, viel sitzen, wenige Schritte und kein oder kaum Sport.';

  @override
  String get caloriesCalculatorActivityLevelLowTitle => 'Leicht aktiv';

  @override
  String get caloriesCalculatorActivityLevelLowDescription => 'Überwiegend sitzend, aber mit etwas Bewegung im Alltag oder 1 bis 2 lockeren Einheiten pro Woche.';

  @override
  String get caloriesCalculatorActivityLevelMediumTitle => 'Moderat aktiv';

  @override
  String get caloriesCalculatorActivityLevelMediumDescription => 'Regelmäßige Bewegung im Alltag oder 3 bis 4 Sporteinheiten pro Woche.';

  @override
  String get caloriesCalculatorActivityLevelHighTitle => 'Sehr aktiv';

  @override
  String get caloriesCalculatorActivityLevelHighDescription => 'Körperlich aktiver Alltag oder intensives Training an den meisten Tagen.';

  @override
  String get caloriesCalculatorActivityLevelExtremeTitle => 'Extrem aktiv';

  @override
  String get caloriesCalculatorActivityLevelExtremeDescription => 'Sehr hohe Trainingsumfänge, körperlich harte Arbeit oder Leistungssport.';

  @override
  String get caloriesCalculatorActivityLevelHint => 'Zum Beispiel 1,2 bis 2,0';

  @override
  String get caloriesCalculatorActivityLevelEmpty => 'Bitte gib dein Aktivitätslevel ein.';

  @override
  String get caloriesCalculatorActivityLevelInvalid => 'Bitte gib ein gültiges Aktivitätslevel ein.';

  @override
  String get caloriesCalculatorGoalModeLabel => 'Zielmodus';

  @override
  String get caloriesCalculatorGoalModeLose => 'Abnehmen';

  @override
  String get caloriesCalculatorGoalModeMaintain => 'Halten';

  @override
  String get caloriesCalculatorGoalModeGain => 'Zunehmen';

  @override
  String get caloriesCalculatorGoalSpeedLabel => 'Zielgeschwindigkeit (kg/Woche)';

  @override
  String get caloriesCalculatorGoalSpeedHint => 'Zum Beispiel 0,25, 0,5 oder 0,75';

  @override
  String get caloriesCalculatorGoalSpeedEmpty => 'Bitte gib eine Zielgeschwindigkeit ein.';

  @override
  String get caloriesCalculatorGoalSpeedInvalid => 'Bitte gib eine gültige Zielgeschwindigkeit ein.';

  @override
  String get caloriesCalculatorResultsTitle => 'Ergebnisse';

  @override
  String get caloriesCalculatorBmrLabel => 'Grundumsatz';

  @override
  String get caloriesCalculatorTdeeLabel => 'Erhaltungskalorien';

  @override
  String get caloriesCalculatorDailyGoalLabel => 'Tägliches Kalorienziel';

  @override
  String get caloriesCalculatorGoalStartLabel => 'Zielstart';

  @override
  String get caloriesCalculatorGoalStartHint => 'Dein Kalorienziel-Verlauf beginnt ab diesem Zeitpunkt.';

  @override
  String get caloriesCalculatorGoalStartChangeAction => 'Ändern';

  @override
  String get caloriesCalculatorEatingWindowLabel => 'Essensfenster';

  @override
  String get caloriesCalculatorEatingWindowHint => 'Wird verwendet, um die heutige Tagebuch-Balance über den Tag zu takten.';

  @override
  String get caloriesCalculatorGoalStartFutureError => 'Der Zielstart darf nicht in der Zukunft liegen.';

  @override
  String caloriesCalculatorMinimumGoalWarning(int minimumKcal) {
    return 'Beim Abnehmen darf das tägliche Ziel nicht unter $minimumKcal kcal fallen. Das Ergebnis wurde auf dieses Minimum begrenzt.';
  }

  @override
  String get caloriesCalculatorSaveAction => 'Ziel speichern';

  @override
  String get caloriesCalculatorSaveFailed => 'Das berechnete Kalorienziel konnte nicht gespeichert werden.';

  @override
  String get caloriesConsumedLabel => 'Verbraucht';

  @override
  String get caloriesGoalLabel => 'Ziel';

  @override
  String get caloriesRemainingLabel => 'Verbleibend';

  @override
  String get caloriesSummaryViewClassic => 'Klassisch';

  @override
  String get caloriesSummaryViewBalance => 'Balance';

  @override
  String get caloriesBalanceCarryoverLabel => '7 Tage Bilanz';

  @override
  String get caloriesBalanceFlexGoalLabel => 'Flex-Ziel';

  @override
  String get caloriesBalancePaceNowLabel => 'Pace jetzt';

  @override
  String get caloriesBalancePaceFinalLabel => 'Pace final';

  @override
  String get caloriesBalanceScaleBufferLabel => 'Defizit';

  @override
  String get caloriesBalanceScaleOnTrackLabel => 'Im Takt';

  @override
  String get caloriesBalanceScaleOverLabel => 'Überschuss';

  @override
  String get caloriesBalanceStatusBalancedNow => 'Für jetzt gut ausbalanciert';

  @override
  String caloriesBalanceStatusEatNow(int kcal) {
    return 'Nimm jetzt etwa $kcal kcal zu dir';
  }

  @override
  String get caloriesBalanceStatusWaitNow => 'Gedulde dich noch etwas mit dem Essen';

  @override
  String caloriesBalanceStatusWaitUntil(String time) {
    return 'Wieder im Takt ab etwa $time Uhr';
  }

  @override
  String get caloriesBalanceStatusWaitRestOfDay => 'Heute vermutlich nicht mehr im Takt';

  @override
  String get caloriesBalanceStatusRecommendFast => 'Empfehlung: heute fasten';

  @override
  String get caloriesBalanceStatusRecommendFastRestOfDay => 'Empfehlung: restlichen Tag fasten';

  @override
  String get caloriesBalanceStatusOnTrack => 'Genau im Takt';

  @override
  String caloriesBalanceStatusBuffer(int kcal) {
    return '$kcal kcal unter Pace';
  }

  @override
  String caloriesBalanceStatusOver(int kcal) {
    return '$kcal kcal über Pace';
  }

  @override
  String caloriesBalanceStatusLoseUnder(int kcal) {
    return '$kcal kcal Puffer fürs Abnehmen';
  }

  @override
  String caloriesBalanceStatusLoseOver(int kcal) {
    return '$kcal kcal über Pace fürs Abnehmen';
  }

  @override
  String caloriesBalanceStatusGainUnder(int kcal) {
    return '$kcal kcal unter Pace fürs Zunehmen';
  }

  @override
  String get caloriesBalanceStatusFinishedOnTrack => 'Der Tag endete im Zielkorridor';

  @override
  String caloriesBalanceStatusFinishedBuffer(int kcal) {
    return '$kcal kcal unter dem Flex-Ziel beendet';
  }

  @override
  String caloriesBalanceStatusFinishedOver(int kcal) {
    return '$kcal kcal über dem Flex-Ziel beendet';
  }

  @override
  String caloriesBalanceStatusFinishedLoseUnder(int kcal) {
    return 'Mit $kcal kcal Puffer fürs Abnehmen beendet';
  }

  @override
  String caloriesBalanceStatusFinishedLoseOver(int kcal) {
    return '$kcal kcal über dem Flex-Ziel fürs Abnehmen beendet';
  }

  @override
  String caloriesBalanceStatusFinishedGainUnder(int kcal) {
    return '$kcal kcal unter dem Flex-Ziel fürs Zunehmen beendet';
  }

  @override
  String caloriesBalanceStatusFinishedGainOver(int kcal) {
    return 'Mit $kcal kcal Extra fürs Zunehmen beendet';
  }

  @override
  String get caloriesBalanceUnavailable => 'Die Balance-Ansicht ist gerade nicht verfügbar.';

  @override
  String get caloriesProteinLabel => 'Eiweiß';

  @override
  String get caloriesCarbsLabel => 'Kohlenhydrate';

  @override
  String get caloriesFatLabel => 'Fett';

  @override
  String get caloriesWeekBufferTitle => 'Wochenbilanz';

  @override
  String caloriesWeekBufferRemaining(int kcal) {
    return '$kcal kcal für diese Woche übrig';
  }

  @override
  String caloriesWeekBufferOverspent(int kcal) {
    return '$kcal kcal diese Woche drüber';
  }

  @override
  String get caloriesWeekBalanceTodayLabel => 'Heu';

  @override
  String caloriesWeekBalanceSaved(int kcal) {
    return 'Du hast seit Zielstart $kcal kcal gespart. Dein heutiges Ziel wurde erhöht.';
  }

  @override
  String caloriesWeekBalanceOverspent(int kcal) {
    return 'Seit Zielstart $kcal kcal im Überschuss.';
  }

  @override
  String get caloriesWeekBalanceStable => 'Seit Zielstart bist du ausgeglichen. Dein heutiges Ziel bleibt unverändert.';

  @override
  String caloriesWeekBalanceStartsLater(String date) {
    return 'Dein Ziel startet am $date. Die Bilanz beginnt dann automatisch.';
  }

  @override
  String get caloriesWeekBalanceStartedToday => 'Dein Zielstart ist heute. Die Bilanz baut sich ab jetzt auf.';

  @override
  String get caloriesSectionEmptyState => 'Noch keine Einträge.';

  @override
  String get caloriesDeleteEntryDialogTitle => 'Eintrag löschen?';

  @override
  String caloriesDeleteEntryDialogMessage(String name) {
    return '\"$name\" für diesen Tag löschen?';
  }

  @override
  String get caloriesDeleteEntryConfirmAction => 'Löschen';

  @override
  String get caloriesReturnPreparedMealDialogTitle => 'Mahlzeit zurück in den Vorrat legen?';

  @override
  String caloriesReturnPreparedMealDialogMessage(String name) {
    return '\"$name\" zurück in den Vorrat legen und aus dem Tagebuch entfernen?';
  }

  @override
  String get caloriesReturnPreparedMealConfirmAction => 'Zurück in den Vorrat';

  @override
  String get caloriesReturnPreparedMealFailed => 'Die Mahlzeit konnte nicht zurück in den Vorrat gelegt werden.';

  @override
  String get caloriesDeleteRestoreInventoryQuestion => 'Nahrungsmittel wieder in den Vorrat legen?';

  @override
  String get caloriesDeleteRestoreFailed => 'Das Nahrungsmittel konnte nicht zurück in den Vorrat gelegt werden.';

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
  String get caloriesPer100SaturatedFatLabel => 'Davon gesättigte Fettsäuren (g)';

  @override
  String get caloriesPer100PolyunsaturatedFatLabel => 'Davon mehrfach ungesättigte Fettsäuren (g)';

  @override
  String get caloriesPer100SugarLabel => 'Davon Zucker (g)';

  @override
  String get caloriesPer100FiberLabel => 'Ballaststoffe (g)';

  @override
  String get caloriesPer100SaltLabel => 'Salz (g)';

  @override
  String get inventoryReceiptReviewManualAddNutritionAction => 'Weitere Nährwerte eintragen';

  @override
  String get inventoryReceiptReviewManualNutritionValueLabel => 'Wert';

  @override
  String get inventoryReceiptReviewManualNutritionUnitLabel => 'Einheit';

  @override
  String get inventoryReceiptReviewManualNutritionTypeLabel => 'Nährwert';

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
  String get caloriesWeekdayShortMonday => 'Mo';

  @override
  String get caloriesWeekdayShortTuesday => 'Di';

  @override
  String get caloriesWeekdayShortWednesday => 'Mi';

  @override
  String get caloriesWeekdayShortThursday => 'Do';

  @override
  String get caloriesWeekdayShortFriday => 'Fr';

  @override
  String get caloriesWeekdayShortSaturday => 'Sa';

  @override
  String get caloriesWeekdayShortSunday => 'So';

  @override
  String get caloriesUnitKcal => 'kcal';

  @override
  String get caloriesUnitGram => 'g';

  @override
  String get caloriesUnitMilliliter => 'ml';

  @override
  String caloriesBundlePortions(int consumed, int total) {
    return '$consumed/$total Portionen';
  }

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
  String get settingsDiaryTitle => 'Tagebuch';

  @override
  String settingsDiarySubtitle(String window) {
    return 'Essensfenster: $window';
  }

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
  String get settingsHouseholdTitle => 'Haushalt';

  @override
  String get settingsHouseholdSubtitle => 'Mitglieder einladen und geteilten Zugriff verwalten';

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
  String get accountPageLinkEmailPassword => 'Mit E-Mail & Passwort verknüpfen';

  @override
  String get accountPageLinkEmailPasswordTitle => 'Gastkonto verknüpfen';

  @override
  String get accountPageLinkEmailPasswordDescription => 'Lege E-Mail-Anmeldedaten für dieses Gastkonto an.';

  @override
  String get accountPageLinkEmailPasswordConfirmAction => 'Konto verknüpfen';

  @override
  String get accountPageLinkSuccess => 'Konto erfolgreich verknüpft.';

  @override
  String get accountPageLinkNotCompleted => 'Die Kontoverknüpfung wurde nicht abgeschlossen. Bitte erneut versuchen.';

  @override
  String get accountPageLinkConflictTitle => 'Konto bereits vergeben';

  @override
  String get accountPageLinkConflictDescription => 'Diese Anmeldeinformation ist bereits mit einem anderen Profil verknüpft. Wähle, wie du fortfahren möchtest.';

  @override
  String get accountPageLinkConflictOverwriteAction => 'Mit diesem Gastkonto überschreiben';

  @override
  String get accountPageLinkConflictOverwriteSubtitle => 'Dieses Gastkonto behalten und das alte verknüpfte Konto ersetzen.';

  @override
  String get accountPageLinkConflictDeleteGuestAction => 'Gastkonto löschen und anmelden';

  @override
  String get accountPageLinkConflictDeleteGuestSubtitle => 'Dieses Gastkonto löschen und mit dem bestehenden Konto weitermachen.';

  @override
  String get accountPageLinkConflictOverwriteDone => 'Anmeldeinformation wurde auf dieses Gastkonto übertragen.';

  @override
  String get accountPageLinkConflictDeleteGuestDone => 'Gastkonto gelöscht. Mit bestehendem Konto angemeldet.';

  @override
  String get accountPageGuestSessionRequired => 'Diese Aktion ist nur für Gastkonten verfügbar.';

  @override
  String get accountPageSignOut => 'Abmelden';

  @override
  String get accountPageDeleteAction => 'Konto löschen';

  @override
  String get accountPageDeleteDialogTitle => 'Konto löschen?';

  @override
  String get accountPageDeleteDialogMessage => 'Dadurch wird dein Konto dauerhaft gelöscht und kann nicht rückgängig gemacht werden.';

  @override
  String get accountPageDeleteDialogConfirmAction => 'Löschen';

  @override
  String get accountPageDeleteSuccess => 'Konto gelöscht.';

  @override
  String get accountPageDisplayName => 'Anzeigename';

  @override
  String get accountPageEmail => 'E-Mail';

  @override
  String get accountPageUserId => 'Benutzer-ID';

  @override
  String get accountPageNotSet => 'Nicht gesetzt';

  @override
  String get householdTitle => 'Haushalt';

  @override
  String get householdJoinTitle => 'Haushalt beitreten';

  @override
  String get householdJoinCodeLabel => 'Code';

  @override
  String get householdJoinCodeHint => '6-stelligen Einladungscode eingeben';

  @override
  String get householdJoinAction => 'Beitreten';

  @override
  String get householdJoinSuccess => 'Haushalt beigetreten.';

  @override
  String get householdJoinInvalidCode => 'Ungültiger Haushaltscode.';

  @override
  String get householdJoinExpiredCode => 'Dieser Haushaltscode ist abgelaufen.';

  @override
  String get householdJoinOwnCode => 'Du kannst deinem eigenen Haushalt nicht beitreten.';

  @override
  String get householdInviteTitle => 'Mitglieder einladen';

  @override
  String get householdInviteGenerateCode => 'Code erstellen';

  @override
  String get householdInviteCodeValidFor => 'Code 24 Stunden gültig';

  @override
  String get householdInviteCopyCode => 'Code kopieren';

  @override
  String get householdInviteCodeCopied => 'Code kopiert.';

  @override
  String get householdInviteRefreshCode => 'Neuen Code erstellen';

  @override
  String get householdInviteVerificationRequired => 'Verknüpfe dein Konto erst mit Google oder E-Mail, bevor du einen Haushalt leitest.';

  @override
  String get householdHostVerificationHint => 'Um andere Personen in deinen Haushalt einzuladen, verknüpfe dein Gastkonto mit Google oder E-Mail & Passwort.';

  @override
  String get householdMembersTitle => 'Mitglieder';

  @override
  String get householdLeaderBadge => 'Leitung';

  @override
  String get householdYouBadge => 'Du';

  @override
  String get householdRemoveMemberTitle => 'Mitglied entfernen?';

  @override
  String householdRemoveMemberMessage(Object name) {
    return '$name aus diesem Haushalt entfernen?';
  }

  @override
  String get householdRemoveMemberAction => 'Entfernen';

  @override
  String get householdRemoveMemberSuccess => 'Mitglied entfernt.';

  @override
  String get householdRemoveMemberFailed => 'Dieses Mitglied kann nicht entfernt werden.';

  @override
  String get householdLeaveTitle => 'Haushalt verlassen?';

  @override
  String get householdLeaveMessage => 'Du verlierst den Zugriff auf den geteilten Haushalt, bis du erneut beitrittst.';

  @override
  String get householdLeaveAction => 'Haushalt verlassen';

  @override
  String get householdLeaveSuccess => 'Haushalt verlassen.';

  @override
  String get householdLeaderOnly => 'Das kann nur die Haushaltsleitung tun.';

  @override
  String get householdActionFailed => 'Haushaltsaktion fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get settingsAboutTitle => 'Über die App';

  @override
  String get settingsAboutSubtitle => 'App-Version und Informationen';

  @override
  String get commonOr => 'Oder';

  @override
  String get login => 'Login';

  @override
  String get register => 'Registrieren';

  @override
  String get loginWithGoogle => 'Mit Google anmelden';

  @override
  String get registerWithGoogle => 'Mit Google registrieren';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get authBrandTitle => 'Yamt';

  @override
  String get authBrandSubtitle => 'Yet Another Meal Tracker';

  @override
  String get authRegisterTitle => 'Registrieren';

  @override
  String get authRegisterSubtitle => 'Erstelle dein Konto und lege direkt los.';

  @override
  String get authContinueAsGuest => 'Als Gast fortfahren';

  @override
  String get authFooterNoAccountPrefix => 'Noch kein Konto?';

  @override
  String get authFooterHasAccountPrefix => 'Bereits ein Konto?';

  @override
  String get authSwitchRegisterAction => 'Jetzt registrieren';

  @override
  String get authSwitchLoginAction => 'Login';

  @override
  String get authForgotPassword => 'Passwort vergessen?';

  @override
  String get authGuestNameSetupTitle => 'Name festlegen';

  @override
  String get authGuestNameSetupSubtitle => 'Wie möchtest du genannt werden?';

  @override
  String get authGuestNameFieldLabel => 'Anzeigename';

  @override
  String get authGuestNameSaveAction => 'Weiter';

  @override
  String get authGuestNameRequiredError => 'Bitte einen Anzeigenamen eingeben.';

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
  String get statisticsPageSubtitle => 'Muster aus Vorrat, Food Waste und Ernährung auf einen Blick.';

  @override
  String get statisticsContextHousehold => 'Haushalt';

  @override
  String get statisticsContextPersonal => 'Persönlich';

  @override
  String get statisticsTimeframeWeek => '7 Tage';

  @override
  String get statisticsTimeframeMonth => 'Monat';

  @override
  String get statisticsTimeframeYear => 'Jahr';

  @override
  String get statisticsTimeframeTotal => 'Gesamt';

  @override
  String get statisticsTabSpending => 'Ausgaben';

  @override
  String get statisticsTabWaste => 'Food Waste';

  @override
  String get statisticsTabCalories => 'Kalorien';

  @override
  String get statisticsHouseholdHintTitle => 'MVP-Hinweis';

  @override
  String get statisticsHouseholdHintBody => 'Haushaltszahlen basieren aktuell auf erfassten Vorratsartikeln und verfügbaren Belegdaten. Eine vollständige Verlaufs-Historie folgt später.';

  @override
  String get statisticsWasteHintTitle => 'Waste-Tracking vorbereiten';

  @override
  String get statisticsWasteHintBody => 'Für echte Food-Waste-Statistiken brauchen wir dauerhafte Wegwerf-Events und Gründe im Wegwerfen-Flow.';

  @override
  String get statisticsSpendingTotalTitle => 'Erfasste Ausgaben';

  @override
  String get statisticsSpendingTotalSubtitle => 'Summe der erfassten Einkäufe im gewählten Zeitraum';

  @override
  String get statisticsSpendingTrendTitle => 'Preisentwicklung';

  @override
  String get statisticsSpendingTrendEmpty => 'Noch keine wiederkehrenden Produkte mit Preisverlauf im gewählten Zeitraum.';

  @override
  String get statisticsSpendingStoresTitle => 'Top Supermärkte';

  @override
  String get statisticsTopStoresEmpty => 'Noch keine Märkte mit verwertbaren Werten im Zeitraum.';

  @override
  String get statisticsSpendingChartTitle => 'Ausgaben nach Belegdatum';

  @override
  String get statisticsSpendingChartSubtitle => 'Der Graph nutzt das echte receiptDate des Belegs und zeigt die letzten Einkaufstage im Filter.';

  @override
  String get statisticsSpendingChartEmpty => 'Sobald Belegdaten mit Datum vorliegen, erscheint hier dein Ausgabenverlauf.';

  @override
  String get statisticsSpendingItemsTitle => 'Teuerste Einkäufe';

  @override
  String get statisticsExpensiveItemsEmpty => 'Noch keine kostenrelevanten Positionen im Zeitraum.';

  @override
  String get statisticsWasteOverviewTitle => 'Food Waste Überblick';

  @override
  String get statisticsWasteTrackingMissingValue => 'Noch keine Historie';

  @override
  String get statisticsWasteTrackingMissingMessage => 'Wegwerf-Events und Gründe werden aktuell noch nicht dauerhaft gespeichert.';

  @override
  String statisticsWasteOverviewSummary(int eventCount, Object lossValue) {
    String _temp0 = intl.Intl.pluralLogic(
      eventCount,
      locale: localeName,
      other: '$eventCount Wegwerf-Events · $lossValue erfasster Verlust',
      one: '1 Wegwerf-Event · $lossValue erfasster Verlust',
    );
    return '$_temp0';
  }

  @override
  String get statisticsWasteRatioTitle => 'Verhältnis & Geldverlust';

  @override
  String get statisticsWasteMoneyLossMissing => 'Sobald Wegwerfwerte erfasst werden, erscheint hier das Verhältnis und der Euro-Verlust.';

  @override
  String get statisticsWasteMoneyLossTracked => 'Erfasster Wert der weggeworfenen Lebensmittel im Zeitraum.';

  @override
  String get statisticsWasteReasonsTitle => 'Waste-Gründe';

  @override
  String get statisticsWasteReasonsMissing => 'Füge beim Wegwerfen Gründe wie abgelaufen oder zu viel gekocht hinzu, damit wir Muster erkennen.';

  @override
  String statisticsWasteReasonsTopSummary(int count) {
    return 'Häufigster Grund über $count Wegwerf-Events.';
  }

  @override
  String get statisticsWasteItemsTitle => 'Oft weggeworfen';

  @override
  String get statisticsWasteItemsMissing => 'Sobald genug Wegwerf-Events vorliegen, zeigen wir hier deine häufigsten Problemartikel.';

  @override
  String statisticsWasteItemsTopSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}x weggeworfen',
      one: '1x weggeworfen',
    );
    return '$_temp0';
  }

  @override
  String get statisticsCaloriesOverviewTitle => 'Kalorien Überblick';

  @override
  String statisticsCaloriesOverviewSummary(int trackedDays, int entries) {
    return '$trackedDays Tage mit Einträgen · $entries Einträge';
  }

  @override
  String get statisticsCaloriesStreakTitle => 'Ziel-Streak';

  @override
  String statisticsCaloriesStreakSummary(int goalDays, int trackedDays) {
    return '$goalDays von $trackedDays Tagen im Ziel';
  }

  @override
  String get statisticsCaloriesBufferTitle => 'Wochenbilanz';

  @override
  String get statisticsCaloriesBufferSubtitle => 'aktuelle Balance gegen dein Ziel';

  @override
  String get statisticsCaloriesChartTitle => 'Tagesverlauf';

  @override
  String get statisticsCaloriesChartSubtitle => 'Letzte Tage mit gegessenen Kalorien und Zielmarke.';

  @override
  String get statisticsCaloriesChartEmpty => 'Sobald Kalorien-Einträge vorliegen, erscheint hier dein Tagesverlauf.';

  @override
  String get statisticsCaloriesMacrosTitle => 'Makro-Verteilung';

  @override
  String get statisticsCaloriesMacroChartSubtitle => 'Anteil der Kalorien aus Kohlenhydraten, Protein und Fett.';

  @override
  String get statisticsCaloriesNoEntries => 'Noch keine Kalorien-Einträge im Zeitraum.';

  @override
  String get statisticsChartGoalLegend => 'Zielmarke';

  @override
  String get statisticsMetricNoTrend => 'Noch kein Trend';

  @override
  String get statisticsMetricNoData => 'Noch keine Daten';

  @override
  String get statisticsMetricAverage => 'Durchschnitt';

  @override
  String get statisticsMetricEntries => 'Einträge';

  @override
  String get statisticsMetricTrackedDays => 'Tage mit Einträgen';

  @override
  String get statisticsMetricGoalDays => 'Im Ziel';

  @override
  String get statisticsMetricReceipts => 'Belege';

  @override
  String get statisticsWasteSignalsTitle => 'Was noch fehlt';

  @override
  String get statisticsWasteChecklistEvents => 'dauerhafte Wegwerf-Events mit Menge und Zeitpunkt';

  @override
  String get statisticsWasteChecklistReasons => 'Wegwerf-Gründe wie abgelaufen, schimmelig oder zu viel gekocht';

  @override
  String get statisticsWasteChecklistEatingOut => 'Preise für externe Mahlzeiten, damit Haushaltskosten vollständiger werden';

  @override
  String statisticsCaloriesBalanceWindow(String startDate, String endDate) {
    return 'Balance-Fenster von $startDate bis $endDate';
  }

  @override
  String get statisticsLoadFailed => 'Statistik konnte nicht geladen werden.';

  @override
  String get commonUndoAction => 'Rückgängig machen';

  @override
  String get commonNotImplementedYet => 'Noch nicht implementiert';
}
