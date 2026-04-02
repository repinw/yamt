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
  String get inventoryReceiptReviewManualDataAction => 'Barcode scannen oder Nährwerte eintragen';

  @override
  String get inventoryReceiptReviewManualDataTitle => 'Barcode scannen oder Nährwerte eintragen';

  @override
  String get inventoryReceiptReviewManualDataHint => 'Scanne zuerst den Barcode. Wenn nichts gefunden wird, kannst du danach die Nährwerttabelle fotografieren oder die Werte direkt eintragen.';

  @override
  String get inventoryReceiptReviewManualDataSaveAction => 'Übernehmen';

  @override
  String get inventoryReceiptReviewManualDataBarcodeLabel => 'Barcode';

  @override
  String get inventoryReceiptReviewManualDataRequired => 'Bitte einen Barcode scannen oder Nährwerte angeben.';

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
  String get inventoryItemBuyAgainAction => 'Erneut kaufen';

  @override
  String get inventoryItemBuyAgainSucceeded => 'Artikel zur Einkaufsliste hinzugefügt.';

  @override
  String get inventoryItemThrowAwayAction => 'Wegwerfen';

  @override
  String get inventoryItemSwapCandidateAction => 'Kandidat tauschen';

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
  String get inventoryManualAddStoreName => 'Manuell hinzugefügt';

  @override
  String get inventoryBarcodePortionDialogTitle => 'Verzehrte Menge eingeben';

  @override
  String get inventoryBarcodePortionDialogConfirmAction => 'Weiter';

  @override
  String get inventoryEmptyState => 'Noch keine Vorratsartikel vorhanden. Scanne einen Beleg, um zu starten.';

  @override
  String get inventoryFilteredEmptyState => 'Keine Artikel entsprechen den ausgewählten Filtern.';

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
  String get preparedMealSaveTemplateAction => 'Als Vorlage speichern';

  @override
  String get preparedMealTemplateSavedMessage => 'Vorlage gespeichert.';

  @override
  String get preparedMealTemplatesPageTitle => 'Vorlagen';

  @override
  String get preparedMealTemplatesEmptyState => 'Noch keine Vorlagen gespeichert.';

  @override
  String get preparedMealTemplatesLoadFailed => 'Vorlagen konnten nicht geladen werden.';

  @override
  String get preparedMealTemplateDeleteAction => 'Vorlage löschen';

  @override
  String get preparedMealTemplateDeletedMessage => 'Vorlage gelöscht.';

  @override
  String get preparedMealTemplateAddRecipeAction => 'Rezeptvorlage hinzufügen';

  @override
  String get preparedMealTemplateCreateFromRecipeAction => 'Aus Rezept anlegen';

  @override
  String get preparedMealTemplateCreateFailedMessage => 'Vorlage konnte nicht erstellt werden.';

  @override
  String get preparedMealTemplateRecipeImportFailedMessage => 'Rezeptdaten konnten nicht importiert werden.';

  @override
  String get preparedMealTemplateRecipeSheetTitle => 'Vorlage aus Rezept anlegen';

  @override
  String get preparedMealTemplateRecipeEditSheetTitle => 'Rezeptvorlage bearbeiten';

  @override
  String get preparedMealTemplateRecipeSheetSubtitle => 'Füge einen Rezept-Link ein, zum Beispiel von Chefkoch.';

  @override
  String get preparedMealTemplateRecipeUrlLabel => 'Rezept-Link';

  @override
  String get preparedMealTemplateRecipeUrlHint => 'https://www.chefkoch.de/...';

  @override
  String get preparedMealTemplateRecipeUrlInvalid => 'Bitte gib einen gültigen Rezept-Link ein.';

  @override
  String get preparedMealTemplateNameLabel => 'Vorlagenname';

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
  String get preparedMealTemplateOpenAction => 'Vorlage öffnen';

  @override
  String get preparedMealTemplateUpdatedMessage => 'Vorlage aktualisiert.';

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
  String get preparedMealTemplateDetailTitle => 'Vorlage';

  @override
  String get preparedMealTemplateDetailNotFound => 'Vorlage nicht gefunden.';

  @override
  String get preparedMealTemplateDetailLoadFailed => 'Vorlage konnte nicht geladen werden.';

  @override
  String preparedMealTemplateDetailBasePortions(int count) {
    return 'Basis: $count Portionen';
  }

  @override
  String get preparedMealTemplateDetailScaleHint => 'Zutaten werden auf diese Portionszahl skaliert.';

  @override
  String get preparedMealTemplateDetailNoIngredients => 'Noch keine Zutaten vorhanden.';

  @override
  String get preparedMealTemplateDetailSaveAction => 'Vorlage anpassen';

  @override
  String get preparedMealTemplateDetailSavingAction => 'Speichert...';

  @override
  String get preparedMealTemplateDetailIngredientsToShoppingListAction => 'Zutaten auf Einkaufsliste';

  @override
  String get preparedMealTemplateDetailCreateMealHint => 'Diese Vorlage braucht mindestens eine Zutat, bevor du eine Mahlzeit erstellst.';

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
  String get preparedMealTemplateDetailInvalidMealMessage => 'Die Vorlage braucht mindestens eine gültige Zutat.';

  @override
  String get preparedMealTemplateDetailSaveFailedMessage => 'Vorlage konnte nicht angepasst werden.';

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
  String get caloriesSetGoalAction => 'Ziel setzen';

  @override
  String get caloriesCalculatorAction => 'Kalorienrechner';

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
  String get caloriesCalculatorSheetTitle => 'Kalorienrechner';

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
  String get caloriesProteinLabel => 'Eiweiß';

  @override
  String get caloriesCarbsLabel => 'Kohlenhydrate';

  @override
  String get caloriesFatLabel => 'Fett';

  @override
  String get caloriesWeekBufferTitle => 'Wochenpuffer';

  @override
  String caloriesWeekBufferRemaining(int kcal) {
    return '$kcal kcal für diese Woche übrig';
  }

  @override
  String caloriesWeekBufferOverspent(int kcal) {
    return '$kcal kcal diese Woche drüber';
  }

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
  String get settingsAiProcessingTitle => 'KI-Verarbeitung';

  @override
  String get settingsAiProcessingSubtitle => 'OCR- und Analyseintensität steuern';

  @override
  String get settingsAiProcessingInfoLabel => 'Info zur Verarbeitungsstufe';

  @override
  String get settingsAiProcessingInfoTitle => 'Verarbeitungsstufe';

  @override
  String get settingsAiProcessingInfoMessage => 'Geschwindigkeit und Ergebnisqualität hängen von der gewählten Stufe ab.';

  @override
  String get settingsAiProcessingMinimal => 'Minimal';

  @override
  String get settingsAiProcessingLow => 'Niedrig';

  @override
  String get settingsAiProcessingBalanced => 'Ausgewogen';

  @override
  String get settingsAiProcessingHigh => 'Hoch';

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
  String get statisticsCaloriesBufferTitle => 'Wochenpuffer';

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
