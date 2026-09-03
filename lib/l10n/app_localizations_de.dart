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
  String get homeCalories => 'Tagebuch';

  @override
  String get homeCookbook => 'Kochbuch';

  @override
  String get homeSettings => 'Einstellungen';

  @override
  String get aiChefTooltip => 'Lass dir von der KI ein zufälliges Rezept vorschlagen';

  @override
  String get aiChefSetupTitle => 'Was soll die KI kochen?';

  @override
  String get aiChefSetupSubtitle => 'Wähle, ob dein Vorrat beachtet wird, und ergänze Wünsche.';

  @override
  String get aiChefUseInventoryTitle => 'Vorrat beachten';

  @override
  String get aiChefUseInventorySubtitle => 'Zutaten aus deinem Vorrat bevorzugen.';

  @override
  String get aiChefWishesLabel => 'Wünsche';

  @override
  String get aiChefWishesHint => 'z. B. vegetarisch, schnell, proteinreich, ohne Reis';

  @override
  String get aiChefGenerateAction => 'Rezept generieren';

  @override
  String get aiChefGeneratingTitle => 'Rezept wird kreiert...';

  @override
  String get aiChefGeneratingSubtitle => 'Deine persönliche KI stellt ein leckeres Rezept zusammen...';

  @override
  String get aiChefSaveAction => 'Im Kochbuch speichern';

  @override
  String get aiChefCloseAction => 'Schließen';

  @override
  String get aiChefSaveSuccess => 'Rezept erfolgreich im Kochbuch gespeichert!';

  @override
  String get aiChefSaveError => 'Rezept konnte nicht gespeichert werden.';

  @override
  String get aiChefFromInventory => 'Aus deinem Vorrat';

  @override
  String get aiChefQuoteLoveGarlic => 'Die Geheimzutat ist immer Liebe. Und Knoblauch.';

  @override
  String get aiChefQuoteCookingMagic => 'Kochen ist wie Zaubern, nur dass man das Ergebnis essen kann.';

  @override
  String get aiChefQuoteGoodFood => 'Gutes Essen bringt gute Laune.';

  @override
  String get aiChefQuoteKitchenTalks => 'Die besten Gespräche finden immer in der Küche statt.';

  @override
  String get aiChefQuoteVirtualOven => 'Die KI heizt schon mal den virtuellen Ofen vor...';

  @override
  String aiChefPortionsLabel(int portions) {
    String _temp0 = intl.Intl.pluralLogic(
      portions,
      locale: localeName,
      other: '$portions Portionen',
      one: '1 Portion',
    );
    return '$_temp0';
  }

  @override
  String aiChefCaloriesLabel(int kcal) {
    return '$kcal kcal';
  }

  @override
  String aiChefProteinLabel(int grams) {
    return 'Eiweiß: $grams g';
  }

  @override
  String aiChefCarbsLabel(int grams) {
    return 'Kohlenhydrate: $grams g';
  }

  @override
  String aiChefFatLabel(int grams) {
    return 'Fett: $grams g';
  }

  @override
  String get homeQuickActionTooltip => 'Schnellaktion';

  @override
  String homeHeartCounterUseTooltip(String day) {
    return 'Herz für $day nutzen';
  }

  @override
  String homeHeartCounterActiveTooltip(String day) {
    return '$day ist bereits ein Herztag';
  }

  @override
  String get homeHeartCounterEmptyTooltip => 'Keine Herzen übrig';

  @override
  String get homeHeartCounterUnavailableTooltip => 'Herzen können nur in der aktuellen Burn Week genutzt werden';

  @override
  String get homeHeartUseTitle => 'Herztag nutzen?';

  @override
  String homeHeartUseMessage(String day) {
    return 'Gib 1 Herz aus, um $day zu ignorieren. Erfasstes Essen bleibt im Tagebuch, aber der Tag zählt als perfekt und wird beim Wochenlernen übersprungen.';
  }

  @override
  String get homeHeartUseConfirmAction => 'Herz nutzen';

  @override
  String get inventoryFabTooltip => 'Produkt hinzufügen';

  @override
  String get productSearchHubTitle => 'Produkt hinzufügen';

  @override
  String get productSearchHubInventoryTitle => 'Zum Vorrat hinzufügen';

  @override
  String get productSearchHubDiaryTitle => 'Lebensmittel essen';

  @override
  String get productSearchHubBarcodeAction => 'Barcode';

  @override
  String get productSearchHubAiAction => 'KI';

  @override
  String get productSearchHubReceiptAction => 'Beleg';

  @override
  String get productSearchHubInventoryAction => 'Aus Vorrat';

  @override
  String get productSearchHubMealAction => 'Mahlzeit';

  @override
  String get productSearchHubCreateOwnAction => 'Erstellen';

  @override
  String get productSearchHubSearchLabel => 'Produkt suchen';

  @override
  String get productSearchHubSearchHint => 'Name, Marke...';

  @override
  String get productSearchHubClearSearchAction => 'Suche leeren';

  @override
  String get productSearchHubSearchLoading => 'Produkte werden gesucht';

  @override
  String get productSearchHubSearchLoadFailed => 'Produktsuche fehlgeschlagen.';

  @override
  String get productSearchHubSearchRetryAction => 'Erneut versuchen';

  @override
  String get productSearchHubSearchEmptyState => 'Keine passenden Produkte gefunden.';

  @override
  String get productSearchHubCreateProductAction => 'Produkt erstellen';

  @override
  String get productSearchHubCartTitle => 'Ausgewählte Produkte';

  @override
  String get productSearchHubCartAddAction => 'Eintragen';

  @override
  String get productSearchHubCartRemoveAction => 'Entfernen';

  @override
  String get productSearchHubRecentlySelectedTab => 'Zuletzt ausgewählt';

  @override
  String get productSearchHubRecentlySelectedLoading => 'Letzte Produkte werden geladen';

  @override
  String get productSearchHubRecentlySelectedLoadFailed => 'Zuletzt ausgewählte Produkte konnten nicht geladen werden.';

  @override
  String get productSearchHubRecentlySelectedRetryAction => 'Erneut versuchen';

  @override
  String get productSearchHubRecentlySelectedEmptyState => 'Noch keine zuletzt ausgewählten Produkte.';

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
  String get inventoryActionManualSearch => 'Manuelle Suche';

  @override
  String get inventoryActionAiSuggestion => 'KI-Vorschlag';

  @override
  String get inventoryActionUploadImagePdf => 'Bild/PDF hochladen';

  @override
  String get inventoryActionCamera => 'Kamera';

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
  String get inventoryReceiptReviewManualDataRequired => 'Bitte Produkt wählen, Barcode scannen oder Nährwerte angeben.';

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
  String get inventoryViewStock => 'Vorrat';

  @override
  String get inventoryViewHistory => 'Historie';

  @override
  String get inventoryRecentSectionTitle => 'Lebensmittel';

  @override
  String get inventoryActivityLoading => 'Historie wird geladen...';

  @override
  String get inventoryActivityLoadFailed => 'Historie konnte nicht geladen werden.';

  @override
  String get inventoryActivityEmptyTitle => 'Noch keine Vorratshistorie.';

  @override
  String get inventoryActivityActorFallback => 'Haushaltsmitglied';

  @override
  String inventoryActivityPieceAmount(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount Artikel',
      one: '1 Artikel',
    );
    return '$_temp0';
  }

  @override
  String inventoryActivityItemAdded(String actor, String item, String amount) {
    return '$actor hat $amount $item hinzugefügt.';
  }

  @override
  String inventoryActivityItemConsumed(String actor, String item, String amount) {
    return '$actor hat $amount $item gegessen.';
  }

  @override
  String inventoryActivityItemDiscarded(String actor, String item, String amount) {
    return '$actor hat $amount $item aussortiert.';
  }

  @override
  String inventoryActivityItemDeleted(String actor, String item, String amount) {
    return '$actor hat $amount $item gelöscht.';
  }

  @override
  String inventoryActivityItemRestored(String actor, String item, String amount) {
    return '$actor hat $amount $item wiederhergestellt.';
  }

  @override
  String inventoryActivityItemUsedInPreparedMeal(String actor, String item, String amount) {
    return '$actor hat $amount $item für eine vorbereitete Mahlzeit verwendet.';
  }

  @override
  String inventoryActivityItemReturnedFromPreparedMeal(String actor, String item, String amount) {
    return '$actor hat $amount $item aus einer vorbereiteten Mahlzeit zurückgelegt.';
  }

  @override
  String get inventorySearchLabel => 'Im Vorrat suchen';

  @override
  String get inventorySearchClearAction => 'Suche leeren';

  @override
  String get inventoryFilterAction => 'Artikel filtern';

  @override
  String get inventoryFiltersTitle => 'Ansicht anpassen';

  @override
  String get inventoryFiltersSubtitle => 'Sortiere und filtere deine Lebensmittel';

  @override
  String get inventoryFiltersShowResultsAction => 'Ergebnisse anzeigen';

  @override
  String get inventoryViewSectionTitle => 'Ansicht';

  @override
  String get inventoryViewListAction => 'Liste';

  @override
  String get inventoryViewTilesAction => 'Kacheln';

  @override
  String get inventorySortSectionTitle => 'Sortierung';

  @override
  String get inventoryFilterSectionTitle => 'Filter';

  @override
  String get inventorySortAdded => 'Hinzugefügt';

  @override
  String get inventorySortEaten => 'Gegessen';

  @override
  String get inventorySortAlphabetical => 'Alphabetisch';

  @override
  String get inventorySortQuantity => 'Menge';

  @override
  String get inventorySortDirectionAscending => 'Aufsteigend';

  @override
  String get inventorySortDirectionDescending => 'Absteigend';

  @override
  String get inventorySortDirectionAlphaAscending => 'A bis Z';

  @override
  String get inventorySortDirectionAlphaDescending => 'Z bis A';

  @override
  String get inventoryNutritionCaloriesShortLabel => 'Kcal';

  @override
  String get inventoryNutritionCarbsShortLabel => 'KH';

  @override
  String get inventoryFilterConsumed => 'Verbraucht';

  @override
  String get inventoryFilterNotConsumed => 'Nicht verbraucht';

  @override
  String get inventoryHideConsumedFilterTitle => 'Verbrauchte ausblenden';

  @override
  String get inventoryHideConsumedFilterSubtitle => 'Komplett leere Artikel verbergen';

  @override
  String get inventoryHideFullyConsumedItemsToggle => 'Komplett verbrauchte Artikel ausblenden';

  @override
  String get preparedMealFilterAction => 'Filtern';

  @override
  String get preparedMealFiltersTitle => 'Ansicht anpassen';

  @override
  String get preparedMealFiltersSubtitle => 'Sortiere und filtere deine Mahlzeiten';

  @override
  String get preparedMealShowReadyOnlyToggle => 'Nur fertige anzeigen';

  @override
  String get preparedMealShowIncompleteOnlyToggle => 'Vollständige ausblenden';

  @override
  String get preparedMealShowDepletedOnlyToggle => 'Nur aufgebrauchte anzeigen';

  @override
  String get preparedMealHideFullyConsumedItemsToggle => 'Verbrauchte ausblenden';

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
  String get inventoryItemRemovedMessage => 'Artikel aussortiert.';

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
  String inventoryItemEatSheetAvailableAmount(Object amount, Object unit) {
    return 'Im Vorrat verfügbar: $amount $unit';
  }

  @override
  String get inventoryItemEatSheetQuickSelectLabel => 'Schnellwahl';

  @override
  String get inventoryItemEatSheetAllAction => 'Alles';

  @override
  String get inventoryAmountDialogAllRemainingAction => 'Alles/Rest';

  @override
  String get inventoryItemEatSheetPortionModeTitle => 'Portionen';

  @override
  String get inventoryItemEatSheetUsePortionsToggle => 'Portionsanzahl verwenden';

  @override
  String get inventoryItemEatSheetPortionLabelFieldLabel => 'Portionsname';

  @override
  String get inventoryItemEatSheetPortionCountFieldLabel => 'Anzahl';

  @override
  String get inventoryItemEatSheetPortionAmountFieldLabel => 'Menge pro Portion';

  @override
  String get inventoryItemEatSheetDecreasePortionCountAction => 'Portionen verringern';

  @override
  String get inventoryItemEatSheetIncreasePortionCountAction => 'Portionen erhöhen';

  @override
  String get inventoryItemEatSheetDefaultPortionLabel => 'Portion';

  @override
  String get inventoryItemEatSheetNewPortionAction => '+ Neue Portion...';

  @override
  String get inventoryItemEatSheetNewPortionTitle => 'Neue Portion';

  @override
  String get inventoryItemEatSheetSavePortionAction => 'Portion speichern';

  @override
  String get inventoryItemEatSheetUnitGram => 'Gramm';

  @override
  String get inventoryItemEatSheetUnitMilliliter => 'Milliliter';

  @override
  String get inventoryItemEatSheetUnitPiece => 'Stück';

  @override
  String inventoryItemEatSheetPortionTotalLabel(String amount, String unit) {
    return 'Gesamt: $amount $unit';
  }

  @override
  String get inventoryItemEatSheetInedibleAmountLabel => 'Nicht essbaren Anteil abziehen';

  @override
  String get inventoryItemEatSheetInedibleAmountHint => 'Optional, z. B. Knochen';

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
  String get inventoryItemEatSheetConfirmAction => 'Hinzufügen';

  @override
  String get inventoryItemEatSheetAddMoreAction => '+ Mehr';

  @override
  String get inventoryItemEatSheetClearAmountAction => 'Menge leeren';

  @override
  String get inventoryItemAddToListAction => 'Auf Liste';

  @override
  String get inventoryItemAddToShoppingListAction => 'Zur Einkaufsliste hinzufügen';

  @override
  String get inventoryItemBuyAgainAction => 'Erneut kaufen';

  @override
  String get inventoryItemBuyAgainSucceeded => 'Artikel zur Einkaufsliste hinzugefügt.';

  @override
  String get inventoryItemRemoveAction => 'Aussortieren';

  @override
  String get inventoryItemRemoveDialogTitle => 'Artikel aussortieren';

  @override
  String inventoryItemRemoveDialogMessage(String name) {
    return 'Warum möchtest du $name aussortieren?';
  }

  @override
  String get inventoryItemRemoveDiscardAction => 'Weggeworfen';

  @override
  String get inventoryItemRemoveDiscardSubtitle => 'Abgelaufen oder verdorben';

  @override
  String get inventoryItemRemoveConsumeElsewhereAction => 'Anderweitig verbraucht';

  @override
  String get inventoryItemRemoveConsumeElsewhereSubtitle => 'Gespendet, verschenkt oder geteilt';

  @override
  String get inventoryItemRemoveDeleteAction => 'Komplett löschen';

  @override
  String get inventoryItemRemoveDeleteSubtitle => 'Fehleingabe, nicht in Statistiken werten';

  @override
  String get inventoryItemThrowAwayAction => 'Wegwerfen';

  @override
  String get inventoryItemEditTitle => 'Vorratsartikel bearbeiten';

  @override
  String get inventoryItemUpdatedMessage => 'Vorratsartikel wurde aktualisiert.';

  @override
  String get inventoryItemEditRequiresFullItem => 'Du kannst den Artikel nur bearbeiten, solange er noch vollständig vorhanden ist.';

  @override
  String get inventoryItemSwapCandidateAction => 'Tauschen';

  @override
  String get inventoryItemSwapCandidateRequiresFullItem => 'Du kannst den Kandidaten nur tauschen, solange der Artikel noch vollständig vorhanden ist.';

  @override
  String get inventoryItemActionFailed => 'Aktion fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get inventoryBarcodeScanUnsupported => 'Barcode-Scan wird aktuell auf Android und iOS unterstützt.';

  @override
  String get inventoryManualAddTitle => 'Lebensmittel manuell hinzufügen';

  @override
  String get inventoryManualAddHint => 'Scanne einen Barcode. Danach kannst du das Produkt prüfen, speichern oder Nährwerte ergänzen.';

  @override
  String get inventoryManualAddScanBarcodeAction => 'Barcode scannen';

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
  String get inventoryManualAddEatSucceeded => 'Ins Tagebuch eingetragen';

  @override
  String get inventoryManualAddSearchDialogTitle => 'Produktsuche';

  @override
  String get inventoryManualAddPackageSizeLabel => 'Packungsgröße';

  @override
  String get inventoryManualAddResultActionInventory => 'Vorrat';

  @override
  String get inventoryManualAddResultActionEat => 'Essen';

  @override
  String get inventoryManualAddNutritionMissing => 'Nährwerte fehlen';

  @override
  String get inventoryManualAddNutritionMissingCalories => 'Kalorien fehlen';

  @override
  String get inventoryManualAddNutritionIncomplete => 'Nährwerte unvollständig';

  @override
  String get inventoryManualAddNutritionComplete => 'Nährwerte vollständig';

  @override
  String get inventoryManualAddNutritionVerified => 'Nährwerte verifiziert';

  @override
  String get inventoryManualAddCreateOwnAction => 'Manuell erstellen';

  @override
  String get inventoryManualAddEatNowOption => 'Sofort essen';

  @override
  String get inventoryManualAddEatNowSizeLabel => 'Sofort essen Menge';

  @override
  String get inventoryManualAddEatNowRequiresNutrition => 'Nur verfügbar, wenn Nährwerte vorhanden sind.';

  @override
  String get inventoryManualAddMissingBarcodeTitle => 'Barcode eintragen?';

  @override
  String get inventoryManualAddMissingBarcodeMessage => 'Dieses Produkt hat noch keinen Barcode. Trage ihn jetzt ein, damit es später wiedererkannt wird, oder speichere es ohne Barcode.';

  @override
  String get inventoryManualAddMissingBarcodeLabel => 'Barcode';

  @override
  String get inventoryManualAddMissingBarcodeRequired => 'Trage einen Barcode ein oder speichere ohne Barcode.';

  @override
  String get inventoryManualAddMissingBarcodeSaveWithout => 'Ohne Barcode speichern';

  @override
  String get inventoryManualAddMissingBarcodeSave => 'Speichern';

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
  String get inventoryManualAddAiSearchAction => 'KI-Vorschlag';

  @override
  String get inventoryManualAddAiSearchTitle => 'Lebensmittel mit KI erstellen';

  @override
  String get inventoryManualAddAiSearchPromptLabel => 'Lebensmittelbeschreibung';

  @override
  String get inventoryManualAddAiSearchPromptHint => 'Zum Beispiel: Döner Hähnchen';

  @override
  String get inventoryManualAddAiSearchGenerateAction => 'Schätzung erstellen';

  @override
  String get inventoryManualAddAiSearchPromptRequired => 'Bitte gib eine Lebensmittelbeschreibung ein.';

  @override
  String get inventoryManualAddAiSearchFailed => 'Die Lebensmittelschätzung konnte nicht erstellt werden. Bitte versuche es erneut.';

  @override
  String get inventoryManualAddAiSearchReadOnlyHint => 'Passe Gewicht oder kcal pro 100 g an, wenn sich die Schätzung falsch anfühlt.';

  @override
  String get inventoryManualAddAiSearchIngredientsTitle => 'Zutaten für diese Portion';

  @override
  String get inventoryManualAddAiSearchAmountColumn => 'Menge';

  @override
  String get inventoryManualAddAiSearchTotalLabel => 'Gesamt';

  @override
  String get inventoryManualAddAiSearchPer100Title => 'Gespeichert pro 100 g';

  @override
  String get inventoryManualAddAiSearchPer100CardTitle => 'PRO 100 G';

  @override
  String get inventoryManualAddAiSearchPortionCardTitle => 'DEINE PORTION';

  @override
  String get inventoryManualAddAiSearchWeightLabel => 'Gewicht';

  @override
  String get inventoryManualAddAiSearchWeightRequired => 'Bitte gib ein gültiges Gewicht ein.';

  @override
  String get inventoryManualAddAiSearchDensityTitle => 'Kaloriendichte anpassen (pro 100 g)';

  @override
  String get inventoryManualAddAiSearchDensityHint => 'War das Gericht eher leichter oder gehaltvoller als erwartet? Skaliere die Kalorien pro 100 g. Die Gesamtwerte passen sich automatisch an.';

  @override
  String inventoryManualAddAiSearchDensityMinLabel(Object kcal) {
    return '$kcal kcal/100g (Leichter)';
  }

  @override
  String inventoryManualAddAiSearchDensityBaseLabel(Object kcal) {
    return 'Basis: $kcal';
  }

  @override
  String inventoryManualAddAiSearchDensityMaxLabel(Object kcal) {
    return '$kcal kcal/100g (Gehaltvoller)';
  }

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
  String get preparedMealAddIngredientAction => 'Zutat hinzufügen';

  @override
  String get preparedMealRemoveIngredientAction => 'Zutat entfernen';

  @override
  String get preparedMealEmptyIngredientsMessage => 'Füge vor dem Speichern mindestens eine Zutat hinzu.';

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
  String preparedMealPortionsRemaining(String remaining, int total) {
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
  String get preparedMealTemplateRecipeGreetingTitle => 'Lass uns ein Rezept zaubern! 🍳';

  @override
  String get preparedMealTemplateRecipeGreetingSubtitle => 'Kopiere die Web-Adresse deines Lieblingsrezepts und wir lesen alle Zutaten automatisch für dich aus.';

  @override
  String get preparedMealTemplateStepCopy => '1. 🔗 Kopieren';

  @override
  String get preparedMealTemplateStepPaste => '2. 📝 Einfügen';

  @override
  String get preparedMealTemplateStepCreate => '3. ✨ Starten';

  @override
  String get preparedMealTemplateClipboardTitle => 'Aus Zwischenablage einfügen ✨';

  @override
  String get preparedMealTemplateClipboardPasteHelper => 'Hier tippen, um die Zwischenablage nach einem Rezept-Link zu durchsuchen.';

  @override
  String preparedMealTemplateClipboardPasteSuccess(String url) {
    return 'Rezept von $url eingefügt!';
  }

  @override
  String get preparedMealTemplateClipboardNoLinkFound => 'Kein gültiger Rezept-Link in der Zwischenablage gefunden.';

  @override
  String get preparedMealTemplateAdvancedOptionsTitle => 'Weitere Optionen (Optional)';

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
  String get kitchenUtensilsPageTitle => 'Küchenutensilien';

  @override
  String get kitchenUtensilsOpenAction => 'Küchenutensilien';

  @override
  String get kitchenUtensilsEmptyState => 'Noch keine Küchenutensilien gespeichert.';

  @override
  String get kitchenUtensilsLoadFailed => 'Küchenutensilien konnten nicht geladen werden.';

  @override
  String get kitchenUtensilAddAction => 'Utensil hinzufügen';

  @override
  String get kitchenUtensilEditTitle => 'Utensil bearbeiten';

  @override
  String get kitchenUtensilAddTitle => 'Utensil hinzufügen';

  @override
  String get kitchenUtensilDeleteAction => 'Utensil löschen';

  @override
  String get kitchenUtensilSavedMessage => 'Utensil gespeichert.';

  @override
  String get kitchenUtensilUpdatedMessage => 'Utensil aktualisiert.';

  @override
  String get kitchenUtensilDeletedMessage => 'Utensil gelöscht.';

  @override
  String get kitchenUtensilUnnamedLabel => 'Unbenanntes Utensil';

  @override
  String get kitchenUtensilNameLabel => 'Name';

  @override
  String get kitchenUtensilWeightLabel => 'Gewicht (g)';

  @override
  String kitchenUtensilWeightValue(int grams) {
    return '$grams g';
  }

  @override
  String get kitchenUtensilImageLabel => 'Foto';

  @override
  String get kitchenUtensilAddImageAction => 'Foto hinzufügen';

  @override
  String get kitchenUtensilChangeImageAction => 'Foto ändern';

  @override
  String get kitchenUtensilRemoveImageAction => 'Foto entfernen';

  @override
  String get kitchenUtensilImageCameraAction => 'Foto aufnehmen';

  @override
  String get kitchenUtensilImageHint => 'Füge ein Foto oder einen Namen hinzu, damit du das Utensil später erkennst.';

  @override
  String get kitchenUtensilImagePickFailed => 'Foto konnte nicht ausgewählt werden.';

  @override
  String get kitchenUtensilImageUploadFailed => 'Foto konnte nicht hochgeladen werden.';

  @override
  String get kitchenUtensilSaveFailed => 'Utensil konnte nicht gespeichert werden.';

  @override
  String get kitchenUtensilDeleteFailed => 'Utensil konnte nicht gelöscht werden.';

  @override
  String get kitchenUtensilInvalidWeight => 'Bitte gib ein Gewicht größer als 0 ein.';

  @override
  String get kitchenUtensilIdentityRequired => 'Füge einen Namen oder ein Foto hinzu.';

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
  String get caloriesOcrScanning => 'Nährwertetikett wird gelesen…';

  @override
  String get caloriesOcrScanningSemantics => 'Das aufgenommene Nährwertetikett wird gescannt';

  @override
  String get caloriesOcrFailed => 'Nährwertetikett konnte nicht erkannt werden.';

  @override
  String get caloriesOcrAppCheckThrottled => 'Nährwertscan ist vorübergehend blockiert. Bitte versuche es später erneut.';

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
  String get caloriesGoalStartSaveFailed => 'Der Zielstart konnte nicht aktualisiert werden.';

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
  String get caloriesCalculatorGoalStartHint => 'Dein Kalorienziel-Verlauf beginnt ab diesem Tag.';

  @override
  String get caloriesCalculatorGoalStartChangeAction => 'Ändern';

  @override
  String get caloriesCalculatorOnboardingStartTitle => 'Wann soll dein Ziel starten?';

  @override
  String get caloriesCalculatorOnboardingStartNowAction => 'Ab sofort';

  @override
  String get caloriesCalculatorOnboardingStartLaterAction => 'Später starten';

  @override
  String get caloriesCalculatorOnboardingStartLaterHint => 'Heute bleibt folgenfrei. Burn Week startet ab diesem Tag automatisch.';

  @override
  String get caloriesCalculatorOnboardingChooseFutureDateAction => 'Tag wählen';

  @override
  String get caloriesCalculatorOnboardingTodayTrackingLabel => 'Wie trackst du heute?';

  @override
  String get caloriesCalculatorOnboardingTodayTrackingExactAction => 'Ganzer Tag exakt';

  @override
  String get caloriesCalculatorOnboardingTodayTrackingEstimateAction => 'Bisher schätzen';

  @override
  String get caloriesCalculatorOnboardingCatchUpLabel => 'Wie viel hast du bisher gegessen?';

  @override
  String get caloriesCalculatorOnboardingCatchUpLowAction => 'Wenig';

  @override
  String get caloriesCalculatorOnboardingCatchUpNormalAction => 'Normal';

  @override
  String get caloriesCalculatorOnboardingCatchUpHighAction => 'Viel';

  @override
  String get caloriesCalculatorOnboardingCatchUpHint => 'Wir setzen dich sicher in die heutige Pufferzone.';

  @override
  String get caloriesOnboardingPlaceholderName => 'Geschätzte Mahlzeit';

  @override
  String caloriesCalculatorMinimumGoalWarning(int minimumKcal) {
    return 'Beim Abnehmen darf das tägliche Ziel nicht unter $minimumKcal kcal fallen. Das Ergebnis wurde auf dieses Minimum begrenzt.';
  }

  @override
  String get caloriesCalculatorSaveAction => 'Ziel speichern';

  @override
  String get caloriesCalculatorSaveFailed => 'Das berechnete Kalorienziel konnte nicht gespeichert werden.';

  @override
  String get caloriesGoalStartFoodTrackingTitle => 'Hast du dein Essen heute getrackt?';

  @override
  String caloriesGoalStartFoodTrackingBody(int entryCount) {
    return 'Ich habe heute $entryCount Essenseinträge gefunden. Soll heute als voller Tracking-Tag für dieses neue Ziel zählen?';
  }

  @override
  String get caloriesGoalStartNoFoodTrackingTitle => 'Heute kein Essen getrackt';

  @override
  String get caloriesGoalStartNoFoodTrackingBody => 'Heute wird ein Starter-Tag. Dein neues Ziel startet jetzt, aber das wöchentliche Lernen startet morgen.';

  @override
  String get caloriesGoalStartFoodTrackingNoAction => 'Frisch starten';

  @override
  String get caloriesGoalStartFoodTrackingYesAction => 'Heute mitzählen';

  @override
  String get caloriesGoalStartFoodTrackingOkAction => 'OK';

  @override
  String get caloriesLearnedTdeeSheetTitle => 'Ziel aus gelerntem TDEE neu berechnen';

  @override
  String get caloriesLearnedTdeeSheetSubtitle => 'Verwende deinen letzten erfolgreichen Wochen-Check-in statt einer Aktivitätsschätzung.';

  @override
  String get caloriesLearnedTdeeLabel => 'Gelernter TDEE';

  @override
  String get caloriesLearnedTdeeResultLabel => 'Neues Tagesziel';

  @override
  String get caloriesLearnedTdeeUseProfileResetAction => 'Profilbasierten Reset nutzen';

  @override
  String get caloriesLearnedTdeeSaveFailed => 'Das Ziel aus dem gelernten TDEE konnte nicht gespeichert werden.';

  @override
  String get caloriesWeeklyCheckInDialogTitle => 'Wochen-Check-in';

  @override
  String get caloriesWeeklyCheckInDialogReadyBody => 'Prüfe deine letzten 7 abgeschlossenen Tage. Dein Ziel nutzt diese Lernwerte bereits automatisch.';

  @override
  String get caloriesWeeklyCheckInDialogBlockedBody => 'Uns fehlen noch ein paar Daten, bevor diese Wochenzusammenfassung vollständig ist.';

  @override
  String get caloriesWeeklyCheckInDialogWindowLabel => 'Zeitraum';

  @override
  String get caloriesWeeklyCheckInDialogTrendLabel => 'Gewichtstrend';

  @override
  String get caloriesWeeklyCheckInDialogTrueTdeeLabel => 'Gelernter TDEE';

  @override
  String get caloriesWeeklyCheckInDialogMeasuredTotalTdeeLabel => 'Gemessener Gesamt-TDEE';

  @override
  String get caloriesWeeklyCheckInDialogMeasuredBaseTdeeLabel => 'Gemessener Basis-TDEE';

  @override
  String get caloriesWeeklyCheckInDialogCreditedActivityAverageLabel => 'Angerechnete Aktivität Ø';

  @override
  String get caloriesWeeklyCheckInDialogNewTargetLabel => 'Neues Ziel';

  @override
  String get caloriesWeeklyCheckInDialogLowConfidence => 'Niedrige Sicherheit: Es lagen nur Start- und Endgewicht vor.';

  @override
  String get caloriesWeeklyCheckInBlockedUnstableWeight => 'Die Gewichtsdaten waren diese Woche zu unruhig für ein verlässliches TDEE-Update. Füge gleichmäßigere Wiegewerte hinzu und versuche es erneut.';

  @override
  String get caloriesWeeklyCheckInApplyAction => 'Fertig';

  @override
  String get caloriesWeeklyCheckInLaterAction => 'Später';

  @override
  String get caloriesWeeklyCheckInApplyFailed => 'Der Wochen-Check-in konnte nicht geschlossen werden.';

  @override
  String get caloriesWeeklyCheckInHintReadyTitle => 'Wochen-Check-in bereit';

  @override
  String get caloriesWeeklyCheckInHintReadyBody => 'Deine letzten 7 abgeschlossenen Tage sind bereit zur Prüfung.';

  @override
  String get caloriesWeeklyCheckInHintBlockedTitle => 'Wochen-Check-in braucht Daten';

  @override
  String get caloriesWeeklyCheckInHintBlockedBody => 'Ergänze fehlende Aufnahme- oder Gewichtsdaten, um die Zusammenfassung zu vervollständigen.';

  @override
  String get caloriesWeeklyCheckInHintContinueAction => 'Fortsetzen';

  @override
  String get caloriesWeeklyCheckInHintStaleTitle => 'Ziel wird alt';

  @override
  String get caloriesWeeklyCheckInHintStaleBody => 'Nutze den nächsten Wochen-Check-in, damit dein Ziel aktuell bleibt.';

  @override
  String get caloriesWeeklyCheckInHintUrgentTitle => 'Ziel braucht Aktualisierung';

  @override
  String get caloriesWeeklyCheckInHintUrgentBody => 'Du verwendest schon länger ältere Zieldaten.';

  @override
  String get caloriesWeeklyCheckInShowAgainAction => 'Wochen-Check-in anzeigen';

  @override
  String get caloriesWeeklyCheckInShowAgainFailed => 'Der Wochen-Check-in konnte nicht erneut geöffnet werden.';

  @override
  String get caloriesWeeklyCheckInSkipDayAction => 'Tag als ausgelassen markieren';

  @override
  String get caloriesWeeklyCheckInUnskipDayAction => 'Ausgelassen-Markierung entfernen';

  @override
  String get caloriesWeeklyCheckInAutoAdjustedHint => 'Ziel durch Wochen-Check-in aktualisiert:';

  @override
  String get caloriesWeeklyCheckInTrackMissingWeightAction => 'Fehlendes Gewicht eintragen';

  @override
  String get caloriesWeeklyCheckInBlockedMissingIntake => 'Mindestens ein Tag in diesem Zeitraum hat noch keine Aufnahme. Trage ihn ein oder markiere 1 oder 2 leere Tage als ausgelassen.';

  @override
  String get caloriesWeeklyCheckInBlockedTooManyMissingIntake => 'Dieser Zeitraum hat 3 oder mehr fehlende Aufnahmetage. Wir behalten dein letztes gelerntes Ziel, bis du wieder mehr vollständige Tage geloggt hast.';

  @override
  String get caloriesWeeklyCheckInBlockedSkippedWithoutAverage => 'Ein ausgelassener Tag braucht frühere geloggte Aufnahme im selben Zeitraum, bevor wir ihn schätzen können.';

  @override
  String caloriesWeeklyCheckInBlockedMissingStartWeightOn(Object date) {
    return 'Füge ein Gewicht für den ersten Tag dieses Zeitraums ($date) hinzu, um fortzufahren.';
  }

  @override
  String caloriesWeeklyCheckInBlockedMissingEndWeightOn(Object date) {
    return 'Füge ein Gewicht für den letzten Tag dieses Zeitraums ($date) hinzu, um fortzufahren.';
  }

  @override
  String caloriesWeeklyCheckInBlockedMissingWeightDates(Object dates) {
    return 'Füge Gewichte für diese Daten hinzu, um fortzufahren: $dates.';
  }

  @override
  String get caloriesConsumedLabel => 'Verbraucht';

  @override
  String get caloriesGoalLabel => 'Ziel';

  @override
  String get caloriesRemainingLabel => 'Verbleibend';

  @override
  String get caloriesDebugActionsTooltip => 'Kalorien-Debug-Aktionen';

  @override
  String get caloriesDebugDumpAction => 'Kalorien-Debug-TXT herunterladen';

  @override
  String get caloriesDebugDumpSaveDialogTitle => 'Kalorien-Debug-TXT speichern';

  @override
  String caloriesDebugDumpPrinted(int rowCount) {
    return 'Kalorien-Debug-TXT heruntergeladen ($rowCount Zeilen).';
  }

  @override
  String get caloriesDebugDumpCanceled => 'Kalorien-Debug-TXT-Download abgebrochen.';

  @override
  String get caloriesDebugDumpFailed => 'Kalorien-Debug-TXT konnte nicht heruntergeladen werden.';

  @override
  String get caloriesSettingsDebugDumpAction => 'Kalorien-Einstellungen als JSON ausgeben';

  @override
  String caloriesSettingsDebugDumpPrinted(int entryCount) {
    return 'Kalorien-Einstellungen-Debug-Ausgabe gedruckt ($entryCount Zieleinträge).';
  }

  @override
  String get caloriesSettingsDebugDumpFailed => 'Kalorien-Einstellungen-Debug-Ausgabe konnte nicht gedruckt werden.';

  @override
  String get caloriesWeeklyCheckInDebugDumpAction => 'Wochen-Check-in-Status ausgeben';

  @override
  String get caloriesWeeklyCheckInDebugDumpPrinted => 'Wochen-Check-in-Debug-Ausgabe gedruckt.';

  @override
  String get caloriesWeeklyCheckInDebugDumpFailed => 'Wochen-Check-in-Debug-Ausgabe konnte nicht gedruckt werden.';

  @override
  String get burnWeekRunOverTitle => 'Run beendet';

  @override
  String burnWeekRunRestartsOn(Object date) {
    return 'Frischer Run startet am $date.';
  }

  @override
  String get burnWeekPracticeDayTitle => 'Übungstag';

  @override
  String burnWeekPracticeDayMessage(Object date) {
    return 'Heute zählt noch nicht. Du kannst Tracking testen, und Burn Week startet am $date.';
  }

  @override
  String get calorieBudgetDetailsActualLabel => 'Ist (du)';

  @override
  String get calorieBudgetDetailsTargetLabel => 'Soll (Ziel)';

  @override
  String get calorieBudgetDetailsBalanceExplanation => 'Das Budget startet mit deinem gespeicherten Tagesziel. Extra-Aktivität ist die Hälfte der Kalorien über deiner erwarteten Aktivitäts-Basis. Übertrag ist die Bilanz abgeschlossener Tage, verteilt auf die übrigen Tage dieses 7-Tage-Runs.';

  @override
  String get calorieBudgetDetailsTodayBudget => 'Heutiges Budget';

  @override
  String get calorieBudgetDetailsFoodToday => 'Essen heute';

  @override
  String get calorieBudgetDetailsRemaining => 'Verbleibend';

  @override
  String get burnWeekDetailsTitle => 'Burn-Week-Details';

  @override
  String get burnWeekDetailsHowCalculated => 'So wird es berechnet';

  @override
  String get burnWeekDetailsDailyGoal => 'Tagesziel';

  @override
  String get burnWeekDetailsWeekTarget => 'Wochenziel';

  @override
  String get burnWeekDetailsCurrentTime => 'Aktuelle Zeit';

  @override
  String get burnWeekDetailsStarsHearts => 'Sterne / Herzen';

  @override
  String get burnWeekDetailsHeartKcalUsed => 'Herz-Anpassung';

  @override
  String get burnWeekDetailsWeekRatio => 'Wochenfortschritt';

  @override
  String get burnWeekDetailsTargetFormula => 'Zielformel';

  @override
  String get burnWeekDetailsLoggedFoodSoFar => 'Bisher erfasstes Essen';

  @override
  String get burnWeekDetailsPlannedLaterToday => 'Später heute geplant';

  @override
  String get burnWeekDetailsActivityBonusSoFar => 'Bisheriger Aktivitätsbonus';

  @override
  String get burnWeekDetailsWeekCarryover => 'Übertrag dieser Woche';

  @override
  String get burnWeekDetailsPreviousWeekOverflow => 'Übertrag aus letzter Woche';

  @override
  String get burnWeekDetailsWeekLeftAfterFood => 'Woche übrig nach Essen';

  @override
  String get burnWeekDetailsSportCounting => 'Sport-Zählung';

  @override
  String get burnWeekDetailsSportCountingValue => 'Erwartete Aktivität steckt bereits im Basisziel. Die Hälfte der Aktivität über dieser Erwartung wird als essbare kcal addiert.';

  @override
  String get burnWeekDetailsSafeZone => 'Sicherheitszone';

  @override
  String burnWeekWeekDayLabel(int week, int day) {
    return 'Woche $week Tag $day';
  }

  @override
  String get caloriesProteinLabel => 'Eiweiß';

  @override
  String get caloriesCarbsLabel => 'Kohlenhydrate';

  @override
  String get caloriesCarbsShortLabel => 'KH';

  @override
  String get caloriesFatLabel => 'Fett';

  @override
  String diaryWeightDialogTitle(String date) {
    return 'Gewicht für $date setzen';
  }

  @override
  String get diaryWeightSaveAction => 'Speichern';

  @override
  String get diaryWeightClearAction => 'Überschreibung löschen';

  @override
  String get diaryWeightSaveFailed => 'Gewicht konnte nicht gespeichert werden.';

  @override
  String get diaryWeightClearFailed => 'Manuelles Gewicht konnte nicht gelöscht werden.';

  @override
  String get caloriesDeleteEntryDialogTitle => 'Eintrag löschen?';

  @override
  String caloriesDeleteEntryDialogMessage(String name) {
    return '\"$name\" für diesen Tag löschen?';
  }

  @override
  String get caloriesDeleteEntryConfirmAction => 'Löschen';

  @override
  String get caloriesRemoveEntryAction => 'Eintrag entfernen';

  @override
  String get caloriesRemoveEntryDialogTitle => 'Eintrag entfernen';

  @override
  String get caloriesRemoveEntryDialogMessage => 'Möchtest du das Nahrungsmittel wieder in den Vorrat zurücklegen?';

  @override
  String get caloriesRemoveEntryPreparedMealMessage => 'Möchtest du die Mahlzeit wieder in den Vorrat zurücklegen?';

  @override
  String get caloriesRemoveEntryOnlyAction => 'Nur aus Tagebuch löschen';

  @override
  String get caloriesRemoveAndRestoreAction => 'In den Vorrat zurücklegen';

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
  String get caloriesMissingInventorySourceDialogTitle => 'Nahrungsmittel nicht mehr im Vorrat';

  @override
  String caloriesMissingInventorySourceDialogMessage(String name) {
    return '\"$name\" ist nicht mehr im Vorrat und kann nicht zurückgelegt werden. Nur aus dem Tagebuch löschen?';
  }

  @override
  String get caloriesDeleteDiaryOnlyConfirmAction => 'Aus Tagebuch löschen';

  @override
  String get caloriesDeleteFailed => 'Eintrag konnte nicht gelöscht werden.';

  @override
  String get caloriesAddEntryTitle => 'Kalorien-Eintrag hinzufügen';

  @override
  String get caloriesEditEntryTitle => 'Kalorien-Eintrag bearbeiten';

  @override
  String get caloriesEntryDetailsTitle => 'Kalorien-Eintragsdetails';

  @override
  String get caloriesDiscardChangesDialogTitle => 'Ungespeicherte Änderungen verwerfen?';

  @override
  String get caloriesDiscardChangesDialogMessage => 'Deine Änderungen an diesem Tagebucheintrag wurden noch nicht gespeichert.';

  @override
  String get caloriesDiscardChangesConfirmAction => 'Änderungen verwerfen';

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
  String get caloriesUnitKg => 'kg';

  @override
  String get caloriesUnitGram => 'g';

  @override
  String get caloriesUnitMilliliter => 'ml';

  @override
  String get diaryTodayTitle => 'Heute';

  @override
  String diaryCycleDayLabel(int week, int day) {
    return 'Woche $week Tag $day';
  }

  @override
  String get diaryMealsTitle => 'Tagebuch';

  @override
  String get diaryMealsEmpty => 'Noch nichts eingetragen';

  @override
  String get diaryMealsLoadFailed => 'Mahlzeiten konnten nicht geladen werden';

  @override
  String diaryQuickEatAddTooltip(String meal) {
    return 'Zu $meal hinzufügen';
  }

  @override
  String get diaryQuickEatSourceInventory => 'Vorrat';

  @override
  String get diaryQuickEatSourceBarcode => 'Barcode';

  @override
  String get diaryQuickEatSourceManualSearch => 'Suche';

  @override
  String get diaryQuickEatSourceAi => 'KI';

  @override
  String get diaryQuickEatInventoryTitle => 'Aus Vorrat essen';

  @override
  String get diaryQuickEatInventoryEmpty => 'Kein verfügbares Essen im Vorrat.';

  @override
  String get diaryBalanceLoadFailed => 'Balance konnte nicht geladen werden';

  @override
  String get diaryNutritionLoadFailed => 'Nährwerte konnten nicht geladen werden';

  @override
  String get diaryNutritionTitle => 'Makronährstoffe';

  @override
  String get diaryBalanceEatenLabel => 'Gegessen';

  @override
  String get diaryBalanceLeftLabel => 'Übrig';

  @override
  String get diaryBalanceLeftTodayLabel => 'Übrig heute';

  @override
  String get diaryBalanceBaseLabel => 'Basis';

  @override
  String get diaryBalancePlannedWithCarryoverLabel => 'Mit Übertrag geplant';

  @override
  String diaryBalanceWeekLabel(Object week) {
    return 'Woche $week';
  }

  @override
  String diaryBalanceDayProgressLabel(Object day, Object total) {
    return 'Tag $day von $total';
  }

  @override
  String get diaryBalanceTargetMarkerLabel => 'Soll';

  @override
  String get diaryBalanceWeekActualLabel => 'Ist (Woche)';

  @override
  String get diaryBalanceWeekTargetLabel => 'Wochenziel';

  @override
  String diaryBalanceRealEatenLabel(Object kcal) {
    return 'Echt $kcal';
  }

  @override
  String diaryBalanceBufferAdjustmentLabel(Object kcal) {
    return 'Puffer $kcal';
  }

  @override
  String diaryBalanceRealLeftLabel(Object kcal) {
    return 'Echt $kcal';
  }

  @override
  String diaryBalanceHeartAdjustmentLabel(Object kcal) {
    return 'Herz $kcal';
  }

  @override
  String get diaryBalanceHeartDayValue => 'Herztag';

  @override
  String get diaryBalanceHeartDaySubtitle => 'Für Lernen ignoriert';

  @override
  String get diaryBalanceRevertHeartDayAction => 'Herztag zurücknehmen';

  @override
  String diaryBalanceActivityIncludedLabel(String kcal) {
    return '$kcal Aktivität im Tagesziel enthalten';
  }

  @override
  String diaryBalanceActivityBonusLabel(String kcal) {
    return '$kcal Extra-Sport';
  }

  @override
  String diaryBalanceBaseGoalShort(String value) {
    return 'Basis $value';
  }

  @override
  String diaryBalanceCarryoverShort(String value) {
    return 'Übertrag $value';
  }

  @override
  String diaryBalanceSportShort(String value) {
    return 'Sport $value';
  }

  @override
  String get diaryBudgetDetailsTitle => 'Tagesbudget-Details';

  @override
  String get diaryBudgetDetailsButtonLabel => 'Details';

  @override
  String get diaryBudgetDetailsTodaySectionTitle => 'Heutige Rechnung';

  @override
  String get diaryBudgetDetailsBaseGoalLabel => 'Basis-Tagesziel';

  @override
  String get diaryBudgetDetailsBaseGoalWithoutActivityLabel => 'Basis-Tagesziel (ohne Aktivität)';

  @override
  String get diaryBudgetDetailsExpectedActivityLabel => 'Vermutete Aktivität';

  @override
  String get diaryBudgetDetailsExtraSportLabel => 'Zusätzlicher Sport';

  @override
  String get diaryBudgetDetailsCarryoverLabel => 'Übertrag aus Vortagen';

  @override
  String get diaryBudgetDetailsActivityBonusLabel => 'Aktivitätsbonus';

  @override
  String get diaryBudgetDetailsEffectiveGoalLabel => 'Effektives Tagesziel';

  @override
  String get diaryBudgetDetailsEatenLabel => 'Bisher gegessen';

  @override
  String get diaryBudgetDetailsLeftLabel => 'Noch übrig heute';

  @override
  String get diaryBudgetDetailsCarryoverSectionTitle => 'Übertrag aus den Vortagen';

  @override
  String get diaryBudgetDetailsCarryoverExplanation => 'Der Übertrag ist die Bilanz abgeschlossener Tage, verteilt auf die verbleibenden Tage dieses 7-Tage-Runs.';

  @override
  String get diaryBudgetDetailsDaySavedLabel => 'eingespart';

  @override
  String get diaryBudgetDetailsDayOverLabel => 'überzogen';

  @override
  String get diaryBudgetDetailsDayExactLabel => 'Ziel erreicht';

  @override
  String get diaryBudgetDetailsHeartDayLabel => 'Durch Herz geschützt';

  @override
  String get diaryBudgetDetailsTotalCarryoverLabel => 'Gesamtbilanz Vortage';

  @override
  String diaryBudgetDetailsDistributionFormula(String total, int days, String daily) {
    return '$total aufgeteilt auf $days verbleibende Tage = $daily / Tag';
  }

  @override
  String diaryBudgetDetailsMacroAdjustment(String protein, String carbs, String fat) {
    return 'Makro-Anpassung: Protein $protein · Carbs $carbs · Fett $fat';
  }

  @override
  String get diaryBudgetDetailsSafetyCapActive => 'Schutzregel aktiv: Tageskürzung wurde begrenzt, um Heißhunger zu verhindern.';

  @override
  String get diaryBudgetDetailsNoPreviousDays => 'Dies ist der erste Tag deines aktuellen Laufs. Es gibt noch keinen Übertrag.';

  @override
  String diaryWorkoutsBaselineProgress(String current, String target, String remaining) {
    return '$current / $target kcal Basis-Aktivität • Noch $remaining kcal bis zum Bonus';
  }

  @override
  String diaryWorkoutsBonusEarned(String bonus) {
    return '+$bonus kcal Extra-Sport wurden deinem Tagesziel gutgeschrieben!';
  }

  @override
  String get diaryIntroBackAction => 'Zurück';

  @override
  String get diaryIntroNextAction => 'Weiter';

  @override
  String get diaryIntroDoneAction => 'Loslegen';

  @override
  String get diaryIntroReplayAction => 'Intro nochmal';

  @override
  String get diaryIntroStartTitle => 'Dein Startwert';

  @override
  String diaryIntroStartBody(String maintenanceKcal) {
    return 'Aus deinen Angaben schätzen wir deinen Erhaltungsbedarf auf ca. $maintenanceKcal kcal pro Tag. Damit sollte dein Gewicht ungefähr gleich bleiben.';
  }

  @override
  String get diaryIntroActivityTitle => 'Aktivitäten';

  @override
  String diaryIntroActivityBody(String activityProfile, String activityKcal) {
    return 'Du kannst YAMT mit Health verbinden, um deine tägliche Aktivität zu tracken. Durch dein Aktivitätsprofil \"$activityProfile\" nimmt YAMT an, dass du täglich ca. $activityKcal kcal durch Aktivität verbrennst. Aktivität darüber erhöht dein Tagesziel, wird aber nur zu 50 % gutgeschrieben, weil aufgezeichnete Kalorien Schätzwerte sind. Keine Sorge, falls du keine Möglichkeit hast, Aktivitätskalorien zu tracken: Das System funktioniert auch ohne sie.';
  }

  @override
  String get diaryIntroGoalTitle => 'Dein Ziel';

  @override
  String diaryIntroGoalLoseBody(String speedKg, String adjustmentKcal) {
    return 'Dein Ziel ist Abnehmen. Für $speedKg kg pro Woche ziehen wir ca. $adjustmentKcal kcal pro Tag ab.';
  }

  @override
  String diaryIntroGoalGainBody(String speedKg, String adjustmentKcal) {
    return 'Dein Ziel ist Zunehmen. Für $speedKg kg pro Woche rechnen wir ca. $adjustmentKcal kcal pro Tag dazu.';
  }

  @override
  String get diaryIntroGoalMaintainBody => 'Dein Ziel ist Gewicht halten. Deshalb bleibt dein Tagesziel nah an deinem Erhaltungsbedarf.';

  @override
  String get diaryIntroTargetTitle => 'Dein Tagesziel';

  @override
  String diaryIntroTargetBody(String targetKcal) {
    return 'Dein Startziel liegt bei ca. $targetKcal kcal pro Tag. Das ist eine erste Schätzung und wird mit deinen Daten besser.';
  }

  @override
  String get diaryIntroWeekOneTitle => 'Woche 1: Routine aufbauen';

  @override
  String get diaryIntroWeekOneBody => 'Iss normal, aber trage Essen, Getränke und Gewicht möglichst vollständig ein. Genaues Tracking hilft YAMT, deinen echten Bedarf zu lernen.';

  @override
  String get diaryIntroBetterDataTitle => 'Besser mit Daten';

  @override
  String get diaryIntroBetterDataBody => 'Nach 7 Tagen ist die Schätzung besser als der Startwert. Nach 14 konsequenten Tagen sieht YAMT deinen Stoffwechsel deutlich klarer.';

  @override
  String get diaryActivityTitle => 'Aktivität';

  @override
  String get diaryActivityEmpty => 'Keine Aktivität';

  @override
  String get diaryActivityWeightLoadFailed => 'Aktivität und Gewicht konnten nicht geladen werden';

  @override
  String diaryActiveMinutesLabel(String minutes) {
    return '$minutes Min. aktiv';
  }

  @override
  String get diaryWeightTitle => 'Gewicht';

  @override
  String get diarySevenDaysLabel => '7 Tage';

  @override
  String diaryProfileWeightLabel(String weight) {
    return 'Profil: $weight kg';
  }

  @override
  String get diaryWeightMissingPrompt => 'Trage dein Gewicht ein für bessere Berechnung.';

  @override
  String get diaryWeightTrackNowAction => 'JETZT TRACKEN';

  @override
  String get diaryWeightEmpty => 'Keine Gewichte';

  @override
  String get diaryWeightAddAction => 'Gewicht eintragen';

  @override
  String get diaryOkAction => 'OK';

  @override
  String diaryCounterLabel(int count) {
    return 'x $count';
  }

  @override
  String get diaryHealthLabel => 'Health';

  @override
  String get diaryHealthInstallTitle => 'Health installieren';

  @override
  String get diaryHealthHistoryTitle => 'Verlauf erlauben';

  @override
  String get diaryHealthUnsupportedTitle => 'Health nicht verfügbar';

  @override
  String get diaryHealthConnectTitle => 'Health verbinden';

  @override
  String get diaryHealthPermissionDenied => 'Berechtigung wurde nicht erteilt.';

  @override
  String get diaryHealthInstallBody => 'Für Schritte und Aktivität.';

  @override
  String get diaryHealthHistoryBody => 'Für ältere Tage erlauben.';

  @override
  String get diaryHealthUnsupportedBody => 'Auf diesem Gerät nicht verfügbar.';

  @override
  String get diaryHealthConnectBody => 'Schritte und Aktivität verbinden.';

  @override
  String get diaryHealthSettingsAction => 'Einstellungen';

  @override
  String get diaryHealthInstallAction => 'Installieren';

  @override
  String get diaryHealthAllowAction => 'Erlauben';

  @override
  String get diaryHealthUnavailableAction => 'Nicht verfügbar';

  @override
  String get diaryHealthConnectAction => 'Verbinden';

  @override
  String get diaryStepsTitle => 'Schritte';

  @override
  String get diaryStepsLoadFailed => 'Schritte konnten nicht geladen werden';

  @override
  String get diaryStepDetailsTitle => 'Schritte Details';

  @override
  String get diaryStepsDuringWorkoutsLabel => 'Schritte im Training';

  @override
  String get diaryStepsDuringOtherActivityLabel => 'Sonstige aktive Schritte';

  @override
  String get diaryStepsOutsideWorkoutsLabel => 'Schritte außerhalb';

  @override
  String get diaryWorkoutsTitle => 'Trainings';

  @override
  String get diaryWorkoutsLoadFailed => 'Trainings konnten nicht geladen werden';

  @override
  String get diaryWorkoutsEmpty => 'Keine Trainings';

  @override
  String get diaryWorkoutFallbackTitle => 'Training';

  @override
  String diaryWorkoutMinutesLabel(String minutes) {
    return '$minutes Min.';
  }

  @override
  String caloriesBundlePortions(String consumed, int total) {
    return '$consumed/$total Portionen';
  }

  @override
  String get homeSettingsActionContextPlaceholder => 'Einstellungsaktion folgt bald.';

  @override
  String get settingsManagePreferencesSubtitle => 'Verwalte deine Einstellungen';

  @override
  String get settingsProfileGuestSubtitle => 'Gastmodus';

  @override
  String get settingsAccountHouseholdSectionTitle => 'Haushalt';

  @override
  String get settingsHealthGoalsSectionTitle => 'Health & Ziele';

  @override
  String get settingsMacroGoalsTitle => 'Makronährstoff-Ziele';

  @override
  String get settingsMacroGoalsSubtitle => 'Eiweiß-, Fett- & Kohlenhydrate-Verteilung';

  @override
  String get settingsMacroGoalsSheetTitle => 'Makronährstoff-Verteilung';

  @override
  String get settingsMacroGoalsSportActiveLabel => 'Sportlich aktiv';

  @override
  String get settingsMacroGoalsSportActiveSubtitle => 'Passt die Empfehlungen an Training an';

  @override
  String get settingsMacroGoalsProteinLabel => 'Protein-Multiplikator';

  @override
  String get settingsMacroGoalsFatLabel => 'Fett-Multiplikator';

  @override
  String get settingsMacroGoalsCarbsAutoLabel => 'Kohlenhydrate füllen die restlichen Kalorien auf';

  @override
  String get settingsMacroGoalsPreviewTitle => 'Vorschau Tagesziel';

  @override
  String get settingsMacroGoalsResetButton => 'Auf Empfehlung zurücksetzen';

  @override
  String get settingsMacroGoalsSaveButton => 'Speichern';

  @override
  String settingsMacroGoalsGramPerKg(String value) {
    return '$value g/kg';
  }

  @override
  String get settingsMacroGoalsWarningBudgetExceeded => 'Eiweiß und Fett übersteigen das Tages-Kalorienziel';

  @override
  String get settingsAppearanceSectionTitle => 'Darstellung';

  @override
  String get settingsAppSectionTitle => 'App';

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsLanguageSubtitle => 'App-Sprache auswählen';

  @override
  String get settingsLanguageEnglish => 'Englisch';

  @override
  String get settingsLanguageGerman => 'Deutsch';

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
  String get settingsDiaryGoalNoGoal => 'Kein Ziel gesetzt';

  @override
  String get settingsDiaryGoalSetGoalFirst => 'Zuerst Ziel setzen';

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
  String get settingsPrivacyTitle => 'Datenschutz';

  @override
  String get settingsPrivacySubtitle => 'Berechtigungen und Daten verwalten';

  @override
  String get settingsHouseholdTitle => 'Haushalt';

  @override
  String get settingsHouseholdSubtitle => 'Mitglieder einladen und geteilten Zugriff verwalten';

  @override
  String get settingsAccountTitle => 'Konto';

  @override
  String get settingsAccountSubtitle => 'Profil und Anmeldung verwalten';

  @override
  String get settingsHealthConnectPlatformTitle => 'Health Connect';

  @override
  String get settingsHealthConnectTitle => 'Health verbinden';

  @override
  String get settingsHealthConnectSubtitle => 'Erlaube YAMT, Schritte, Workouts und verbrannte Kalorien aus Health Connect zu lesen.';

  @override
  String get settingsAppleHealthTitle => 'Apple Health';

  @override
  String get settingsAppleHealthConnectSubtitle => 'Erlaube YAMT, Schritte, Workouts und verbrannte Kalorien aus Apple Health zu lesen.';

  @override
  String get settingsHealthHistorySubtitle => 'Erlaube ältere Health-Connect-Historie, damit vergangene Tagebuch-Tage Aktivitätsdaten laden können.';

  @override
  String get settingsHealthInstallSubtitle => 'Installiere Health Connect, bevor du hier Gesundheitsdaten verbinden kannst.';

  @override
  String get settingsHealthDisconnectSubtitle => 'Entferne den Health-Connect-Zugriff für YAMT.';

  @override
  String get settingsAppleHealthDisconnectSubtitle => 'Stoppe die Nutzung von Apple Health in YAMT.';

  @override
  String get settingsHealthDisconnectDialogTitle => 'Health-Zugriff trennen?';

  @override
  String get settingsHealthDisconnectDialogBody => 'YAMT verliert den Zugriff auf Health Connect, bis du es erneut verbindest.';

  @override
  String get settingsAppleHealthDisconnectDialogBody => 'YAMT nutzt Apple-Health-Daten nicht mehr, bis du es erneut verbindest. Die Apple-Health-Berechtigungen auf deinem iPhone bleiben unverändert.';

  @override
  String get settingsHealthDisconnectAction => 'Trennen';

  @override
  String get settingsHealthDisconnectSuccess => 'Health-Zugriff getrennt. Starte YAMT neu, bevor du Health Connect erneut verbindest.';

  @override
  String get settingsAppleHealthDisconnectSuccess => 'Apple Health in YAMT getrennt. Du kannst es jederzeit in den Einstellungen wieder verbinden.';

  @override
  String get settingsHealthDisconnectOpenedSettings => 'Einstellungen geöffnet, damit du den Apple-Health-Zugriff verwalten kannst.';

  @override
  String get settingsHealthDisconnectFailed => 'Health-Zugriff konnte nicht getrennt werden.';

  @override
  String get settingsHealthConnectFailed => 'Health-Zugriff konnte nicht verbunden werden.';

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
  String get healthInstallAction => 'Health Connect installieren';

  @override
  String get healthHistoryAction => 'Ältere Historie erlauben';

  @override
  String get healthUnsupportedHint => 'Health Connect oder Apple Health ist auf diesem Gerät nicht verfügbar.';

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
  String get householdJoinNameDialogTitle => 'Name angeben';

  @override
  String get householdJoinNameDialogMessage => 'Bitte gib deinen Namen ein, damit andere Haushaltsmitglieder dich erkennen können.';

  @override
  String get householdJoinNameDialogFieldLabel => 'Dein Name';

  @override
  String get householdJoinNameDialogRequiredError => 'Bitte gib einen Namen ein.';

  @override
  String get householdJoinNameDialogAction => 'Speichern & Beitreten';

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
  String get commonUndoAction => 'Rückgängig machen';

  @override
  String get commonNotImplementedYet => 'Noch nicht implementiert';

  @override
  String get onboardingWelcomeTitle => 'Schön, dass du hier bist!';

  @override
  String get onboardingWelcomeText => 'Vergiss kompliziertes Kalorienzählen. Wir machen es dir so einfach wie möglich. Damit wir dich optimal unterstützen können, brauchen wir nur ein paar kleine Infos zu dir.';

  @override
  String get onboardingWelcomeAction => 'Lass uns starten';

  @override
  String get onboardingWelcomeAlreadyHaveAccount => 'Bereits registriert?';

  @override
  String get onboardingWelcomeLoginAction => 'Hier einloggen';

  @override
  String get onboardingAgeYearsUnit => 'Jahre';

  @override
  String get onboardingHeightCmUnit => 'cm';

  @override
  String get onboardingDoneAction => 'Fertig';

  @override
  String get onboardingNextAction => 'Weiter';

  @override
  String get onboardingNextActionStep5 => 'Klingt super, weiter!';

  @override
  String get onboardingFinishAction => 'Starten';

  @override
  String get onboardingPersonalInfoTitle => 'Erzähl uns etwas über dich.';

  @override
  String get onboardingPersonalInfoSubtitle => 'Diese Daten helfen uns, deinen Grundumsatz zu berechnen – denn jeder Körper verbrennt Energie anders!';

  @override
  String get onboardingActivityLevelTitle => 'Wie aktiv bist du?';

  @override
  String get onboardingActivityLevelSubtitle => 'Dein normaler Alltag (Training kommt später).';

  @override
  String get onboardingActivityTitle => 'Aktivitätslevel';

  @override
  String get onboardingActivitySubtitle => 'Wie aktiv bist du in deinem Alltag?';

  @override
  String get onboardingGoalWeightTitle => 'Dein Ziel';

  @override
  String get onboardingGoalWeightSubtitle => 'Lass uns dein Zielgewicht festlegen.';

  @override
  String get onboardingGoalWeightStartLabel => 'Startgewicht (kg)';

  @override
  String get onboardingGoalWeightTargetLabel => 'Wunschgewicht (kg)';

  @override
  String get onboardingGoalWeightLoseFeedback => 'Du möchtest abnehmen. Ein gesundes Ziel!';

  @override
  String get onboardingGoalWeightGainFeedback => 'Du möchtest zunehmen. Muskelaufbau ist super!';

  @override
  String get onboardingGoalWeightMaintainFeedback => 'Du möchtest dein Gewicht halten. Perfekt!';

  @override
  String get onboardingPaceTitle => 'Dein Tempo';

  @override
  String get onboardingPaceSubtitle => 'Wie schnell möchtest du dein Ziel erreichen?';

  @override
  String get onboardingPaceMaintainMessage => 'Da du dein Gewicht halten möchtest, berechnen wir einfach deinen Erhaltungsbedarf. Du brauchst kein Tempo festlegen.';

  @override
  String get onboardingPaceWarningTitle => 'Ambitioniertes Tempo';

  @override
  String get onboardingPaceWarningLoseMessage => 'Mehr als 0,5 kg pro Woche abzunehmen ist recht hoch. Achte darauf, dass du ausreichend Nährstoffe zu dir nimmst!';

  @override
  String get onboardingPaceWarningGainMessage => 'Mehr als 0,5 kg pro Woche zuzunehmen ist recht hoch. Ein moderateres Tempo hilft dir, Muskeln aufzubauen, ohne zu viel Fett anzusetzen.';

  @override
  String onboardingPacePerWeek(String pace) {
    return '$pace kg / Woche';
  }

  @override
  String get onboardingInfoTitle => 'Dein Plan steht! 🎉';

  @override
  String get onboardingInfoSubtitle => 'Ein paar Dinge, die du wissen solltest.';

  @override
  String get onboardingInfoPoint1Title => 'Kassenzettel scannen';

  @override
  String get onboardingInfoPoint1Body => 'Kein langes Tippen mehr.';

  @override
  String get onboardingInfoPoint2Title => 'KI-Erkennung';

  @override
  String get onboardingInfoPoint2Body => 'Sag uns einfach, was du gegessen hast.';

  @override
  String get onboardingInfoPoint3Title => 'Barcode-Scanner';

  @override
  String get onboardingInfoPoint3Body => 'Ein Scan, alle Nährwerte.';

  @override
  String get onboardingInfoBoxTitle => 'Die Kennenlern-Woche';

  @override
  String get onboardingInfoBoxBody => 'Deine erste Mission: Versuche in den nächsten 7 Tagen nichts krampfhaft zu ändern. Iss wie immer und tracke einfach. Unser smarter Algorithmus lernt deinen Stoffwechsel kennen und erstellt danach dein maßgeschneidertes Kalorienziel!';

  @override
  String get onboardingStartDateTitle => 'Wann geht\'s los?';

  @override
  String get onboardingStartDateSubtitle => 'Wann möchtest du mit dem Tracking starten?';

  @override
  String get onboardingStartDateNowLabel => 'Ab heute';

  @override
  String get onboardingStartDateNowDesc => 'Ich tracke heute alles (oder habe es bereits getan).';

  @override
  String get onboardingStartDateNowQuestion => 'Wie gehen wir mit dem heutigen Tag um?';

  @override
  String get onboardingStartDateNowExact => 'Ich trage den ganzen Tag exakt nach';

  @override
  String get onboardingStartDateNowEstimate => 'Ich schätze grob ab, was ich bisher aß';

  @override
  String get onboardingStartDateLaterLabel => 'Ab morgen';

  @override
  String get onboardingStartDateLaterDesc => 'Heute ist schon fast rum, ich starte lieber morgen frisch.';

  @override
  String get onboardingReadyTitle => 'Alles bereit!';

  @override
  String get onboardingReadySubtitle => 'Dein Profil ist fertig. Lass uns loslegen!';

  @override
  String get cookflowPrepflowTitle => 'Prepflow';

  @override
  String get cookflowTemplateNotFound => 'Rezept nicht gefunden.';

  @override
  String get cookflowLoadFailed => 'Cookflow konnte nicht geladen werden.';

  @override
  String get cookflowStartButton => 'Flow starten';

  @override
  String get cookflowLaterButton => 'Später';

  @override
  String get cookflowShoppingListContinueButton => 'Zur Einkaufsliste hinzufügen und später fortsetzen';

  @override
  String get cookflowShoppingListAddSucceeded => 'Zutaten zur Einkaufsliste hinzugefügt.';

  @override
  String get cookflowShoppingListAddFailed => 'Einkaufsliste konnte nicht aktualisiert werden.';

  @override
  String get cookflowSessionSaveFailed => 'Cookflow konnte nicht gespeichert werden.';

  @override
  String get cookflowResolveConflictsButton => 'Bitte Konflikte lösen';

  @override
  String get cookflowContinueButton => 'Weiter';

  @override
  String cookflowPhaseChip(int currentPhase, int totalPhases) {
    return 'Phase $currentPhase / $totalPhases';
  }

  @override
  String get cookflowSaveMealButton => 'Mahlzeit speichern';

  @override
  String get cookflowSavingMealButton => 'Mahlzeit wird gespeichert';

  @override
  String get cookflowInvalidWeight => 'Bitte gib ein gültiges Bruttogewicht ein.';

  @override
  String get cookflowMissingWeight => 'Bitte gib das Bruttogewicht ein.';

  @override
  String get cookflowGrossMustExceedTara => 'Bruttogewicht muss größer als Tara sein.';

  @override
  String get cookflowMissingAssignments => 'Bitte weise mindestens eine Zutat dem Vorrat zu.';

  @override
  String get cookflowIngredientContainerMissing => 'Bitte wähle für jede Zutat einen Behälter.';

  @override
  String get cookflowContainerMissingIngredients => 'Jeder Behälter braucht mindestens eine Zutat.';

  @override
  String get cookflowSaveFailed => 'Mahlzeit konnte nicht gespeichert werden.';

  @override
  String get cookflowSuccessFallbackMealName => 'Deine Mahlzeit';

  @override
  String cookflowSavedMealsCount(int count) {
    return '$count Mahlzeiten gespeichert';
  }

  @override
  String get cookflowIntroHeadline => 'Kochsession starten';

  @override
  String get cookflowRecipeLabel => 'Rezept: ';

  @override
  String get cookflowInventoryCheckTitle => 'Inventar Check';

  @override
  String get cookflowResetButton => 'Zurücksetzen';

  @override
  String get cookflowEmptyIngredients => 'Keine Zutaten vorhanden.';

  @override
  String get cookflowShoppingCartTooltip => 'Einkaufswagen';

  @override
  String get cookflowAssignTooltip => 'Zuweisen';

  @override
  String get cookflowIgnoreTooltip => 'Ignorieren';

  @override
  String get cookflowUnknownAmount => 'Menge offen';

  @override
  String get cookflowInventorySelectionTitle => 'Vorrat auswählen';

  @override
  String cookflowInventoryConflictMessage(Object availableAmount, Object missingAmount) {
    return 'Vorrat reicht nicht: Nur $availableAmount da. Es fehlen $missingAmount.';
  }

  @override
  String cookflowInventoryUsagePreview(Object usedAmount, Object remainingAmount) {
    return 'Abzug $usedAmount · übrig $remainingAmount';
  }

  @override
  String get cookflowBuyRemainingButton => 'REST EINKAUFEN';

  @override
  String get cookflowAdjustTemplateButton => 'REZEPT ANPASSEN';

  @override
  String cookflowInventoryUnitConflictMessage(Object recipeUnit, Object inventoryUnit) {
    return 'Einheiten-Konflikt: Rezept nutzt \"$recipeUnit\". Inventar hat \"$inventoryUnit\".';
  }

  @override
  String get cookflowInventoryUnitConversionPrefix => '1 Stück ≈';

  @override
  String get cookflowInventoryUnitConvertAction => 'Umrechnen';

  @override
  String get cookflowInventoryUnitWeighLaterAction => 'Später beim Kochen wiegen';

  @override
  String get cookflowEditIngredientTooltip => 'Zutat bearbeiten';

  @override
  String get cookflowEditIngredientTitle => 'Zutat bearbeiten';

  @override
  String get cookflowEditIngredientNameLabel => 'Zutat';

  @override
  String get cookflowEditIngredientAmountLabel => 'Menge';

  @override
  String get cookflowEditIngredientUnitLabel => 'Einheit';

  @override
  String get cookflowEditIngredientRequiredField => 'Bitte ausfüllen.';

  @override
  String get cookflowEditIngredientSaveAction => 'Speichern';

  @override
  String get cookflowInventorySelectionEmpty => 'Keine passenden Vorratsartikel gefunden.';

  @override
  String get cookflowCancelButton => 'Abbrechen';

  @override
  String get cookflowInventorySelectionSaveButton => 'Auswählen';

  @override
  String get cookflowInventorySelectionItemLabel => 'Vorratsartikel';

  @override
  String get cookflowInventorySelectionAddIngredient => 'Zutat hinzufügen';

  @override
  String get cookflowInventorySelectionAddIngredientSubtitle => 'Optionalen Vorratsartikel auswählen.';

  @override
  String get cookflowInventorySelectionWeightLater => 'Gewicht später in Phase 3 festlegen.';

  @override
  String get cookflowInventorySelectionAddConfirm => 'Hinzufügen';

  @override
  String get cookflowInventoryReturnSuggestion => 'Neuer Treffer im Vorrat gefunden.';

  @override
  String get cookflowInventoryReturnSuggestionButton => 'Übernehmen';

  @override
  String get cookflowPreparationTitle => '1. Vorbereitung';

  @override
  String get cookflowPreparationBody => 'Bevor wir loslegen: Wähle alle Töpfe oder Behälter und trage ihr Leergewicht ein.';

  @override
  String get cookflowTaraFieldTitle => 'Leergewicht (Tara)';

  @override
  String get cookflowGramUnit => 'Gramm';

  @override
  String get cookflowTaraUtensilsTitle => 'Gespeicherte Utensilien';

  @override
  String get cookflowTaraUtensilsLoadFailed => 'Utensilien konnten nicht geladen werden.';

  @override
  String get cookflowPreparationHint => 'Wenn Nudeln und Soße in getrennten Behältern landen, füge beide jetzt hinzu. In Phase 3 weist du jede Zutat zu.';

  @override
  String get cookflowPortionScalerTitle => 'Rezeptportionen';

  @override
  String cookflowOriginalPortionsLabel(int count) {
    return 'Originalrezept: $count Portionen';
  }

  @override
  String cookflowTargetPortionsLabel(int count) {
    return '$count Portionen';
  }

  @override
  String get cookflowTargetPortionsFieldLabel => 'Neue Portionen';

  @override
  String get cookflowCookingTitle => '2. Kochen';

  @override
  String get cookflowCookingBody => 'Die Zutaten aus deinem Vorrat sind lokal reserviert.\nLass es dir schmecken!';

  @override
  String get cookflowOnTheFlyTitle => 'On-the-fly Anpassung';

  @override
  String get cookflowOnTheFlyHint => 'z.B. 150g extra Erbsen...';

  @override
  String get cookflowOnTheFlyRemoveTooltip => 'Anpassung entfernen';

  @override
  String get cookflowVoiceInputStartTooltip => 'Spracheingabe starten';

  @override
  String get cookflowVoiceInputStopTooltip => 'Spracheingabe beenden';

  @override
  String get cookflowVoiceInputUnavailable => 'Spracheingabe wird auf diesem Gerät aktuell nicht unterstützt.';

  @override
  String get cookflowVoiceInputPermissionDenied => 'Bitte erlaube Mikrofonzugriff, um die Spracheingabe zu verwenden.';

  @override
  String get cookflowVoiceInputFailed => 'Spracheingabe konnte nicht gestartet werden. Bitte versuche es erneut.';

  @override
  String get cookflowCookingFallbackNoIngredients => 'Bereite dein Rezept nach den vorhandenen Zutaten vor.';

  @override
  String get cookflowCookingFallbackPrepPrefix => 'Bereite die Zutaten vor:';

  @override
  String get cookflowCookingFallbackCookText => 'Koche das Gericht anschließend wie im Rezept beschrieben.';

  @override
  String get cookflowSummaryTitle => '3. Resümee';

  @override
  String get cookflowSummaryBody => 'Prüfe die finalen Zutaten, löse spontane Änderungen auf und wähle, wo jede Zutat verstaut ist.';

  @override
  String get cookflowSummaryIngredientsTitle => 'Grundrezept Zutaten';

  @override
  String get cookflowSummaryAdjustmentsTitle => 'Ungelöste Anpassungen';

  @override
  String get cookflowSummaryMatchInventoryButton => 'Als Zutat hinzufügen';

  @override
  String get cookflowSummaryPlaceholderAdjustment => '200g Gurken';

  @override
  String get cookflowFinalizeTitle => '4. Finalisieren';

  @override
  String get cookflowFinalizeBody => 'Stell jeden gefüllten Behälter auf die Waage und lege danach die Portionen für die erstellten Mahlzeiten fest.';

  @override
  String get cookflowStorageContainersTitle => 'Aufbewahrungsbehälter';

  @override
  String get cookflowAddStorageContainerButton => 'Behälter hinzufügen';

  @override
  String get cookflowContainerLabel => 'Behälter';

  @override
  String cookflowContainerNameHint(int index) {
    return 'Behälter $index';
  }

  @override
  String get cookflowRemoveContainerTooltip => 'Behälter entfernen';

  @override
  String get cookflowContainerTaraLabel => 'Tara';

  @override
  String get cookflowPortionsUnit => 'Portionen';

  @override
  String get cookflowIngredientContainerTitle => 'Wo ist welche Zutat verstaut?';

  @override
  String get cookflowIngredientContainerEmpty => 'Keine Vorratszutaten für Behälter-Zuweisung vorhanden.';

  @override
  String get cookflowGrossWeightTitle => 'Bruttogewicht (Topf + Essen)';

  @override
  String get cookflowGrossWeightHint => 'z.B. 2500';

  @override
  String get cookflowMinusTaraLabel => 'Minus Leergewicht (Tara)';

  @override
  String get cookflowNetWeightLabel => 'Netto-Endgewicht';

  @override
  String get cookflowSplitIntoPortionsLabel => 'Portionen nachjustieren?';

  @override
  String get cookflowHowManyPortions => 'Wie viele Portionen sind das?';

  @override
  String get cookflowCaloriesShortLabel => 'KALORIEN';

  @override
  String get cookflowCarbsShortLabel => 'KOHLENH.';

  @override
  String get cookflowProteinShortLabel => 'PROTEIN';

  @override
  String get cookflowFatShortLabel => 'FETT';

  @override
  String get cookflowSuccessTitle => 'Fertig';

  @override
  String get cookflowSuccessSubtitle => 'Deine Mahlzeit wurde gespeichert und ist jetzt im Inventar verfügbar.';

  @override
  String get cookflowSuccessHeadline => 'Mahlzeit gespeichert';

  @override
  String get cookflowToInventoryButton => 'Zum Inventar';

  @override
  String get cookflowResumeLabel => 'Fortsetzen';
}
