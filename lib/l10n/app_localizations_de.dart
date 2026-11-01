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
  String get homeProfile => 'Profil';

  @override
  String get homeProgress => 'Fortschritt';

  @override
  String get homeMenuTool => 'Menü';

  @override
  String get aiChefIdeaDescription =>
      'Die KI schlägt dir ein zufälliges Rezept vor';

  @override
  String get aiChefIdeaTitle => 'KI-Rezeptidee';

  @override
  String get aiChefSetupTitle => 'Was soll die KI kochen?';

  @override
  String get aiChefSetupSubtitle =>
      'Wähle, ob dein Vorrat beachtet wird, und ergänze Wünsche.';

  @override
  String get aiChefUseInventoryTitle => 'Vorrat beachten';

  @override
  String get aiChefUseInventorySubtitle =>
      'Zutaten aus deinem Vorrat bevorzugen.';

  @override
  String get aiChefWishesLabel => 'Wünsche';

  @override
  String get aiChefWishesHint =>
      'z. B. vegetarisch, schnell, proteinreich, ohne Reis';

  @override
  String get aiChefGenerateAction => 'Rezept generieren';

  @override
  String get aiChefGeneratingTitle => 'Rezept wird kreiert...';

  @override
  String get aiChefGeneratingSubtitle =>
      'Deine persönliche KI stellt ein leckeres Rezept zusammen...';

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
  String get aiChefQuoteLoveGarlic =>
      'Die Geheimzutat ist immer Liebe. Und Knoblauch.';

  @override
  String get aiChefQuoteCookingMagic =>
      'Kochen ist wie Zaubern, nur dass man das Ergebnis essen kann.';

  @override
  String get aiChefQuoteGoodFood => 'Gutes Essen bringt gute Laune.';

  @override
  String get aiChefQuoteKitchenTalks =>
      'Die besten Gespräche finden immer in der Küche statt.';

  @override
  String get aiChefQuoteVirtualOven =>
      'Die KI heizt schon mal den virtuellen Ofen vor...';

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
  String get productSearchHubCreateOwnAction => 'Erstellen';

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
  String get productSearchHubSearchEmptyState =>
      'Keine passenden Produkte gefunden.';

  @override
  String get productSearchHubSearchOfflineState =>
      'Ohne Verbindung keine Suche. Sobald du online bist, wird erneut gesucht.';

  @override
  String get eatPageAmountUnknown => '–';

  @override
  String get productSearchHubMissingNutritionHint =>
      'Pflichtwerte fehlen noch. Jedes EU-Nährwertetikett nennt sie.';

  @override
  String get productEditorPhotosHint =>
      'Zwei Fotos füllen das Produkt aus. Du prüfst nur noch.';

  @override
  String get productEditorFrontPhoto => 'Vorderseite';

  @override
  String get productEditorCreateAction => 'Erstellen';

  @override
  String get productEditorSaveAction => 'Speichern';

  @override
  String get productEditorSaveChangesAction => 'Änderungen speichern';

  @override
  String get productEditorDoneAction => 'Fertig';

  @override
  String get productEditorFrontPhotoHint => 'Name, Marke, Packung';

  @override
  String get productEditorNutritionTablePhoto => 'Nährwerttabelle';

  @override
  String get productEditorNutritionTablePhotoHint => 'Nährwerte';

  @override
  String get productEditorPhotoReading => 'Liest …';

  @override
  String productEditorMissing(String fields) {
    return 'Noch offen: $fields';
  }

  @override
  String productEditorMissingValues(int count) {
    return '$count Nährwerte';
  }

  @override
  String get productEditorMissingBarcode =>
      'Barcode – scannen oder „Hat keinen“';

  @override
  String productMissingValuesHint(String values) {
    return 'Fehlt: $values – ergänzen';
  }

  @override
  String get productPieceWeightLabel => 'Gramm pro Stück';

  @override
  String get productServingChoiceLabel => 'Portion';

  @override
  String productServingAmount(String amount, String unit) {
    return '$amount $unit';
  }

  @override
  String get productEditorPhotoReadName => 'Name';

  @override
  String productEditorPhotoReadValues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Werte',
      one: '1 Wert',
    );
    return '$_temp0';
  }

  @override
  String get productEditorPhotoRead => 'Erkannt';

  @override
  String get productEditorPhotoRetake => 'Nochmal';

  @override
  String get productEditorScanBarcode => 'Scannen';

  @override
  String get productEditorNoBarcode => 'Hat keinen';

  @override
  String get productEditorBarcodeFromPhoto => 'Vom Foto erkannt';

  @override
  String get productEditorBarcodeFromAi => 'Von der KI gelesen, bitte prüfen';

  @override
  String get productEditorBarcodeMissing => 'Kein Barcode auf den Fotos';

  @override
  String get productEditorCameraFailed =>
      'Das Foto konnte nicht aufgenommen werden.';

  @override
  String get productEditorCameraUnsupported =>
      'Auf diesem Gerät gehen keine Fotos.';

  @override
  String get productEditorPhotosNotSaved =>
      'Die Fotos konnten nicht gespeichert werden. Das Produkt wird ohne sie gespeichert.';

  @override
  String get photoUploadQueued => 'Fotos werden später hochgeladen.';

  @override
  String get productEditorTakeNutritionTablePhoto =>
      'Nährwerttabelle fotografieren';

  @override
  String get productSearchHubCreateProductAction => 'Produkt erstellen';

  @override
  String productSearchHubStoredInVorrat(String name) {
    return '$name ist im Vorrat';
  }

  @override
  String inventoryRestToStockQuestion(String amount) {
    return 'Soll der Rest ($amount) in den Vorrat?';
  }

  @override
  String get inventoryRestToStockNo => 'Nein';

  @override
  String get inventoryRestToStockYes => 'In den Vorrat';

  @override
  String get inventoryPackChoiceTitle => 'Vom Vorrat abziehen?';

  @override
  String get inventoryPackChoiceSkip => 'Nicht abziehen';

  @override
  String get productSearchHubRecentlySelectedTab => 'Zuletzt ausgewählt';

  @override
  String get productSearchHubRecentlySelectedLoading =>
      'Letzte Produkte werden geladen';

  @override
  String get productSearchHubRecentlySelectedLoadFailed =>
      'Zuletzt ausgewählte Produkte konnten nicht geladen werden.';

  @override
  String get productSearchHubRecentlySelectedRetryAction => 'Erneut versuchen';

  @override
  String get productSearchHubRecentlySelectedEmptyState =>
      'Noch keine zuletzt ausgewählten Produkte.';

  @override
  String get inventoryPageTitle => 'Vorrat';

  @override
  String inventoryPageKicker(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Lebensmittel',
      one: '1 Lebensmittel',
    );
    return '$_temp0';
  }

  @override
  String get inventorySortAction => 'Sortieren';

  @override
  String get inventoryQuickFilterAll => 'Alle';

  @override
  String get inventoryQuickFilterPlanned => 'Verplant';

  @override
  String get inventoryQuickFilterOpen => 'Offen';

  @override
  String get inventoryQuickFilterMeals => 'Mahlzeiten';

  @override
  String get inventoryQuickFilterLow => 'Fast leer';

  @override
  String inventoryRowOfAmount(String amount) {
    return 'von $amount';
  }

  @override
  String inventoryRowPlanMissing(String amount) {
    return '$amount fehlen';
  }

  @override
  String inventoryRowPlanned(String amount) {
    return '$amount verplant';
  }

  @override
  String get inventoryRowLow => 'fast leer';

  @override
  String inventoryRowInfo(String first, String second) {
    return '$first · $second';
  }

  @override
  String inventoryRowKcalPer100(String kcal) {
    return '$kcal kcal/100 g';
  }

  @override
  String inventoryRowMealFromRecipe(String left, int total) {
    return 'Aus Rezept · $left von $total Portionen';
  }

  @override
  String inventoryRowMealCombined(String left, int total) {
    return 'Kombiniert · $left von $total Portionen';
  }

  @override
  String get inventoryMealInPot => 'Im Topf';

  @override
  String inventoryRowMealMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zutaten fehlen',
      one: '1 Zutat fehlt',
    );
    return '$_temp0';
  }

  @override
  String get inventorySortNewestFirst => 'Neueste zuerst';

  @override
  String get inventorySortOldestFirst => 'Älteste zuerst';

  @override
  String get inventorySortLeastFirst => 'Wenig zuerst';

  @override
  String get inventorySortMostFirst => 'Viel zuerst';

  @override
  String get inventoryActionManualSearch => 'Manuelle Suche';

  @override
  String get inventoryActionAiSuggestion => 'KI-Vorschlag';

  @override
  String get inventoryActionUploadImagePdf => 'Bild/PDF hochladen';

  @override
  String get inventoryDockAddAction => 'Hinzufügen';

  @override
  String get inventoryDockReceiptTool => 'Bon';

  @override
  String get inventoryAddManualSearchDescription =>
      'Lebensmittel nach Name oder Marke finden';

  @override
  String get inventoryAddAiDescription =>
      'Beschreib ein Lebensmittel, die KI schätzt die Nährwerte';

  @override
  String get inventoryAddCreateDescription =>
      'Eigenes Produkt anlegen, per Foto oder von Hand';

  @override
  String get inventoryAddUploadDescription =>
      'Einen Bon als Bild oder PDF einlesen';

  @override
  String get inventoryReceiptPhotoAction => 'Bon fotografieren';

  @override
  String get inventoryReceiptPhotoDescription =>
      'Den Kassenbon mit der Kamera aufnehmen';

  @override
  String get inventorySharedReceiptConfirmTitle => 'Geteilten Beleg scannen?';

  @override
  String get inventorySharedReceiptConfirmSingleMessage =>
      'Möchtest du diese geteilte Datei als Beleg scannen?';

  @override
  String inventorySharedReceiptConfirmMultipleMessage(int count) {
    return 'Möchtest du $count geteilte Dateien als Belege scannen?';
  }

  @override
  String get inventorySharedReceiptConfirmAction => 'Scannen';

  @override
  String get inventoryReceiptSelectionFailed =>
      'Beleg konnte nicht ausgewählt werden. Bitte erneut versuchen.';

  @override
  String get inventoryReceiptAnalysisFailed =>
      'Beleganalyse fehlgeschlagen. Bitte erneut versuchen.';

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
  String get inventoryReceiptReviewPriceExcluded =>
      'Ausgeschlossene Positionen';

  @override
  String get inventoryReceiptReviewEmpty =>
      'Keine Positionen im Beleg gefunden.';

  @override
  String get inventoryReceiptReviewExcludedTag => 'Nur prüfen';

  @override
  String get inventoryReceiptReviewEditAction => 'Bearbeiten';

  @override
  String get inventoryReceiptReviewFieldName => 'Name';

  @override
  String get inventoryReceiptReviewFieldQuantity => 'Menge';

  @override
  String get inventoryReceiptReviewFieldWeight => 'Gewicht';

  @override
  String get inventoryReceiptReviewFieldWeightUnit => 'Einheit';

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
  String get inventoryReceiptReviewNoDate => 'Kein Datum';

  @override
  String get inventoryReceiptReviewInvalidNumber =>
      'Bitte gültige Zahlen eingeben.';

  @override
  String get inventoryReceiptReviewConfirmItemAction => 'Artikel bestätigen';

  @override
  String get inventoryReceiptReviewUndoConfirmAction => 'Bestätigung aufheben';

  @override
  String get inventoryReceiptReviewDetectedItems => 'Erkannte Artikel';

  @override
  String get inventoryReceiptReviewOriginalReceiptAction =>
      'Original-Beleg ansehen';

  @override
  String get inventoryReceiptReviewOriginalReceiptTitle =>
      'Original-Beleg Vorschau';

  @override
  String get inventoryReceiptReviewOriginalReceiptUnavailable =>
      '(Hier würde das Foto angezeigt werden)';

  @override
  String get inventoryReceiptReviewReadAsPrefix => 'Gelesen als';

  @override
  String get inventoryReceiptReviewCandidatesAction => 'Kandidaten';

  @override
  String get inventoryReceiptReviewProductSelectionLabel => 'Produkt auswählen';

  @override
  String get inventoryReceiptReviewRecentProductsTitle => 'Zuletzt hinzugefügt';

  @override
  String get inventoryReceiptReviewManualDataAction =>
      'Produkt suchen oder Barcode scannen';

  @override
  String get inventoryReceiptReviewManualDataHint =>
      'Produkt suchen oder Barcode scannen. Nährwerte später ergänzen.';

  @override
  String get inventoryReceiptReviewManualDataSaveAction => 'Übernehmen';

  @override
  String get inventoryReceiptReviewManualDataRequired =>
      'Bitte Produkt wählen, Barcode scannen oder Nährwerte angeben.';

  @override
  String get inventoryReceiptReviewSwitchAction => 'Wechseln';

  @override
  String get inventoryReceiptReviewCancelAction => 'Abbrechen';

  @override
  String get inventoryReceiptReviewSaveAction => 'Speichern';

  @override
  String get inventoryReceiptSaveSucceeded =>
      'Positionen zum Vorrat hinzugefügt.';

  @override
  String get inventoryReceiptSaveFailed =>
      'Positionen konnten nicht gespeichert werden.';

  @override
  String get inventoryListModeByReceipt => 'Nach Beleg';

  @override
  String get inventoryViewStock => 'Vorrat';

  @override
  String get inventoryViewHistory => 'Verlauf';

  @override
  String get inventoryActivityLoading => 'Historie wird geladen...';

  @override
  String get inventoryActivityLoadFailed =>
      'Historie konnte nicht geladen werden.';

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
  String inventoryActivityItemConsumed(
    String actor,
    String item,
    String amount,
  ) {
    return '$actor hat $amount $item gegessen.';
  }

  @override
  String inventoryActivityItemDiscarded(
    String actor,
    String item,
    String amount,
  ) {
    return '$actor hat $amount $item aussortiert.';
  }

  @override
  String inventoryActivityItemDeleted(
    String actor,
    String item,
    String amount,
  ) {
    return '$actor hat $amount $item gelöscht.';
  }

  @override
  String inventoryActivityItemRestored(
    String actor,
    String item,
    String amount,
  ) {
    return '$actor hat $amount $item wiederhergestellt.';
  }

  @override
  String inventoryActivityItemUsedInPreparedMeal(
    String actor,
    String item,
    String amount,
  ) {
    return '$actor hat $amount $item für eine vorbereitete Mahlzeit verwendet.';
  }

  @override
  String inventoryActivityItemReturnedFromPreparedMeal(
    String actor,
    String item,
    String amount,
  ) {
    return '$actor hat $amount $item aus einer vorbereiteten Mahlzeit zurückgelegt.';
  }

  @override
  String get inventorySearchLabel => 'Im Vorrat suchen';

  @override
  String get inventorySearchHint => 'Suchen';

  @override
  String get inventorySearchClearAction => 'Suche leeren';

  @override
  String get inventoryViewListAction => 'Liste';

  @override
  String get inventoryViewTilesAction => 'Kacheln';

  @override
  String get inventorySortAdded => 'Hinzugefügt';

  @override
  String get inventorySortEaten => 'Gegessen';

  @override
  String get inventorySortAlphabetical => 'Alphabetisch';

  @override
  String get inventorySortQuantity => 'Menge';

  @override
  String get inventorySortDirectionAlphaAscending => 'A bis Z';

  @override
  String get inventorySortDirectionAlphaDescending => 'Z bis A';

  @override
  String get inventoryNutritionCaloriesShortLabel => 'Kcal';

  @override
  String get inventoryNutritionCarbsShortLabel => 'KH';

  @override
  String get inventoryHideConsumedFilterTitle => 'Verbrauchte ausblenden';

  @override
  String get inventoryReceiptGroupTitle => 'Beleg';

  @override
  String get inventoryReceiptGroupNoReceipt => 'Ohne Beleg';

  @override
  String get inventoryReceiptGroupItems => 'Artikel';

  @override
  String get inventoryItemDeletedMessage => 'Artikel gelöscht.';

  @override
  String get inventoryItemRemovedMessage => 'Artikel aussortiert.';

  @override
  String get inventoryAmountDialogAllRemainingAction => 'Alles/Rest';

  @override
  String get inventoryItemEatSheetDecreasePortionCountAction =>
      'Portionen verringern';

  @override
  String get inventoryItemEatSheetIncreasePortionCountAction =>
      'Portionen erhöhen';

  @override
  String get inventoryItemEatSheetDefaultPortionLabel => 'Portion';

  @override
  String get inventoryItemEatSheetUnitPiece => 'Stück';

  @override
  String get inventoryItemEatSheetInedibleAmountLabel =>
      'Nicht essbaren Anteil abziehen';

  @override
  String get inventoryItemEatSheetInedibleAmountFieldLabel =>
      'Nicht essbarer Anteil';

  @override
  String get inventoryItemEatSheetInedibleAmountError =>
      'Der Abzug muss kleiner als die verzehrte Menge sein.';

  @override
  String get inventoryItemEatSheetConfirmAction => 'Ins Tagebuch';

  @override
  String get eatPagePlanIconTooltip => 'Planen';

  @override
  String get eatPageStoreIconTooltip => 'In den Vorrat';

  @override
  String get eatPotWeighTitle => 'Topf auf der Waage';

  @override
  String get eatPotWeighReminder =>
      'Seit dem letzten Wiegen kann Wasser verdunstet sein. Wieg den Topf nochmal, dann stimmt es für alle.';

  @override
  String eatPotNetWeight(int tare, int net) {
    return '− leerer Topf $tare g = $net g im Topf';
  }

  @override
  String get eatPotTakeOutHint =>
      'Dann Tara drücken und die genommenen Gramm eintragen.';

  @override
  String get eatPageRest => 'Rest';

  @override
  String get eatPageRestHint =>
      'Rest nimmt alles, was im Topf ist. So stimmt die Summe auch ohne Waage.';

  @override
  String get eatPagePlanReminderHint =>
      'Ein Plan zählt erst, wenn alle Zeilen gefüllt sind. Bis dahin ist er eine Erinnerung ohne kcal.';

  @override
  String eatPageMealPortionGrams(String portions, int grams) {
    return '$portions · $grams g';
  }

  @override
  String get eatPagePotUnit => 'Topf';

  @override
  String get eatPagePlanAction => 'Einplanen';

  @override
  String get eatPageNutritionTitle => 'Nährwerte';

  @override
  String get eatPageItemTitle => 'Artikel';

  @override
  String get eatPageMealTitle => 'Mahlzeit';

  @override
  String get eatPageIngredientMissing => 'Fehlt – keinem Vorrat zugeordnet';

  @override
  String get eatPageIngredientIgnored => 'Ignoriert – zählt nicht mit';

  @override
  String get eatPageIngredientNutritionIncomplete => 'Nährwerte unvollständig';

  @override
  String get eatPageReplaceProduct => 'Produkt ersetzen';

  @override
  String get eatPageOnShoppingList => 'Steht auf der Einkaufsliste';

  @override
  String get eatPageCombineLink => 'Mit anderem Lebensmittel kombinieren';

  @override
  String get eatPageCombineAdd => '+ Lebensmittel hinzufügen';

  @override
  String get eatPageCombinePickConfirm => 'Übernehmen';

  @override
  String get eatPageCombineNoMoreStock =>
      'Alle passenden Lebensmittel aus deinem Vorrat sind schon in der Mahlzeit.';

  @override
  String get eatPageCombineNeedsNutrition =>
      'Dieses Lebensmittel hat keine Nährwerte zum Zusammenrechnen.';

  @override
  String get eatPageCombineAddFood => 'Hinzufügen';

  @override
  String get eatPageCombineStore => 'In Vorrat';

  @override
  String eatPageMealTotal(String amount) {
    return 'gesamt $amount';
  }

  @override
  String get eatPageRemovePortion => 'Eine Portion weniger';

  @override
  String get eatPageAddPortion => 'Eine Portion mehr';

  @override
  String inventoryStockAddConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In Vorrat ($count Packungen)',
      one: 'In Vorrat (1 Packung)',
    );
    return '$_temp0';
  }

  @override
  String get eatPagePackages => 'Packungen';

  @override
  String get eatPageRemovePackage => 'Eine Packung weniger';

  @override
  String get eatPageAddPackage => 'Eine Packung mehr';

  @override
  String get eatPageMealPortions => 'Portionen';

  @override
  String eatPageMealPerPortion(String amount) {
    return 'Portion $amount';
  }

  @override
  String get eatPageMealUnknownValue => '–';

  @override
  String get eatPageCombineConfirm => 'Mahlzeit ins Tagebuch';

  @override
  String get eatPageCombineRemove => 'Aus der Liste nehmen';

  @override
  String get eatPageCombineAmount => 'Menge';

  @override
  String get eatPageCombineSaved => 'Mahlzeit eingetragen.';

  @override
  String get eatPageCombineFailed =>
      'Mahlzeit konnte nicht eingetragen werden.';

  @override
  String eatPageWhen(String day, String meal) {
    return '$day · $meal';
  }

  @override
  String get eatPagePickDay => 'Anderer Tag…';

  @override
  String get eatPageRememberPortion => '+ diese Menge als Portion merken';

  @override
  String eatPagePortionNameLabel(String amount) {
    return 'Name für $amount';
  }

  @override
  String get eatPagePortionNameHint => 'z. B. Scheibe';

  @override
  String get eatPageSavePortion => 'Speichern';

  @override
  String eatPageInStock(String amount) {
    return '$amount im Vorrat';
  }

  @override
  String eatPageTotal(String amount) {
    return '= $amount';
  }

  @override
  String eatPageKcal(int kcal) {
    return '$kcal kcal';
  }

  @override
  String get eatPageRememberPieceSize => '+ als Stückgröße merken';

  @override
  String get eatPagePieceSizeNameHint => 'z. B. L';

  @override
  String get eatPageAll => 'Alles';

  @override
  String get eatPageRecentMark => 'Zuletzt';

  @override
  String get eatPageServingMark => 'Portion';

  @override
  String get eatPageQuarterMark => '¼';

  @override
  String get eatPageHalfMark => '½';

  @override
  String get eatPageCountLabel => 'Anzahl Portionen';

  @override
  String get eatPagePieceCountLabel => 'Anzahl Stück';

  @override
  String get eatPageTimes => '×';

  @override
  String eatPageMark(String label, String amount) {
    return '$label $amount';
  }

  @override
  String eatPagePortionMultiple(String count, String label) {
    return '= $count × $label';
  }

  @override
  String eatPageApprox(String amount) {
    return '≈ $amount';
  }

  @override
  String get eatPagePortionsUnit => 'Port.';

  @override
  String inventoryEatSheetPortionsHeader(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount Portionen',
      one: '$amount Portion',
    );
    return '$_temp0';
  }

  @override
  String inventoryEatSheetAmountCompact(String amount, String unit) {
    return '$amount$unit';
  }

  @override
  String inventoryEatSheetAmountWithUnit(String amount, String unit) {
    return '$amount $unit';
  }

  @override
  String inventoryItemEatSheetInedibleAmountSummary(String amount) {
    return 'Nicht essbar: $amount';
  }

  @override
  String get inventoryItemAddToListAction => 'Auf Liste';

  @override
  String get inventoryItemAddToShoppingListAction =>
      'Zur Einkaufsliste hinzufügen';

  @override
  String get inventoryItemBuyAgainSucceeded =>
      'Artikel zur Einkaufsliste hinzugefügt.';

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
  String get inventoryItemRemoveConsumeElsewhereAction =>
      'Anderweitig verbraucht';

  @override
  String get inventoryItemRemoveConsumeElsewhereSubtitle =>
      'Gespendet, verschenkt oder geteilt';

  @override
  String get inventoryItemRemoveDeleteAction => 'Komplett löschen';

  @override
  String get inventoryItemRemoveDeleteSubtitle =>
      'Fehleingabe, nicht in Statistiken werten';

  @override
  String get inventoryItemThrowAwayAction => 'Wegwerfen';

  @override
  String get inventoryItemUpdatedMessage =>
      'Vorratsartikel wurde aktualisiert.';

  @override
  String get inventoryItemEditRequiresFullItem =>
      'Du kannst den Artikel nur bearbeiten, solange er noch vollständig vorhanden ist.';

  @override
  String get inventoryItemSwapCandidateRequiresFullItem =>
      'Du kannst den Kandidaten nur tauschen, solange der Artikel noch vollständig vorhanden ist.';

  @override
  String get inventoryItemActionFailed =>
      'Aktion fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get inventoryItemReanalyzeFailed =>
      'Neue Schätzung konnte nicht übernommen werden.';

  @override
  String get inventoryItemCannotPlan =>
      'Konnte nicht geplant werden: diese Menge braucht den Kalorien-Editor';

  @override
  String get inventoryBarcodeScanUnsupported =>
      'Barcode-Scan wird aktuell auf Android und iOS unterstützt.';

  @override
  String get inventoryManualAddHint =>
      'Scanne einen Barcode. Danach kannst du das Produkt prüfen, speichern oder Nährwerte ergänzen.';

  @override
  String get inventoryManualAddScanBarcodeAction => 'Barcode scannen';

  @override
  String get inventoryManualAddResolving => 'Barcode wird gesucht...';

  @override
  String get inventoryManualAddCandidateTitle => 'Produkt auswählen';

  @override
  String get inventoryManualAddCandidateSubtitle =>
      'Zu diesem Barcode wurden mehrere passende Produkte gefunden.';

  @override
  String get inventoryManualAddCandidateSourceLearned => 'Community';

  @override
  String get inventoryManualAddCandidateSourceOff => 'OFF';

  @override
  String get inventoryManualAddNotFound =>
      'Zu diesem Barcode wurde kein passendes Produkt gefunden.';

  @override
  String get inventoryManualAddLookupFailed =>
      'Barcode-Abfrage fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get inventoryManualAddLookupOffline =>
      'Ohne Verbindung kann der Barcode nicht gesucht werden. Versuche es erneut, sobald du online bist.';

  @override
  String get inventoryManualAddSaveFailed =>
      'Das Produkt konnte nicht zum Inventar hinzugefügt werden.';

  @override
  String get inventoryManualAddEatSucceeded => 'Ins Tagebuch eingetragen';

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
  String get inventoryManualAddEatNowRequiresNutrition =>
      'Nur verfügbar, wenn Nährwerte vorhanden sind.';

  @override
  String get inventoryManualAddMissingBarcodeTitle => 'Barcode eintragen?';

  @override
  String get inventoryManualAddMissingBarcodeMessage =>
      'Dieses Produkt hat noch keinen Barcode. Trage ihn jetzt ein, damit es später wiedererkannt wird, oder speichere es ohne Barcode.';

  @override
  String get inventoryManualAddMissingBarcodeLabel => 'Barcode';

  @override
  String get inventoryManualAddMissingBarcodeRequired =>
      'Trage einen Barcode ein oder speichere ohne Barcode.';

  @override
  String get inventoryManualAddMissingBarcodeSaveWithout =>
      'Ohne Barcode speichern';

  @override
  String get inventoryManualAddMissingBarcodeSave => 'Speichern';

  @override
  String get inventoryManualAddVoiceSearchStartTooltip => 'Sprachsuche starten';

  @override
  String get inventoryManualAddVoiceSearchStopTooltip => 'Sprachsuche beenden';

  @override
  String get inventoryManualAddVoiceSearchUnavailable =>
      'Sprachsuche wird auf diesem Gerät aktuell nicht unterstützt.';

  @override
  String get inventoryManualAddVoiceSearchPermissionDenied =>
      'Bitte erlaube Mikrofonzugriff, um die Sprachsuche zu verwenden.';

  @override
  String get inventoryManualAddVoiceSearchFailed =>
      'Sprachsuche konnte nicht gestartet werden. Bitte versuche es erneut.';

  @override
  String get inventoryManualAddAiSearchPer100CardTitle => 'PRO 100 G';

  @override
  String get inventoryManualAddStoreName => 'Manuell hinzugefügt';

  @override
  String get inventoryBarcodePortionDialogTitle => 'Verzehrte Menge eingeben';

  @override
  String get inventoryBarcodePortionDialogConfirmAction => 'Weiter';

  @override
  String get inventoryEmptyState =>
      'Noch keine Vorratsartikel vorhanden. Scanne einen Beleg oder füge Lebensmittel manuell hinzu.';

  @override
  String get inventoryFilteredEmptyState =>
      'Keine Artikel passen zu deiner Suche oder den aktiven Filtern.';

  @override
  String get inventoryLoadFailed =>
      'Vorratsartikel konnten nicht geladen werden.';

  @override
  String get inventoryRetryAction => 'Erneut versuchen';

  @override
  String get preparedMealSectionTitle => 'Mahlzeiten';

  @override
  String get preparedMealEditLockedHint =>
      'Von dieser Mahlzeit wurde schon gegessen. Zutaten und Portionen bleiben daher fest; Name und Bild kannst du ändern.';

  @override
  String get preparedMealNameLabel => 'Mahlzeitname';

  @override
  String get preparedMealClearNameAction => 'Namen leeren';

  @override
  String get preparedMealInvalidName => 'Bitte gib einen Mahlzeitnamen ein.';

  @override
  String get preparedMealFixFormErrorsMessage =>
      'Bitte prüfe die markierten Felder.';

  @override
  String get preparedMealInvalidPortionsRange =>
      'Bitte gib eine gültige Portionsanzahl im verfügbaren Bereich ein.';

  @override
  String get preparedMealImageLabel => 'Titelbild';

  @override
  String get preparedMealAddImageAction => 'Bild hinzufügen';

  @override
  String get preparedMealChangeImageAction => 'Bild ändern';

  @override
  String get preparedMealRemoveImageAction => 'Bild entfernen';

  @override
  String get preparedMealImageHint =>
      'Füge ein Foto für diese Mahlzeit hinzu oder nutze das Standard-Cover.';

  @override
  String get preparedMealImageCameraAction => 'Foto aufnehmen';

  @override
  String get preparedMealImagePickFailed =>
      'Das Mahlzeitenbild konnte nicht ausgewählt werden.';

  @override
  String get preparedMealImageTooLarge => 'Das ausgewählte Bild ist zu groß.';

  @override
  String get preparedMealIngredientsTitle => 'Zutaten';

  @override
  String get preparedMealEmptyIngredientsMessage =>
      'Füge vor dem Speichern mindestens eine Zutat hinzu.';

  @override
  String get preparedMealBindAction => 'Lebensmittel kombinieren';

  @override
  String get preparedMealSelectionNeedsStockFood =>
      'Wähle ein Lebensmittel aus dem Vorrat';

  @override
  String preparedMealSelectionCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get inventorySelectionCatalogSearch => 'Im Katalog suchen';

  @override
  String inventorySelectionCatalogSearchQuery(String query) {
    return '„$query“ im Katalog suchen';
  }

  @override
  String get inventorySelectionCatalogFoodRemove =>
      'Aus der Mahlzeit entfernen';

  @override
  String get preparedMealUpdatedMessage => 'Mahlzeit wurde aktualisiert.';

  @override
  String get preparedMealActionFailed =>
      'Mahlzeit-Aktion fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String preparedMealIngredientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zutaten',
      one: '1 Zutat',
    );
    return '$_temp0';
  }

  @override
  String get preparedMealPendingIngredientAddAction => 'Zutat ergänzen';

  @override
  String get preparedMealPendingIngredientIgnoreAction => 'Zutat ignorieren';

  @override
  String get preparedMealPendingIngredientSelectionTitle =>
      'Zutat aus dem Vorrat ergänzen';

  @override
  String get preparedMealPendingIngredientSelectionEmpty =>
      'Kein Artikel im Vorrat passt zu dieser Zutat.';

  @override
  String get preparedMealPendingIngredientSelectionUnitHint =>
      'Nur Artikel, die die Menge in ihrer Einheit liefern.';

  @override
  String get preparedMealPendingIngredientFillFailed =>
      'Zutat konnte nicht zur Mahlzeit hinzugefügt werden.';

  @override
  String get preparedMealPendingIngredientIgnoreFailed =>
      'Zutat konnte nicht ignoriert werden.';

  @override
  String get preparedMealPendingIngredientUnignoreAction =>
      'Nicht mehr ignorieren';

  @override
  String get preparedMealPendingIngredientUnignoreFailed =>
      'Zutat konnte nicht wieder geöffnet werden.';

  @override
  String get preparedMealUnassignAction => 'Zuordnung entfernen';

  @override
  String get preparedMealUnassignFailed =>
      'Zuordnung konnte nicht entfernt werden.';

  @override
  String get preparedMealEditDeleteRowAction => 'Zeile löschen';

  @override
  String preparedMealPortionsRemaining(String remaining, int total) {
    return '$remaining/$total Portionen';
  }

  @override
  String get preparedMealUnbundleAction => 'Auflösen';

  @override
  String get preparedMealWeightAction => 'Gewicht ändern';

  @override
  String get preparedMealWeightWholeHint =>
      'Wieg das ganze Gericht, am besten abgekühlt. Gramm pro Portion und je 100 g rechnen sich daraus neu.';

  @override
  String preparedMealWeightLeftHint(String portions, int total) {
    return 'Wieg, was noch da ist: $portions von $total Portionen. Gramm pro Portion und je 100 g rechnen sich daraus neu. Einträge im Tagebuch bleiben, wie sie sind.';
  }

  @override
  String get preparedMealWeightFoodLabel => 'Gewicht des Essens';

  @override
  String preparedMealWeightCurrent(int grams) {
    return 'Bisher $grams g';
  }

  @override
  String get preparedMealWeightInvalid =>
      'Bitte ein Gewicht in Gramm eingeben.';

  @override
  String get preparedMealWeightFailed =>
      'Das Gewicht konnte nicht gespeichert werden.';

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
  String get preparedMealTemplateNameSave => 'Speichern';

  @override
  String get preparedMealTemplateNoFoods =>
      'Kein Lebensmittel im Vorrat hat Bestand und vollständige Nährwerte.';

  @override
  String get preparedMealTemplateCreateFailed =>
      'Das Rezept konnte nicht gespeichert werden.';

  @override
  String get preparedMealTemplateSavedMessage => 'Rezept gespeichert.';

  @override
  String get preparedMealTemplatesLoadFailed =>
      'Rezepte konnten nicht geladen werden.';

  @override
  String get preparedMealTemplateDeletedMessage => 'Rezept gelöscht.';

  @override
  String get preparedMealTemplateAddRecipeAction => 'Rezept hinzufügen';

  @override
  String get preparedMealTemplateAddRecipeDescription =>
      'Ein Rezept von einer Webseite übernehmen';

  @override
  String get preparedMealTemplateCreateFromRecipeAction => 'Aus Rezept anlegen';

  @override
  String get preparedMealTemplateCreateFailedMessage =>
      'Rezept konnte nicht erstellt werden.';

  @override
  String get preparedMealTemplateRecipeImportFailedMessage =>
      'Rezeptdaten konnten nicht importiert werden.';

  @override
  String get preparedMealTemplateRecipeSheetTitle => 'Rezept anlegen';

  @override
  String get preparedMealTemplateRecipeSheetSubtitle =>
      'Füge einen Rezept-Link ein, zum Beispiel von Chefkoch.';

  @override
  String get preparedMealTemplateRecipeGreetingSubtitle =>
      'Kopiere die Web-Adresse deines Lieblingsrezepts und wir lesen alle Zutaten automatisch für dich aus.';

  @override
  String get preparedMealTemplateClipboardTitle =>
      'Aus Zwischenablage einfügen ✨';

  @override
  String get preparedMealTemplateClipboardPasteHelper =>
      'Hier tippen, um die Zwischenablage nach einem Rezept-Link zu durchsuchen.';

  @override
  String preparedMealTemplateClipboardPasteSuccess(String url) {
    return 'Rezept von $url eingefügt!';
  }

  @override
  String get preparedMealTemplateClipboardNoLinkFound =>
      'Kein gültiger Rezept-Link in der Zwischenablage gefunden.';

  @override
  String get preparedMealTemplateAdvancedOptionsTitle =>
      'Weitere Optionen (Optional)';

  @override
  String get preparedMealTemplateRecipeUrlLabel => 'Rezept-Link';

  @override
  String get preparedMealTemplateRecipeUrlHint => 'https://www.chefkoch.de/...';

  @override
  String get preparedMealTemplateRecipeUrlInvalid =>
      'Bitte gib einen gültigen Rezept-Link ein.';

  @override
  String get preparedMealTemplateNameLabel => 'Rezeptname';

  @override
  String get preparedMealTemplateNameHelper =>
      'Optional. Wenn leer, wird der Name aus dem Link abgeleitet.';

  @override
  String get preparedMealTemplatePortionsLabel => 'Portionen';

  @override
  String get preparedMealTemplatePortionsHelper =>
      'Optional. Wenn leer, werden die Portionen aus dem Rezept übernommen.';

  @override
  String get kitchenUtensilsPageTitle => 'Küchenutensilien';

  @override
  String get kitchenUtensilsToolLabel => 'Geräte';

  @override
  String get kitchenUtensilsEmptyState =>
      'Noch keine Küchenutensilien gespeichert.';

  @override
  String get kitchenUtensilsLoadFailed =>
      'Küchenutensilien konnten nicht geladen werden.';

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
  String get kitchenUtensilImageHint =>
      'Füge ein Foto oder einen Namen hinzu, damit du das Utensil später erkennst.';

  @override
  String get kitchenUtensilImagePickFailed =>
      'Foto konnte nicht ausgewählt werden.';

  @override
  String get kitchenUtensilImageUploadFailed =>
      'Foto konnte nicht hochgeladen werden.';

  @override
  String get kitchenUtensilSaveFailed =>
      'Utensil konnte nicht gespeichert werden.';

  @override
  String get kitchenUtensilDeleteFailed =>
      'Utensil konnte nicht gelöscht werden.';

  @override
  String get kitchenUtensilInvalidWeight =>
      'Bitte gib ein Gewicht größer als 0 ein.';

  @override
  String get kitchenUtensilIdentityRequired =>
      'Füge einen Namen oder ein Foto hinzu.';

  @override
  String get preparedMealTemplateImportReviewTitle => 'Rezept prüfen';

  @override
  String get preparedMealTemplateImportReviewInstructionsTitle =>
      'Kurze Anleitung';

  @override
  String get preparedMealTemplateImportReviewSavingAction => 'Speichert...';

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
  String get shoppingListInvalidNameError =>
      'Bitte einen Artikelnamen eingeben.';

  @override
  String get shoppingListAddFailedError =>
      'Artikel konnte nicht hinzugefügt werden. Bitte erneut versuchen.';

  @override
  String get shoppingListLoadFailed =>
      'Einkaufsartikel konnten nicht geladen werden.';

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
  String get shoppingListClearCrossedOffDialogTitle =>
      'Durchgestrichene Artikel löschen?';

  @override
  String get shoppingListClearCrossedOffDialogMessage =>
      'Alle durchgestrichenen Artikel werden von der Einkaufsliste entfernt.';

  @override
  String get shoppingListClearCrossedOffConfirmAction => 'Löschen';

  @override
  String get caloriesOcrFailed =>
      'Nährwertetikett konnte nicht erkannt werden.';

  @override
  String get caloriesOcrAppCheckThrottled =>
      'Nährwertscan ist vorübergehend blockiert. Bitte versuche es später erneut.';

  @override
  String get caloriesOcrRetakePhoto =>
      'Nicht alle Pflichtwerte der Nährwerttabelle waren sicher lesbar. Bitte fotografiere die ganze Tabelle scharf und ohne Spiegelung.';

  @override
  String get caloriesOcrRetakePhotoAction => 'Neues Foto';

  @override
  String get caloriesLoadFailed =>
      'Kalorien-Einträge konnten nicht geladen werden.';

  @override
  String get caloriesRetryAction => 'Erneut versuchen';

  @override
  String get caloriesAuthRequired =>
      'Bitte melde dich an, um Kalorien zu verwalten.';

  @override
  String get caloriesTodayAction => 'Heute';

  @override
  String get caloriesShiftGoalStartAction => 'Zielstart verschieben';

  @override
  String get caloriesCalculatorAction => 'Ziel neu berechnen';

  @override
  String get caloriesGoalSaveFailed =>
      'Kalorienziel konnte nicht gespeichert werden.';

  @override
  String get caloriesGoalStartDialogTitle => 'Zielstart verschieben';

  @override
  String get caloriesGoalStartDateLabel => 'Datum';

  @override
  String get caloriesGoalStartSaveFailed =>
      'Der Zielstart konnte nicht aktualisiert werden.';

  @override
  String get caloriesCalculatorSheetTitle => 'Kalorienrechner';

  @override
  String get caloriesCalculatorOnboardingSubtitle =>
      'Wir berechnen aus ein paar Angaben dein tägliches Kalorienziel.';

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
  String get caloriesCalculatorWeightInvalid =>
      'Bitte gib ein gültiges Gewicht ein.';

  @override
  String get caloriesCalculatorHeightLabel => 'Größe (cm)';

  @override
  String get caloriesCalculatorHeightEmpty => 'Bitte gib deine Größe ein.';

  @override
  String get caloriesCalculatorHeightInvalid =>
      'Bitte gib eine gültige Größe ein.';

  @override
  String get caloriesCalculatorAgeLabel => 'Alter (Jahre)';

  @override
  String get caloriesCalculatorAgeEmpty => 'Bitte gib dein Alter ein.';

  @override
  String get caloriesCalculatorAgeInvalid =>
      'Bitte gib ein gültiges Alter ein.';

  @override
  String get caloriesCalculatorActivityLevelLabel => 'Aktivitätslevel (PAL)';

  @override
  String get caloriesCalculatorActivityLevelHelp =>
      'Wähle, was zu deinem Alltag passt. Training zählt über die Trainingstage extra.';

  @override
  String get caloriesCalculatorActivityLevelNoneTitle => 'Kaum aktiv';

  @override
  String get caloriesCalculatorActivityLevelNoneDescription =>
      'Büro, viel sitzen, wenige Schritte.';

  @override
  String get caloriesCalculatorActivityLevelLowTitle => 'Leicht aktiv';

  @override
  String get caloriesCalculatorActivityLevelLowDescription =>
      'Überwiegend sitzend, aber mit etwas Bewegung im Alltag.';

  @override
  String get caloriesCalculatorActivityLevelMediumTitle => 'Moderat aktiv';

  @override
  String get caloriesCalculatorActivityLevelMediumDescription =>
      'Viel auf den Beinen, im Beruf oder im Alltag.';

  @override
  String get caloriesCalculatorActivityLevelHighTitle => 'Sehr aktiv';

  @override
  String get caloriesCalculatorActivityLevelHighDescription =>
      'Körperlich aktiver Beruf mit viel Laufen und Tragen.';

  @override
  String get caloriesCalculatorActivityLevelExtremeTitle => 'Extrem aktiv';

  @override
  String get caloriesCalculatorActivityLevelExtremeDescription =>
      'Schwere körperliche Arbeit den ganzen Tag.';

  @override
  String get caloriesCalculatorGoalModeLabel => 'Zielmodus';

  @override
  String get caloriesCalculatorGoalModeLose => 'Abnehmen';

  @override
  String get caloriesCalculatorGoalModeMaintain => 'Halten';

  @override
  String get caloriesCalculatorGoalModeGain => 'Zunehmen';

  @override
  String get caloriesCalculatorGoalSpeedLabel =>
      'Zielgeschwindigkeit (kg/Woche)';

  @override
  String get caloriesCalculatorGoalSpeedHint =>
      'Zum Beispiel 0,25, 0,5 oder 0,75';

  @override
  String get caloriesCalculatorGoalSpeedEmpty =>
      'Bitte gib eine Zielgeschwindigkeit ein.';

  @override
  String get caloriesCalculatorGoalSpeedInvalid =>
      'Bitte gib eine gültige Zielgeschwindigkeit ein.';

  @override
  String get tdeeWeightStatTrend => 'Trendgewicht';

  @override
  String get caloriesCalculatorTargetWeightLabel => 'Zielgewicht (kg)';

  @override
  String get caloriesMaintainUntilTitle => 'Gewicht halten bis';

  @override
  String get caloriesMaintainUntilUnlimited =>
      'Unbegrenzt – bis du ein neues Ziel setzt';

  @override
  String get caloriesMaintainUntilChoose => 'Enddatum wählen';

  @override
  String get caloriesMaintainUntilClear => 'Enddatum entfernen';

  @override
  String get caloriesGoalReachedTitle => 'Ziel erreicht!';

  @override
  String get caloriesGoalReachedBody =>
      'Du hast dein Zielgewicht erreicht. Möchtest du den aktuellen 7-Tage-Run fortsetzen oder jetzt ein neues Ziel setzen?';

  @override
  String get caloriesGoalReachedContinue => 'Run fortsetzen';

  @override
  String get caloriesGoalReachedNewGoal => 'Neues Ziel setzen';

  @override
  String get caloriesNewGoalTitle => 'Neues Ziel';

  @override
  String caloriesNewGoalStartsOn(String date) {
    return 'Tagesziel ab $date';
  }

  @override
  String caloriesNewGoalTdee(String kcal) {
    return 'TDEE $kcal kcal';
  }

  @override
  String caloriesNewGoalTargetDetail(String weight, String mode) {
    return 'Aktuelles Gewicht: $weight kg · $mode';
  }

  @override
  String get caloriesNewGoalTargetLabel => 'Zielgewicht';

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
  String get caloriesCalculatorGoalStartHint =>
      'Dein Kalorienziel-Verlauf beginnt ab diesem Tag.';

  @override
  String get caloriesCalculatorGoalStartChangeAction => 'Ändern';

  @override
  String caloriesCalculatorMinimumGoalWarning(int minimumKcal) {
    return 'Beim Abnehmen darf das tägliche Ziel nicht unter $minimumKcal kcal fallen. Das Ergebnis wurde auf dieses Minimum begrenzt.';
  }

  @override
  String get caloriesCalculatorSaveAction => 'Ziel speichern';

  @override
  String get caloriesCalculatorSaveFailed =>
      'Das berechnete Kalorienziel konnte nicht gespeichert werden.';

  @override
  String get caloriesGoalStartFoodTrackingTitle =>
      'Hast du dein Essen heute getrackt?';

  @override
  String caloriesGoalStartFoodTrackingBody(int entryCount) {
    return 'Ich habe heute $entryCount Essenseinträge gefunden. Soll heute als voller Tracking-Tag für dieses neue Ziel zählen?';
  }

  @override
  String get caloriesGoalStartNoFoodTrackingTitle =>
      'Heute kein Essen getrackt';

  @override
  String get caloriesGoalStartNoFoodTrackingBody =>
      'Heute wird ein Starter-Tag. Dein neues Ziel startet jetzt, aber das wöchentliche Lernen startet morgen.';

  @override
  String get caloriesGoalStartFoodTrackingNoAction => 'Frisch starten';

  @override
  String get caloriesGoalStartFoodTrackingYesAction => 'Heute mitzählen';

  @override
  String get caloriesGoalStartFoodTrackingOkAction => 'OK';

  @override
  String get caloriesLearnedTdeeSheetTitle =>
      'Ziel aus gelerntem TDEE neu berechnen';

  @override
  String get caloriesLearnedTdeeSheetSubtitle =>
      'Verwende deinen letzten erfolgreichen Wochen-Check-in statt einer Aktivitätsschätzung.';

  @override
  String get caloriesLearnedTdeeLabel => 'Gelernter TDEE';

  @override
  String get caloriesLearnedTdeeResultLabel => 'Neues Tagesziel';

  @override
  String get caloriesLearnedTdeeUseProfileResetAction =>
      'Profilbasierten Reset nutzen';

  @override
  String get caloriesLearnedTdeeSaveFailed =>
      'Das Ziel aus dem gelernten TDEE konnte nicht gespeichert werden.';

  @override
  String get caloriesLearnedTdeeRunRestartFailed =>
      'Ziel gespeichert, aber der Run konnte nicht neu starten.';

  @override
  String get caloriesWeeklyCheckInDialogTitle => 'Wochen-Check-in';

  @override
  String get caloriesWeeklyCheckInDialogBlockedBody =>
      'Uns fehlen noch ein paar Daten, bevor diese Wochenzusammenfassung vollständig ist.';

  @override
  String get caloriesWeeklyCheckInDialogLowConfidence =>
      'Niedrige Sicherheit: Es lagen nur Start- und Endgewicht vor.';

  @override
  String get caloriesWeeklyCheckInBlockedUnstableWeight =>
      'Die Gewichtsdaten waren diese Woche zu unruhig für ein verlässliches TDEE-Update. Füge gleichmäßigere Wiegewerte hinzu und versuche es erneut.';

  @override
  String get caloriesWeeklyCheckInLaterAction => 'Später';

  @override
  String get caloriesWeeklyCheckInApplyFailed =>
      'Der Wochen-Check-in konnte nicht geschlossen werden.';

  @override
  String get caloriesWeeklyCheckInRejectFailed =>
      'Der Wochen-Check-in konnte nicht abgelehnt werden.';

  @override
  String get caloriesWeeklyCheckInHintReadyTitle => 'Wochen-Check-in bereit';

  @override
  String get caloriesWeeklyCheckInHintReadyBody =>
      'Deine letzten 7 abgeschlossenen Tage sind bereit zur Prüfung.';

  @override
  String get caloriesWeeklyCheckInHintBlockedTitle =>
      'Wochen-Check-in braucht Daten';

  @override
  String get caloriesWeeklyCheckInHintBlockedBody =>
      'Ergänze fehlende Aufnahme- oder Gewichtsdaten, um die Zusammenfassung zu vervollständigen.';

  @override
  String get caloriesWeeklyCheckInHintContinueAction => 'Fortsetzen';

  @override
  String get caloriesWeeklyCheckInHintStaleTitle => 'Ziel wird alt';

  @override
  String get caloriesWeeklyCheckInHintStaleBody =>
      'Nutze den nächsten Wochen-Check-in, damit dein Ziel aktuell bleibt.';

  @override
  String get caloriesWeeklyCheckInHintUrgentTitle =>
      'Ziel braucht Aktualisierung';

  @override
  String get caloriesWeeklyCheckInHintUrgentBody =>
      'Du verwendest schon länger ältere Zieldaten.';

  @override
  String get caloriesWeeklyCheckInRedoAction => 'Check-in wiederholen';

  @override
  String get caloriesWeeklyCheckInShowAgainAction => 'Wochen-Check-in anzeigen';

  @override
  String get caloriesWeeklyCheckInShowAgainFailed =>
      'Der Wochen-Check-in konnte nicht erneut geöffnet werden.';

  @override
  String get caloriesWeeklyCheckInSkipDayAction =>
      'Tag als ausgelassen markieren';

  @override
  String get caloriesWeeklyCheckInUnskipDayAction =>
      'Ausgelassen-Markierung entfernen';

  @override
  String get caloriesWeeklyCheckInAutoAdjustedHint =>
      'Ziel durch Wochen-Check-in aktualisiert:';

  @override
  String get caloriesWeeklyCheckInTrackMissingWeightAction =>
      'Fehlendes Gewicht eintragen';

  @override
  String get caloriesWeeklyCheckInBlockedMissingIntake =>
      'Mindestens ein Tag in diesem Zeitraum hat noch keine Aufnahme. Trage ihn ein oder markiere 1 oder 2 leere Tage als ausgelassen.';

  @override
  String get caloriesWeeklyCheckInBlockedTooManyMissingIntake =>
      'Dieser Zeitraum hat 3 oder mehr fehlende Aufnahmetage. Wir behalten dein letztes gelerntes Ziel, bis du wieder mehr vollständige Tage geloggt hast.';

  @override
  String get caloriesWeeklyCheckInBlockedSkippedWithoutAverage =>
      'Ein ausgelassener Tag braucht frühere geloggte Aufnahme im selben Zeitraum, bevor wir ihn schätzen können.';

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
  String get caloriesGoalLabel => 'Ziel';

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
  String get caloriesDebugDumpCanceled =>
      'Kalorien-Debug-TXT-Download abgebrochen.';

  @override
  String get caloriesDebugDumpFailed =>
      'Kalorien-Debug-TXT konnte nicht heruntergeladen werden.';

  @override
  String get caloriesSettingsDebugDumpAction =>
      'Kalorien-Einstellungen als JSON ausgeben';

  @override
  String caloriesSettingsDebugDumpPrinted(int entryCount) {
    return 'Kalorien-Einstellungen-Debug-Ausgabe gedruckt ($entryCount Zieleinträge).';
  }

  @override
  String get caloriesSettingsDebugDumpFailed =>
      'Kalorien-Einstellungen-Debug-Ausgabe konnte nicht gedruckt werden.';

  @override
  String get caloriesWeeklyCheckInDebugDumpAction =>
      'Wochen-Check-in-Status ausgeben';

  @override
  String get caloriesWeeklyCheckInDebugDumpPrinted =>
      'Wochen-Check-in-Debug-Ausgabe gedruckt.';

  @override
  String get caloriesWeeklyCheckInDebugDumpFailed =>
      'Wochen-Check-in-Debug-Ausgabe konnte nicht gedruckt werden.';

  @override
  String burnWeekPracticeDayBadge(Object date) {
    return 'Übungstag · zählt ab $date';
  }

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
  String get diaryWeightSaveFailed =>
      'Gewicht konnte nicht gespeichert werden.';

  @override
  String get caloriesRemoveEntryAction => 'Eintrag entfernen';

  @override
  String get caloriesRemoveEntryDialogTitle => 'Eintrag entfernen';

  @override
  String get caloriesRemoveEntryDialogMessage =>
      'Möchtest du das Nahrungsmittel wieder in den Vorrat zurücklegen?';

  @override
  String get caloriesRemoveEntryPreparedMealMessage =>
      'Möchtest du die Mahlzeit wieder in den Vorrat zurücklegen?';

  @override
  String get caloriesRemoveEntryOnlyAction => 'Nur aus Tagebuch löschen';

  @override
  String get caloriesRemoveAndRestoreAction => 'In den Vorrat zurücklegen';

  @override
  String get caloriesReturnPreparedMealFailed =>
      'Die Mahlzeit konnte nicht zurück in den Vorrat gelegt werden.';

  @override
  String get caloriesDeleteRestoreFailed =>
      'Das Nahrungsmittel konnte nicht zurück in den Vorrat gelegt werden.';

  @override
  String get caloriesMissingInventorySourceDialogTitle =>
      'Nahrungsmittel nicht mehr im Vorrat';

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
  String get caloriesEntryDetailsTitle => 'Kalorien-Eintragsdetails';

  @override
  String get caloriesEntryUpdatedMessage => 'Eintrag aktualisiert';

  @override
  String get caloriesNutritionTableNutrient => 'Nährwert';

  @override
  String get caloriesNutritionTableEnergy => 'Brennwert';

  @override
  String get caloriesUnitKilojoule => 'kJ';

  @override
  String get caloriesNutritionTableSaturatedFat =>
      'davon gesättigte Fettsäuren';

  @override
  String get caloriesNutritionTablePolyunsaturatedFat =>
      'davon mehrfach ungesättigte Fettsäuren';

  @override
  String get caloriesNutritionTableSugar => 'davon Zucker';

  @override
  String get caloriesNutritionTableFiber => 'Ballaststoffe';

  @override
  String get caloriesNutritionTableSalt => 'Salz';

  @override
  String caloriesNutritionTableAtLeast(String value) {
    return 'mind. $value';
  }

  @override
  String get caloriesEntryDeletedMessage => 'Eintrag entfernt';

  @override
  String get caloriesEntryReturnedToInventoryMessage => 'Zurück im Vorrat';

  @override
  String get caloriesEatAgainDoneMessage => 'Nochmal eingetragen';

  @override
  String get caloriesEatAgainMissedStockMessage =>
      'Nochmal eingetragen. Dein Vorrat hat nicht gereicht und ist jetzt leer.';

  @override
  String get diaryEntryAgainAction => 'Nochmal';

  @override
  String caloriesEntryPer100Label(String unit) {
    return 'Je 100 $unit';
  }

  @override
  String get caloriesEntryAmountStockExhaustedMessage =>
      'Menge geändert. Dein Vorrat hat nicht gereicht und ist jetzt leer.';

  @override
  String get caloriesEntryAmountSourceMissingMessage =>
      'Menge geändert. Das Produkt ist nicht mehr in deinem Vorrat.';

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
  String get inventoryReceiptReviewManualAddNutritionAction =>
      'Weitere Nährwerte eintragen';

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
  String get caloriesPositiveNumberValidation =>
      'Bitte eine Zahl größer als null eingeben.';

  @override
  String get caloriesNonNegativeNumberValidation =>
      'Bitte eine Zahl größer oder gleich null eingeben.';

  @override
  String get caloriesMealBreakfast => 'Frühstück';

  @override
  String get caloriesMealLunch => 'Mittagessen';

  @override
  String get caloriesMealDinner => 'Abendessen';

  @override
  String get caloriesMealSnack => 'Snack';

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
  String get diaryJumpToTodayAction => 'Zu heute springen';

  @override
  String get diaryYesterdayTitle => 'Gestern';

  @override
  String get diaryTomorrowTitle => 'Morgen';

  @override
  String get diaryDayAfterTomorrowTitle => 'Übermorgen';

  @override
  String get diaryDayTypeTraining => 'Trainingstag';

  @override
  String get diaryDayTypeNormal => 'Normaler Tag';

  @override
  String get diaryDayTypePause => 'Pausentag';

  @override
  String get diaryDayTypeTrainingShort => 'Training';

  @override
  String get diaryDayTypeNormalShort => 'Normal';

  @override
  String get diaryDayTypePauseShort => 'Pause';

  @override
  String get diaryMealsLoadFailed => 'Mahlzeiten konnten nicht geladen werden';

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
  String get diaryQuickEatSourceQuickEntry => 'Schnell';

  @override
  String get diaryQuickEntryDefaultName => 'Schnelleintrag';

  @override
  String get diaryQuickEntryKcalLabel => 'Kalorien';

  @override
  String get diaryQuickEntryValuesHeader => 'Gegessen';

  @override
  String get diaryQuickEntryKcalMissing => 'Noch offen: Kalorien';

  @override
  String get diaryQuickEntryAiHint =>
      'Fehlende Makros zählen als 0 g. Die KI-Schätzung ist genauer.';

  @override
  String get diaryQuickEntryAiAction => 'Lieber mit KI schätzen';

  @override
  String get diaryQuickEntrySaved => 'Ins Tagebuch eingetragen';

  @override
  String diaryPlanSavedFor(String day) {
    return 'Für $day geplant';
  }

  @override
  String get diaryPlanSavedToday => 'heute';

  @override
  String get diaryPlanSavedTomorrow => 'morgen';

  @override
  String get diaryPlanSaved => 'Für den Tag geplant';

  @override
  String get diaryPlanDeleted => 'Plan gelöscht';

  @override
  String get diaryPlanDeleteFailed => 'Plan konnte nicht gelöscht werden';

  @override
  String get diaryPlanSaveAction => 'Plan speichern';

  @override
  String get diaryPlanChanged => 'Plan geändert';

  @override
  String get diaryPlanChangeFailed => 'Plan konnte nicht geändert werden';

  @override
  String get diaryPlanCopyAction => 'Auch planen für…';

  @override
  String get diaryPlanCopyTitle => 'Auch planen für';

  @override
  String diaryPlanCopyRange(String month) {
    return '$month · 2 Wochen';
  }

  @override
  String get diaryPlanCopyPlannedLegend => '• schon geplant';

  @override
  String get diaryPlanCopyMealLabel => 'Mahlzeit';

  @override
  String diaryPlanCopyConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage planen',
      one: '1 Tag planen',
      zero: 'Tage wählen',
    );
    return '$_temp0';
  }

  @override
  String diaryPlanCopyConfirmKcal(int count, int kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage planen',
      one: '1 Tag planen',
    );
    return '$_temp0 · $kcal kcal';
  }

  @override
  String diaryPlanCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'An $count weiteren Tagen geplant',
      one: 'An 1 weiteren Tag geplant',
    );
    return '$_temp0';
  }

  @override
  String get diaryMealCopyAction => 'Als Plan kopieren';

  @override
  String get diaryMealCopyPickMeal => 'Mahlzeit wählen';

  @override
  String get diaryMealCopyDaysLabel => 'Auf welche Tage';

  @override
  String get diaryPlanCopyFailed => 'Pläne konnten nicht gespeichert werden';

  @override
  String get diaryPlanSemanticsLabel => 'Plan';

  @override
  String get diaryPlanAcceptAction => 'Wie geplant gegessen';

  @override
  String get diaryPlanAccepted => 'Wie geplant gegessen';

  @override
  String get diaryPlanAcceptedWithoutStock =>
      'Eingetragen – nicht mehr im Vorrat';

  @override
  String get diaryPlanAcceptedRecipe => 'Eingetragen – Vorrat nicht abgezogen';

  @override
  String get diaryPlanAcceptFailed => 'Plan konnte nicht eingetragen werden';

  @override
  String get diaryPlanRemoveAction => 'Aus Plan entfernen';

  @override
  String diaryOverduePlansHint(int count, String day) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Offene Pläne an $count Tagen, zuletzt $day',
      one: 'Offene Pläne vom $day',
    );
    return '$_temp0';
  }

  @override
  String get diaryPlanAcceptLaterHint => 'Ab dem geplanten Tag';

  @override
  String get diaryPlanAcceptAllAction => 'Alle wie geplant gegessen';

  @override
  String diaryPlansAccepted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pläne gegessen',
      one: '1 Plan gegessen',
    );
    return '$_temp0';
  }

  @override
  String diaryPlansAcceptedPartly(int eaten, int total) {
    return '$eaten von $total Plänen gegessen';
  }

  @override
  String diaryPlansAcceptedWithoutStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pläne gegessen – nicht alles aus dem Vorrat',
      one: '1 Plan gegessen – nicht alles aus dem Vorrat',
    );
    return '$_temp0';
  }

  @override
  String get diaryPlanAcceptMealInPot =>
      'Erst das Gericht als „Gekocht“ eintragen';

  @override
  String get diaryPlanAcceptMealGone => 'Das Gericht ist nicht mehr im Vorrat';

  @override
  String get diaryPlanAcceptNutritionPending =>
      'Erst die offenen Zeilen des Gerichts füllen';

  @override
  String get diaryPlanAcceptRecipePending =>
      'Erst alle Zutaten des Rezepts einem Vorrat zuordnen';

  @override
  String get diaryPlanAcceptRecipeGone =>
      'Das Rezept ist nicht mehr im Kochbuch';

  @override
  String get diaryPlanNutritionPending => 'kcal offen';

  @override
  String get diaryPlanShortTag => 'Fehlt im Vorrat';

  @override
  String get diaryPlanMealPrepTag => 'Meal Prep';

  @override
  String get diaryBalanceLoadFailed => 'Balance konnte nicht geladen werden';

  @override
  String get diaryBalanceEatenLabel => 'Gegessen';

  @override
  String get diaryBalanceLeftLabel => 'Übrig';

  @override
  String get diaryBalanceAfterPlanChip => 'Nach Plan';

  @override
  String get diaryBalanceLeftAfterPlanLabel => 'Übrig nach Plan';

  @override
  String get diaryMealsEmptyTitle => 'Noch nichts gegessen';

  @override
  String get diaryMealsEmptyHint =>
      'Über „Essen“ unten per Barcode, Vorrat, Suche oder KI eintragen.';

  @override
  String get diaryMealsPlanEmptyTitle => 'Noch nichts geplant';

  @override
  String get diaryMealsPlanEmptyHint =>
      'Über „Essen“ unten trägst du ein, was du an diesem Tag essen willst.';

  @override
  String diaryMacroEatenOfTarget(String eaten, String target) {
    return '$eaten / $target g';
  }

  @override
  String diaryMealEntryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
    );
    return '$_temp0';
  }

  @override
  String progressGoalAverageKcal(String kcal) {
    return 'Ø $kcal kcal/Tag';
  }

  @override
  String progressGoalAboveStart(String kg) {
    return '$kg kg über Start';
  }

  @override
  String progressGoalBelowStart(String kg) {
    return '$kg kg unter Start';
  }

  @override
  String get progressAveragePerDay => 'Schnitt pro Tag';

  @override
  String get progressScopeGoal => 'Aktuelles Ziel';

  @override
  String get progressScopeAll => 'Gesamt';

  @override
  String get progressScopePastGoal => 'Ziel';

  @override
  String progressRunKicker(int run, int day, int total) {
    return 'Run $run · Tag $day von $total';
  }

  @override
  String get progressDayTypeKickerGoal => 'Seit Zielstart · Schnitt';

  @override
  String progressDayTypeKickerPastGoal(int number) {
    return 'Ziel $number · Schnitt';
  }

  @override
  String get progressDayTypeKickerAll => 'Alle Ziele · Schnitt';

  @override
  String progressGoalMarker(int number) {
    return 'Ziel $number';
  }

  @override
  String progressGoalMenuRunning(int number) {
    return 'Ziel $number · läuft';
  }

  @override
  String progressGoalMenuSince(String date) {
    return 'seit $date';
  }

  @override
  String progressGoalMenuRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String progressGoalWeightValue(String weight) {
    return '$weight kg';
  }

  @override
  String get progressGoalSpeedLabel => 'Geschwindigkeit';

  @override
  String progressGoalSpeedValue(String speed) {
    return '$speed kg/Woche';
  }

  @override
  String get progressGoalStartLabel => 'Start';

  @override
  String get progressGoalStartWeightLabel => 'Startgewicht';

  @override
  String get progressGoalEndWeightLabel => 'Endgewicht';

  @override
  String get progressGoalEndLabel => 'Ende';

  @override
  String get progressGoalReachedLabel => 'Erreicht';

  @override
  String progressWeekKicker(String start, String end) {
    return '$start – $end';
  }

  @override
  String progressGoalKcal(String kcal) {
    return 'Ziel $kcal';
  }

  @override
  String progressKcalUnderGoal(String kcal) {
    return '$kcal unter Ziel';
  }

  @override
  String progressKcalOverGoal(String kcal) {
    return '$kcal über Ziel';
  }

  @override
  String progressWeekBudgetKicker(String start, String end) {
    return 'Wochenbudget · $start – $end';
  }

  @override
  String progressWeekBudgetValue(String eaten, String goal) {
    return '$eaten / $goal kcal';
  }

  @override
  String progressWeekBudgetLeft(String kcal) {
    return 'noch $kcal kcal';
  }

  @override
  String progressWeekBudgetOver(String kcal) {
    return '$kcal kcal drüber';
  }

  @override
  String get progressDayBarLegend => 'Balken = Tagesziel in Vierteln';

  @override
  String progressMacroGoal(String grams) {
    return 'Ziel $grams g';
  }

  @override
  String progressGrams(String grams) {
    return '$grams g';
  }

  @override
  String get progressWeightKicker => 'Gewicht · Trend';

  @override
  String progressWeightPerWeek(String kg) {
    return '$kg kg / Woche';
  }

  @override
  String progressWeightForecast(String date) {
    return 'voraussichtlich $date';
  }

  @override
  String get progressWeightGoalReached => 'Ziel erreicht';

  @override
  String get progressWeightLegendWeighIn => 'Messung';

  @override
  String get progressWeightLegendTrend => 'Trend';

  @override
  String get progressWeightEmpty => 'Keine Messung in den letzten vier Wochen.';

  @override
  String get progressToday => 'heute';

  @override
  String get progressTdeeKicker => 'TDEE · täglich';

  @override
  String progressTdeeChange(String kcal) {
    return '$kcal seit gestern';
  }

  @override
  String progressTdeeWeekChange(String kcal) {
    return '$kcal diese Woche';
  }

  @override
  String progressTdeeNextCheckIn(String date) {
    return 'nächster Check-in $date';
  }

  @override
  String get progressTdeeCheckInOpen => 'Check-in wartet im Tagebuch';

  @override
  String get progressTdeeLegendLine => 'TDEE';

  @override
  String get progressTdeeLegendDay => 'Tageswert';

  @override
  String get progressTdeeLegendCheckIn => 'Check-in';

  @override
  String get progressTdeeEmpty => 'Die Kurve beginnt mit deinem ersten Ziel.';

  @override
  String get progressDayTypeTitle => 'Training vs. normaler Tag';

  @override
  String progressDayTypeDays(String emoji, String type, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$emoji $type · $_temp0';
  }

  @override
  String progressKcal(String kcal) {
    return '$kcal kcal';
  }

  @override
  String get progressEaten => 'Gegessen';

  @override
  String get progressDayTypeEmpty =>
      'Trag ein paar Tage ein, dann siehst du Training und normale Tage im Vergleich.';

  @override
  String get progressLoadFailed =>
      'Dieser Bereich konnte nicht geladen werden.';

  @override
  String get diaryBalanceBaseLabel => 'Basis';

  @override
  String get diaryBalancePlannedLabel => 'Geplant';

  @override
  String diaryPreviousDayCloseAction(String weekday) {
    return '$weekday abschließen';
  }

  @override
  String diaryPreviousDayClosed(String weekday) {
    return '$weekday abgeschlossen';
  }

  @override
  String get diaryDayTypeSaveFailed => 'Tagesart konnte nicht geändert werden.';

  @override
  String diaryPreviousDayCloseFailed(String weekday) {
    return '$weekday konnte nicht abgeschlossen werden.';
  }

  @override
  String diaryPreviousDayReopenFailed(String weekday) {
    return '$weekday konnte nicht wieder geöffnet werden.';
  }

  @override
  String diaryPreviousDayReopenAction(String weekday) {
    return '$weekday wieder öffnen';
  }

  @override
  String diaryBalanceRealLeftLabel(Object kcal) {
    return 'Echt $kcal';
  }

  @override
  String get diaryBalancePauseDayValue => 'Pausentag';

  @override
  String get diaryBalancePauseDaySubtitle => 'Fürs Lernen ignoriert';

  @override
  String get diaryBudgetDetailsTitle => 'Tagesbudget-Details';

  @override
  String get diaryBudgetDetailsButtonLabel => 'Details';

  @override
  String get diaryBudgetDetailsTodaySectionTitle => 'Tagesrechnung';

  @override
  String get diaryBudgetDetailsWeeklyAverageGoalLabel =>
      'Basisziel (Wochenschnitt)';

  @override
  String get diaryBudgetDetailsTrainingDayAdjustmentLabel =>
      'Trainingstag-Anpassung';

  @override
  String get diaryBudgetDetailsRestDayAdjustmentLabel =>
      'Normaler-Tag-Anpassung';

  @override
  String get diaryBudgetDetailsBaseGoalLabel => 'Basis-Tagesziel';

  @override
  String get diaryBudgetDetailsBaseGoalWithoutActivityLabel =>
      'Basis-Tagesziel (ohne Aktivität)';

  @override
  String get diaryBudgetDetailsExpectedActivityLabel => 'Vermutete Aktivität';

  @override
  String get diaryBudgetDetailsCarryoverLabel => 'Übertrag aus Vortagen';

  @override
  String get diaryBudgetDetailsEffectiveGoalLabel => 'Effektives Tagesziel';

  @override
  String get diaryBudgetDetailsEatenLabel => 'Bisher gegessen';

  @override
  String get diaryBudgetDetailsPlannedLabel => 'Offene Pläne';

  @override
  String get diaryBudgetDetailsLeftLabel => 'Noch übrig';

  @override
  String get diaryBudgetDetailsCarryoverSectionTitle =>
      'Übertrag aus den Vortagen';

  @override
  String get diaryBudgetDetailsCarryoverExplanation =>
      'Der Übertrag ist die Bilanz abgeschlossener Tage, verteilt auf die verbleibenden Tage dieses 7-Tage-Runs.';

  @override
  String get diaryBudgetDetailsDaySavedLabel => 'eingespart';

  @override
  String get diaryBudgetDetailsDayOverLabel => 'überzogen';

  @override
  String get diaryBudgetDetailsDayExactLabel => 'Ziel erreicht';

  @override
  String get diaryBudgetDetailsPauseDayLabel => 'Pausentag';

  @override
  String get diaryBudgetDetailsTotalCarryoverLabel => 'Gesamtbilanz Vortage';

  @override
  String diaryBudgetDetailsDistributionFormula(
    String total,
    int days,
    String daily,
  ) {
    return '$total aufgeteilt auf $days verbleibende Tage = $daily / Tag';
  }

  @override
  String diaryBudgetDetailsMacroAdjustment(String carbs, String fat) {
    return 'Makro-Anpassung: Carbs $carbs · Fett $fat';
  }

  @override
  String get diaryBudgetDetailsSafetyCapActive =>
      'Schutzregel aktiv: Tageskürzung wurde begrenzt, um Heißhunger zu verhindern.';

  @override
  String get diaryBudgetDetailsNoPreviousDays =>
      'Dies ist der erste Tag deines aktuellen Laufs. Es gibt noch keinen Übertrag.';

  @override
  String get diaryActivityTitle => 'Aktivität';

  @override
  String get diaryWeightTitle => 'Gewicht';

  @override
  String get diarySevenDaysLabel => '7 Tage';

  @override
  String diaryProfileWeightLabel(String weight) {
    return 'Profil: $weight kg';
  }

  @override
  String get diaryWeightMissingPrompt =>
      'Trage dein Gewicht ein für bessere Berechnung.';

  @override
  String get diaryWeightTrackNowAction => 'JETZT TRACKEN';

  @override
  String get diaryWeightAddAction => 'Gewicht eintragen';

  @override
  String get diaryOkAction => 'OK';

  @override
  String diaryCounterLabel(int count) {
    return 'x $count';
  }

  @override
  String get diaryStepsTitle => 'Schritte';

  @override
  String get diaryStepsLoadFailed => 'Schritte konnten nicht geladen werden';

  @override
  String get diaryStepDetailsTitle => 'Schritte Details';

  @override
  String get diaryStepsDuringOtherActivityLabel => 'Sonstige aktive Schritte';

  @override
  String caloriesCombinedFoodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Lebensmittel',
      one: '1 Lebensmittel',
    );
    return '$_temp0';
  }

  @override
  String get caloriesCombinedEntryLabel => 'Kombiniert';

  @override
  String caloriesCountedPortion(
    String count,
    String amount,
    String unit,
    String label,
  ) {
    return '$count× $amount $unit $label';
  }

  @override
  String caloriesBundlePortions(String consumed, int total) {
    return '$consumed/$total Portionen';
  }

  @override
  String get homeSettingsActionContextPlaceholder =>
      'Einstellungsaktion folgt bald.';

  @override
  String get settingsManagePreferencesSubtitle =>
      'Verwalte deine Einstellungen';

  @override
  String get settingsProfileGuestSubtitle => 'Gastmodus';

  @override
  String get settingsProfileSummaryHeightLabel => 'Größe';

  @override
  String settingsProfileSummaryHeightValue(String height) {
    return '$height cm';
  }

  @override
  String get settingsProfileSummaryAgeLabel => 'Alter';

  @override
  String settingsProfileSummaryAgeValue(int age) {
    String _temp0 = intl.Intl.pluralLogic(
      age,
      locale: localeName,
      other: '$age Jahre',
      one: '1 Jahr',
    );
    return '$_temp0';
  }

  @override
  String get settingsProfileSummaryNoProfile =>
      'Noch keine Körperdaten. Der Kalorienrechner speichert sie.';

  @override
  String settingsProfileSummaryCaloriesValue(String kcal) {
    return '$kcal kcal/Tag';
  }

  @override
  String settingsProfileSummaryWeightValue(String weight) {
    return '$weight kg';
  }

  @override
  String get settingsProfileSummaryLoadFailed =>
      'Profil konnte nicht geladen werden.';

  @override
  String get settingsAccountHouseholdSectionTitle => 'Haushalt';

  @override
  String get settingsHealthGoalsSectionTitle => 'Health & Ziele';

  @override
  String get settingsMacroGoalsTitle => 'Makronährstoff-Ziele';

  @override
  String get settingsMacroGoalsSubtitle =>
      'Eiweiß-, Fett- & Kohlenhydrate-Verteilung';

  @override
  String get settingsMacroGoalsSheetTitle => 'Makronährstoff-Verteilung';

  @override
  String get settingsMacroGoalsSportActiveLabel => 'Sportlich aktiv';

  @override
  String get settingsMacroGoalsSportActiveSubtitle =>
      'Passt die Empfehlungen an Training an';

  @override
  String get settingsMacroGoalsProteinLabel => 'Protein-Multiplikator';

  @override
  String get settingsMacroGoalsFatLabel => 'Fett-Multiplikator';

  @override
  String settingsMacroGoalsCarbsAutoLabel(int percent) {
    return 'Kohlenhydrate füllen die restlichen Kalorien auf, höchstens $percent %';
  }

  @override
  String macroAdjustedWeightNote(String weight) {
    return 'Für Eiweiß und Fett rechnen wir mit einem angepassten Körpergewicht von $weight kg, weil Fettgewebe kaum Eiweiß braucht. Das sind Richtwerte, keine medizinische Beratung. Bei starkem Übergewicht oder Vorerkrankungen wie Diabetes oder Nierenproblemen sprich deine Ernährung mit deiner Ärztin oder deinem Arzt ab.';
  }

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
  String get settingsMacroGoalsWarningBudgetExceeded =>
      'Eiweiß und Fett übersteigen das Tages-Kalorienziel';

  @override
  String get settingsAppearanceSectionTitle => 'Darstellung';

  @override
  String get settingsAppSectionTitle => 'App';

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsLanguageEnglish => 'Englisch';

  @override
  String get settingsLanguageGerman => 'Deutsch';

  @override
  String get settingsThemeModeTitle => 'Design';

  @override
  String get settingsThemeModeSystem => 'System';

  @override
  String get settingsThemeModeLight => 'Hell';

  @override
  String get settingsThemeModeDark => 'Dunkel';

  @override
  String get settingsAccentTitle => 'Akzentfarbe';

  @override
  String get settingsAccentLime => 'Limette';

  @override
  String get settingsAccentPink => 'Pink';

  @override
  String get settingsAccentViolet => 'Violett';

  @override
  String get settingsAccentCyan => 'Cyan';

  @override
  String get settingsAccentEmerald => 'Smaragd';

  @override
  String get settingsDesignCustom => 'Individuell';

  @override
  String get settingsCustomBaseTitle => 'Worauf aufbauen?';

  @override
  String get settingsCustomBaseMessage =>
      'Individuell startet als Kopie. Danach kannst du jede Farbe ändern.';

  @override
  String get settingsCustomColorsTitle => 'Farben bearbeiten';

  @override
  String get settingsCustomColorsBasedOnLight => 'Aufgebaut auf Hell';

  @override
  String get settingsCustomColorsBasedOnDark => 'Aufgebaut auf Dunkel';

  @override
  String get settingsCustomColorsReset => 'Farben zurücksetzen';

  @override
  String get settingsCustomColorsUndo => 'Letzte Änderung rückgängig';

  @override
  String get settingsCustomColorApply => 'Übernehmen';

  @override
  String get settingsCustomColorRecent => 'Zuletzt';

  @override
  String settingsCustomColorRecentSwatch(String hex) {
    return 'Zuletzt verwendet: $hex';
  }

  @override
  String get settingsCustomAllMacrosColored => 'Makros immer bunt';

  @override
  String get settingsCustomAllMacrosColoredHint =>
      'Aus: nur das niedrigste Makro ist farbig';

  @override
  String get settingsCustomColorPaper => 'Hintergrund';

  @override
  String get settingsCustomColorCard => 'Karten';

  @override
  String get settingsCustomColorInk => 'Text';

  @override
  String get settingsCustomColorMuted => 'Nebentext';

  @override
  String get settingsCustomColorLines => 'Linien';

  @override
  String get settingsCustomColorAccent => 'Akzent';

  @override
  String get settingsCustomColorPlan => 'Plan';

  @override
  String get settingsCustomColorSignal => 'Signal';

  @override
  String get settingsCustomPreviewCurry => 'Linsen-Curry';

  @override
  String get settingsCustomPreviewBar => 'Proteinriegel';

  @override
  String get settingsCustomPreviewLogged => 'Curry gebucht';

  @override
  String get settingsCustomPreviewScan => 'Scannen';

  @override
  String get colorPickerHue => 'Farbton';

  @override
  String get colorPickerSaturation => 'Sättigung';

  @override
  String get colorPickerBrightness => 'Helligkeit';

  @override
  String colorPickerPercent(int value) {
    return '$value %';
  }

  @override
  String colorPickerDegrees(int value) {
    return '$value°';
  }

  @override
  String get settingsDiaryGoalSetGoalFirst => 'Zuerst Ziel setzen';

  @override
  String get settingsPrivacyTitle => 'Datenschutz';

  @override
  String get settingsPrivacySubtitle => 'Berechtigungen und Daten verwalten';

  @override
  String get settingsHouseholdTitle => 'Haushalt';

  @override
  String get settingsHouseholdSubtitle =>
      'Mitglieder einladen und geteilten Zugriff verwalten';

  @override
  String get settingsAccountTitle => 'Konto';

  @override
  String get settingsHealthConnectPlatformTitle => 'Health Connect';

  @override
  String get settingsHealthConnectTitle => 'Health verbinden';

  @override
  String get settingsHealthConnectSubtitle =>
      'Erlaube YAMT, dein Gewicht in Health Connect zu lesen und zu speichern.';

  @override
  String get settingsAppleHealthTitle => 'Apple Health';

  @override
  String get settingsAppleHealthConnectSubtitle =>
      'Erlaube YAMT, dein Gewicht in Apple Health zu lesen und zu speichern.';

  @override
  String get settingsHealthHistorySubtitle =>
      'Erlaube ältere Health-Connect-Historie, damit frühere Wiegungen laden.';

  @override
  String get settingsHealthInstallSubtitle =>
      'Installiere Health Connect, bevor du hier Gesundheitsdaten verbinden kannst.';

  @override
  String get settingsHealthDisconnectSubtitle =>
      'Entferne den Health-Connect-Zugriff für YAMT.';

  @override
  String get settingsAppleHealthDisconnectSubtitle =>
      'Stoppe die Nutzung von Apple Health in YAMT.';

  @override
  String get settingsHealthDisconnectDialogTitle => 'Health-Zugriff trennen?';

  @override
  String get settingsHealthDisconnectDialogBody =>
      'YAMT verliert den Zugriff auf Health Connect, bis du es erneut verbindest.';

  @override
  String get settingsAppleHealthDisconnectDialogBody =>
      'YAMT nutzt Apple-Health-Daten nicht mehr, bis du es erneut verbindest. Die Apple-Health-Berechtigungen auf deinem iPhone bleiben unverändert.';

  @override
  String get settingsHealthDisconnectAction => 'Trennen';

  @override
  String get settingsHealthDisconnectSuccess =>
      'Health-Zugriff getrennt. Starte YAMT neu, bevor du Health Connect erneut verbindest.';

  @override
  String get settingsAppleHealthDisconnectSuccess =>
      'Apple Health in YAMT getrennt. Du kannst es jederzeit in den Einstellungen wieder verbinden.';

  @override
  String get settingsHealthDisconnectOpenedSettings =>
      'Einstellungen geöffnet, damit du den Apple-Health-Zugriff verwalten kannst.';

  @override
  String get settingsHealthDisconnectFailed =>
      'Health-Zugriff konnte nicht getrennt werden.';

  @override
  String get settingsHealthConnectFailed =>
      'Health-Zugriff konnte nicht verbunden werden.';

  @override
  String get accountPageNoSession => 'Keine aktive Kontositzung.';

  @override
  String get accountPageGuestTitle => 'Gastkonto';

  @override
  String get accountPageGuestDescription =>
      'Verknüpfe dein Gastkonto mit Google, um den Zugriff geräteübergreifend zu behalten.';

  @override
  String get accountPageLinkGoogle => 'Mit Google verknüpfen';

  @override
  String get accountPageLinkEmailPassword => 'Mit E-Mail & Passwort verknüpfen';

  @override
  String get accountPageLinkEmailPasswordTitle => 'Gastkonto verknüpfen';

  @override
  String get accountPageLinkEmailPasswordDescription =>
      'Lege E-Mail-Anmeldedaten für dieses Gastkonto an.';

  @override
  String get accountPageLinkEmailPasswordConfirmAction => 'Konto verknüpfen';

  @override
  String get healthInstallAction => 'Health Connect installieren';

  @override
  String get healthHistoryAction => 'Ältere Historie erlauben';

  @override
  String get healthUnsupportedHint =>
      'Health Connect oder Apple Health ist auf diesem Gerät nicht verfügbar.';

  @override
  String get accountPageLinkSuccess => 'Konto erfolgreich verknüpft.';

  @override
  String get accountPageLinkNotCompleted =>
      'Die Kontoverknüpfung wurde nicht abgeschlossen. Bitte erneut versuchen.';

  @override
  String get accountPageLinkConflictTitle => 'Konto bereits vergeben';

  @override
  String get accountPageLinkConflictDescription =>
      'Diese Anmeldeinformation ist bereits mit einem anderen Profil verknüpft. Wähle, wie du fortfahren möchtest.';

  @override
  String get accountPageLinkConflictOverwriteAction =>
      'Mit diesem Gastkonto überschreiben';

  @override
  String get accountPageLinkConflictOverwriteSubtitle =>
      'Dieses Gastkonto behalten und das alte verknüpfte Konto ersetzen.';

  @override
  String get accountPageLinkConflictDeleteGuestAction =>
      'Gastkonto löschen und anmelden';

  @override
  String get accountPageLinkConflictDeleteGuestSubtitle =>
      'Dieses Gastkonto löschen und mit dem bestehenden Konto weitermachen.';

  @override
  String get accountPageLinkConflictOverwriteDone =>
      'Anmeldeinformation wurde auf dieses Gastkonto übertragen.';

  @override
  String get accountPageLinkConflictDeleteGuestDone =>
      'Gastkonto gelöscht. Mit bestehendem Konto angemeldet.';

  @override
  String get accountPageGuestSessionRequired =>
      'Diese Aktion ist nur für Gastkonten verfügbar.';

  @override
  String get accountPageSignOut => 'Abmelden';

  @override
  String get accountPageDeleteAction => 'Konto löschen';

  @override
  String get accountPageDeleteDialogTitle => 'Konto löschen?';

  @override
  String get accountPageDeleteDialogMessage =>
      'Dadurch wird dein Konto dauerhaft gelöscht und kann nicht rückgängig gemacht werden.';

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
  String get householdJoinLinkLabel => 'Einladungslink';

  @override
  String get householdJoinLinkHint => 'Link einfügen oder QR-Code scannen';

  @override
  String get householdJoinAction => 'Beitreten';

  @override
  String get householdJoinSuccess => 'Haushalt beigetreten.';

  @override
  String get householdJoinInvalidCode => 'Ungültige Einladung.';

  @override
  String get householdJoinExpiredCode => 'Diese Einladung ist abgelaufen.';

  @override
  String get householdJoinOwnCode => 'Du bist schon in diesem Haushalt.';

  @override
  String get householdJoinNameDialogTitle => 'Name angeben';

  @override
  String get householdJoinNameDialogMessage =>
      'Bitte gib deinen Namen ein, damit andere Haushaltsmitglieder dich erkennen können.';

  @override
  String get householdJoinNameDialogFieldLabel => 'Dein Name';

  @override
  String get householdJoinNameDialogRequiredError =>
      'Bitte gib einen Namen ein.';

  @override
  String get householdJoinNameDialogAction => 'Speichern & Beitreten';

  @override
  String get householdInviteCreate => 'Mitglieder einladen';

  @override
  String get householdInviteValidFor => 'Für eine Person, 24 Stunden gültig';

  @override
  String get householdInviteCopyLink => 'Link kopieren';

  @override
  String get householdInviteLinkCopied => 'Link kopiert.';

  @override
  String get householdInviteRefresh => 'Neue Einladung erstellen';

  @override
  String get householdInviteVerificationRequired =>
      'Verknüpfe dein Konto erst mit Google oder E-Mail, bevor du Leute einlädst.';

  @override
  String get householdJoinScanQr => 'QR-Code scannen';

  @override
  String get householdKeyUnavailable =>
      'Dein Schlüssel wird noch geladen. Versuche es gleich noch einmal.';

  @override
  String householdKeyRestoreMemberMessage(Object name) {
    return '$name hat neu gestartet und kann den gemeinsamen Vorrat nicht mehr lesen. Erstelle einen Freigabe-Code und gib ihn weiter.';
  }

  @override
  String get householdKeyRestoreCodeLabel => 'Freigabe-Code';

  @override
  String get householdKeyRestoreAction => 'Vorrat freigeben';

  @override
  String get householdKeyRestoreSuccess => 'Vorrat freigegeben.';

  @override
  String get householdKeyRestoreInvalidCode =>
      'Dieser Freigabe-Code passt nicht.';

  @override
  String get householdKeyRestoreCreateAction => 'Freigabe-Code erstellen';

  @override
  String householdKeyRestoreCodeHint(Object name) {
    return 'Gib diesen Code an $name weiter. Er gilt, bis er benutzt wird oder du einen neuen erstellst.';
  }

  @override
  String get householdKeyRestoreCopyAction => 'Code kopieren';

  @override
  String get householdKeyRestoreCopied => 'Code kopiert.';

  @override
  String get householdHostVerificationHint =>
      'Um andere Personen in deinen Haushalt einzuladen, verknüpfe dein Gastkonto mit Google oder E-Mail & Passwort.';

  @override
  String get householdRemoveMemberTitle => 'Mitglied entfernen?';

  @override
  String householdRemoveMemberMessage(Object name) {
    return '$name aus diesem Haushalt entfernen? Die gemeinsamen Sachen bleiben hier.';
  }

  @override
  String get householdRemoveMemberAction => 'Entfernen';

  @override
  String get householdRemoveMemberSuccess => 'Mitglied entfernt.';

  @override
  String get householdLeaveTitle => 'Haushalt verlassen?';

  @override
  String get householdLeaveMessage =>
      'Du wechselst zurück in deinen eigenen Haushalt. Die gemeinsamen Sachen bleiben hier.';

  @override
  String get householdLeaveAction => 'Haushalt verlassen';

  @override
  String get householdLeaveSuccess => 'Haushalt verlassen.';

  @override
  String get householdActionFailed =>
      'Haushaltsaktion fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get householdLoadFailed => 'Haushalt konnte nicht geladen werden.';

  @override
  String get householdKeyRestoreSelfMessage =>
      'Du hast neu gestartet, darum ist der Vorrat dieses Haushalts gesperrt. Lass dir von einem anderen Mitglied einen Freigabe-Code geben und gib ihn hier ein.';

  @override
  String get householdAdminBadge => 'Admin';

  @override
  String householdMemberSelf(Object name) {
    return '$name (du)';
  }

  @override
  String get householdMemberNoName => 'Ohne Namen';

  @override
  String get householdMemberActions => 'Mitglied verwalten';

  @override
  String get householdMakeAdminAction => 'Zum Admin machen';

  @override
  String householdMakeAdminTitle(Object name) {
    return '$name zum Admin machen?';
  }

  @override
  String householdMakeAdminMessage(Object name) {
    return '$name lädt dann Mitglieder ein und entfernt sie. Du bleibst als Mitglied im Haushalt.';
  }

  @override
  String householdMakeAdminSuccess(Object name) {
    return '$name ist jetzt Admin.';
  }

  @override
  String get householdMemberNotFound =>
      'Diese Person ist nicht mehr im Haushalt.';

  @override
  String get householdChanged =>
      'Der Haushalt hat sich inzwischen geändert. Prüfe ihn und versuche es erneut.';

  @override
  String get householdAdminOnly => 'Das kann nur der Admin.';

  @override
  String get householdJoinLeaveFirst =>
      'Verlasse erst deinen geteilten Haushalt, bevor du einem anderen beitrittst.';

  @override
  String get householdLeaveOwnMessage =>
      'Du bekommst einen neuen, leeren Haushalt. Die anderen behalten alles hier.';

  @override
  String get householdLeaveSuccessorLabel =>
      'Wer leitet den Haushalt nach dir?';

  @override
  String get householdDeleteTitle => 'Haushalt löschen?';

  @override
  String get householdDeleteMessage =>
      'Du bist das letzte Mitglied. Wenn du gehst, wird dieser Haushalt mit allen Sachen gelöscht.';

  @override
  String get householdDeleteAction => 'Verlassen und löschen';

  @override
  String get settingsAboutTitle => 'Über die App';

  @override
  String get settingsAboutSubtitle => 'App-Version und Informationen';

  @override
  String get settingsHomeWidgetVerboseModeTitle =>
      'Ausführliches Homescreen-Widget';

  @override
  String get settingsHomeWidgetVerboseModeSubtitle =>
      'Mahlzeiten und Makros zeigen, nicht nur verbleibende kcal';

  @override
  String get settingsPlanShortageReminderTitle =>
      'Erinnerung für fehlende Zutaten';

  @override
  String get settingsPlanShortageReminderSubtitle =>
      'Am Vortag, wenn für geplantes Essen etwas fehlt';

  @override
  String get settingsPlanShortageReminderBlocked =>
      'Benachrichtigungen sind aus. Tippen zum Erlauben.';

  @override
  String get settingsPlanShortageReminderTimeTitle => 'Uhrzeit';

  @override
  String get commonOr => 'Oder';

  @override
  String get login => 'Login';

  @override
  String get loginWithGoogle => 'Mit Google anmelden';

  @override
  String get authShowPassword => 'Passwort anzeigen';

  @override
  String get authHidePassword => 'Passwort verbergen';

  @override
  String get authBrandTitle => 'Yamt';

  @override
  String get authBrandSubtitle => 'Yet Another Meal Tracker';

  @override
  String get authContinueAsGuest => 'Als Gast fortfahren';

  @override
  String get authForgotPassword => 'Passwort vergessen?';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get confirmPasswordLabel => 'Passwort bestätigen';

  @override
  String get validationPasswordsDoNotMatch =>
      'Passwörter stimmen nicht überein';

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
  String get authErrorEmailAlreadyInUse =>
      'Für diese E-Mail existiert bereits ein Konto.';

  @override
  String get authErrorWeakPassword => 'Das Passwort ist zu schwach.';

  @override
  String get authErrorOperationNotAllowed =>
      'Diese Anmeldemethode ist nicht aktiviert.';

  @override
  String get authErrorTooManyRequests =>
      'Zu viele Anfragen. Bitte später erneut versuchen.';

  @override
  String get authErrorNetworkRequestFailed =>
      'Netzwerkfehler. Bitte Internetverbindung prüfen.';

  @override
  String get authErrorRequiresRecentLogin =>
      'Bitte melde dich erneut an, um fortzufahren.';

  @override
  String get authErrorAccountExistsWithDifferentCredential =>
      'Es existiert bereits ein Konto mit einer anderen Anmeldemethode.';

  @override
  String get authErrorCredentialAlreadyInUse =>
      'Diese Anmeldeinformation wird bereits von einem anderen Konto verwendet.';

  @override
  String get authErrorProviderAlreadyLinked =>
      'Dieser Anmeldeanbieter ist bereits mit deinem Konto verknüpft.';

  @override
  String get authErrorGoogleSignInCanceled =>
      'Google-Anmeldung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get authErrorGoogleIdTokenMissing =>
      'Google-Anmeldung hat kein gültiges Token geliefert.';

  @override
  String get commonUndoAction => 'Rückgängig';

  @override
  String get commonUndoFailed => 'Rückgängig fehlgeschlagen.';

  @override
  String get commonNotImplementedYet => 'Noch nicht implementiert';

  @override
  String get onboardingNextAction => 'Weiter';

  @override
  String get onboardingFinishOffline =>
      'Keine Internetverbindung. Deine Angaben bleiben erhalten, versuch es erneut, sobald du online bist.';

  @override
  String get onboardingGoalWeightSubtitle =>
      'Lass uns dein Zielgewicht festlegen.';

  @override
  String get onboardingGoalWeightTargetLabel => 'Wunschgewicht (kg)';

  @override
  String get onboardingGoalWeightLoseFeedback => 'Du möchtest abnehmen.';

  @override
  String get onboardingGoalWeightGainFeedback => 'Du möchtest zunehmen.';

  @override
  String get onboardingGoalWeightMaintainFeedback =>
      'Du möchtest dein Gewicht halten.';

  @override
  String get onboardingPaceTitle => 'Dein Tempo';

  @override
  String get onboardingPaceSubtitle =>
      'Wie schnell möchtest du dein Ziel erreichen?';

  @override
  String get onboardingPaceMaintainMessage =>
      'Da du dein Gewicht halten möchtest, berechnen wir einfach deinen Erhaltungsbedarf. Du brauchst kein Tempo festlegen.';

  @override
  String get onboardingPaceWarningLoseMessage =>
      'Mehr als 0,5 kg pro Woche abzunehmen ist recht hoch. Achte darauf, dass du ausreichend Nährstoffe zu dir nimmst!';

  @override
  String get onboardingPaceWarningGainMessage =>
      'Mehr als 0,5 kg pro Woche zuzunehmen ist recht hoch. Ein moderateres Tempo hilft dir, Muskeln aufzubauen, ohne zu viel Fett anzusetzen.';

  @override
  String onboardingTrainingDaysTrainingResult(int days) {
    return '🏋️ Training ($days Tage)';
  }

  @override
  String onboardingTrainingDaysRestResult(int days) {
    return '🛋️ Normaler Tag ($days Tage)';
  }

  @override
  String get onboardingReadyTitle => 'Alles bereit!';

  @override
  String get introWelcomeTitle => 'Willkommen bei YAMT';

  @override
  String get introWelcomeBody =>
      'Tracke, was du isst, lerne, was dein Körper wirklich verbrennt, und behalte deine Küche im Griff.';

  @override
  String get introStartAction => 'Los geht\'s';

  @override
  String get introLoginAction => 'Ich habe schon ein Konto';

  @override
  String get introCalorieModelTitle =>
      'Alles beginnt mit dem, was du hineingibst.';

  @override
  String get introCalorieModelBody =>
      'Dein Gewicht folgt einer einfachen Gleichung: Energie, die du isst, gegen Energie, die dein Körper verbrennt. Isst du mehr, als du verbrennst, nimmst du zu. Isst du weniger, nimmst du ab.';

  @override
  String get introInputQualityTitle =>
      'Dein Körper ist ein Ofen, der niemals schläft.';

  @override
  String get introInputQualityBody =>
      'Rund um die Uhr verbrennst du Energie: für deinen Herzschlag, dein Gehirn, die Atmung und konstante Wärme. Dazu kommt jede kleine Geste im Alltag – Treppensteigen, Zappeln, Frieren, Gehen.';

  @override
  String get introFollowTargetTitle => 'Deine Waage korrigiert die Schätzung.';

  @override
  String get introFollowTargetBody =>
      'Nach den ersten sieben Tagen vergleichen wir diesen Startwert damit, wie sich dein Gewicht wirklich entwickelt hat, und korrigieren ihn. Danach Woche für Woche.';

  @override
  String get introGoalDirectionBody =>
      'Zum Abnehmen ziehen wir Kalorien von deinem Verbrauch ab, zum Zunehmen legen wir welche drauf. Beim Halten entspricht dein Ziel genau deinem Verbrauch.';

  @override
  String get introGoalDirectionTitle => 'Dein Ziel biegt die Zahl.';

  @override
  String get introTrendTitle => 'Ein Wiegen sagt nichts. Die Woche sagt alles.';

  @override
  String get introTrendBody =>
      'Wasser, Salz und ein spätes Abendessen bewegen die Waage über Nacht um ein Kilo. Das ist Rauschen, kein Fett.';

  @override
  String get introExtrasTitle => 'Und der Rest deiner Küche kommt mit.';

  @override
  String get introExtrasBody =>
      'Speichere Rezepte und plane mit der Einkaufsliste, scanne Barcodes für deinen Vorrat, übernimm Lebensmittel vom Kassenbon oder beschreibe sie und lass die KI den Rest ergänzen.';

  @override
  String get introIdentityTitle =>
      'Erstmal brauchen wir ein ungefähres Bild von dir.';

  @override
  String get introIdentitySubtitle =>
      'Bevor die App deine echten Werte lernt, brauchen wir einen wissenschaftlichen Ausgangspunkt für deinen Grundumsatz.';

  @override
  String get introBirthDateLabel => 'Geburtstag';

  @override
  String get introBirthDateEmpty => 'Bitte wähle deinen Geburtstag.';

  @override
  String get introCalorieModelHighlight => 'was du hineingibst';

  @override
  String get introCalorieModelNote =>
      'Die Essens-Hälfte der Gleichung ist greifbar: Was du isst, lässt sich wiegen, sehen und fast auf das Gramm genau erfassen.';

  @override
  String get introInputQualityHighlight => 'der niemals schläft';

  @override
  String get introInputQualityNote =>
      'Der Haken: Diesen Verbrauch kann niemand direkt messen. Deshalb starten wir mit einem Startwert, geschätzt aus deinen Angaben.';

  @override
  String get introFollowTargetHighlight => 'korrigiert die Schätzung';

  @override
  String get introFollowTargetNote =>
      'Die erste Woche ist also eine Messung, kein Urteil. Lies nicht zu viel hinein.';

  @override
  String get introGoalDirectionHighlight => 'biegt die Zahl';

  @override
  String get introGoalDirectionNote =>
      'Du wählst das Tempo. Das Rechnen übernehmen wir, jeden Tag.';

  @override
  String get introTrendHighlight => 'Die Woche sagt alles';

  @override
  String get introTrendNote =>
      'Für die Korrektur lesen wir deshalb den Trend der ganzen Woche. Ein schlechter Morgen wirft deinen Plan nicht um.';

  @override
  String get introExtrasHighlight => 'der Rest deiner Küche';

  @override
  String get introExtrasNote =>
      'Erfassen fühlt sich nicht mehr nach Hausaufgabe an, wenn das Essen schon in der App liegt.';

  @override
  String get introSummarySubtitle =>
      'Das ist dein geschätzter Startwert. Ab deinem Starttag vergleicht YAMT sieben Tage lang dein Essen mit deinem Gewicht und korrigiert die Zahl, danach jede Woche.';

  @override
  String get introBodyTitle => 'Wie sind deine aktuellen Eckdaten?';

  @override
  String get introBodySubtitle =>
      'Körpergewicht und Körpergröße bestimmen, wie viele Zellen in Ruhe mit Sauerstoff und Glukose versorgt werden müssen.';

  @override
  String get introWeightKgUnit => 'kg';

  @override
  String get introSportTitle => 'An welchen Tagen trainierst du?';

  @override
  String get introSportSubtitle =>
      'Jede Einheit zählt zu deinem Verbrauch. Trainingstage bekommen sie dazu, normale Tage etwas weniger.';

  @override
  String get introWeekDepotTitle => 'Kalorien pro Tag über die Woche';

  @override
  String get introIdentityPrivacyNote =>
      'Deine Angaben dienen nur der Energieberechnung.';

  @override
  String get introBodyWeighInNote =>
      'Wieg dich am besten morgens nach dem Aufstehen. So bleiben deine Werte vergleichbar.';

  @override
  String get introSummaryDepotHint =>
      'Deine Einheiten stecken im Wochenbudget. Ein Trainingstag bekommt eine Einheit mehr als ein normaler Tag.';

  @override
  String get introStartDayTitle => 'Wann startet deine erste Woche?';

  @override
  String get introStartDayToday => 'Heute';

  @override
  String get introStartDayTodayHint =>
      'Trag auch nach, was du heute schon gegessen hast.';

  @override
  String get introStartDayTomorrow => 'Morgen';

  @override
  String get introStartDayTomorrowHint =>
      'Heute in Ruhe ausprobieren. Es zählt noch nicht.';

  @override
  String get introStartDayOther => 'Anderer Tag';

  @override
  String get introStartDayOtherHint =>
      'Bis dahin übst du, ohne dass etwas zählt.';

  @override
  String get introStartTodayAction => 'Heute starten';

  @override
  String get introStartTomorrowAction => 'Morgen starten';

  @override
  String introStartOnDateAction(String date) {
    return 'Am $date starten';
  }

  @override
  String get introCategoryHowItWorks => 'Wie YAMT rechnet';

  @override
  String get introCategoryYourProfile => 'Dein Profil';

  @override
  String get introCategoryYourStart => 'Dein Start';

  @override
  String get introCategoryBeyondCalories => 'Mehr als Kalorien';

  @override
  String get introChapterEnergyBalance => 'Energiebilanz';

  @override
  String get introChapterStartValue => 'Der Startwert';

  @override
  String get introChapterCorrection => 'Die Korrektur';

  @override
  String get introChapterGoalDirection => 'Dein Ziel';

  @override
  String get introChapterTrend => 'Der Trend';

  @override
  String get introChapterKitchen => 'Deine Küche';

  @override
  String get introChapterProfile => 'Über dich';

  @override
  String get introChapterBody => 'Körpermaße';

  @override
  String get introChapterTargetWeight => 'Zielgewicht';

  @override
  String get introChapterActivity => 'Alltagsaktivität';

  @override
  String get introChapterTraining => 'Training';

  @override
  String get introChapterPace => 'Tempo';

  @override
  String get introChapterResult => 'Dein Startwert';

  @override
  String introChapterKicker(int number, String name) {
    return 'Kapitel $number · $name';
  }

  @override
  String introNextChapterAction(String name) {
    return 'Weiter: $name';
  }

  @override
  String introChapterCounter(String current, String total) {
    return '$current / $total';
  }

  @override
  String get introTargetWeightHint =>
      'Dreh das Rad oder lass es stehen, um dein Gewicht zu halten.';

  @override
  String get introTargetTitle => 'Wo willst du hin?';

  @override
  String get introBirthDayLabel => 'Tag';

  @override
  String get introBirthMonthLabel => 'Monat';

  @override
  String get introBirthYearLabel => 'Jahr';

  @override
  String get introHeightCmUnit => 'cm';

  @override
  String get introCurrentWeightLabel => 'Aktuelles Gewicht';

  @override
  String get introPaceLabel => 'Tempo';

  @override
  String get introPacePerWeekUnit => 'kg / Woche';

  @override
  String get introActivityTitle => 'Wie aktiv ist deine typische Woche?';

  @override
  String get introActivitySubtitle =>
      'Nur dein Alltag: Beruf und Wege. Dein Training fragen wir gleich extra.';

  @override
  String get introActivitySittingTitle => 'Kaum aktiv';

  @override
  String get introActivitySittingBody =>
      'Schreibtisch, Auto, Sofa, wenige Schritte';

  @override
  String get introActivityLightTitle => 'Leicht aktiv';

  @override
  String get introActivityLightBody =>
      'Überwiegend sitzend, täglich etwas zu Fuß';

  @override
  String get introActivityOnFeetTitle => 'Moderat aktiv';

  @override
  String get introActivityOnFeetBody =>
      'Viel auf den Beinen, z. B. Verkauf oder Pflege';

  @override
  String get introActivityHardLabourTitle => 'Sehr aktiv';

  @override
  String get introActivityHardLabourBody =>
      'Harte körperliche Arbeit, z. B. Bau oder Lager';

  @override
  String get introSummaryExpenditureLabel => 'Dein berechneter Verbrauch';

  @override
  String get introSummaryExpenditureHint =>
      'Was dein Körper an einem normalen Tag verbrennt.';

  @override
  String get introSummaryTargetLabel => 'Dein Tagesziel';

  @override
  String get introSummaryTargetMaintainHint =>
      'Entspricht deinem Verbrauch, dein Gewicht bleibt also gleich.';

  @override
  String introSummaryKcalValue(int kcal) {
    return '$kcal kcal';
  }

  @override
  String introSummaryTargetDeficitHint(int kcal) {
    return '$kcal kcal unter deinem Verbrauch, damit du abnimmst.';
  }

  @override
  String introSummaryTargetSurplusHint(int kcal) {
    return '$kcal kcal über deinem Verbrauch, damit du zunimmst.';
  }

  @override
  String introBirthDateValue(String date, String age) {
    return '$date ($age Jahre)';
  }

  @override
  String introTargetDateEstimate(String date) {
    return 'In diesem Tempo erreichst du dein Ziel etwa am $date.';
  }

  @override
  String get caloriesProteinShortLetter => 'P';

  @override
  String get caloriesCarbsShortLetter => 'K';

  @override
  String get caloriesFatShortLetter => 'F';

  @override
  String shoppingListPlanNeedMissing(String amount) {
    return '$amount fehlen';
  }

  @override
  String shoppingListPlanNeedAmount(String amount, String unit) {
    return '$amount $unit';
  }

  @override
  String shoppingListPlanNeedGroup(String day, String meal) {
    return '$day · $meal';
  }

  @override
  String shoppingListPlanNeedBrand(String brand, String amount) {
    return '$brand · $amount';
  }

  @override
  String get shoppingListPlanNeedsLoadFailed =>
      'Der Bedarf deiner Pläne konnte nicht geladen werden';

  @override
  String get shoppingListPlanNeedsRetry => 'Bedarf neu laden';

  @override
  String get shoppingListPlanNeedsTitle => 'Für deinen Plan';

  @override
  String get shoppingListSuggestionsTitle => 'Vorschläge';

  @override
  String get shoppingListSuggestionsExplanation =>
      'Fast leere Vorräte und häufig gekaufte Artikel aus deinen Belegen.';

  @override
  String get shoppingListSuggestionsEmpty =>
      'Noch keine Vorschläge. Sie erscheinen bei niedrigem Vorrat oder wiederholten Käufen auf verschiedenen Belegen.';

  @override
  String get shoppingListSuggestionsRetry => 'Vorschläge erneut laden';

  @override
  String shoppingListConsumptionDays(int count) {
    return 'An $count Tagen verbraucht';
  }

  @override
  String get shoppingListOpenTitle => 'Noch einkaufen';

  @override
  String get shoppingListDoneTitle => 'Erledigt';

  @override
  String get shoppingListLowStock => 'Fast leer';

  @override
  String shoppingListPurchaseCount(int count) {
    return '$count× gekauft';
  }

  @override
  String get shoppingListSchedule => 'Dauerauftrag';

  @override
  String get shoppingListScheduleExplanation =>
      'Fällige Artikel werden beim Öffnen dieser Liste wieder hinzugefügt. Bereits offene Artikel werden nicht verdoppelt.';

  @override
  String get shoppingListScheduleDays => 'Intervall in Tagen';

  @override
  String get shoppingListFirstDue => 'Erstmals am';

  @override
  String get shoppingListStopSchedule => 'Dauerauftrag beenden';

  @override
  String get shoppingListSaveSettings => 'Speichern';

  @override
  String shoppingListNumberRange(int max) {
    return 'Bitte eine Zahl von 1 bis $max eingeben.';
  }

  @override
  String get shoppingListProductSettings => 'Artikeleinstellungen';

  @override
  String get shoppingListRemoveFavorite => 'Favorit entfernen';

  @override
  String get shoppingListAddFavorite => 'Als Favorit speichern';

  @override
  String get shoppingListSettingsFailed =>
      'Einstellungen konnten nicht gespeichert werden.';

  @override
  String get shoppingListSavedProducts => 'Favoriten & Daueraufträge';

  @override
  String shoppingListRepeatSummary(int quantity, int days) {
    return '$quantity Stück alle $days Tage';
  }

  @override
  String shoppingListNextDue(String date) {
    return 'Nächster Termin: $date';
  }

  @override
  String get shoppingListFavorite => 'Favorit';

  @override
  String get shoppingListOutOfStock => 'Aufgebraucht';

  @override
  String get receiptReviewTitle => 'Beleg prüfen';

  @override
  String get receiptReviewAddItem => 'Position hinzufügen';

  @override
  String get receiptReviewConfirmAllSuggestions => 'Alle Vorschläge übernehmen';

  @override
  String get receiptReviewSaveAction => 'Ins Inventar übernehmen';

  @override
  String get receiptReviewStoreEdit => 'Händler anpassen';

  @override
  String get receiptReviewStoreLabel => 'Händlername';

  @override
  String get receiptReviewAnalyzing => 'Beleg wird analysiert...';

  @override
  String get receiptReviewProcessingFailed =>
      'Beleg konnte nicht verarbeitet werden.';

  @override
  String get receiptCameraFailed =>
      'Kamera für den Beleg konnte nicht geöffnet werden.';

  @override
  String get receiptReviewNoDate => 'Kein Datum erkannt';

  @override
  String get receiptReviewUnknownStore => 'Unbekannter Händler';

  @override
  String get receiptReviewPrintedTotal => 'Bon-Summe';

  @override
  String get receiptReviewCalculatedTotal => 'Berechnete Summe';

  @override
  String receiptReviewDifference(String difference) {
    return 'Differenz: $difference';
  }

  @override
  String get receiptReviewSumMatches => 'Summe stimmt';

  @override
  String receiptReviewDiscount(String amount) {
    return 'Rabatt: -$amount';
  }

  @override
  String receiptReviewDeposit(String amount) {
    return 'Pfand: $amount';
  }

  @override
  String receiptReviewOpenItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Positionen',
      one: '1 Position',
    );
    return 'Noch $_temp0 offen';
  }

  @override
  String get receiptReviewReceiptPrefix => 'Bon';

  @override
  String get receiptReviewDepositBadge => 'Pfand';

  @override
  String get receiptReviewConfirmSuggestionTooltip => 'Vorschlag übernehmen';

  @override
  String get receiptReviewOriginalReceiptText => 'Originaltext vom Kassenbon';

  @override
  String get receiptReviewQuantityLabel => 'Menge:';

  @override
  String get receiptReviewScanBarcode => 'Barcode scannen';

  @override
  String get receiptReviewSearchProduct => 'Produkt suchen';

  @override
  String get receiptReviewIncludeItem => 'Einbeziehen';

  @override
  String get receiptReviewIgnoreItem => 'Ignorieren';

  @override
  String get receiptReviewDeleteItem => 'Löschen';

  @override
  String get receiptReviewSuggestedAlternatives =>
      'Vorgeschlagene Alternativen:';

  @override
  String get receiptReviewSelectCandidateAction => 'Wählen';

  @override
  String get receiptReviewNoProductAssigned => 'Kein Produkt zugewiesen';

  @override
  String get receiptReviewClearProductMatchTooltip => 'Zuordnung aufheben';

  @override
  String get receiptReviewSwitchProductAction => 'Produkt wechseln';

  @override
  String get receiptReviewSearchProductAction => 'Produkt suchen';

  @override
  String get receiptReviewItemNameLabel => 'Artikelbezeichnung';

  @override
  String get receiptReviewItemNameHint => 'z. B. Hafermilch Barista';

  @override
  String get receiptReviewItemQuantityLabel => 'Menge';

  @override
  String get receiptReviewPriceLabel => 'Preis';

  @override
  String get receiptReviewIsDepositLabel => 'Ist Pfand';

  @override
  String get receiptReviewAddAction => 'Hinzufügen';

  @override
  String get receiptReviewPriceEditTitle => 'Preis anpassen';

  @override
  String get receiptReviewBarcodeDialogTitle => 'Barcode eingeben / scannen';

  @override
  String get receiptReviewBarcodeDialogLabel => 'Barcode (EAN)';

  @override
  String get receiptReviewConfirmAction => 'Bestätigen';

  @override
  String get receiptReviewManualInputTooltip => 'Manuell eingeben';

  @override
  String get receiptReviewSearchProductDialogTitle => 'Artikel suchen';

  @override
  String get receiptReviewSearchProductHint => 'Produktname eingeben...';

  @override
  String get receiptReviewNoProductsFound => 'Keine Artikel gefunden';

  @override
  String get receiptReviewNutritionPer100g => 'Nährwerte je 100 g/ml';

  @override
  String receiptReviewPackageSize(String size) {
    return 'Packung: $size';
  }

  @override
  String get receiptReviewNutritionEnergy => 'Energie';

  @override
  String get receiptReviewNutritionFat => 'Fett';

  @override
  String get receiptReviewNutritionCarbs => 'KH';

  @override
  String get receiptReviewNutritionProtein => 'Protein';

  @override
  String get recoveryKeyTitle => 'Wiederherstellungsschlüssel';

  @override
  String get recoveryKeyExplanation =>
      'Dein Tagebuch, dein Gewicht und deine Körperdaten werden verschlüsselt, bevor sie dieses Handy verlassen. Ein neues Handy mit demselben Google- oder Apple-Konto bekommt den Schlüssel meist automatisch. Diesen Wiederherstellungsschlüssel brauchst du nur, wenn du zwischen Android und iPhone wechselst oder dein Handy verlierst. Niemand kann ihn für dich wiederherstellen, auch wir nicht.';

  @override
  String get recoveryKeySaveToPasswordManagerAction =>
      'Im Passwortmanager speichern';

  @override
  String get recoveryKeySaved => 'Wiederherstellungsschlüssel gespeichert';

  @override
  String get recoveryKeySaveFailed =>
      'Wiederherstellungsschlüssel konnte nicht gespeichert werden.';

  @override
  String get recoveryKeyNotSavedHint => 'Noch nicht gesichert';

  @override
  String get recoveryKeyCopyTooltip => 'Wiederherstellungsschlüssel kopieren';

  @override
  String get recoveryKeyCopied => 'Wiederherstellungsschlüssel kopiert';

  @override
  String get recoveryKeyConfirmAction => 'Ich habe ihn gespeichert';

  @override
  String get recoveryKeyConfirmFailed =>
      'Bestätigung konnte nicht gespeichert werden.';

  @override
  String get recoveryKeyUnavailable =>
      'Gäste haben keinen Wiederherstellungsschlüssel. Verknüpfe ein Konto, um einen zu bekommen.';

  @override
  String get dataKeyRestoreTitle => 'Daten wiederherstellen';

  @override
  String get dataKeyRestoreExplanation =>
      'Deine Daten sind verschlüsselt. Gib den Wiederherstellungsschlüssel ein, den du beim Anlegen deines Kontos gespeichert hast.';

  @override
  String get dataKeyRestoreAction => 'Wiederherstellen';

  @override
  String get dataKeyRestoreInvalid =>
      'Dieser Wiederherstellungsschlüssel stimmt nicht.';

  @override
  String get dataKeyRestoreFailed =>
      'Daten konnten nicht wiederhergestellt werden.';

  @override
  String get dataKeyStartFreshAction => 'Ohne alte Daten neu starten';

  @override
  String get dataKeyStartFreshDialogTitle => 'Alte Daten löschen?';

  @override
  String get dataKeyStartFreshDialogMessage =>
      'Ohne den Wiederherstellungsschlüssel können dein Tagebuch, dein Gewicht und deine Ziele nicht gelesen werden. Sie werden gelöscht. Dein Vorrat wird auch gelöscht, außer andere Mitglieder teilen deinen Haushalt: Dann kann ein Mitglied ihn dir wieder freigeben.';

  @override
  String get dataKeyStartFreshConfirmAction => 'Löschen und neu starten';

  @override
  String get dataKeyStartFreshFailed => 'Neustart fehlgeschlagen.';

  @override
  String get dataKeyLoadFailed =>
      'Dein Datenschlüssel konnte nicht geladen werden. Prüfe deine Verbindung.';

  @override
  String get dataKeyRetryAction => 'Erneut versuchen';

  @override
  String get calorieGoalLoadFailed =>
      'Dein Ziel konnte nicht geladen werden. Prüfe deine Verbindung.';

  @override
  String get calorieGoalLoadRetryAction => 'Erneut versuchen';

  @override
  String get calorieGoalLoadFailedSignOutAction => 'Abmelden';

  @override
  String get calorieGoalLoadFailedSignOutFailed =>
      'Abmelden hat nicht geklappt. Prüfe deine Verbindung.';

  @override
  String get dataKeyPickFromPasswordManagerAction =>
      'Aus Passwortmanager einfügen';

  @override
  String get dataKeyPickFailed =>
      'Passwortmanager konnte nicht geöffnet werden.';

  @override
  String get foodEstimateHeadline => 'Was isst du?';

  @override
  String get foodEstimateHint => 'Foto, Text oder beides. Eins reicht.';

  @override
  String get foodEstimateDescriptionLabel => 'Beschreibung';

  @override
  String get foodEstimateDescriptionHint =>
      'z. B. ohne Zwiebeln, extra Soße, großer Teller';

  @override
  String get foodEstimateChipLargePortion => 'große Portion';

  @override
  String get foodEstimateChipRestaurant => 'Restaurant';

  @override
  String get foodEstimateChipHomemade => 'selbst gekocht';

  @override
  String get foodEstimateChipHalfEaten => 'halb gegessen';

  @override
  String get foodEstimateAnalyze => 'Analysieren';

  @override
  String get foodEstimateAnalyzing => 'Analysiere …';

  @override
  String get foodEstimateNotFood => 'Auf den Fotos ist kein Essen zu erkennen.';

  @override
  String get foodEstimateUnclear =>
      'Das Essen ist nicht zu erkennen. Nimm ein helleres Foto oder beschreibe es.';

  @override
  String get foodEstimateFailed =>
      'Die Schätzung hat nicht geklappt. Bitte versuche es erneut.';

  @override
  String get foodEstimateOverline => 'KI-Schätzung';

  @override
  String get foodEstimateReanalyze => 'Neu analysieren';

  @override
  String get foodEstimateAddToStock => 'In Vorrat';

  @override
  String get foodEstimateApply => 'Übernehmen';

  @override
  String get foodEstimateLevelLean => 'mager';

  @override
  String get foodEstimateLevelNormal => 'normal';

  @override
  String get foodEstimateLevelRich => 'reichhaltig';

  @override
  String get foodEstimateTakePhoto => 'Foto machen';

  @override
  String get foodEstimateTakePhotoHint => 'Teller, Verpackung oder Speisekarte';

  @override
  String get foodEstimateFromGallery => 'oder Bild aus Galerie';

  @override
  String get foodEstimateAnotherPhoto => 'Noch eins';

  @override
  String get foodEstimatePhotoNotSaved =>
      'Das Foto konnte nicht gespeichert werden. Das Essen wird ohne Bild gespeichert.';

  @override
  String foodEstimateRemovePhoto(int index) {
    return 'Foto $index entfernen';
  }

  @override
  String get homeMenuClose => 'Menü schließen';

  @override
  String get homeMenuSectionYou => 'Du';

  @override
  String get homeMenuSectionKitchen => 'Küche';

  @override
  String get homeMenuSectionApp => 'App';

  @override
  String get homeMenuLinkAccount => 'Konto verknüpfen';

  @override
  String get homeMenuGuest => 'Gastmodus';

  @override
  String get appName => 'YAMT';

  @override
  String get profileNoValue => '–';

  @override
  String profileWeightChartDays(int days) {
    return '$days Tage';
  }

  @override
  String get profileWeightMeasuredLabel => 'Gemessen';

  @override
  String profileWeighInDay(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'vor $days Tagen',
      one: 'gestern',
      zero: 'heute',
    );
    return '$_temp0';
  }

  @override
  String get profileWeightStartLabel => 'Start';

  @override
  String get profileWeightStartNote => 'am Zielstart';

  @override
  String get profileWeightTrendLabel => 'Trend';

  @override
  String get profileWeightPerWeek => 'pro Woche';

  @override
  String get profileBodySection => 'Körper';

  @override
  String get profileTrainingLabel => 'Training';

  @override
  String get profileTrainingNone => 'Keine';

  @override
  String profileTrainingOffset(String kcal) {
    return '$kcal kcal pro Einheit';
  }

  @override
  String get profileMacroWeightLabel => 'Makro-Gewicht';

  @override
  String profileMacroWeightSince(String date) {
    return 'seit $date';
  }

  @override
  String get profileTdeeLabel => 'Verbrauch';

  @override
  String get profileTdeeLearned => 'gelernt';

  @override
  String get profileTdeeEstimated => 'geschätzt';

  @override
  String progressGoalLose(String weight) {
    return 'Abnehmen auf $weight kg';
  }

  @override
  String progressGoalGain(String weight) {
    return 'Zunehmen auf $weight kg';
  }

  @override
  String get progressGoalMaintain => 'Gewicht halten';

  @override
  String progressGoalStart(String weight) {
    return 'Start $weight kg';
  }

  @override
  String progressGoalRemaining(String weight, String pace) {
    return 'noch $weight kg · $pace kg/Woche';
  }

  @override
  String get progressGoalNone => 'Noch kein Ziel gesetzt.';

  @override
  String get profileHeightTitle => 'Größe';

  @override
  String get profileBirthDateTitle => 'Geburtstag';

  @override
  String get profileSexTitle => 'Geschlecht';

  @override
  String get profileStartWeightTitle => 'Startgewicht';

  @override
  String get profileWeightSection => 'Gewicht';

  @override
  String get profileUnitCm => 'cm';

  @override
  String get profileUnitKg => 'kg';

  @override
  String profileHeightRange(String min, String max) {
    return 'Zwischen $min und $max cm';
  }

  @override
  String profileStartWeightRange(String min, String max) {
    return 'Zwischen $min und $max kg';
  }

  @override
  String profileBirthDateRange(String min, String max) {
    return 'Alter zwischen $min und $max Jahren';
  }

  @override
  String get profileEditCancel => 'Abbrechen';

  @override
  String get profileEditApply => 'Übernehmen';

  @override
  String get profileEditSaveFailed =>
      'Die Änderung konnte nicht gespeichert werden.';

  @override
  String get profileEditEffectToday => 'Das ändert sich ab heute';

  @override
  String profileEditEffectFromGoalStart(String date) {
    return 'Das ändert sich ab Zielstart am $date';
  }

  @override
  String get profileEditKcalLabel => 'Kalorienziel';

  @override
  String profileEditKcalStays(String kcal) {
    return 'bleibt $kcal kcal';
  }

  @override
  String profileEditKcalChange(String before, String after) {
    return '$before → $after kcal';
  }

  @override
  String profileEditGramsChange(String before, String after) {
    return '$before → $after g';
  }

  @override
  String get profileEditMacrosLabel => 'Makros';

  @override
  String get profileEditMacrosStay => 'bleiben gleich';

  @override
  String get profileEditNoteLearned =>
      'Dein Verbrauch ist gelernt. Deshalb ändert sich nur die Aufteilung der Makros.';

  @override
  String get profileEditNoteManual =>
      'Dein Kalorienziel ist fest eingestellt. Deshalb ändert sich nur die Aufteilung der Makros.';

  @override
  String get profileEditNoteCorrection =>
      'Noch ist kein Verbrauch gelernt. Deshalb rechnet die App dein Kalorienziel ab dem Zielstart neu.';

  @override
  String get profileEditNoteNoGoal =>
      'Du hast gerade kein Ziel. Die Angabe zählt ab deinem nächsten Ziel.';

  @override
  String profileTrainingRunRange(String start, String end) {
    return 'Run $start – $end';
  }

  @override
  String profileTrainingRunNote(String date) {
    return 'diesen Run bis $date';
  }

  @override
  String get profileTrainingEffectTitle => 'Das ändert sich in diesem Run';

  @override
  String profileTrainingBecomesTraining(String date) {
    return '$date wird Trainingstag';
  }

  @override
  String profileTrainingBecomesRest(String date) {
    return '$date wird normaler Tag';
  }

  @override
  String get profileTrainingRunSum => 'Summe des Runs';

  @override
  String get profileTrainingNote =>
      'Gilt nur für diesen Run, wie ein Tagestyp im Tagebuch. Die Summe des Runs bleibt; was vergangene Tage anders bekommen, gibt der Übertrag an die restlichen Tage weiter.';

  @override
  String get profileTrainingPauseDay => 'Pausentag';

  @override
  String profileTrainingOtherRestDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count übrige normale Tage',
      one: 'Übriger normaler Tag',
    );
    return '$_temp0';
  }

  @override
  String profileTrainingOtherTrainingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count übrige Trainingstage',
      one: 'Übriger Trainingstag',
    );
    return '$_temp0';
  }

  @override
  String get caloriesGoalBodyStepTitle => 'Deine Körperdaten';

  @override
  String get caloriesGoalBodyEditInProfile => 'Im Profil bearbeiten';

  @override
  String caloriesGoalBodyHeightValue(String height) {
    return '$height cm';
  }

  @override
  String caloriesGoalBodyAgeValue(int age) {
    return '$age Jahre';
  }

  @override
  String caloriesGoalBodyAgeWithBirthday(int age, String birthday) {
    return '$age Jahre · $birthday';
  }

  @override
  String get homeActionEat => 'Essen';

  @override
  String get inventoryAddBarcodeDescription =>
      'Packung scannen und in den Vorrat legen';

  @override
  String get diaryQuickEatBarcodeDescription =>
      'Packung scannen und Gegessenes eintragen';

  @override
  String get diaryQuickEatInventoryDescription =>
      'Etwas aus deinem Vorrat essen';

  @override
  String get diaryQuickEatQuickEntryDescription =>
      'Kalorien und Makros von Hand eintragen';

  @override
  String get diaryQuickEatAiDescription =>
      'Beschreib eine Mahlzeit, die KI schätzt sie';

  @override
  String get diaryQuickEatSearchDescription =>
      'Lebensmittel nach Name oder Marke finden';

  @override
  String diaryCheckInRunKicker(int run, String range) {
    return 'Run $run · $range';
  }

  @override
  String diaryCheckInRangeKicker(String range) {
    return '$range';
  }

  @override
  String get diaryCheckInReviewTitle => 'Woche geschafft';

  @override
  String get diaryCheckInBlockedTitle => 'Check-in braucht Daten';

  @override
  String diaryCheckInGoalSince(String weight, String date) {
    return 'Ziel $weight kg · seit $date';
  }

  @override
  String diaryCheckInSince(String date) {
    return 'Seit $date';
  }

  @override
  String get diaryCheckInTrendFact => 'Trend';

  @override
  String diaryCheckInTrendChange(String change) {
    return '$change kg seit Start';
  }

  @override
  String get diaryCheckInEatenFact => 'Gegessen';

  @override
  String get diaryCheckInPerDay => 'kcal / Tag';

  @override
  String get diaryCheckInTrainingFact => 'Training';

  @override
  String get diaryCheckInTrainingDaysCaption => 'Tage im Run';

  @override
  String get diaryCheckInWeightChart => 'Gewicht';

  @override
  String get diaryCheckInTrend => 'Trend';

  @override
  String get diaryCheckInTdeeChart => 'Verbrauch (TDEE) je Run';

  @override
  String get diaryCheckInUseMeasured => 'Gemessenen übernehmen';

  @override
  String diaryCheckInUseMeasuredDetail(String kcal) {
    return 'TDEE $kcal aus diesem Run';
  }

  @override
  String get diaryCheckInKeepPrevious => 'Bisherigen behalten';

  @override
  String diaryCheckInKeepPreviousDetail(String kcal) {
    return 'TDEE $kcal, Ziel wie letzte Woche';
  }

  @override
  String get diaryCheckInGoalKcalCaption => 'kcal Ziel';

  @override
  String get diaryCheckInChangeGoal => 'Ziel ändern';

  @override
  String get diaryCheckInChangeGoalDetail =>
      'Zielgewicht oder Tempo neu setzen';

  @override
  String get diaryCheckInNext => 'Weiter';

  @override
  String get diaryCheckInBack => 'Zurück';

  @override
  String get diaryCheckInTrainingTitle => 'Wann trainierst du?';

  @override
  String get diaryCheckInTrainingSubtitle =>
      'Tippe die Tage an, an denen du trainierst';

  @override
  String get diaryCheckInSessions => 'Einheiten';

  @override
  String get diaryCheckInSameAsLastRun => 'Wie letzter Run';

  @override
  String get diaryCheckInNoSession => 'Keine Einheit';

  @override
  String get diaryCheckInAverageGoal => 'Tagesziel im Schnitt';

  @override
  String get diaryCheckInMeasuredSource => 'gemessen';

  @override
  String get diaryCheckInPreviousSource => 'bisher';

  @override
  String diaryCheckInGoalChange(String change) {
    return '$change zur Vorwoche';
  }

  @override
  String diaryCheckInDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get diaryCheckInMacros => 'Makros';

  @override
  String get diaryCheckInMacrosPrevious => 'bisher';

  @override
  String get diaryCheckInMacrosNew => 'neu';

  @override
  String diaryCheckInGramsValue(int grams) {
    return '$grams g';
  }

  @override
  String diaryCheckInMacroWeightDetail(String weight) {
    return 'Eiweiß und Fett zählen mit $weight kg.';
  }

  @override
  String get diaryCheckInStartWeek => 'Woche starten';

  @override
  String get diaryCheckInGoalReachedKicker => 'Ziel erreicht';

  @override
  String get diaryCheckInGoalReachedTitle => 'Glückwunsch!';

  @override
  String diaryCheckInGoalReachedBody(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks Wochen',
      one: '1 Woche',
    );
    return 'Du hast dein Zielgewicht in $_temp0 erreicht.';
  }

  @override
  String get diaryCheckInStartFact => 'Start';

  @override
  String get diaryCheckInTodayFact => 'Heute';

  @override
  String get diaryCheckInDoneFact => 'Geschafft';

  @override
  String diaryCheckInPerWeek(String change) {
    return '$change kg / Woche';
  }

  @override
  String get diaryCheckInStartNewGoal => 'Neues Ziel starten';

  @override
  String get diaryCheckInClose => 'Schließen';

  @override
  String get diaryCheckInLoadFailed =>
      'Der Check-in konnte nicht geladen werden.';

  @override
  String get diaryHoloPreviewAction => 'Vorschau Holo-Budgetkarte';

  @override
  String get diaryCheckInPreviewAction => 'Wochen-Check-in Vorschau';

  @override
  String get diaryCheckInGoalReachedPreviewAction => 'Vorschau Ziel erreicht';

  @override
  String diaryCheckInPreviewResult(String action, int days) {
    return 'Vorschau: $action, $days Trainingstage, nichts gespeichert';
  }

  @override
  String get diaryCheckInMissingDataPreviewAction => 'Vorschau Daten fehlen';

  @override
  String get homeMenuDebugSection => 'Debug';

  @override
  String get diaryCheckInFixedDaysHint =>
      'Vergangene Tage und Pausentage bleiben, wie sie sind.';

  @override
  String cookbookRecipeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Rezepte',
      one: '1 Rezept',
    );
    return '$_temp0';
  }

  @override
  String get cookbookOpenMealsTitle => 'Offen';

  @override
  String cookbookOpenMealRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeilen offen',
      one: '1 Zeile offen',
    );
    return 'Im Vorrat · $_temp0';
  }

  @override
  String get cookbookContinueAction => 'Weiter';

  @override
  String cookbookInPotOpenRows(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeilen offen',
      one: '1 Zeile offen',
    );
    return 'Im Topf seit $time · $_temp0';
  }

  @override
  String get cookbookTemplatesTitle => 'Vorlagen';

  @override
  String get cookbookTemplatesCaption => 'Aus dem Vorrat kombiniert';

  @override
  String get cookbookNewTemplateTitle => 'Neue Vorlage';

  @override
  String get cookbookNewTemplateCaption => 'aus dem Vorrat kombinieren';

  @override
  String get cookbookRecipesTitle => 'Rezepte';

  @override
  String get cookbookRecipesEmpty =>
      'Noch keine Rezepte. Füge eins per Link hinzu oder hol dir eine KI-Idee.';

  @override
  String get cookbookStockComplete => 'Alles da';

  @override
  String cookbookStockMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fehlen',
      one: '1 fehlt',
    );
    return '$_temp0';
  }

  @override
  String cookbookKcal(int kcal) {
    return '$kcal kcal';
  }

  @override
  String get cookbookLoadFailed => 'Das Kochbuch konnte nicht geladen werden.';

  @override
  String get cookbookRemoveAction => 'Entfernen';

  @override
  String get cookbookEntryMenuHint => 'Aktionen zeigen';

  @override
  String cookbookRemovedMessage(String name) {
    return '$name entfernt';
  }

  @override
  String cookbookRemoveFailed(String name) {
    return '$name konnte nicht entfernt werden.';
  }

  @override
  String get homeActionCook => 'Kochen';

  @override
  String get homeActionWeigh => 'Wiegen';

  @override
  String get homeActionProgress => 'Erfassen';

  @override
  String get cookbookFreeCookingAction => 'Frei kochen';

  @override
  String get cookbookFreeCookingDescription =>
      'Zutaten beim Kochen sagen oder schreiben';

  @override
  String get freeCookingNameHint => 'Wie heißt das Gericht?';

  @override
  String get freeCookingDefaultName => 'Frei gekocht';

  @override
  String get freeCookingIngredientsTitle => 'Zutaten';

  @override
  String freeCookingStockCount(int inStock, int total) {
    return '$inStock von $total da';
  }

  @override
  String freeCookingStockLeft(String amount) {
    return '$amount da';
  }

  @override
  String freeCookingAmountWithUnit(int amount, String unit) {
    return '$amount $unit';
  }

  @override
  String freeCookingPieces(int count) {
    return '$count Stk.';
  }

  @override
  String get freeCookingMissing => 'fehlt';

  @override
  String get freeCookingPickStock => 'Wählen';

  @override
  String get freeCookingListenTitle => 'Ich höre zu';

  @override
  String get freeCookingListenHint =>
      'Menge und Zutat sagen. Eine Pause trennt die Zeilen. Irgendwo tippen beendet.';

  @override
  String get freeCookingIdleTitle => 'Tippen und sprechen';

  @override
  String get freeCookingIdleHint => 'Zum Beispiel: 500 g Hähnchen, 40 g Butter';

  @override
  String get freeCookingTypeAction => 'Schreiben';

  @override
  String get freeCookingTypeHint => 'z. B. 200 g Reis';

  @override
  String get freeCookingAddAction => 'Hinzufügen';

  @override
  String get freeCookingCookAction => 'Kochen';

  @override
  String get freeCookingStockLoadFailed =>
      'Der Vorrat konnte nicht geladen werden.';

  @override
  String get freeCookingSaveFailed =>
      'Die Mahlzeit konnte nicht gespeichert werden.';

  @override
  String get freeCookingDiscardTitle => 'Mahlzeit verwerfen?';

  @override
  String get freeCookingDiscardBody => 'Die Zutaten gehen verloren.';

  @override
  String get freeCookingDiscardAction => 'Verwerfen';

  @override
  String get freeCookingVoiceUnavailable =>
      'Spracheingabe geht auf diesem Gerät nicht.';

  @override
  String get freeCookingVoicePermissionDenied =>
      'Erlaube das Mikrofon, um Zutaten zu sagen.';

  @override
  String get freeCookingVoiceFailed =>
      'Die Spracheingabe konnte nicht starten.';

  @override
  String get preparedMealFillTitle => 'Zeile füllen';

  @override
  String get preparedMealFillStockMatch => 'Im Vorrat gefunden';

  @override
  String get preparedMealFillTake => 'Übernehmen';

  @override
  String get preparedMealFillStock => 'Vorrat';

  @override
  String get preparedMealFillStockDescription => 'Anderes Lebensmittel wählen';

  @override
  String get preparedMealFillSearch => 'Suche';

  @override
  String get preparedMealFillSearchDescription => 'Produkt im Katalog finden';

  @override
  String get preparedMealFillBarcode => 'Barcode';

  @override
  String get preparedMealFillBarcodeDescription => 'Packung scannen';

  @override
  String get preparedMealFillAi => 'KI';

  @override
  String get preparedMealFillAiDescription => 'Aus Foto oder Text schätzen';

  @override
  String get preparedMealFillShoppingList => 'Auf die Einkaufsliste';

  @override
  String get preparedMealFillShoppingListFailed =>
      'Die Zeile konnte nicht auf die Einkaufsliste.';

  @override
  String get preparedMealFillShoppingListDescription =>
      'Zeile bleibt, wie sie ist';

  @override
  String get preparedMealFillIgnore => 'Zeile ignorieren';

  @override
  String preparedMealFillStockLeft(String amount) {
    return '$amount übrig';
  }

  @override
  String get keyboardDoneAction => 'Fertig';

  @override
  String get cookedKicker => 'Gekocht';

  @override
  String cookedOpenRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeilen offen',
      one: '1 Zeile offen',
    );
    return '$_temp0';
  }

  @override
  String get cookedFillRows => 'Füllen';

  @override
  String get cookedPotTitle => 'Aufteilen';

  @override
  String get cookedPortions => 'Portionen';

  @override
  String get cookedPortionsLess => 'Eine Portion weniger';

  @override
  String get cookedPortionsMore => 'Eine Portion mehr';

  @override
  String get cookedUtensil => 'Behälter';

  @override
  String get cookedPickUtensil => 'Wählen';

  @override
  String cookedUtensilOption(String name, int grams) {
    return '$name · $grams g';
  }

  @override
  String cookedUtensilWeight(int grams) {
    return '$grams g';
  }

  @override
  String get cookedGrossWeight => 'Auf der Waage';

  @override
  String get cookedWeighTip => 'Tipp: wiegen, wenn das Essen abgekühlt ist.';

  @override
  String cookedNetWeight(int grams) {
    return '$grams g Essen';
  }

  @override
  String get cookedTooLight => 'Nicht schwerer als der leere Behälter';

  @override
  String cookedPerPortionWeighed(int grams, int kcal) {
    return 'Portion $grams g · $kcal kcal';
  }

  @override
  String cookedPerPortion(int kcal) {
    return '$kcal kcal pro Portion';
  }

  @override
  String get cookedPieces => 'Stück';

  @override
  String get cookedPiecesLess => 'Ein Stück weniger';

  @override
  String get cookedPiecesMore => 'Ein Stück mehr';

  @override
  String cookedPiecesHint(int count) {
    return 'Stück brauchen kein Gewicht. Jedes Stück ist 1/$count der Nährwerte.';
  }

  @override
  String cookedPerPiece(int kcal) {
    return '$kcal kcal pro Stück';
  }

  @override
  String inventoryRowMealFromRecipePieces(String left, int total) {
    return 'Aus Rezept · $left von $total Stück';
  }

  @override
  String inventoryEatSheetPiecesHeader(num count, String amount) {
    return '$amount Stück';
  }

  @override
  String preparedMealPiecesRemaining(String remaining, int total) {
    return '$remaining/$total Stück';
  }

  @override
  String get cookedCombinedKicker => 'Kombiniert';

  @override
  String get cookedWeight => 'Gewicht';

  @override
  String cookedIngredientsWeight(int grams) {
    return '$grams g aus den Zutaten';
  }

  @override
  String get cookedWeighInstead => 'Gewicht stimmt nicht? Mit Behälter wiegen';

  @override
  String get cookedDiscardBody => 'Die Zutaten gehen zurück in den Vorrat.';

  @override
  String get cookedDiscardFailed =>
      'Mahlzeit konnte nicht verworfen werden. Die Zutaten sind noch nicht zurück im Vorrat.';

  @override
  String get cookedSave => 'In den Vorrat';

  @override
  String get cookedNeedsUtensil => 'Erst den Behälter wählen';

  @override
  String cookedSaved(String name) {
    return '$name ist im Vorrat';
  }

  @override
  String get cookedToCookbook => 'Ins Kochbuch';

  @override
  String get cookedToCookbookNote => 'Zutaten und Mengen von heute';

  @override
  String cookedSavedWithCookbook(String name) {
    return '$name ist im Vorrat und im Kochbuch';
  }

  @override
  String get cookedCookbookFailed =>
      'Die Mahlzeit ist im Vorrat, konnte aber nicht ins Kochbuch.';

  @override
  String recipeOriginalPortions(int count) {
    return 'Original für $count';
  }

  @override
  String get recipeStepsTitle => 'Zubereitung';

  @override
  String recipeStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schritte',
      one: '1 Schritt',
    );
    return '$_temp0';
  }

  @override
  String get recipeWithGuide => 'Mit Anleitung kochen';

  @override
  String get recipeWithGuideHint => 'Öffnet Satz für Satz; danach „Gekocht“';

  @override
  String get cookingGuideTitle => 'Kochhelfer';

  @override
  String cookingGuideKicker(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Portionen',
      one: '1 Portion',
    );
    return 'Anleitung · $_temp0';
  }

  @override
  String cookingGuideSentenceNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sätze',
      one: '1 Satz',
    );
    return '$_temp0. Danach kommt ein Satz pro Bildschirm, und der Bildschirm bleibt an.';
  }

  @override
  String get cookingGuideStart => 'Los geht\'s · Satz für Satz';

  @override
  String get cookingGuideKeepsScreenOn => 'Bildschirm bleibt an';

  @override
  String cookingGuideProgress(int sentence, int count, int step) {
    return 'Satz $sentence von $count · Schritt $step';
  }

  @override
  String get cookingGuideInPot => 'Im Topf';

  @override
  String cookingGuideLineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeilen',
      one: '1 Zeile',
    );
    return '$_temp0';
  }

  @override
  String recipeGuideAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zusätze aus dem Kochhelfer',
      one: '1 Zusatz aus dem Kochhelfer',
    );
    return '$_temp0';
  }

  @override
  String get cookingGuideJustAdded => 'Gerade dazu';

  @override
  String get cookingGuideVoiceHint => '„50 g Sahne“ · „nein“ macht rückgängig';

  @override
  String get cookingGuideJumpTitle => 'Springen zu';

  @override
  String get cookingGuideNext => 'Nächster Satz';

  @override
  String get cookingGuideDone => 'Fertig gekocht';

  @override
  String get recipeNotFound => 'Das Rezept gibt es nicht mehr.';

  @override
  String get recipeLoadFailed =>
      'Das Rezept oder der Vorrat konnte nicht geladen werden.';

  @override
  String recipeCheckChangeKicker(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Portionen',
      one: '1 Portion',
    );
    return '$name · $_temp0';
  }

  @override
  String get recipeCheckChangeTitle => 'Diesmal etwas ändern?';

  @override
  String get recipeCheckChangeHint =>
      'Zum Beispiel „mehr Fleisch“ oder „ohne Tomaten“. Gilt nur für dieses Mal.';

  @override
  String get recipeCheckChangeYes => 'Ja';

  @override
  String get recipeCheckChangeNo => 'Nein, weiter';

  @override
  String get recipeCheckEditKicker => 'Diesmal anders';

  @override
  String get recipeCheckEditTitle => 'Was änderst du?';

  @override
  String recipeCheckEditAmount(String food) {
    return 'Menge von $food';
  }

  @override
  String recipeCheckEditRemove(String food) {
    return '$food weglassen';
  }

  @override
  String get recipeCheckEditAdd => '+ Zutat';

  @override
  String get recipeCheckEditAddHint => 'z. B. 200 g Paprika';

  @override
  String get recipeCheckChanged => 'Geändert';

  @override
  String recipeCheckChangeAmount(String food, String from, String to) {
    return '$food $from → $to';
  }

  @override
  String recipeCheckChangeRemoved(String food) {
    return 'ohne $food';
  }

  @override
  String recipeCheckChangeOther(String food) {
    return '$food: andere Menge';
  }

  @override
  String recipeCheckChangeAdded(String food) {
    return '+ $food';
  }

  @override
  String recipeCheckChangeAddedAmount(String amount, String food) {
    return '+ $amount $food';
  }

  @override
  String get recipeCheckSaveEdits => 'Änderungen ins Rezept übernehmen';

  @override
  String get recipeCheckSaveEditsHint => 'Sonst gelten sie nur heute';

  @override
  String get recipeCheckTitle => 'Zutaten prüfen';

  @override
  String recipeCheckMissingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fehlen',
      one: '1 fehlt',
    );
    return '$_temp0';
  }

  @override
  String recipeCheckPartialCount(int count) {
    return '$count nur teilweise da';
  }

  @override
  String recipeCheckOpenBoth(int missing, int partial) {
    String _temp0 = intl.Intl.pluralLogic(
      missing,
      locale: localeName,
      other: '$missing fehlen',
      one: '1 fehlt',
    );
    return '$_temp0, $partial nur teilweise da';
  }

  @override
  String recipeCheckStep(int step, int total) {
    return '$step/$total';
  }

  @override
  String get recipeCheckSettled => 'Alles geklärt';

  @override
  String recipeCheckFoundKicker(int count) {
    return 'Im Vorrat gefunden · $count';
  }

  @override
  String get recipeCheckFoundTitle => 'Passt das?';

  @override
  String get recipeCheckFoundHint =>
      'Tippe auf eine Zutat, um einen anderen Artikel zu wählen.';

  @override
  String recipeCheckNextMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fehlen',
      one: '1 fehlt',
    );
    return 'Weiter · $_temp0';
  }

  @override
  String recipeCheckMissingKicker(int count) {
    return 'Fehlt · $count';
  }

  @override
  String get recipeCheckMissingTitle => 'Auf die Einkaufsliste?';

  @override
  String get recipeCheckMissingHint =>
      '„Hab ich“ trägt es in den Vorrat ein und nimmt es gleich.';

  @override
  String get recipeCheckHave => 'Hab ich';

  @override
  String recipeCheckRest(String amount) {
    return 'Rest · $amount sind da';
  }

  @override
  String recipeCheckPartialNote(String stocked, String missing) {
    return '$stocked da · $missing fehlen';
  }

  @override
  String get recipeCheckUse => 'Aus dem Vorrat';

  @override
  String get recipeCheckCart => 'Auf die Einkaufsliste';

  @override
  String get recipeCheckIgnore => 'Ignorieren';

  @override
  String get recipeCheckSummaryKicker => 'Fertig geprüft';

  @override
  String get recipeCheckSummaryTitle => 'So kochst du heute';

  @override
  String recipeCheckFromStock(int count) {
    return 'Aus dem Vorrat · $count';
  }

  @override
  String recipeCheckOnList(int count) {
    return 'Auf die Einkaufsliste · $count';
  }

  @override
  String recipeCheckIgnored(int count) {
    return 'Ignoriert · $count';
  }

  @override
  String get recipeCheckNothing => 'Nichts';

  @override
  String get recipeCheckNext => 'Weiter';

  @override
  String get recipeCheckFinish => 'Fertig';

  @override
  String get recipeCheckSaveFailed =>
      'Die Auswahl konnte nicht gespeichert werden.';

  @override
  String get recipeCheckListFailed =>
      'Die Einkaufsliste konnte nicht ergänzt werden.';

  @override
  String get recipeCheckHaveFailed =>
      'Das Lebensmittel konnte nicht in den Vorrat eingetragen werden.';

  @override
  String recipePickTitle(String food) {
    return '$food: woraus nehmen?';
  }

  @override
  String get recipeNotFromStock => 'Nicht aus dem Vorrat';

  @override
  String get cookedDoneElsewhere =>
      'Diese Mahlzeit ist schon gekocht und im Vorrat.';

  @override
  String get cookedLoadFailed => 'Die Mahlzeit konnte nicht geladen werden.';

  @override
  String get preparedMealGone => 'Mahlzeit nicht mehr im Vorrat';

  @override
  String cookbookInPotSince(String time) {
    return 'Im Topf seit $time';
  }

  @override
  String get appUpdateRequiredTitle => 'yamt aktualisieren';

  @override
  String get appUpdateRequiredBody =>
      'Diese Version von yamt ist zu alt für deine Daten. Aktualisiere die App, um weiterzumachen.';

  @override
  String get appUpdateAction => 'Aktualisieren';

  @override
  String appUpdateAvailable(String version) {
    return 'yamt $version ist verfügbar';
  }

  @override
  String get appUpdateStoreOpenFailed =>
      'Der Store konnte nicht geöffnet werden.';

  @override
  String whatsNewNotice(String version, String point) {
    return 'Neu in $version: $point';
  }

  @override
  String get whatsNewShowAll => 'Alles ansehen';

  @override
  String whatsNewTitle(String version) {
    return 'Neu in $version';
  }

  @override
  String get whatsNewAdded => 'Neu';

  @override
  String get whatsNewImproved => 'Verbessert';

  @override
  String get whatsNewFixed => 'Behoben';

  @override
  String whatsNewPoint(String point) {
    return '• $point';
  }

  @override
  String get connectivityOfflineBanner => 'Offline – keine Verbindung';

  @override
  String get connectivityBackOnline => 'Wieder online';

  @override
  String get progressPhotoCaptureTitle => 'Foto hinzufügen';

  @override
  String get progressPhotoPoseLabel => 'Pose';

  @override
  String get progressPhotoPoseFront => 'Vorne';

  @override
  String get progressPhotoPoseSide => 'Seitlich';

  @override
  String get progressPhotoPoseBack => 'Hinten';

  @override
  String get progressPhotoDayLabel => 'Tag';

  @override
  String get progressPhotoWeightLabel => 'Gewicht in kg (optional)';

  @override
  String get progressPhotoWeightHelper => 'Leer lassen: Gewicht des Tages';

  @override
  String progressPhotoWeightInvalid(String min, String max) {
    return 'Gib ein Gewicht zwischen $min und $max kg ein.';
  }

  @override
  String get progressPhotoReplaceHint =>
      'Für diesen Tag und diese Pose gibt es schon ein Foto. Ein neues ersetzt es.';

  @override
  String get progressPhotoSaveFailed =>
      'Das Foto konnte nicht gespeichert werden.';

  @override
  String get progressPhotoFromGallery => 'Aus Galerie';

  @override
  String get progressPhotoCamera => 'Kamera';

  @override
  String get progressPhotoPrivacy =>
      'Verschlüsselt. Nur du siehst deine Fotos.';

  @override
  String get progressPhotoSaved => 'Foto gespeichert';

  @override
  String progressPhotoCaption(String day, String kg) {
    return '$day · $kg kg';
  }

  @override
  String get progressPhotosLoadFailed =>
      'Die Fotos konnten nicht geladen werden.';

  @override
  String get progressPhotoLoadFailed => 'Das Foto konnte nicht geladen werden.';

  @override
  String get progressPhotoLabel => 'Fortschrittsfoto';

  @override
  String get progressActionWeighDescription => 'Gewicht für heute eintragen';

  @override
  String get progressActionPhoto => 'Foto';

  @override
  String get progressActionPhotoDescription =>
      'Fortschrittsfoto aufnehmen oder aus der Galerie';

  @override
  String get diaryCheckInPhotoTitle => 'Dein Weg bisher';

  @override
  String get diaryCheckInPhotoSubtitle =>
      'Gleiche Pose, gleiches Licht wie beim letzten Mal.';

  @override
  String get diaryCheckInPhotoFirst => 'Erstes';

  @override
  String get diaryCheckInPhotoMiddle => 'Mitte';

  @override
  String get diaryCheckInPhotoNew => 'Neu';

  @override
  String get diaryCheckInPhotoAdd => 'Foto';

  @override
  String get progressPhotosKicker => 'Fotos · Vorher / Nachher';

  @override
  String get progressPhotosEmpty =>
      'Noch keine Fotos. Füg eins hinzu oder mach es im nächsten Check-in.';

  @override
  String get progressPhotosEmptyPastGoal => 'Keine Fotos aus diesem Ziel.';

  @override
  String get progressPhotosAdd => 'Foto hinzufügen';

  @override
  String get progressPhotosAll => 'Alle Fotos';

  @override
  String get progressPhotosCompare => 'Vergleichen';

  @override
  String get progressPhotosBefore => 'Vorher';

  @override
  String get progressPhotosAfter => 'Nachher';

  @override
  String get progressPhotosTitle => 'Fotos';

  @override
  String progressPhotosGoalGroup(int number, String date) {
    return 'Ziel $number · seit $date';
  }

  @override
  String get progressPhotosBeforeGoals => 'Vor dem ersten Ziel';

  @override
  String progressPhotosWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'in $weeks Wochen',
      one: 'in 1 Woche',
      zero: 'diese Woche',
    );
    return '$_temp0';
  }

  @override
  String get progressPhotoDeleteTitle => 'Foto löschen?';

  @override
  String get progressPhotoDeleteBody => 'Das Foto wird endgültig gelöscht.';

  @override
  String get progressPhotoDelete => 'Löschen';

  @override
  String get progressPhotoDeleteFailed =>
      'Das Foto konnte nicht gelöscht werden.';

  @override
  String get progressPhotoReplace => 'Ersetzen';

  @override
  String get progressPhotoMove => 'Verschieben';

  @override
  String get progressPhotoOpen => 'Foto öffnen';

  @override
  String get progressPhotoMoveTitle => 'Foto verschieben';

  @override
  String get progressPhotoMoveReplaceTitle => 'Foto ersetzen?';

  @override
  String get progressPhotoMoveReplaceBody =>
      'An diesem Tag gibt es schon ein Foto dieser Pose. Es wird gelöscht.';

  @override
  String get progressPhotoMoveFailed =>
      'Das Foto konnte nicht verschoben werden.';

  @override
  String get progressPhotoMissing => 'Dieses Foto gibt es nicht mehr.';

  @override
  String progressPhotoViewerCaption(String pose, String caption) {
    return '$pose · $caption';
  }

  @override
  String get progressPhotoCompareTitle => 'Vergleich';

  @override
  String get progressPhotoCompareSlider => 'Vorher und Nachher vergleichen';

  @override
  String get progressWeightsTitle => 'Gewichte';

  @override
  String get progressWeightsAll => 'Alle Gewichte';

  @override
  String get progressWeightsRangeGoal => 'Ziel';

  @override
  String get progressWeightsRangeFourWeeks => '4 Wochen';

  @override
  String get progressWeightsRangeAll => 'Alles';

  @override
  String progressWeightsSinceGoal(String date) {
    return 'Seit Zielstart $date';
  }

  @override
  String progressWeightsSince(String date) {
    return 'Seit $date';
  }

  @override
  String progressWeightsTrend(String kg) {
    return 'Trend $kg kg';
  }

  @override
  String progressWeightsToTarget(String kg) {
    return 'noch $kg kg bis zum Ziel';
  }

  @override
  String progressWeightsTarget(String kg) {
    return 'Ziel $kg kg';
  }

  @override
  String progressWeightsRun(int number, String date) {
    return 'Run $number · seit $date';
  }

  @override
  String progressWeightsRunTrend(String trend, String change) {
    return 'Trend $trend kg · $change kg';
  }

  @override
  String get progressWeightsSourceManual => 'Von Hand';

  @override
  String get progressWeightsSourceScale => 'Waage';

  @override
  String get progressWeightsEmpty =>
      'In diesem Zeitraum gibt es noch keine Gewichte.';

  @override
  String get progressWeightsHealthTitle => 'Waage automatisch übernehmen';

  @override
  String get progressWeightsHealthBody =>
      'Verbinde Health, dann kommen die Gewichte deiner Waage von selbst.';

  @override
  String get progressWeightsHealthConnect => 'Health verbinden';

  @override
  String get progressWeightsHealthDismiss => 'Ausblenden';

  @override
  String shoppingPlanNeedsDialogTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zutaten fehlen',
      one: '1 Zutat fehlt',
    );
    return '$_temp0';
  }

  @override
  String get shoppingPlanNeedsDialogMessage => 'Auf die Einkaufsliste setzen?';

  @override
  String get shoppingPlanNeedsDialogSkip => 'Nicht jetzt';

  @override
  String get shoppingPlanNeedsDialogAdd => 'Auf die Liste';

  @override
  String get shoppingPlanNeedsDialogNeverAsk => 'Nicht mehr fragen';

  @override
  String get planShortageReminderChannelName => 'Fehlende Zutaten';

  @override
  String planShortageReminderTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Für morgen fehlen $count Zutaten',
      one: 'Für morgen fehlt 1 Zutat',
    );
    return '$_temp0';
  }

  @override
  String get planShortageReminderBody => 'Auf die Einkaufsliste setzen?';

  @override
  String get planShortageReminderCheckFailed =>
      'Die fehlenden Zutaten ließen sich nicht prüfen.';

  @override
  String get planShortageReminderSettingsFailed =>
      'Die Benachrichtigungseinstellungen ließen sich nicht öffnen.';

  @override
  String get planShortageReminderAllThere => 'Für den Plan ist alles da.';

  @override
  String get progressWeighingEditTitle => 'Gewicht bearbeiten';

  @override
  String get progressWeighingDayLabel => 'Tag';

  @override
  String get progressWeighingTimeLabel => 'Uhrzeit';

  @override
  String get progressWeighingDelete => 'Löschen';

  @override
  String get progressWeighingIgnore => 'Ignorieren';

  @override
  String get progressWeighingCount => 'Wieder zählen';

  @override
  String get progressWeighingOpenHealth => 'In Health öffnen';

  @override
  String get progressWeighingOtherDevice =>
      'Auf einem anderen Gerät in Health gespeichert. Ändern kannst du es nur dort.';

  @override
  String get progressWeighingDeleteFailed =>
      'Das Gewicht konnte nicht gelöscht werden.';

  @override
  String get progressWeighingIgnoreFailed =>
      'Das Gewicht konnte nicht geändert werden.';

  @override
  String get progressWeighingOpenHealthFailed =>
      'Health konnte nicht geöffnet werden.';

  @override
  String get progressWeighingHealthReadFailed =>
      'Health konnte nicht gelesen werden.';

  @override
  String get diaryBudgetKcalLeft => 'kcal übrig';

  @override
  String get diaryBudgetKcalLeftAfterPlan => 'kcal übrig nach Plan';

  @override
  String get diaryBudgetKcalOver => 'kcal drüber';

  @override
  String diaryBudgetOverValue(String kcal) {
    return '+$kcal';
  }

  @override
  String diaryBudgetPauseEaten(String kcal) {
    return '$kcal kcal gegessen';
  }

  @override
  String diaryBudgetPausePlanned(String kcal) {
    return '+ $kcal geplant';
  }

  @override
  String diaryBudgetMacroLeft(String grams) {
    return '$grams g';
  }

  @override
  String diaryBudgetMacroOver(String grams) {
    return '+$grams g';
  }

  @override
  String get diaryBudgetCarbsLabel => 'Kohlenh.';

  @override
  String get diaryBudgetViewLeft => 'Übrig';

  @override
  String get diaryBudgetViewEaten => 'Gegessen';

  @override
  String diaryBudgetKcalEatenOf(String target) {
    return 'kcal gegessen\nvon $target';
  }

  @override
  String diaryBudgetKcalWithPlanOf(String target) {
    return 'kcal mit Plan\nvon $target';
  }

  @override
  String diaryBudgetKcalEatenOfTarget(String eaten, String target) {
    return '$eaten / $target kcal';
  }

  @override
  String diaryBudgetMacroEaten(String grams) {
    return '$grams g gegessen';
  }

  @override
  String diaryBudgetMacroPlanned(String grams) {
    return '$grams geplant';
  }

  @override
  String get diaryBudgetBufferRow => 'Puffer-Anpassung';

  @override
  String get diaryBudgetCarryoverRow => 'Übertrag aus der Woche';

  @override
  String get diaryBudgetPlannedCountedRow => 'Geplant · eingerechnet';

  @override
  String get diaryBudgetOverRow => 'Drüber';

  @override
  String get diaryBudgetAllDays => 'Alle Tage';

  @override
  String get diaryBudgetWeekTitle => 'Tagesarten im Run';

  @override
  String diaryBudgetRunEndedNotice(String date) {
    return 'Run beendet · neuer Run zählt ab $date';
  }

  @override
  String diaryBudgetWeekDaySemantics(String day, String type) {
    return '$day: $type, tippen zum Wechseln';
  }

  @override
  String diaryBudgetWeekPauseDaySemantics(String day, String type) {
    return '$day: $type, mit dem Pause-Knopf setzen';
  }

  @override
  String diaryBudgetTrainingDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Trainingstage',
      one: '1 Trainingstag',
    );
    return '$_temp0';
  }

  @override
  String diaryMealKcalOfTarget(String eaten, String target) {
    return '$eaten / $target kcal';
  }

  @override
  String get diaryMealSharesTitle => 'Tagesabschnitte';

  @override
  String diaryMealSharesPart(String percent, String kcal) {
    return '$percent % · $kcal kcal';
  }

  @override
  String get diaryMealSharesReset => 'Zurücksetzen';

  @override
  String diaryMealSharesPercent(String percent) {
    return '$percent %';
  }

  @override
  String diaryMealSharesBorder(String before, String after) {
    return 'Grenze zwischen $before und $after';
  }

  @override
  String diaryMealSharesBorderValue(String before, String after) {
    return '$before % / $after %';
  }

  @override
  String get diaryMealSharesOff => 'Aus';

  @override
  String get diaryMealTimesDayStart => 'Tagesbeginn';

  @override
  String diaryMealTimesFrom(String time) {
    return 'ab $time';
  }

  @override
  String diaryMealTimesBy(String time) {
    return 'bis $time';
  }

  @override
  String get diaryBudgetMenuOpen => 'Tagesbudget-Menü öffnen';

  @override
  String get diaryBudgetMenuTitle => 'Tagesbudget';

  @override
  String get diaryBudgetMenuPace => 'Soll-Strich';

  @override
  String get diaryBudgetMenuPaceHint =>
      'Zeigt auf der kcal-Linie von heute, wo du jetzt stehen solltest, und bei jeder Mahlzeit ihr Ziel';

  @override
  String get diaryBudgetMenuAllMacros => 'Makros immer bunt';

  @override
  String get diaryBudgetMenuAllMacrosHint =>
      'Aus: nur das niedrigste Makro ist farbig';

  @override
  String get dataExportTitle => 'Exportieren';

  @override
  String get dataExportActionDescription =>
      'Essen, Gewicht und Ziele teilen – mit KI, Berater oder dir selbst';

  @override
  String get settingsDataExportTitle => 'Daten exportieren';

  @override
  String get dataExportPurposeHeader => 'Für wen';

  @override
  String get dataExportPurposeAi => 'Meine KI';

  @override
  String get dataExportPurposeAiDescription =>
      'Text mit Frage und erklärten Feldern · .txt';

  @override
  String get dataExportPurposeAdvisor => 'Ernährungsberater';

  @override
  String get dataExportPurposeAdvisorDescription =>
      'Bericht und Tabelle · .pdf + .xlsx';

  @override
  String get dataExportPurposeSelf => 'Für mich';

  @override
  String get dataExportPurposeSelfDescription => 'Bericht mit Grafiken · .pdf';

  @override
  String get dataExportRangeHeader => 'Zeitraum';

  @override
  String get dataExportRangeSevenDays => '7 Tage';

  @override
  String get dataExportRangeFourWeeks => '4 Wochen';

  @override
  String get dataExportRangeThreeMonths => '3 Monate';

  @override
  String get dataExportRangeCustom => 'Eigener …';

  @override
  String dataExportSummary(
    String from,
    String to,
    int days,
    int entries,
    int weighings,
  ) {
    return '$from – $to · Tage: $days · Einträge: $entries · Wiegungen: $weighings';
  }

  @override
  String get dataExportPrivacyNote =>
      'Die Datei ist nicht verschlüsselt. Wer sie bekommt, sieht deine Gesundheitsdaten.';

  @override
  String get dataExportShare => 'Teilen';

  @override
  String get dataExportShareFailed => 'Export konnte nicht erstellt werden.';

  @override
  String get dataExportLoadFailed => 'Daten konnten nicht geladen werden.';

  @override
  String get dataExportReportTitle => 'Ernährungsbericht';

  @override
  String dataExportReportPeriod(String from, String to, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage',
      one: '1 Tag',
    );
    return '$from – $to · $_temp0';
  }

  @override
  String get dataExportAiPrompt =>
      'Ich tracke mein Essen mit der App yamt. Unten stehen meine Daten aus diesem Zeitraum. Bewerte bitte meine Ernährung: Was mache ich gut, was falsch, und was soll ich konkret ändern, um mein Ziel zu erreichen? Beachte Trainings- und Pausentage.';

  @override
  String get dataExportFieldsHeader => 'Felder';

  @override
  String get dataExportFieldsText =>
      '- kcal: Kilokalorien. P, KH, F: Protein, Kohlenhydrate, Fett in Gramm.\n- Ziel: kcal- und Makroziel des Tages. Trainingstage haben ein höheres kcal-Ziel, Ruhetage ein niedrigeres, damit die Woche aufgeht.\n- Pausentag: ein Tag ohne Ziel, zum Beispiel bei Krankheit oder im Urlaub.\n- TDEE: geschätzter Tagesverbrauch, gelernt aus Gewicht und Essen.\n- Gewicht: Wiegung des Tages; Trend: geglättetes Gewicht.\n- Tagesabschnitte: wie sich das kcal-Ziel des Tages auf die Mahlzeiten aufteilt.';

  @override
  String get dataExportGoalsHeader => 'Ziele';

  @override
  String dataExportGoalLine(
    int number,
    String mode,
    String start,
    String end,
    String startWeight,
    String targetWeight,
    String speed,
    String kcal,
  ) {
    return 'Ziel $number: $mode, $start – $end, Startgewicht $startWeight kg, Zielgewicht $targetWeight kg, $speed kg pro Woche, $kcal kcal pro Tag vor Trainings- und Ruhetag-Ausgleich';
  }

  @override
  String get dataExportGoalRunning => 'läuft';

  @override
  String get dataExportNoGoal => 'Kein Ziel in diesem Zeitraum.';

  @override
  String dataExportMealShares(String shares) {
    return 'Tagesabschnitte: $shares';
  }

  @override
  String dataExportMealShare(String meal, int percent) {
    return '$meal $percent %';
  }

  @override
  String get dataExportOverviewHeader => 'Übersicht';

  @override
  String dataExportOverviewLine(
    String kcal,
    String protein,
    String carbs,
    String fat,
    String tdee,
  ) {
    return 'Schnitt pro Tag mit Einträgen: $kcal kcal, Protein $protein g, Kohlenhydrate $carbs g, Fett $fat g. Schnitt TDEE: $tdee kcal.';
  }

  @override
  String dataExportWeightLine(String first, String last, String change) {
    return 'Gewicht: $first kg → $last kg ($change kg)';
  }

  @override
  String dataExportDayTypesLine(int training, int normal, int pause) {
    return 'Tage: $training Training, $normal normal, $pause Pause';
  }

  @override
  String get dataExportDaysHeader => 'Tage';

  @override
  String dataExportDayLine(
    String date,
    String type,
    String kcal,
    String goal,
    String protein,
    String proteinGoal,
    String carbs,
    String carbsGoal,
    String fat,
    String fatGoal,
  ) {
    return '$date · $type · $kcal / $goal kcal · P $protein/$proteinGoal g · KH $carbs/$carbsGoal g · F $fat/$fatGoal g';
  }

  @override
  String dataExportDayWeight(String weight, String trend) {
    return 'Gewicht $weight kg, Trend $trend kg';
  }

  @override
  String dataExportDayTdee(String tdee) {
    return 'TDEE $tdee kcal';
  }

  @override
  String get dataExportNoEntries => 'Keine Einträge';

  @override
  String dataExportMealLine(String meal, String kcal) {
    return '$meal · $kcal kcal';
  }

  @override
  String dataExportFoodLine(
    String name,
    String amount,
    String kcal,
    String protein,
    String carbs,
    String fat,
  ) {
    return '$name · $amount · $kcal kcal · P $protein g · KH $carbs g · F $fat g';
  }

  @override
  String get dataExportKpiEaten => 'Ø gegessen';

  @override
  String get dataExportKpiTdee => 'Ø TDEE';

  @override
  String get dataExportKpiWeight => 'Gewicht';

  @override
  String get dataExportKpiDays => 'Training / Pause';

  @override
  String dataExportKpiGoal(String kcal) {
    return 'kcal · Ziel $kcal';
  }

  @override
  String get dataExportChartCombined => 'Essen, Gewicht und TDEE zusammen';

  @override
  String get dataExportChartWeight => 'Gewicht';

  @override
  String get dataExportChartTdee => 'TDEE-Verlauf';

  @override
  String get dataExportChartKcal => 'kcal gegessen vs. Ziel';

  @override
  String get dataExportChartMacros => 'Makros im Schnitt vs. Ziel';

  @override
  String get dataExportLegendEaten => 'gegessen';

  @override
  String get dataExportLegendGoal => 'Ziel';

  @override
  String get dataExportLegendWeight => 'Gewicht';

  @override
  String get dataExportLegendTdee => 'TDEE';

  @override
  String get dataExportColumnDate => 'Datum';

  @override
  String get dataExportColumnDayType => 'Tagestyp';

  @override
  String get dataExportColumnGoal => 'Ziel kcal';

  @override
  String get dataExportColumnKcal => 'kcal';

  @override
  String get dataExportColumnProtein => 'Protein g';

  @override
  String get dataExportColumnProteinGoal => 'Protein Ziel g';

  @override
  String get dataExportColumnCarbs => 'KH g';

  @override
  String get dataExportColumnCarbsGoal => 'KH Ziel g';

  @override
  String get dataExportColumnFat => 'Fett g';

  @override
  String get dataExportColumnFatGoal => 'Fett Ziel g';

  @override
  String get dataExportColumnWeight => 'Gewicht kg';

  @override
  String get dataExportColumnTrend => 'Trend kg';

  @override
  String get dataExportColumnTdee => 'TDEE kcal';

  @override
  String get dataExportColumnMeal => 'Mahlzeit';

  @override
  String get dataExportColumnMealGoal => 'Tagesabschnitt kcal';

  @override
  String get dataExportColumnFood => 'Lebensmittel';

  @override
  String get dataExportColumnBrand => 'Marke';

  @override
  String get dataExportColumnAmount => 'Menge';

  @override
  String get dataExportColumnUnit => 'Einheit';

  @override
  String get dataExportColumnNumber => 'Ziel';

  @override
  String get dataExportColumnMode => 'Modus';

  @override
  String get dataExportColumnStart => 'Start';

  @override
  String get dataExportColumnEnd => 'Ende';

  @override
  String get dataExportColumnStartWeight => 'Startgewicht kg';

  @override
  String get dataExportColumnTargetWeight => 'Zielgewicht kg';

  @override
  String get dataExportColumnSpeed => 'kg pro Woche';

  @override
  String get dataExportColumnBaseKcal => 'Basis kcal';

  @override
  String get dataExportColumnShare => 'Anteil %';

  @override
  String get dataExportSheetDays => 'Tage';

  @override
  String get dataExportSheetMeals => 'Mahlzeiten';

  @override
  String get dataExportSheetFoods => 'Lebensmittel';

  @override
  String get dataExportSheetGoals => 'Ziele';

  @override
  String get dataExportFooter => 'Erstellt mit yamt';

  @override
  String dataExportMacroBar(String name, String value, String goal) {
    return '$name $value / $goal g';
  }

  @override
  String dataExportKpiWeightRange(String first, String last) {
    return '$first → $last kg';
  }

  @override
  String get dataExportCopy => 'Kopieren';

  @override
  String get dataExportCopied => 'Kopiert. Füge es in deinen KI-Chat ein.';

  @override
  String get dataExportSave => 'Speichern';

  @override
  String get dataExportSaved => 'Gespeichert.';

  @override
  String get dataExportRangeAll => 'Alle Daten';

  @override
  String get dataExportRangeGoals => 'Ziele';

  @override
  String dataExportRangeGoalSpan(int first, int last) {
    return 'Ziele $first–$last';
  }

  @override
  String dataExportFoodPending(String name) {
    return '$name · Nährwerte noch offen';
  }

  @override
  String get dataExportListSeparator => ', ';

  @override
  String get dataExportPartsSeparator => ' · ';

  @override
  String dataExportWeightValue(String weight) {
    return '$weight kg';
  }

  @override
  String dataExportValueOfGoal(String value, String goal) {
    return '$value / $goal';
  }

  @override
  String dataExportTrainingPauseCount(int training, int pause) {
    return '$training / $pause';
  }

  @override
  String get dataExportKcalUnit => 'kcal';

  @override
  String get cookStepRecipe => 'Rezept';

  @override
  String get cookStepShopping => 'Einkauf';

  @override
  String get cookStepCooking => 'Kochen';

  @override
  String get cookStepPortion => 'Portionieren';

  @override
  String cookPortionsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Portionen',
      one: '1 Portion',
    );
    return '$_temp0';
  }

  @override
  String get cookFewer => 'Weniger';

  @override
  String get cookMore => 'Mehr';

  @override
  String get cookIngredients => 'Zutaten';

  @override
  String get cookAssignAction => 'Zutaten zuordnen';

  @override
  String cookFoundKicker(int done, int count) {
    return '$done von $count Zutaten';
  }

  @override
  String get cookFoundTitle => 'Im Vorrat gefunden';

  @override
  String get cookFoundHint =>
      'Passt der Vorschlag? Tippe den Artikel für einen anderen.';

  @override
  String get cookFits => 'Passt';

  @override
  String get cookFitsNot => 'Passt nicht';

  @override
  String cookMissingAmount(String amount) {
    return 'Es fehlen $amount';
  }

  @override
  String cookCheckRest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count prüfen',
      one: 'Noch 1 prüfen',
    );
    return '$_temp0';
  }

  @override
  String get cookNext => 'Weiter';

  @override
  String cookOpenKicker(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zutaten',
      one: '1 Zutat',
    );
    return '$_temp0';
  }

  @override
  String get cookOpenTitle => 'Noch zu klären';

  @override
  String get cookOpenHint => 'Aus dem Vorrat zuordnen oder weglassen.';

  @override
  String get cookOpenNoItem => 'Kein Artikel im Vorrat';

  @override
  String get cookOpenRejected => 'Vorschlag abgelehnt';

  @override
  String get cookOpenOmitted => 'Weggelassen';

  @override
  String get cookAssign => 'Zuordnen';

  @override
  String get cookOmit => 'Weglassen';

  @override
  String cookStockLeft(String amount) {
    return '$amount da';
  }

  @override
  String get cookPotTitle => 'Worin kochst du?';

  @override
  String get cookPotHint =>
      'Am Ende wiegst du den vollen Topf; sein Leergewicht ist bekannt.';

  @override
  String cookPotEmptyWeight(int grams) {
    return 'leer $grams g';
  }

  @override
  String get cookPotUnnamed => 'Topf';

  @override
  String get cookPotNone => 'Ohne Topf · nach Anzahl';

  @override
  String get cookDoneCooking => 'Fertig gekocht';

  @override
  String get cookPortionTitle => 'In den Vorrat';

  @override
  String get cookMealName => 'Name';

  @override
  String get cookGrossWeight => 'Topf mit Essen (g)';

  @override
  String cookNetWeight(int grams) {
    return 'Essen: $grams g';
  }

  @override
  String cookWeightTooLow(int grams) {
    return 'Schwerer als der leere Topf ($grams g)';
  }

  @override
  String get cookCountPortions => 'Portionen';

  @override
  String get cookCountPieces => 'Stück';

  @override
  String get cookToStock => 'In Vorrat';

  @override
  String cookSaved(String name) {
    return '$name ist im Vorrat';
  }

  @override
  String get cookFinishFailed =>
      'Konnte die Mahlzeit nicht in den Vorrat legen.';

  @override
  String get cookFinishMissingNutrition => 'Einer Zutat fehlen Nährwerte.';

  @override
  String get cookFinishTooLittle =>
      'Der Vorrat hat sich geändert: ein Artikel reicht nicht mehr.';

  @override
  String get cookFinishItemGone => 'Ein Artikel ist nicht mehr im Vorrat.';

  @override
  String get cookPickerKicker => 'Zeile füllen';

  @override
  String get cookPickerHint => 'Passend im Vorrat · antippen in Reihenfolge';

  @override
  String cookPickerSum(String have, String need) {
    return 'Zusammen: $have von $need';
  }

  @override
  String get cookPickerEmpty => 'Nichts Passendes im Vorrat.';

  @override
  String get cookPickerApply => 'Übernehmen';

  @override
  String get cookRecipeGone => 'Das Rezept ist nicht mehr im Kochbuch.';

  @override
  String get cookLoadFailed => 'Konnte das Rezept nicht laden.';

  @override
  String get cookPickerShowAll => 'Alle Vorrat-Artikel zeigen';

  @override
  String cookAmountGrams(String amount) {
    return '$amount g';
  }

  @override
  String cookAmountMilliliters(String amount) {
    return '$amount ml';
  }

  @override
  String cookAmountPieces(String amount) {
    return '$amount Stk';
  }

  @override
  String cookAmountOf(String amount, String food) {
    return '$amount $food';
  }

  @override
  String cookStockAfterTake(String amount) {
    return '· $amount da';
  }

  @override
  String get cookFinishNothingTaken =>
      'Noch nichts aus dem Vorrat in diesem Gericht.';

  @override
  String get cookPotLoadFailed => 'Konnte deine Töpfe nicht laden.';
}
