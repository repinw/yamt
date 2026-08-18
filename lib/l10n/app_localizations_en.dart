// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get homeInventory => 'Inventory';

  @override
  String get homeShopping => 'Shopping';

  @override
  String get homeCalories => 'Diary';

  @override
  String get homeCookbook => 'Cookbook';

  @override
  String get homeSettings => 'Settings';

  @override
  String get aiChefTooltip => 'Let the AI suggest a random recipe';

  @override
  String get aiChefSetupTitle => 'What should the AI cook?';

  @override
  String get aiChefSetupSubtitle => 'Choose whether your inventory matters and add any wishes.';

  @override
  String get aiChefUseInventoryTitle => 'Use inventory';

  @override
  String get aiChefUseInventorySubtitle => 'Prefer ingredients that are currently in stock.';

  @override
  String get aiChefWishesLabel => 'Wishes';

  @override
  String get aiChefWishesHint => 'e.g. vegetarian, quick, high protein, no rice';

  @override
  String get aiChefGenerateAction => 'Generate recipe';

  @override
  String get aiChefGeneratingTitle => 'AI is cooking...';

  @override
  String get aiChefGeneratingSubtitle => 'Your personal AI is assembling a delicious recipe...';

  @override
  String get aiChefSaveAction => 'Save to Cookbook';

  @override
  String get aiChefCloseAction => 'Close';

  @override
  String get aiChefSaveSuccess => 'Recipe successfully saved to Cookbook!';

  @override
  String get aiChefSaveError => 'Failed to save recipe.';

  @override
  String get aiChefFromInventory => 'From your stock';

  @override
  String get aiChefQuoteLoveGarlic => 'The secret ingredient is always love. And garlic.';

  @override
  String get aiChefQuoteCookingMagic => 'Cooking is like magic, except you can eat the results.';

  @override
  String get aiChefQuoteGoodFood => 'Good food brings good mood.';

  @override
  String get aiChefQuoteKitchenTalks => 'The best conversations always happen in the kitchen.';

  @override
  String get aiChefQuoteVirtualOven => 'AI is preheating the virtual oven...';

  @override
  String aiChefPortionsLabel(int portions) {
    String _temp0 = intl.Intl.pluralLogic(
      portions,
      locale: localeName,
      other: '$portions portions',
      one: '1 portion',
    );
    return '$_temp0';
  }

  @override
  String aiChefCaloriesLabel(int kcal) {
    return '$kcal kcal';
  }

  @override
  String aiChefProteinLabel(int grams) {
    return 'Protein: $grams g';
  }

  @override
  String aiChefCarbsLabel(int grams) {
    return 'Carbs: $grams g';
  }

  @override
  String aiChefFatLabel(int grams) {
    return 'Fat: $grams g';
  }

  @override
  String get homeQuickActionTooltip => 'Quick action';

  @override
  String homeHeartCounterUseTooltip(String day) {
    return 'Use heart for $day';
  }

  @override
  String homeHeartCounterActiveTooltip(String day) {
    return '$day is already a heart day';
  }

  @override
  String get homeHeartCounterEmptyTooltip => 'No hearts left';

  @override
  String get homeHeartCounterUnavailableTooltip => 'Hearts can only be used during the current Burn Week';

  @override
  String get homeHeartUseTitle => 'Use heart day?';

  @override
  String homeHeartUseMessage(String day) {
    return 'Spend 1 heart to ignore $day. Logged food stays in the diary, but this day counts as perfect and is skipped for weekly learning.';
  }

  @override
  String get homeHeartUseConfirmAction => 'Use heart';

  @override
  String get inventoryFabTooltip => 'Add product';

  @override
  String get productSearchHubTitle => 'Add product';

  @override
  String get productSearchHubInventoryTitle => 'Add to inventory';

  @override
  String get productSearchHubDiaryTitle => 'Eat food';

  @override
  String get productSearchHubBarcodeAction => 'Barcode';

  @override
  String get productSearchHubAiAction => 'AI';

  @override
  String get productSearchHubReceiptAction => 'Receipt';

  @override
  String get productSearchHubInventoryAction => 'From inventory';

  @override
  String get productSearchHubMealAction => 'Meal';

  @override
  String get productSearchHubCreateOwnAction => 'Create';

  @override
  String get productSearchHubSearchLabel => 'Search product';

  @override
  String get productSearchHubSearchHint => 'Name, brand...';

  @override
  String get productSearchHubClearSearchAction => 'Clear search';

  @override
  String get productSearchHubSearchLoading => 'Searching products';

  @override
  String get productSearchHubSearchLoadFailed => 'Product search failed.';

  @override
  String get productSearchHubSearchRetryAction => 'Retry';

  @override
  String get productSearchHubSearchEmptyState => 'No matching products found.';

  @override
  String get productSearchHubCreateProductAction => 'Create product';

  @override
  String get productSearchHubCartTitle => 'Selected products';

  @override
  String get productSearchHubCartAddAction => 'Add';

  @override
  String get productSearchHubCartRemoveAction => 'Remove';

  @override
  String get productSearchHubRecentlySelectedTab => 'Recently selected';

  @override
  String get productSearchHubRecentlySelectedLoading => 'Loading recent products';

  @override
  String get productSearchHubRecentlySelectedLoadFailed => 'Could not load recent products.';

  @override
  String get productSearchHubRecentlySelectedRetryAction => 'Retry';

  @override
  String get productSearchHubRecentlySelectedEmptyState => 'No recently selected products yet.';

  @override
  String get inventoryPageTitle => 'My inventory';

  @override
  String get inventoryActionScanCamera => 'Scan receipt (camera)';

  @override
  String get inventoryActionUploadFile => 'Upload receipt (image/PDF)';

  @override
  String get inventoryActionCameraUnsupported => 'Camera is not supported on this platform.';

  @override
  String get inventoryActionManualAdd => 'Add food manually';

  @override
  String get inventoryActionManualSearch => 'Manual search';

  @override
  String get inventoryActionAiSuggestion => 'AI suggestion';

  @override
  String get inventoryActionUploadImagePdf => 'Upload image/PDF';

  @override
  String get inventoryActionCamera => 'Camera';

  @override
  String get inventorySharedReceiptConfirmTitle => 'Scan shared receipt?';

  @override
  String get inventorySharedReceiptConfirmSingleMessage => 'Do you want to scan this shared file as a receipt?';

  @override
  String inventorySharedReceiptConfirmMultipleMessage(int count) {
    return 'Do you want to scan $count shared files as receipts?';
  }

  @override
  String get inventorySharedReceiptConfirmAction => 'Scan';

  @override
  String get inventoryReceiptSelectionFailed => 'Could not select a receipt. Please try again.';

  @override
  String get inventoryReceiptAnalysisFailed => 'Receipt analysis failed. Please try again.';

  @override
  String get inventoryReceiptBatchTitle => 'Processing receipts';

  @override
  String inventoryReceiptBatchProgress(int processed, int total) {
    return '$processed/$total';
  }

  @override
  String get inventoryReceiptBatchQueued => 'Queued';

  @override
  String get inventoryReceiptBatchProcessing => 'Processing';

  @override
  String get inventoryReceiptBatchSucceeded => 'Done';

  @override
  String get inventoryReceiptBatchFailed => 'Failed';

  @override
  String get inventoryReceiptBatchReviewAction => 'Review';

  @override
  String get inventoryReceiptBatchReviewed => 'Reviewed';

  @override
  String get inventoryReceiptBatchCloseAction => 'Close';

  @override
  String get inventoryReceiptReviewTitle => 'Review receipt';

  @override
  String get inventoryReceiptReviewPriceTitle => 'Total amount';

  @override
  String get inventoryReceiptReviewPriceTotal => 'According to detected receipt';

  @override
  String get inventoryReceiptReviewPriceSavable => 'Saved to inventory';

  @override
  String get inventoryReceiptReviewPriceExcluded => 'Excluded lines';

  @override
  String get inventoryReceiptReviewEmpty => 'No items found on this receipt.';

  @override
  String get inventoryReceiptReviewExcludedTag => 'Review only';

  @override
  String get inventoryReceiptReviewEditAction => 'Edit';

  @override
  String get inventoryReceiptReviewEditTitle => 'Edit receipt item';

  @override
  String get inventoryReceiptReviewApplyItemAction => 'Apply changes';

  @override
  String get inventoryReceiptReviewFieldName => 'Name';

  @override
  String get inventoryReceiptReviewFieldStoreName => 'Store name';

  @override
  String get inventoryReceiptReviewFieldQuantity => 'Quantity';

  @override
  String get inventoryReceiptReviewFieldUnitPrice => 'Unit price';

  @override
  String get inventoryReceiptReviewFieldWeight => 'Weight';

  @override
  String get inventoryReceiptReviewFieldWeightUnit => 'Unit';

  @override
  String get inventoryReceiptReviewFieldWeightUnitFallback => 'Fallback unit';

  @override
  String get inventoryReceiptReviewWeightUnitAuto => 'Auto';

  @override
  String get inventoryReceiptReviewWeightUnitGram => 'Gram (g)';

  @override
  String get inventoryReceiptReviewWeightUnitMilliliter => 'Milliliter (ml)';

  @override
  String get inventoryReceiptReviewWeightUnitPiece => 'Piece';

  @override
  String get inventoryUnitGram => 'g';

  @override
  String get inventoryUnitMilliliter => 'ml';

  @override
  String get inventoryUnitPiece => 'pc';

  @override
  String get inventoryReceiptReviewFieldBrand => 'Brand';

  @override
  String get inventoryReceiptReviewFieldCategory => 'Category';

  @override
  String get inventoryReceiptReviewFieldDiscounts => 'Discounts';

  @override
  String get inventoryReceiptReviewDiscountNameLabel => 'Discount label';

  @override
  String get inventoryReceiptReviewDiscountAmountLabel => 'Amount';

  @override
  String get inventoryReceiptReviewAddDiscountAction => 'Add discount row';

  @override
  String get inventoryReceiptReviewFieldIsDeposit => 'Is deposit item';

  @override
  String get inventoryReceiptReviewFieldIsDiscount => 'Is discount item';

  @override
  String get inventoryReceiptReviewNoDate => 'No date';

  @override
  String get inventoryReceiptReviewInvalidNumber => 'Please enter valid numbers.';

  @override
  String get inventoryReceiptReviewInvalidWeightUnit => 'Please add a unit (e.g. g or ml).';

  @override
  String get inventoryReceiptReviewConfirmItemAction => 'Confirm item';

  @override
  String get inventoryReceiptReviewUndoConfirmAction => 'Undo confirmation';

  @override
  String get inventoryReceiptReviewInvalidDiscounts => 'Use JSON or key=value pairs.';

  @override
  String get inventoryReceiptReviewDetectedItems => 'Detected items';

  @override
  String get inventoryReceiptReviewOriginalReceiptAction => 'View original receipt';

  @override
  String get inventoryReceiptReviewOriginalReceiptTitle => 'Original receipt preview';

  @override
  String get inventoryReceiptReviewOriginalReceiptUnavailable => '(The receipt photo would appear here)';

  @override
  String get inventoryReceiptReviewReadAsPrefix => 'Read as';

  @override
  String get inventoryReceiptReviewCandidatesAction => 'Candidates';

  @override
  String get inventoryReceiptReviewProductSelectionLabel => 'Select product';

  @override
  String get inventoryReceiptReviewManualSearchLabel => 'Search product';

  @override
  String get inventoryReceiptReviewRecentProductsTitle => 'Recently added';

  @override
  String get inventoryReceiptReviewManualDataAction => 'Search product or scan barcode';

  @override
  String get inventoryReceiptReviewManualDataTitle => 'Search product or scan barcode';

  @override
  String get inventoryReceiptReviewManualDataHint => 'Search product or scan barcode. Add nutrition later.';

  @override
  String get inventoryReceiptReviewManualDataSaveAction => 'Apply';

  @override
  String get inventoryReceiptReviewManualDataRequired => 'Please select a product, scan a barcode, or add nutrition.';

  @override
  String get inventoryReceiptReviewSwitchAction => 'Switch';

  @override
  String get inventoryReceiptReviewCancelAction => 'Cancel';

  @override
  String get inventoryReceiptReviewSaveAction => 'Save';

  @override
  String get inventoryReceiptSaveSucceeded => 'Items added to inventory.';

  @override
  String get inventoryReceiptSaveFailed => 'Could not save receipt items. Please try again.';

  @override
  String get inventoryListModeByReceipt => 'By receipt';

  @override
  String get inventoryListModeAllItems => 'All foods';

  @override
  String get inventoryViewStock => 'Stock';

  @override
  String get inventoryViewHistory => 'History';

  @override
  String get inventoryRecentSectionTitle => 'Foods';

  @override
  String get inventoryActivityLoading => 'Loading history...';

  @override
  String get inventoryActivityLoadFailed => 'Could not load history.';

  @override
  String get inventoryActivityEmptyTitle => 'No inventory history yet.';

  @override
  String get inventoryActivityActorFallback => 'Household member';

  @override
  String inventoryActivityPieceAmount(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String inventoryActivityItemAdded(String actor, String item, String amount) {
    return '$actor added $amount of $item.';
  }

  @override
  String inventoryActivityItemConsumed(String actor, String item, String amount) {
    return '$actor ate $amount of $item.';
  }

  @override
  String inventoryActivityItemDiscarded(String actor, String item, String amount) {
    return '$actor discarded $amount of $item.';
  }

  @override
  String inventoryActivityItemDeleted(String actor, String item, String amount) {
    return '$actor deleted $amount of $item.';
  }

  @override
  String inventoryActivityItemRestored(String actor, String item, String amount) {
    return '$actor restored $amount of $item.';
  }

  @override
  String inventoryActivityItemUsedInPreparedMeal(String actor, String item, String amount) {
    return '$actor used $amount of $item for a prepared meal.';
  }

  @override
  String inventoryActivityItemReturnedFromPreparedMeal(String actor, String item, String amount) {
    return '$actor returned $amount of $item from a prepared meal.';
  }

  @override
  String get inventorySearchLabel => 'Search inventory';

  @override
  String get inventorySearchClearAction => 'Clear search';

  @override
  String get inventoryFilterAction => 'Filter items';

  @override
  String get inventoryFiltersTitle => 'Adjust view';

  @override
  String get inventoryFiltersSubtitle => 'Sort and filter your foods';

  @override
  String get inventoryFiltersShowResultsAction => 'Show results';

  @override
  String get inventoryViewSectionTitle => 'View';

  @override
  String get inventoryViewListAction => 'List';

  @override
  String get inventoryViewTilesAction => 'Tiles';

  @override
  String get inventorySortSectionTitle => 'Sort';

  @override
  String get inventoryFilterSectionTitle => 'Filter';

  @override
  String get inventorySortAdded => 'Added';

  @override
  String get inventorySortEaten => 'Eaten';

  @override
  String get inventorySortAlphabetical => 'Alphabetical';

  @override
  String get inventorySortQuantity => 'Amount';

  @override
  String get inventorySortDirectionAscending => 'Ascending';

  @override
  String get inventorySortDirectionDescending => 'Descending';

  @override
  String get inventorySortDirectionAlphaAscending => 'A to Z';

  @override
  String get inventorySortDirectionAlphaDescending => 'Z to A';

  @override
  String get inventoryNutritionCaloriesShortLabel => 'Kcal';

  @override
  String get inventoryNutritionCarbsShortLabel => 'Carbs';

  @override
  String get inventoryFilterConsumed => 'Consumed';

  @override
  String get inventoryFilterNotConsumed => 'Not consumed';

  @override
  String get inventoryHideConsumedFilterTitle => 'Hide consumed';

  @override
  String get inventoryHideConsumedFilterSubtitle => 'Hide completely empty items';

  @override
  String get inventoryHideFullyConsumedItemsToggle => 'Hide fully consumed items';

  @override
  String get preparedMealFilterAction => 'Filter meals';

  @override
  String get preparedMealFiltersTitle => 'Adjust view';

  @override
  String get preparedMealFiltersSubtitle => 'Sort and filter your meals';

  @override
  String get preparedMealShowReadyOnlyToggle => 'Only ready meals';

  @override
  String get preparedMealShowIncompleteOnlyToggle => 'Only incomplete meals';

  @override
  String get preparedMealShowDepletedOnlyToggle => 'Only fully consumed';

  @override
  String get preparedMealHideFullyConsumedItemsToggle => 'Hide fully consumed meals';

  @override
  String get inventoryReceiptGroupTitle => 'Receipt';

  @override
  String get inventoryReceiptGroupNoReceipt => 'No receipt';

  @override
  String get inventoryReceiptGroupItems => 'items';

  @override
  String get inventoryItemDeleteAction => 'Delete';

  @override
  String get inventoryItemDeletedMessage => 'Item deleted.';

  @override
  String get inventoryItemRemovedMessage => 'Item removed.';

  @override
  String get inventoryItemEatAction => 'Eat';

  @override
  String get inventoryItemEatSheetEyebrow => 'Log food';

  @override
  String inventoryItemEatSheetTitle(String name) {
    return 'Eat: $name';
  }

  @override
  String get inventoryItemEatSheetAmountLabel => 'Enter amount';

  @override
  String inventoryItemEatSheetAvailableAmount(Object amount, Object unit) {
    return 'Available in inventory: $amount $unit';
  }

  @override
  String get inventoryItemEatSheetQuickSelectLabel => 'Quick select';

  @override
  String get inventoryItemEatSheetAllAction => 'All';

  @override
  String get inventoryAmountDialogAllRemainingAction => 'All/Rest';

  @override
  String get inventoryItemEatSheetPortionModeTitle => 'Portions';

  @override
  String get inventoryItemEatSheetUsePortionsToggle => 'Use portion count';

  @override
  String get inventoryItemEatSheetPortionLabelFieldLabel => 'Portion label';

  @override
  String get inventoryItemEatSheetPortionCountFieldLabel => 'Count';

  @override
  String get inventoryItemEatSheetPortionAmountFieldLabel => 'Amount per portion';

  @override
  String get inventoryItemEatSheetDecreasePortionCountAction => 'Decrease portions';

  @override
  String get inventoryItemEatSheetIncreasePortionCountAction => 'Increase portions';

  @override
  String get inventoryItemEatSheetDefaultPortionLabel => 'Portion';

  @override
  String get inventoryItemEatSheetNewPortionAction => '+ New portion...';

  @override
  String get inventoryItemEatSheetNewPortionTitle => 'New portion';

  @override
  String get inventoryItemEatSheetSavePortionAction => 'Save portion';

  @override
  String get inventoryItemEatSheetUnitGram => 'Gram';

  @override
  String get inventoryItemEatSheetUnitMilliliter => 'Milliliter';

  @override
  String get inventoryItemEatSheetUnitPiece => 'Piece';

  @override
  String inventoryItemEatSheetPortionTotalLabel(String amount, String unit) {
    return 'Total: $amount $unit';
  }

  @override
  String get inventoryItemEatSheetInedibleAmountLabel => 'Subtract inedible part';

  @override
  String get inventoryItemEatSheetInedibleAmountHint => 'Optional, e.g. bones';

  @override
  String get inventoryItemEatSheetInedibleAmountFieldLabel => 'Inedible amount';

  @override
  String get inventoryItemEatSheetInedibleAmountError => 'The deducted amount must be smaller than the eaten amount.';

  @override
  String get inventoryItemEatSheetWhenLabel => 'When?';

  @override
  String get inventoryItemEatSheetNowValue => 'Today';

  @override
  String get inventoryItemEatSheetNutritionLabel => 'Nutrition';

  @override
  String get inventoryItemEatSheetConfirmAction => 'Add';

  @override
  String get inventoryItemEatSheetAddMoreAction => '+ More';

  @override
  String get inventoryItemEatSheetClearAmountAction => 'Clear amount';

  @override
  String get inventoryItemAddToListAction => 'Add to list';

  @override
  String get inventoryItemAddToShoppingListAction => 'Add to shopping list';

  @override
  String get inventoryItemBuyAgainAction => 'Buy again';

  @override
  String get inventoryItemBuyAgainSucceeded => 'Item added to shopping list.';

  @override
  String get inventoryItemRemoveAction => 'Remove';

  @override
  String get inventoryItemRemoveDialogTitle => 'Remove item';

  @override
  String inventoryItemRemoveDialogMessage(String name) {
    return 'Why do you want to remove $name?';
  }

  @override
  String get inventoryItemRemoveDiscardAction => 'Thrown away';

  @override
  String get inventoryItemRemoveDiscardSubtitle => 'Expired or spoiled';

  @override
  String get inventoryItemRemoveConsumeElsewhereAction => 'Consumed elsewhere';

  @override
  String get inventoryItemRemoveConsumeElsewhereSubtitle => 'Donated, shared or gifted';

  @override
  String get inventoryItemRemoveDeleteAction => 'Delete completely';

  @override
  String get inventoryItemRemoveDeleteSubtitle => 'Input mistake, do not count in statistics';

  @override
  String get inventoryItemThrowAwayAction => 'Throw away';

  @override
  String get inventoryItemEditTitle => 'Edit inventory item';

  @override
  String get inventoryItemUpdatedMessage => 'Inventory item updated.';

  @override
  String get inventoryItemEditRequiresFullItem => 'You can edit the item only while it is still fully available.';

  @override
  String get inventoryItemSwapCandidateAction => 'Swap candidate';

  @override
  String get inventoryItemSwapCandidateRequiresFullItem => 'You can swap the candidate only while the item is still fully available.';

  @override
  String get inventoryItemActionFailed => 'Action failed. Please try again.';

  @override
  String get inventoryBarcodeScanUnsupported => 'Barcode scanning is currently supported on Android and iOS.';

  @override
  String get inventoryManualAddTitle => 'Add food manually';

  @override
  String get inventoryManualAddHint => 'Scan a barcode. Then you can review the product, save it, or add nutrition values.';

  @override
  String get inventoryManualAddScanBarcodeAction => 'Scan barcode';

  @override
  String get inventoryManualAddResolving => 'Looking up barcode...';

  @override
  String get inventoryManualAddCandidateTitle => 'Select product';

  @override
  String get inventoryManualAddCandidateSubtitle => 'Multiple matching products were found for this barcode.';

  @override
  String get inventoryManualAddCandidateSourceLearned => 'Community';

  @override
  String get inventoryManualAddCandidateSourceOff => 'OFF';

  @override
  String get inventoryManualAddUnknownBrand => 'Unknown brand';

  @override
  String get inventoryManualAddNotFound => 'No matching product was found for this barcode.';

  @override
  String get inventoryManualAddLookupFailed => 'Barcode lookup failed. Please try again.';

  @override
  String get inventoryManualAddSaveFailed => 'The product could not be added to the inventory.';

  @override
  String get inventoryManualAddSaved => 'Product added to inventory.';

  @override
  String get inventoryManualAddEatSucceeded => 'Added to diary';

  @override
  String get inventoryManualAddSearchDialogTitle => 'Product search';

  @override
  String get inventoryManualAddPackageSizeLabel => 'Package size';

  @override
  String get inventoryManualAddResultActionInventory => 'Inventory';

  @override
  String get inventoryManualAddResultActionEat => 'Eat';

  @override
  String get inventoryManualAddNutritionMissing => 'Nutrition missing';

  @override
  String get inventoryManualAddNutritionMissingCalories => 'Calories missing';

  @override
  String get inventoryManualAddNutritionIncomplete => 'Nutrition incomplete';

  @override
  String get inventoryManualAddNutritionComplete => 'Nutrition complete';

  @override
  String get inventoryManualAddNutritionVerified => 'Nutrition verified';

  @override
  String get inventoryManualAddCreateOwnAction => 'Create manually';

  @override
  String get inventoryManualAddEatNowOption => 'Eat now';

  @override
  String get inventoryManualAddEatNowSizeLabel => 'Eat now amount';

  @override
  String get inventoryManualAddEatNowRequiresNutrition => 'Only available when nutrition values are present.';

  @override
  String get inventoryManualAddMissingBarcodeTitle => 'Add barcode?';

  @override
  String get inventoryManualAddMissingBarcodeMessage => 'This product has no barcode yet. Enter one now so it can be recognized next time, or save it without a barcode.';

  @override
  String get inventoryManualAddMissingBarcodeLabel => 'Barcode';

  @override
  String get inventoryManualAddMissingBarcodeRequired => 'Enter a barcode or save without one.';

  @override
  String get inventoryManualAddMissingBarcodeSaveWithout => 'Save without barcode';

  @override
  String get inventoryManualAddMissingBarcodeSave => 'Save';

  @override
  String get inventoryManualAddVoiceSearchStartTooltip => 'Start voice search';

  @override
  String get inventoryManualAddVoiceSearchStopTooltip => 'Stop voice search';

  @override
  String get inventoryManualAddVoiceSearchUnavailable => 'Voice search is not currently supported on this device.';

  @override
  String get inventoryManualAddVoiceSearchPermissionDenied => 'Please allow microphone access to use voice search.';

  @override
  String get inventoryManualAddVoiceSearchFailed => 'Voice search could not be started. Please try again.';

  @override
  String get inventoryManualAddAiSearchAction => 'Create with AI';

  @override
  String get inventoryManualAddAiSearchTitle => 'Create food with AI';

  @override
  String get inventoryManualAddAiSearchPromptLabel => 'Food description';

  @override
  String get inventoryManualAddAiSearchPromptHint => 'For example: Chicken kebab';

  @override
  String get inventoryManualAddAiSearchGenerateAction => 'Generate estimate';

  @override
  String get inventoryManualAddAiSearchPromptRequired => 'Please enter a food description.';

  @override
  String get inventoryManualAddAiSearchFailed => 'Could not generate a food estimate. Please try again.';

  @override
  String get inventoryManualAddAiSearchReadOnlyHint => 'Adjust weight or kcal per 100 g if the estimate feels off.';

  @override
  String get inventoryManualAddAiSearchIngredientsTitle => 'Ingredients for this portion';

  @override
  String get inventoryManualAddAiSearchAmountColumn => 'Amount';

  @override
  String get inventoryManualAddAiSearchTotalLabel => 'Total';

  @override
  String get inventoryManualAddAiSearchPer100Title => 'Saved per 100 g';

  @override
  String get inventoryManualAddAiSearchPer100CardTitle => 'PER 100 G';

  @override
  String get inventoryManualAddAiSearchPortionCardTitle => 'YOUR PORTION';

  @override
  String get inventoryManualAddAiSearchWeightLabel => 'Weight';

  @override
  String get inventoryManualAddAiSearchWeightRequired => 'Enter a valid weight.';

  @override
  String get inventoryManualAddAiSearchDensityTitle => 'Adjust kcal density (per 100 g)';

  @override
  String get inventoryManualAddAiSearchDensityHint => 'Was the dish lighter or richer than expected? Scale calories per 100 g. Total nutrition updates automatically.';

  @override
  String inventoryManualAddAiSearchDensityMinLabel(Object kcal) {
    return '$kcal kcal/100g (lighter)';
  }

  @override
  String inventoryManualAddAiSearchDensityBaseLabel(Object kcal) {
    return 'Base: $kcal';
  }

  @override
  String inventoryManualAddAiSearchDensityMaxLabel(Object kcal) {
    return '$kcal kcal/100g (richer)';
  }

  @override
  String get inventoryManualAddStoreName => 'Added manually';

  @override
  String get inventoryBarcodePortionDialogTitle => 'Enter consumed amount';

  @override
  String get inventoryBarcodePortionDialogConfirmAction => 'Continue';

  @override
  String get inventoryEmptyState => 'No items in your fridge yet. Scan a receipt or add foods manually.';

  @override
  String get inventoryFilteredEmptyState => 'No items match your search or active filters.';

  @override
  String get inventoryLoadFailed => 'Could not load inventory items.';

  @override
  String get inventoryRetryAction => 'Retry';

  @override
  String get preparedMealSectionTitle => 'Prepared meals';

  @override
  String get preparedMealCreateTitle => 'Create prepared meal';

  @override
  String get preparedMealEditTitle => 'Edit prepared meal';

  @override
  String get preparedMealNameLabel => 'Meal name';

  @override
  String get preparedMealClearNameAction => 'Clear name';

  @override
  String get preparedMealInvalidName => 'Please enter a meal name.';

  @override
  String get preparedMealPortionsLabel => 'Portions';

  @override
  String get preparedMealInvalidPortions => 'Please enter at least one portion.';

  @override
  String get preparedMealFixFormErrorsMessage => 'Please check the highlighted fields.';

  @override
  String get preparedMealInvalidPortionsRange => 'Please enter a valid portion count within the available range.';

  @override
  String get preparedMealImageLabel => 'Cover image';

  @override
  String get preparedMealAddImageAction => 'Add image';

  @override
  String get preparedMealChangeImageAction => 'Change image';

  @override
  String get preparedMealRemoveImageAction => 'Remove image';

  @override
  String get preparedMealImageHint => 'Add a photo for this meal or use the default cover.';

  @override
  String get preparedMealImageCameraAction => 'Take photo';

  @override
  String get preparedMealImagePickFailed => 'Could not pick the meal image.';

  @override
  String get preparedMealImageTooLarge => 'The selected image is too large.';

  @override
  String get preparedMealIngredientsTitle => 'Ingredients';

  @override
  String get preparedMealAddIngredientAction => 'Add ingredient';

  @override
  String get preparedMealRemoveIngredientAction => 'Remove ingredient';

  @override
  String get preparedMealEmptyIngredientsMessage => 'Add at least one ingredient before saving.';

  @override
  String get preparedMealCreateAction => 'Create meal';

  @override
  String get preparedMealBindAction => 'Bind meal';

  @override
  String get preparedMealUsedAmountLabel => 'Used amount';

  @override
  String preparedMealAvailableAmount(int amount, String unit) {
    return 'Available: $amount $unit';
  }

  @override
  String get preparedMealInvalidIngredientAmount => 'Please enter a valid ingredient amount.';

  @override
  String get preparedMealNutritionPerPieceHint => 'Add nutrition values per used piece.';

  @override
  String get preparedMealNutritionPerHundredHint => 'Add nutrition values per 100 g/ml.';

  @override
  String get preparedMealNutritionModePerHundred => '100 g/ml';

  @override
  String get preparedMealNutritionModePerPortion => 'Portion';

  @override
  String get preparedMealNutritionModeTotal => 'Total';

  @override
  String get preparedMealPricePerHundred => 'Price per 100 g/ml';

  @override
  String get preparedMealPricePerPortion => 'Price per portion';

  @override
  String get preparedMealPriceTotal => 'Total price';

  @override
  String preparedMealSelectionCount(int count) {
    return '$count selected';
  }

  @override
  String get preparedMealCreatedMessage => 'Prepared meal created.';

  @override
  String get preparedMealUpdatedMessage => 'Prepared meal updated.';

  @override
  String get preparedMealInsufficientAmountMessage => 'At least one selected ingredient is no longer available in a sufficient amount.';

  @override
  String get preparedMealMissingNutritionMessage => 'At least one selected ingredient is missing complete nutrition values.';

  @override
  String get preparedMealItemUnavailableMessage => 'At least one selected ingredient is no longer available in inventory.';

  @override
  String get preparedMealActionFailed => 'Prepared meal action failed. Please try again.';

  @override
  String preparedMealIngredientsCount(int count) {
    return '$count ingredients';
  }

  @override
  String get preparedMealIncompleteLabel => 'Incomplete';

  @override
  String get preparedMealIncompleteHint => 'This meal is not complete yet and can only be eaten once all missing ingredients have been added.';

  @override
  String get preparedMealPendingIngredientUnassigned => 'Not linked yet';

  @override
  String get preparedMealPendingIngredientAddAction => 'Add ingredient';

  @override
  String get preparedMealPendingIngredientIgnoreAction => 'Ignore ingredient';

  @override
  String get preparedMealPendingIngredientSelectionTitle => 'Add ingredient from inventory';

  @override
  String get preparedMealPendingIngredientSelectionEmpty => 'No inventory items available.';

  @override
  String get preparedMealPendingIngredientFillFailed => 'Ingredient could not be added to the meal.';

  @override
  String get preparedMealPendingIngredientIgnoreFailed => 'Ingredient could not be ignored.';

  @override
  String preparedMealPortionsRemaining(String remaining, int total) {
    return '$remaining/$total portions';
  }

  @override
  String get preparedMealUnbundleAction => 'Return to inventory';

  @override
  String get preparedMealEatTitle => 'Eat prepared meal';

  @override
  String get preparedMealDiaryDayLabel => 'Diary day';

  @override
  String get preparedMealThrowAwayTitle => 'Throw away portions';

  @override
  String get preparedMealPortionsToUseLabel => 'Portions to use';

  @override
  String get preparedMealConfirmAction => 'Confirm';

  @override
  String get inventoryDiscardReasonTitle => 'Why are you throwing this away?';

  @override
  String get inventoryDiscardReasonExpired => 'Expired';

  @override
  String get inventoryDiscardReasonSpoiled => 'Spoiled';

  @override
  String get inventoryDiscardReasonCookedTooMuch => 'Cooked too much';

  @override
  String get inventoryDiscardReasonOther => 'Other';

  @override
  String get preparedMealSaveTemplateAction => 'Save as template';

  @override
  String get preparedMealTemplateSavedMessage => 'Template saved.';

  @override
  String get preparedMealTemplatesPageTitle => 'Templates';

  @override
  String get preparedMealTemplatesEmptyState => 'No templates saved yet.';

  @override
  String get preparedMealTemplatesLoadFailed => 'Could not load templates.';

  @override
  String get preparedMealTemplateDeleteAction => 'Delete template';

  @override
  String get preparedMealTemplateDeletedMessage => 'Template deleted.';

  @override
  String get preparedMealTemplateAddRecipeAction => 'Add recipe template';

  @override
  String get preparedMealTemplateCreateFromRecipeAction => 'Create from recipe';

  @override
  String get preparedMealTemplateCreateFailedMessage => 'Template could not be created.';

  @override
  String get preparedMealTemplateRecipeImportFailedMessage => 'Recipe data could not be imported.';

  @override
  String get preparedMealTemplateRecipeSheetTitle => 'Create template from recipe';

  @override
  String get preparedMealTemplateRecipeEditSheetTitle => 'Edit recipe template';

  @override
  String get preparedMealTemplateRecipeSheetSubtitle => 'Paste a recipe link, for example from Chefkoch.';

  @override
  String get preparedMealTemplateRecipeGreetingTitle => 'Let\'s cook up a new recipe! 🍳';

  @override
  String get preparedMealTemplateRecipeGreetingSubtitle => 'Simply copy the web address of your favorite recipe and we will read all ingredients automatically.';

  @override
  String get preparedMealTemplateStepCopy => '1. 🔗 Copy';

  @override
  String get preparedMealTemplateStepPaste => '2. 📝 Paste';

  @override
  String get preparedMealTemplateStepCreate => '3. ✨ Create';

  @override
  String get preparedMealTemplateClipboardTitle => 'Paste from clipboard ✨';

  @override
  String get preparedMealTemplateClipboardPasteHelper => 'Tap here to check your clipboard for a recipe link.';

  @override
  String preparedMealTemplateClipboardPasteSuccess(String url) {
    return 'Pasted recipe from $url!';
  }

  @override
  String get preparedMealTemplateClipboardNoLinkFound => 'No valid recipe link found in clipboard.';

  @override
  String get preparedMealTemplateAdvancedOptionsTitle => 'More Options (Optional)';

  @override
  String get preparedMealTemplateRecipeUrlLabel => 'Recipe link';

  @override
  String get preparedMealTemplateRecipeUrlHint => 'https://www.chefkoch.de/...';

  @override
  String get preparedMealTemplateRecipeUrlInvalid => 'Please enter a valid recipe link.';

  @override
  String get preparedMealTemplateNameLabel => 'Template name';

  @override
  String get preparedMealTemplateNameHelper => 'Optional. If empty, the name is derived from the link.';

  @override
  String get preparedMealTemplatePortionsLabel => 'Portions';

  @override
  String get preparedMealTemplatePortionsHelper => 'Optional. If empty, the servings from the recipe are used.';

  @override
  String get preparedMealTemplateRecipePlaceholder => 'Recipe link';

  @override
  String get preparedMealTemplateNoIngredientsYet => 'No ingredients linked yet.';

  @override
  String get preparedMealTemplateOpenAction => 'Open template';

  @override
  String get preparedMealTemplateUpdatedMessage => 'Template updated.';

  @override
  String get kitchenUtensilsPageTitle => 'Kitchen utensils';

  @override
  String get kitchenUtensilsOpenAction => 'Kitchen utensils';

  @override
  String get kitchenUtensilsEmptyState => 'No kitchen utensils saved yet.';

  @override
  String get kitchenUtensilsLoadFailed => 'Could not load kitchen utensils.';

  @override
  String get kitchenUtensilAddAction => 'Add utensil';

  @override
  String get kitchenUtensilEditTitle => 'Edit utensil';

  @override
  String get kitchenUtensilAddTitle => 'Add utensil';

  @override
  String get kitchenUtensilDeleteAction => 'Delete utensil';

  @override
  String get kitchenUtensilSavedMessage => 'Utensil saved.';

  @override
  String get kitchenUtensilUpdatedMessage => 'Utensil updated.';

  @override
  String get kitchenUtensilDeletedMessage => 'Utensil deleted.';

  @override
  String get kitchenUtensilUnnamedLabel => 'Unnamed utensil';

  @override
  String get kitchenUtensilNameLabel => 'Name';

  @override
  String get kitchenUtensilWeightLabel => 'Weight (g)';

  @override
  String kitchenUtensilWeightValue(int grams) {
    return '$grams g';
  }

  @override
  String get kitchenUtensilImageLabel => 'Photo';

  @override
  String get kitchenUtensilAddImageAction => 'Add photo';

  @override
  String get kitchenUtensilChangeImageAction => 'Change photo';

  @override
  String get kitchenUtensilRemoveImageAction => 'Remove photo';

  @override
  String get kitchenUtensilImageCameraAction => 'Take photo';

  @override
  String get kitchenUtensilImageHint => 'Add a photo or name so you can recognize this utensil later.';

  @override
  String get kitchenUtensilImagePickFailed => 'Could not pick the utensil photo.';

  @override
  String get kitchenUtensilImageUploadFailed => 'Utensil photo could not be uploaded.';

  @override
  String get kitchenUtensilSaveFailed => 'Utensil could not be saved.';

  @override
  String get kitchenUtensilDeleteFailed => 'Utensil could not be deleted.';

  @override
  String get kitchenUtensilInvalidWeight => 'Please enter a weight greater than 0.';

  @override
  String get kitchenUtensilIdentityRequired => 'Add a name or photo.';

  @override
  String get preparedMealTemplateImportReviewTitle => 'Review recipe';

  @override
  String get preparedMealTemplateImportReviewInstructionsTitle => 'Short instructions';

  @override
  String get preparedMealTemplateImportReviewSavingAction => 'Saving...';

  @override
  String preparedMealTemplateRecipeSource(String host) {
    return 'Recipe: $host';
  }

  @override
  String preparedMealTemplatePortions(int count) {
    return '$count portions';
  }

  @override
  String get shoppingListStatsEntries => 'Entries';

  @override
  String get shoppingListStatsQuantity => 'Total quantity';

  @override
  String get shoppingListStatsEstimatedTotal => 'Estimated total';

  @override
  String get shoppingListNameFieldLabel => 'Name';

  @override
  String get shoppingListBrandFieldLabel => 'Brand (optional)';

  @override
  String get shoppingListAddAction => 'Add item';

  @override
  String get shoppingListEmptyState => 'Your shopping list is empty.';

  @override
  String get shoppingListInvalidNameError => 'Please enter an item name.';

  @override
  String get shoppingListAddFailedError => 'Could not add item. Please try again.';

  @override
  String get shoppingListLoadFailed => 'Could not load shopping list items.';

  @override
  String get shoppingListRetryAction => 'Retry';

  @override
  String get shoppingListQuantityLabel => 'Qty';

  @override
  String get shoppingListIncreaseQuantityAction => 'Increase quantity';

  @override
  String get shoppingListDecreaseQuantityAction => 'Decrease quantity';

  @override
  String shoppingListClearCrossedOffAction(int count) {
    return 'Clear crossed-off ($count)';
  }

  @override
  String get shoppingListClearCrossedOffDialogTitle => 'Clear crossed-off items?';

  @override
  String get shoppingListClearCrossedOffDialogMessage => 'All crossed-off items will be removed from the shopping list.';

  @override
  String get shoppingListClearCrossedOffConfirmAction => 'Clear';

  @override
  String get caloriesAddOptionManual => 'Manual entry';

  @override
  String get caloriesAddOptionBarcode => 'Scan barcode';

  @override
  String get caloriesFabTooltip => 'Add calorie entry';

  @override
  String get caloriesBarcodeScannerTitle => 'Scan barcode';

  @override
  String get caloriesBarcodeResolving => 'Looking up product...';

  @override
  String get caloriesBarcodeLookupFailed => 'Barcode lookup failed. Please try again.';

  @override
  String get caloriesBarcodeCandidateTitle => 'Choose product';

  @override
  String get caloriesBarcodeCandidateSubtitle => 'Multiple products were found for this barcode.';

  @override
  String get caloriesBarcodeUnknownBrand => 'Unknown brand';

  @override
  String get caloriesBarcodeNotFoundTitle => 'Product not found';

  @override
  String get caloriesBarcodeNotFoundMessage => 'No product was found for this barcode.';

  @override
  String get caloriesBarcodeNotFoundManualAction => 'Manual entry';

  @override
  String get caloriesBarcodeNotFoundOcrAction => 'Scan nutrition label';

  @override
  String get caloriesOcrFailed => 'Nutrition label scan failed. Please try again.';

  @override
  String get caloriesOcrAppCheckThrottled => 'Nutrition scan is temporarily blocked. Please try again later.';

  @override
  String get caloriesLoadFailed => 'Could not load calorie entries.';

  @override
  String get caloriesRetryAction => 'Retry';

  @override
  String get caloriesAuthRequired => 'Please sign in to manage calories.';

  @override
  String get caloriesTodayAction => 'Today';

  @override
  String get caloriesSetGoalAction => 'Set goal manually';

  @override
  String get caloriesShiftGoalStartAction => 'Move goal start';

  @override
  String get caloriesCalculatorAction => 'Recalculate goal';

  @override
  String get caloriesGoalDialogTitle => 'Set daily goal';

  @override
  String get caloriesGoalFieldLabel => 'Daily kcal goal';

  @override
  String get caloriesGoalSaveAction => 'Save goal';

  @override
  String get caloriesGoalClearAction => 'Clear goal';

  @override
  String get caloriesGoalInvalidValue => 'Please enter a number greater than zero.';

  @override
  String get caloriesGoalSaveFailed => 'Could not save calorie goal.';

  @override
  String get caloriesGoalClearFailed => 'Could not clear calorie goal.';

  @override
  String get caloriesGoalStartDialogTitle => 'Move goal start';

  @override
  String get caloriesGoalStartDateLabel => 'Date';

  @override
  String get caloriesGoalStartSaveFailed => 'Could not update goal start.';

  @override
  String get caloriesCalculatorSheetTitle => 'Calorie calculator';

  @override
  String get caloriesCalculatorOnboardingTitle => 'Set your calorie goal';

  @override
  String get caloriesCalculatorOnboardingSubtitle => 'We use a few details to calculate a daily calorie target for you.';

  @override
  String caloriesCalculatorStepProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get caloriesCalculatorBackAction => 'Back';

  @override
  String get caloriesCalculatorNextAction => 'Continue';

  @override
  String get caloriesCalculatorSexLabel => 'Sex';

  @override
  String get caloriesCalculatorSexMale => 'Male';

  @override
  String get caloriesCalculatorSexFemale => 'Female';

  @override
  String get caloriesCalculatorWeightLabel => 'Weight (kg)';

  @override
  String get caloriesCalculatorWeightEmpty => 'Please enter your weight.';

  @override
  String get caloriesCalculatorWeightInvalid => 'Please enter a valid weight.';

  @override
  String get caloriesCalculatorHeightLabel => 'Height (cm)';

  @override
  String get caloriesCalculatorHeightEmpty => 'Please enter your height.';

  @override
  String get caloriesCalculatorHeightInvalid => 'Please enter a valid height.';

  @override
  String get caloriesCalculatorAgeLabel => 'Age (years)';

  @override
  String get caloriesCalculatorAgeEmpty => 'Please enter your age.';

  @override
  String get caloriesCalculatorAgeInvalid => 'Please enter a valid age.';

  @override
  String get caloriesCalculatorActivityLevelLabel => 'Activity level (PAL)';

  @override
  String get caloriesCalculatorActivityLevelHelp => 'Choose the option that best matches your typical week.';

  @override
  String get caloriesCalculatorActivityLevelNoneTitle => 'Sedentary';

  @override
  String get caloriesCalculatorActivityLevelNoneDescription => 'Office work, lots of sitting, few steps, and little to no exercise.';

  @override
  String get caloriesCalculatorActivityLevelLowTitle => 'Lightly active';

  @override
  String get caloriesCalculatorActivityLevelLowDescription => 'Mostly sitting, but with some daily movement or 1 to 2 light workouts per week.';

  @override
  String get caloriesCalculatorActivityLevelMediumTitle => 'Moderately active';

  @override
  String get caloriesCalculatorActivityLevelMediumDescription => 'Regular daily movement or 3 to 4 training sessions per week.';

  @override
  String get caloriesCalculatorActivityLevelHighTitle => 'Very active';

  @override
  String get caloriesCalculatorActivityLevelHighDescription => 'A physically active daily life or intense training on most days.';

  @override
  String get caloriesCalculatorActivityLevelExtremeTitle => 'Extremely active';

  @override
  String get caloriesCalculatorActivityLevelExtremeDescription => 'Very high training volume, physically demanding work, or competitive sports.';

  @override
  String get caloriesCalculatorActivityLevelHint => 'For example 1.2 to 2.0';

  @override
  String get caloriesCalculatorActivityLevelEmpty => 'Please enter your activity level.';

  @override
  String get caloriesCalculatorActivityLevelInvalid => 'Please enter a valid activity level.';

  @override
  String get caloriesCalculatorGoalModeLabel => 'Goal mode';

  @override
  String get caloriesCalculatorGoalModeLose => 'Lose';

  @override
  String get caloriesCalculatorGoalModeMaintain => 'Maintain';

  @override
  String get caloriesCalculatorGoalModeGain => 'Gain';

  @override
  String get caloriesCalculatorGoalSpeedLabel => 'Goal speed (kg/week)';

  @override
  String get caloriesCalculatorGoalSpeedHint => 'For example 0.25, 0.5 or 0.75';

  @override
  String get caloriesCalculatorGoalSpeedEmpty => 'Please enter a goal speed.';

  @override
  String get caloriesCalculatorGoalSpeedInvalid => 'Please enter a valid goal speed.';

  @override
  String get caloriesCalculatorResultsTitle => 'Results';

  @override
  String get caloriesCalculatorBmrLabel => 'Basal metabolic rate';

  @override
  String get caloriesCalculatorTdeeLabel => 'Maintenance calories';

  @override
  String get caloriesCalculatorDailyGoalLabel => 'Daily calorie target';

  @override
  String get caloriesCalculatorGoalStartLabel => 'Goal start';

  @override
  String get caloriesCalculatorGoalStartHint => 'Your calorie target history begins from this day.';

  @override
  String get caloriesCalculatorGoalStartChangeAction => 'Change';

  @override
  String get caloriesCalculatorOnboardingStartTitle => 'When should your goal start?';

  @override
  String get caloriesCalculatorOnboardingStartNowAction => 'Start now';

  @override
  String get caloriesCalculatorOnboardingStartLaterAction => 'Start later';

  @override
  String get caloriesCalculatorOnboardingStartLaterHint => 'Today stays consequence-free. Burn Week starts automatically from this day.';

  @override
  String get caloriesCalculatorOnboardingChooseFutureDateAction => 'Choose day';

  @override
  String get caloriesCalculatorOnboardingTodayTrackingLabel => 'How will you track today?';

  @override
  String get caloriesCalculatorOnboardingTodayTrackingExactAction => 'Full day exact';

  @override
  String get caloriesCalculatorOnboardingTodayTrackingEstimateAction => 'Estimate so far';

  @override
  String get caloriesCalculatorOnboardingCatchUpLabel => 'How much have you eaten so far?';

  @override
  String get caloriesCalculatorOnboardingCatchUpLowAction => 'Little';

  @override
  String get caloriesCalculatorOnboardingCatchUpNormalAction => 'Normal';

  @override
  String get caloriesCalculatorOnboardingCatchUpHighAction => 'A lot';

  @override
  String get caloriesCalculatorOnboardingCatchUpHint => 'We place you safely into today\'s buffer zone.';

  @override
  String get caloriesOnboardingPlaceholderName => 'Estimated meal';

  @override
  String caloriesCalculatorMinimumGoalWarning(int minimumKcal) {
    return 'For weight loss, the daily target cannot go below $minimumKcal kcal. The result was capped at this minimum.';
  }

  @override
  String get caloriesCalculatorSaveAction => 'Save target';

  @override
  String get caloriesCalculatorSaveFailed => 'Could not save the calculated calorie target.';

  @override
  String get caloriesGoalStartFoodTrackingTitle => 'Did you track today\'s food?';

  @override
  String caloriesGoalStartFoodTrackingBody(int entryCount) {
    return 'I found $entryCount food entries today. Count today as a full tracking day for this new target?';
  }

  @override
  String get caloriesGoalStartNoFoodTrackingTitle => 'No food tracked today';

  @override
  String get caloriesGoalStartNoFoodTrackingBody => 'Today will be a starter day. Your new target starts now, but weekly learning starts tomorrow.';

  @override
  String get caloriesGoalStartFoodTrackingNoAction => 'Start fresh';

  @override
  String get caloriesGoalStartFoodTrackingYesAction => 'Count today';

  @override
  String get caloriesGoalStartFoodTrackingOkAction => 'OK';

  @override
  String get caloriesLearnedTdeeSheetTitle => 'Recalculate from learned TDEE';

  @override
  String get caloriesLearnedTdeeSheetSubtitle => 'Use your last successful weekly check-in instead of an activity estimate.';

  @override
  String get caloriesLearnedTdeeLabel => 'Learned TDEE';

  @override
  String get caloriesLearnedTdeeResultLabel => 'New daily target';

  @override
  String get caloriesLearnedTdeeUseProfileResetAction => 'Use profile reset';

  @override
  String get caloriesLearnedTdeeSaveFailed => 'Could not save the learned TDEE target.';

  @override
  String get caloriesWeeklyCheckInDialogTitle => 'Weekly check-in';

  @override
  String get caloriesWeeklyCheckInDialogReadyBody => 'Review your last 7 completed days. Your target already uses this learning automatically.';

  @override
  String get caloriesWeeklyCheckInDialogBlockedBody => 'We still need a bit more data before this weekly summary is complete.';

  @override
  String get caloriesWeeklyCheckInDialogWindowLabel => 'Window';

  @override
  String get caloriesWeeklyCheckInDialogTrendLabel => 'Weight trend';

  @override
  String get caloriesWeeklyCheckInDialogTrueTdeeLabel => 'Learned TDEE';

  @override
  String get caloriesWeeklyCheckInDialogMeasuredTotalTdeeLabel => 'Measured total TDEE';

  @override
  String get caloriesWeeklyCheckInDialogMeasuredBaseTdeeLabel => 'Measured base TDEE';

  @override
  String get caloriesWeeklyCheckInDialogCreditedActivityAverageLabel => 'Credited activity avg';

  @override
  String get caloriesWeeklyCheckInDialogNewTargetLabel => 'New target';

  @override
  String get caloriesWeeklyCheckInDialogLowConfidence => 'Low confidence: only start and end weights were available.';

  @override
  String get caloriesWeeklyCheckInBlockedUnstableWeight => 'Weight data was too noisy this week for a reliable TDEE update. Add steadier weigh-ins and try again.';

  @override
  String get caloriesWeeklyCheckInApplyAction => 'Done';

  @override
  String get caloriesWeeklyCheckInLaterAction => 'Later';

  @override
  String get caloriesWeeklyCheckInApplyFailed => 'Could not close the weekly check-in.';

  @override
  String get caloriesWeeklyCheckInHintReadyTitle => 'Weekly check-in ready';

  @override
  String get caloriesWeeklyCheckInHintReadyBody => 'Your last 7 completed days are ready to review.';

  @override
  String get caloriesWeeklyCheckInHintBlockedTitle => 'Weekly check-in needs data';

  @override
  String get caloriesWeeklyCheckInHintBlockedBody => 'Finish the missing intake or weight data to complete the summary.';

  @override
  String get caloriesWeeklyCheckInHintContinueAction => 'Continue';

  @override
  String get caloriesWeeklyCheckInHintStaleTitle => 'Target getting stale';

  @override
  String get caloriesWeeklyCheckInHintStaleBody => 'Use your next weekly check-in to keep your target current.';

  @override
  String get caloriesWeeklyCheckInHintUrgentTitle => 'Target needs refresh';

  @override
  String get caloriesWeeklyCheckInHintUrgentBody => 'You have been using older target data for a while now.';

  @override
  String get caloriesWeeklyCheckInShowAgainAction => 'Show weekly check-in';

  @override
  String get caloriesWeeklyCheckInShowAgainFailed => 'Could not reopen the weekly check-in.';

  @override
  String get caloriesWeeklyCheckInSkipDayAction => 'Mark day as skipped';

  @override
  String get caloriesWeeklyCheckInUnskipDayAction => 'Undo skipped day';

  @override
  String get caloriesWeeklyCheckInAutoAdjustedHint => 'Target updated from weekly check-in:';

  @override
  String get caloriesWeeklyCheckInTrackMissingWeightAction => 'Add missing weight';

  @override
  String get caloriesWeeklyCheckInBlockedMissingIntake => 'One or more days in this window have no intake yet. Log them or mark 1 or 2 empty days as skipped.';

  @override
  String get caloriesWeeklyCheckInBlockedTooManyMissingIntake => 'This window has 3 or more missing intake days. We will keep your last learned target until you log more complete days.';

  @override
  String get caloriesWeeklyCheckInBlockedSkippedWithoutAverage => 'A skipped day needs earlier logged intake in the same window before we can estimate it.';

  @override
  String caloriesWeeklyCheckInBlockedMissingStartWeightOn(Object date) {
    return 'Add a weight for the first day of this window ($date) to continue.';
  }

  @override
  String caloriesWeeklyCheckInBlockedMissingEndWeightOn(Object date) {
    return 'Add a weight for the last day of this window ($date) to continue.';
  }

  @override
  String caloriesWeeklyCheckInBlockedMissingWeightDates(Object dates) {
    return 'Add weights for these dates to continue: $dates.';
  }

  @override
  String get caloriesConsumedLabel => 'Consumed';

  @override
  String get caloriesGoalLabel => 'Goal';

  @override
  String get caloriesRemainingLabel => 'Remaining';

  @override
  String get caloriesDebugActionsTooltip => 'Calorie debug actions';

  @override
  String get caloriesDebugDumpAction => 'Download calorie debug TXT';

  @override
  String get caloriesDebugDumpSaveDialogTitle => 'Save calorie debug TXT';

  @override
  String caloriesDebugDumpPrinted(int rowCount) {
    return 'Downloaded calorie debug TXT ($rowCount rows).';
  }

  @override
  String get caloriesDebugDumpCanceled => 'Calorie debug TXT download canceled.';

  @override
  String get caloriesDebugDumpFailed => 'Could not download calorie debug TXT.';

  @override
  String get caloriesSettingsDebugDumpAction => 'Print calorie settings JSON';

  @override
  String caloriesSettingsDebugDumpPrinted(int entryCount) {
    return 'Printed calorie settings debug dump ($entryCount goal entries).';
  }

  @override
  String get caloriesSettingsDebugDumpFailed => 'Could not print calorie settings debug dump.';

  @override
  String get caloriesWeeklyCheckInDebugDumpAction => 'Print weekly check-in state';

  @override
  String get caloriesWeeklyCheckInDebugDumpPrinted => 'Printed weekly check-in debug dump.';

  @override
  String get caloriesWeeklyCheckInDebugDumpFailed => 'Could not print weekly check-in debug dump.';

  @override
  String get burnWeekRunOverTitle => 'Run over';

  @override
  String burnWeekRunRestartsOn(Object date) {
    return 'Fresh run starts on $date.';
  }

  @override
  String get burnWeekPracticeDayTitle => 'Practice day';

  @override
  String burnWeekPracticeDayMessage(Object date) {
    return 'Today does not count yet. You can try tracking, and Burn Week starts on $date.';
  }

  @override
  String get calorieBudgetDetailsActualLabel => 'Actual (you)';

  @override
  String get calorieBudgetDetailsTargetLabel => 'Target (goal)';

  @override
  String get calorieBudgetDetailsBalanceExplanation => 'Budget starts with your saved daily target. Extra activity is half of the calories above your expected activity baseline. Carryover is the finished-day balance spread across the remaining days in this 7-day run.';

  @override
  String get calorieBudgetDetailsTodayBudget => 'Today budget';

  @override
  String get calorieBudgetDetailsFoodToday => 'Food today';

  @override
  String get calorieBudgetDetailsRemaining => 'Remaining';

  @override
  String get burnWeekDetailsTitle => 'Burn Week details';

  @override
  String get burnWeekDetailsHowCalculated => 'How this is calculated';

  @override
  String get burnWeekDetailsDailyGoal => 'Daily goal';

  @override
  String get burnWeekDetailsWeekTarget => 'Week target';

  @override
  String get burnWeekDetailsCurrentTime => 'Current time';

  @override
  String get burnWeekDetailsStarsHearts => 'Stars / Hearts';

  @override
  String get burnWeekDetailsHeartKcalUsed => 'Heart adjustment';

  @override
  String get burnWeekDetailsWeekRatio => 'Week ratio';

  @override
  String get burnWeekDetailsTargetFormula => 'Target formula';

  @override
  String get burnWeekDetailsLoggedFoodSoFar => 'Logged food so far';

  @override
  String get burnWeekDetailsPlannedLaterToday => 'Planned later today';

  @override
  String get burnWeekDetailsActivityBonusSoFar => 'Activity bonus so far';

  @override
  String get burnWeekDetailsWeekCarryover => 'This week carryover';

  @override
  String get burnWeekDetailsPreviousWeekOverflow => 'Previous week overflow';

  @override
  String get burnWeekDetailsWeekLeftAfterFood => 'Week left after food';

  @override
  String get burnWeekDetailsSportCounting => 'Sport counting';

  @override
  String get burnWeekDetailsSportCountingValue => 'Expected activity is already in your base goal. Half of activity above that expectation is added as eatable kcal.';

  @override
  String get burnWeekDetailsSafeZone => 'Safe zone';

  @override
  String burnWeekWeekDayLabel(int week, int day) {
    return 'Week $week day $day';
  }

  @override
  String get caloriesProteinLabel => 'Protein';

  @override
  String get caloriesCarbsLabel => 'Carbs';

  @override
  String get caloriesFatLabel => 'Fat';

  @override
  String diaryWeightDialogTitle(String date) {
    return 'Set weight for $date';
  }

  @override
  String get diaryWeightSaveAction => 'Save';

  @override
  String get diaryWeightClearAction => 'Clear override';

  @override
  String get diaryWeightSaveFailed => 'Could not save weight.';

  @override
  String get diaryWeightClearFailed => 'Could not clear manual weight.';

  @override
  String get caloriesDeleteEntryDialogTitle => 'Delete entry?';

  @override
  String caloriesDeleteEntryDialogMessage(String name) {
    return 'Delete \"$name\" from this day?';
  }

  @override
  String get caloriesDeleteEntryConfirmAction => 'Delete';

  @override
  String get caloriesRemoveEntryAction => 'Remove entry';

  @override
  String get caloriesRemoveEntryDialogTitle => 'Remove entry';

  @override
  String get caloriesRemoveEntryDialogMessage => 'Would you like to return this food to the inventory?';

  @override
  String get caloriesRemoveEntryPreparedMealMessage => 'Would you like to return this meal to the inventory?';

  @override
  String get caloriesRemoveEntryOnlyAction => 'Delete from diary only';

  @override
  String get caloriesRemoveAndRestoreAction => 'Return to inventory';

  @override
  String get caloriesReturnPreparedMealDialogTitle => 'Return meal to inventory?';

  @override
  String caloriesReturnPreparedMealDialogMessage(String name) {
    return 'Return \"$name\" to inventory and remove it from the diary?';
  }

  @override
  String get caloriesReturnPreparedMealConfirmAction => 'Return to inventory';

  @override
  String get caloriesReturnPreparedMealFailed => 'The meal could not be returned to inventory.';

  @override
  String get caloriesDeleteRestoreInventoryQuestion => 'Add the food back to inventory?';

  @override
  String get caloriesDeleteRestoreFailed => 'The food could not be added back to inventory.';

  @override
  String get caloriesMissingInventorySourceDialogTitle => 'Food no longer in inventory';

  @override
  String caloriesMissingInventorySourceDialogMessage(String name) {
    return '\"$name\" is no longer in inventory, so it cannot be returned. Delete it from the diary only?';
  }

  @override
  String get caloriesDeleteDiaryOnlyConfirmAction => 'Delete from diary';

  @override
  String get caloriesDeleteFailed => 'Could not delete entry.';

  @override
  String get caloriesAddEntryTitle => 'Add calorie entry';

  @override
  String get caloriesEditEntryTitle => 'Edit calorie entry';

  @override
  String get caloriesEntryDetailsTitle => 'Calorie entry details';

  @override
  String get caloriesDiscardChangesDialogTitle => 'Discard unsaved changes?';

  @override
  String get caloriesDiscardChangesDialogMessage => 'Your changes to this diary entry have not been saved yet.';

  @override
  String get caloriesDiscardChangesConfirmAction => 'Discard changes';

  @override
  String get caloriesEntryNotFound => 'Entry not found.';

  @override
  String get caloriesEntryNameLabel => 'Name';

  @override
  String get caloriesEntryBrandLabel => 'Brand (optional)';

  @override
  String get caloriesEntryMealLabel => 'Meal';

  @override
  String get caloriesEntryAmountLabel => 'Consumed amount';

  @override
  String get caloriesEntryUnitLabel => 'Unit';

  @override
  String get caloriesPer100SectionTitle => 'Nutrition per 100';

  @override
  String get caloriesPer100KcalLabel => 'Energy (kcal)';

  @override
  String get caloriesPer100ProteinLabel => 'Protein (g)';

  @override
  String get caloriesPer100CarbsLabel => 'Carbs (g)';

  @override
  String get caloriesPer100FatLabel => 'Fat (g)';

  @override
  String get caloriesPer100SaturatedFatLabel => 'Saturated fat (g)';

  @override
  String get caloriesPer100PolyunsaturatedFatLabel => 'Polyunsaturated fat (g)';

  @override
  String get caloriesPer100SugarLabel => 'Sugar (g)';

  @override
  String get caloriesPer100FiberLabel => 'Fiber (g)';

  @override
  String get caloriesPer100SaltLabel => 'Salt (g)';

  @override
  String get inventoryReceiptReviewManualAddNutritionAction => 'Add more nutrients';

  @override
  String get inventoryReceiptReviewManualNutritionValueLabel => 'Value';

  @override
  String get inventoryReceiptReviewManualNutritionUnitLabel => 'Unit';

  @override
  String get inventoryReceiptReviewManualNutritionTypeLabel => 'Nutrient';

  @override
  String get caloriesEntryDateTimeLabel => 'Date and time';

  @override
  String get caloriesSaveEntryAction => 'Save';

  @override
  String get caloriesSaveFailed => 'Could not save entry.';

  @override
  String get caloriesRequiredField => 'This field is required.';

  @override
  String get caloriesInvalidNumber => 'Please enter valid numbers.';

  @override
  String get caloriesPositiveNumberValidation => 'Please enter a number greater than zero.';

  @override
  String get caloriesNonNegativeNumberValidation => 'Please enter a number equal to or greater than zero.';

  @override
  String get caloriesMealBreakfast => 'Breakfast';

  @override
  String get caloriesMealLunch => 'Lunch';

  @override
  String get caloriesMealDinner => 'Dinner';

  @override
  String get caloriesMealSnack => 'Snack';

  @override
  String get caloriesWeekdayShortMonday => 'Mon';

  @override
  String get caloriesWeekdayShortTuesday => 'Tue';

  @override
  String get caloriesWeekdayShortWednesday => 'Wed';

  @override
  String get caloriesWeekdayShortThursday => 'Thu';

  @override
  String get caloriesWeekdayShortFriday => 'Fri';

  @override
  String get caloriesWeekdayShortSaturday => 'Sat';

  @override
  String get caloriesWeekdayShortSunday => 'Sun';

  @override
  String get caloriesUnitKcal => 'kcal';

  @override
  String get caloriesUnitKg => 'kg';

  @override
  String get caloriesUnitGram => 'g';

  @override
  String get caloriesUnitMilliliter => 'ml';

  @override
  String get diaryTodayTitle => 'Today';

  @override
  String diaryCycleDayLabel(int week, int day) {
    return 'Week $week day $day';
  }

  @override
  String get diaryMealsTitle => 'Diary';

  @override
  String get diaryMealsEmpty => 'Nothing logged yet';

  @override
  String get diaryMealsLoadFailed => 'Meals could not be loaded';

  @override
  String diaryQuickEatAddTooltip(String meal) {
    return 'Add to $meal';
  }

  @override
  String get diaryQuickEatSourceInventory => 'Inventory';

  @override
  String get diaryQuickEatSourceBarcode => 'Barcode';

  @override
  String get diaryQuickEatSourceManualSearch => 'Search';

  @override
  String get diaryQuickEatSourceAi => 'AI';

  @override
  String get diaryQuickEatInventoryTitle => 'Eat from inventory';

  @override
  String get diaryQuickEatInventoryEmpty => 'No available food in inventory.';

  @override
  String get diaryBalanceLoadFailed => 'Balance could not be loaded';

  @override
  String get diaryNutritionLoadFailed => 'Nutrition could not be loaded';

  @override
  String get diaryNutritionTitle => 'Macronutrients';

  @override
  String get diaryBalanceEatenLabel => 'Eaten';

  @override
  String get diaryBalanceLeftLabel => 'Left';

  @override
  String get diaryBalanceLeftTodayLabel => 'Left today';

  @override
  String diaryBalanceWeekLabel(Object week) {
    return 'Week $week';
  }

  @override
  String diaryBalanceDayProgressLabel(Object day, Object total) {
    return 'Day $day of $total';
  }

  @override
  String get diaryBalanceTargetMarkerLabel => 'Target';

  @override
  String get diaryBalanceWeekActualLabel => 'Week actual';

  @override
  String get diaryBalanceWeekTargetLabel => 'Week target';

  @override
  String diaryBalanceRealEatenLabel(Object kcal) {
    return 'Real $kcal';
  }

  @override
  String diaryBalanceBufferAdjustmentLabel(Object kcal) {
    return 'Buffer $kcal';
  }

  @override
  String diaryBalanceRealLeftLabel(Object kcal) {
    return 'Real $kcal';
  }

  @override
  String diaryBalanceHeartAdjustmentLabel(Object kcal) {
    return 'Heart $kcal';
  }

  @override
  String get diaryBalanceHeartDayValue => 'Heart day';

  @override
  String get diaryBalanceHeartDaySubtitle => 'Ignored for learning';

  @override
  String get diaryBalanceRevertHeartDayAction => 'Revert heart day';

  @override
  String diaryBalanceActivityIncludedLabel(String kcal) {
    return '$kcal activity included in daily goal';
  }

  @override
  String diaryBalanceActivityBonusLabel(String kcal) {
    return '$kcal extra sport bonus';
  }

  @override
  String diaryWorkoutsBaselineProgress(String current, String target, String remaining) {
    return '$current / $target kcal baseline activity • $remaining kcal to bonus';
  }

  @override
  String diaryWorkoutsBonusEarned(String bonus) {
    return '+$bonus kcal extra sport bonus credited to daily goal!';
  }

  @override
  String get diaryIntroBackAction => 'Back';

  @override
  String get diaryIntroNextAction => 'Next';

  @override
  String get diaryIntroDoneAction => 'Start tracking';

  @override
  String get diaryIntroReplayAction => 'Show intro';

  @override
  String get diaryIntroStartTitle => 'Your starting point';

  @override
  String diaryIntroStartBody(String maintenanceKcal) {
    return 'From your profile, we estimate your maintenance at about $maintenanceKcal kcal per day. That should keep your weight roughly stable.';
  }

  @override
  String get diaryIntroActivityTitle => 'Activity';

  @override
  String diaryIntroActivityBody(String activityProfile, String activityKcal) {
    return 'You can connect Health so YAMT can track daily activity. With your activity profile \"$activityProfile\", YAMT expects about $activityKcal kcal from activity per day. Extra activity above that can raise today\'s target, but only 50% is credited because recorded calories are estimates. No worries if you cannot track activity calories: the system also works without them.';
  }

  @override
  String get diaryIntroGoalTitle => 'Your goal';

  @override
  String diaryIntroGoalLoseBody(String speedKg, String adjustmentKcal) {
    return 'Your goal is losing weight. For $speedKg kg per week, we subtract about $adjustmentKcal kcal per day.';
  }

  @override
  String diaryIntroGoalGainBody(String speedKg, String adjustmentKcal) {
    return 'Your goal is gaining weight. For $speedKg kg per week, we add about $adjustmentKcal kcal per day.';
  }

  @override
  String get diaryIntroGoalMaintainBody => 'Your goal is maintaining weight, so your daily target stays close to your maintenance estimate.';

  @override
  String get diaryIntroTargetTitle => 'Your first daily target';

  @override
  String diaryIntroTargetBody(String targetKcal) {
    return 'Your start target is about $targetKcal kcal per day. It is a first estimate and gets better with your data.';
  }

  @override
  String get diaryIntroWeekOneTitle => 'Week 1: build routine';

  @override
  String get diaryIntroWeekOneBody => 'Eat normally, but track food, drinks, and weight as completely as you can. Accurate tracking helps YAMT learn your real needs.';

  @override
  String get diaryIntroBetterDataTitle => 'Better with data';

  @override
  String get diaryIntroBetterDataBody => 'After 7 days, the estimate is better than the start value. After 14 consistent days, YAMT sees your metabolism more clearly.';

  @override
  String get diaryActivityTitle => 'Activity';

  @override
  String get diaryActivityEmpty => 'No activity';

  @override
  String get diaryActivityWeightLoadFailed => 'Activity and weight could not be loaded';

  @override
  String diaryActiveMinutesLabel(String minutes) {
    return '$minutes min active';
  }

  @override
  String get diaryWeightTitle => 'Weight';

  @override
  String get diarySevenDaysLabel => '7 days';

  @override
  String diaryProfileWeightLabel(String weight) {
    return 'Profile: $weight kg';
  }

  @override
  String get diaryWeightMissingPrompt => 'Log your weight for better calculation.';

  @override
  String get diaryWeightTrackNowAction => 'Track now';

  @override
  String get diaryWeightEmpty => 'No weights';

  @override
  String get diaryWeightAddAction => 'Log weight';

  @override
  String get diaryOkAction => 'OK';

  @override
  String diaryCounterLabel(int count) {
    return 'x $count';
  }

  @override
  String get diaryHealthLabel => 'Health';

  @override
  String get diaryHealthInstallTitle => 'Install Health';

  @override
  String get diaryHealthHistoryTitle => 'Allow history';

  @override
  String get diaryHealthUnsupportedTitle => 'Health unavailable';

  @override
  String get diaryHealthConnectTitle => 'Connect Health';

  @override
  String get diaryHealthPermissionDenied => 'Permission was not granted.';

  @override
  String get diaryHealthInstallBody => 'For steps and activity.';

  @override
  String get diaryHealthHistoryBody => 'Allow older days.';

  @override
  String get diaryHealthUnsupportedBody => 'Not available on this device.';

  @override
  String get diaryHealthConnectBody => 'Connect steps and activity.';

  @override
  String get diaryHealthSettingsAction => 'Settings';

  @override
  String get diaryHealthInstallAction => 'Install';

  @override
  String get diaryHealthAllowAction => 'Allow';

  @override
  String get diaryHealthUnavailableAction => 'Unavailable';

  @override
  String get diaryHealthConnectAction => 'Connect';

  @override
  String get diaryStepsTitle => 'Steps';

  @override
  String get diaryStepsLoadFailed => 'Steps could not be loaded';

  @override
  String get diaryStepDetailsTitle => 'Step details';

  @override
  String get diaryStepsDuringWorkoutsLabel => 'Steps during workouts';

  @override
  String get diaryStepsDuringOtherActivityLabel => 'Other active steps';

  @override
  String get diaryStepsOutsideWorkoutsLabel => 'Steps outside';

  @override
  String get diaryWorkoutsTitle => 'Workouts';

  @override
  String get diaryWorkoutsLoadFailed => 'Workouts could not be loaded';

  @override
  String get diaryWorkoutsEmpty => 'No workouts';

  @override
  String get diaryWorkoutFallbackTitle => 'Workout';

  @override
  String diaryWorkoutMinutesLabel(String minutes) {
    return '$minutes min';
  }

  @override
  String caloriesBundlePortions(String consumed, int total) {
    return '$consumed/$total portions';
  }

  @override
  String get homeSettingsActionContextPlaceholder => 'Settings action coming soon.';

  @override
  String get settingsManagePreferencesSubtitle => 'Manage your preferences';

  @override
  String get settingsProfileGuestSubtitle => 'Guest mode';

  @override
  String get settingsAccountHouseholdSectionTitle => 'Household';

  @override
  String get settingsHealthGoalsSectionTitle => 'Health & Goals';

  @override
  String get settingsAppearanceSectionTitle => 'Appearance';

  @override
  String get settingsAppSectionTitle => 'App';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose app language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageGerman => 'German';

  @override
  String get settingsThemeTitle => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsDiaryTitle => 'Diary';

  @override
  String get settingsDiaryGoalNoGoal => 'No goal set';

  @override
  String get settingsDiaryGoalSetGoalFirst => 'Set a goal first';

  @override
  String get settingsColorTitle => 'Accent color';

  @override
  String get settingsColorLime => 'Lime';

  @override
  String get settingsColorBlue => 'Blue';

  @override
  String get settingsColorTeal => 'Teal';

  @override
  String get settingsColorPink => 'Pink';

  @override
  String get settingsColorOrange => 'Orange';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsSubtitle => 'Manage reminders and alerts';

  @override
  String get settingsPrivacyTitle => 'Privacy';

  @override
  String get settingsPrivacySubtitle => 'Permissions and data controls';

  @override
  String get settingsHouseholdTitle => 'Household';

  @override
  String get settingsHouseholdSubtitle => 'Invite members and manage shared access';

  @override
  String get settingsAccountTitle => 'Account';

  @override
  String get settingsAccountSubtitle => 'Manage profile and sign-in';

  @override
  String get settingsHealthConnectPlatformTitle => 'Health Connect';

  @override
  String get settingsHealthConnectTitle => 'Connect health';

  @override
  String get settingsHealthConnectSubtitle => 'Allow YAMT to read steps, workouts, and burned calories from Health Connect.';

  @override
  String get settingsAppleHealthTitle => 'Apple Health';

  @override
  String get settingsAppleHealthConnectSubtitle => 'Allow YAMT to read steps, workouts, and burned calories from Apple Health.';

  @override
  String get settingsHealthHistorySubtitle => 'Allow older Health Connect history so past diary days can load activity data.';

  @override
  String get settingsHealthInstallSubtitle => 'Install Health Connect before you can connect health data here.';

  @override
  String get settingsHealthDisconnectSubtitle => 'Remove Health Connect access for YAMT.';

  @override
  String get settingsAppleHealthDisconnectSubtitle => 'Stop using Apple Health in YAMT.';

  @override
  String get settingsHealthDisconnectDialogTitle => 'Disconnect health access?';

  @override
  String get settingsHealthDisconnectDialogBody => 'YAMT will lose access to Health Connect until you connect it again.';

  @override
  String get settingsAppleHealthDisconnectDialogBody => 'YAMT will stop using Apple Health data until you connect it again. Apple Health permissions on your iPhone stay unchanged.';

  @override
  String get settingsHealthDisconnectAction => 'Disconnect';

  @override
  String get settingsHealthDisconnectSuccess => 'Health access disconnected. Restart YAMT before reconnecting Health Connect.';

  @override
  String get settingsAppleHealthDisconnectSuccess => 'Apple Health disconnected in YAMT. You can reconnect it anytime from Settings.';

  @override
  String get settingsHealthDisconnectOpenedSettings => 'Opened Settings so you can manage Apple Health access.';

  @override
  String get settingsHealthDisconnectFailed => 'Health access could not be disconnected.';

  @override
  String get settingsHealthConnectFailed => 'Health access could not be connected.';

  @override
  String get accountPageNoSession => 'No active account session.';

  @override
  String get accountPageGuestTitle => 'Guest account';

  @override
  String get accountPageGuestDescription => 'Link your guest account with Google to keep access across devices.';

  @override
  String get accountPageLinkGoogle => 'Link with Google';

  @override
  String get accountPageLinkEmailPassword => 'Link with email & password';

  @override
  String get accountPageLinkEmailPasswordTitle => 'Link guest account';

  @override
  String get accountPageLinkEmailPasswordDescription => 'Create email sign-in credentials for this guest account.';

  @override
  String get accountPageLinkEmailPasswordConfirmAction => 'Link account';

  @override
  String get healthInstallAction => 'Install Health Connect';

  @override
  String get healthHistoryAction => 'Allow older history';

  @override
  String get healthUnsupportedHint => 'Health Connect or Apple Health is not available on this device.';

  @override
  String get accountPageLinkSuccess => 'Account linked successfully.';

  @override
  String get accountPageLinkNotCompleted => 'Account linking was not completed. Please try again.';

  @override
  String get accountPageLinkConflictTitle => 'Account already in use';

  @override
  String get accountPageLinkConflictDescription => 'This sign-in credential is already linked to another profile. Choose how to continue.';

  @override
  String get accountPageLinkConflictOverwriteAction => 'Overwrite with this guest';

  @override
  String get accountPageLinkConflictOverwriteSubtitle => 'Keep this guest account and replace the old linked account.';

  @override
  String get accountPageLinkConflictDeleteGuestAction => 'Delete guest and sign in';

  @override
  String get accountPageLinkConflictDeleteGuestSubtitle => 'Delete this guest account and continue with the existing account.';

  @override
  String get accountPageLinkConflictOverwriteDone => 'Credential moved to this guest account.';

  @override
  String get accountPageLinkConflictDeleteGuestDone => 'Guest account deleted. Signed in with existing account.';

  @override
  String get accountPageGuestSessionRequired => 'This action is only available for guest accounts.';

  @override
  String get accountPageSignOut => 'Sign out';

  @override
  String get accountPageDeleteAction => 'Delete account';

  @override
  String get accountPageDeleteDialogTitle => 'Delete account?';

  @override
  String get accountPageDeleteDialogMessage => 'This permanently deletes your account and cannot be undone.';

  @override
  String get accountPageDeleteDialogConfirmAction => 'Delete';

  @override
  String get accountPageDeleteSuccess => 'Account deleted.';

  @override
  String get accountPageDisplayName => 'Display name';

  @override
  String get accountPageEmail => 'Email';

  @override
  String get accountPageUserId => 'User ID';

  @override
  String get accountPageNotSet => 'Not set';

  @override
  String get householdTitle => 'Household';

  @override
  String get householdJoinTitle => 'Join household';

  @override
  String get householdJoinCodeLabel => 'Code';

  @override
  String get householdJoinCodeHint => 'Enter 6-digit invite code';

  @override
  String get householdJoinAction => 'Join';

  @override
  String get householdJoinSuccess => 'Household joined.';

  @override
  String get householdJoinInvalidCode => 'Invalid household code.';

  @override
  String get householdJoinExpiredCode => 'This household code has expired.';

  @override
  String get householdJoinOwnCode => 'You cannot join your own household.';

  @override
  String get householdJoinNameDialogTitle => 'Enter your name';

  @override
  String get householdJoinNameDialogMessage => 'Please enter your name so other household members can recognize you.';

  @override
  String get householdJoinNameDialogFieldLabel => 'Your name';

  @override
  String get householdJoinNameDialogRequiredError => 'Please enter a name.';

  @override
  String get householdJoinNameDialogAction => 'Save & Join';

  @override
  String get householdInviteTitle => 'Invite members';

  @override
  String get householdInviteGenerateCode => 'Generate code';

  @override
  String get householdInviteCodeValidFor => 'Code valid for 24 hours';

  @override
  String get householdInviteCopyCode => 'Copy code';

  @override
  String get householdInviteCodeCopied => 'Code copied.';

  @override
  String get householdInviteRefreshCode => 'Generate new code';

  @override
  String get householdInviteVerificationRequired => 'Verify your account with Google or email before you lead a household.';

  @override
  String get householdHostVerificationHint => 'To invite other people into your household, link your guest account with Google or email & password.';

  @override
  String get householdMembersTitle => 'Members';

  @override
  String get householdLeaderBadge => 'Leader';

  @override
  String get householdYouBadge => 'You';

  @override
  String get householdRemoveMemberTitle => 'Remove member?';

  @override
  String householdRemoveMemberMessage(Object name) {
    return 'Remove $name from this household?';
  }

  @override
  String get householdRemoveMemberAction => 'Remove';

  @override
  String get householdRemoveMemberSuccess => 'Member removed.';

  @override
  String get householdRemoveMemberFailed => 'This member cannot be removed.';

  @override
  String get householdLeaveTitle => 'Leave household?';

  @override
  String get householdLeaveMessage => 'You will lose access to the shared household until you join again.';

  @override
  String get householdLeaveAction => 'Leave household';

  @override
  String get householdLeaveSuccess => 'Household left.';

  @override
  String get householdLeaderOnly => 'Only the household leader can do that.';

  @override
  String get householdActionFailed => 'Household action failed. Please try again.';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsAboutSubtitle => 'App version and information';

  @override
  String get commonOr => 'Or';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get loginWithGoogle => 'Login with Google';

  @override
  String get registerWithGoogle => 'Register with Google';

  @override
  String get createAccount => 'Create account';

  @override
  String get authBrandTitle => 'Yamt';

  @override
  String get authBrandSubtitle => 'Yet Another Meal Tracker';

  @override
  String get authRegisterTitle => 'Register';

  @override
  String get authRegisterSubtitle => 'Create your account and get started.';

  @override
  String get authContinueAsGuest => 'Continue as Guest';

  @override
  String get authFooterNoAccountPrefix => 'Don\'t have an account?';

  @override
  String get authFooterHasAccountPrefix => 'Already have an account?';

  @override
  String get authSwitchRegisterAction => 'Register now';

  @override
  String get authSwitchLoginAction => 'Login';

  @override
  String get authForgotPassword => 'Forgot?';

  @override
  String get authGuestNameSetupTitle => 'Set your guest name';

  @override
  String get authGuestNameSetupSubtitle => 'Choose a display name so your guest session is easier to recognize.';

  @override
  String get authGuestNameFieldLabel => 'Display name';

  @override
  String get authGuestNameSaveAction => 'Continue';

  @override
  String get authGuestNameRequiredError => 'Please enter a display name.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get validationPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get authFailed => 'Authentication failed';

  @override
  String get authErrorInvalidEmail => 'The email address is not valid.';

  @override
  String get authErrorUserDisabled => 'This user account has been disabled.';

  @override
  String get authErrorUserNotFound => 'No account found for this email.';

  @override
  String get authErrorWrongPassword => 'The password is incorrect.';

  @override
  String get authErrorInvalidCredential => 'The login credentials are invalid.';

  @override
  String get authErrorEmailAlreadyInUse => 'An account already exists for this email.';

  @override
  String get authErrorWeakPassword => 'The password is too weak.';

  @override
  String get authErrorOperationNotAllowed => 'This sign-in method is not enabled.';

  @override
  String get authErrorTooManyRequests => 'Too many requests. Please try again later.';

  @override
  String get authErrorNetworkRequestFailed => 'Network error. Please check your connection.';

  @override
  String get authErrorRequiresRecentLogin => 'Please log in again to continue.';

  @override
  String get authErrorAccountExistsWithDifferentCredential => 'An account already exists with a different sign-in method.';

  @override
  String get authErrorCredentialAlreadyInUse => 'This credential is already used by another account.';

  @override
  String get authErrorProviderAlreadyLinked => 'This sign-in provider is already linked to your account.';

  @override
  String get authErrorGoogleSignInCanceled => 'Google sign-in failed. Please try again.';

  @override
  String get authErrorGoogleIdTokenMissing => 'Google sign-in did not return a valid token.';

  @override
  String get commonUndoAction => 'Undo';

  @override
  String get commonNotImplementedYet => 'Not implemented yet';

  @override
  String get onboardingWelcomeTitle => 'Glad you are here!';

  @override
  String get onboardingWelcomeText => 'Forget complicated calorie counting. We make it as easy as possible. To support you optimally, we just need a little bit of information about you.';

  @override
  String get onboardingWelcomeAction => 'Let\'s start';

  @override
  String get onboardingWelcomeAlreadyHaveAccount => 'Already registered?';

  @override
  String get onboardingWelcomeLoginAction => 'Log in here';

  @override
  String get onboardingAgeYearsUnit => 'years';

  @override
  String get onboardingHeightCmUnit => 'cm';

  @override
  String get onboardingDoneAction => 'Done';

  @override
  String get onboardingNextAction => 'Next';

  @override
  String get onboardingNextActionStep5 => 'Sounds great, next!';

  @override
  String get onboardingFinishAction => 'Let\'s go';

  @override
  String get onboardingPersonalInfoTitle => 'Tell us something about yourself.';

  @override
  String get onboardingPersonalInfoSubtitle => 'This data helps us calculate your basal metabolic rate – because every body burns energy differently!';

  @override
  String get onboardingActivityLevelTitle => 'How active are you?';

  @override
  String get onboardingActivityLevelSubtitle => 'Your normal daily level (training comes later).';

  @override
  String get onboardingActivityTitle => 'Activity Level';

  @override
  String get onboardingActivitySubtitle => 'How active are you in your daily life?';

  @override
  String get onboardingGoalWeightTitle => 'Your Goal';

  @override
  String get onboardingGoalWeightSubtitle => 'Let\'s set your goal weight.';

  @override
  String get onboardingGoalWeightStartLabel => 'Start weight (kg)';

  @override
  String get onboardingGoalWeightTargetLabel => 'Goal weight (kg)';

  @override
  String get onboardingGoalWeightLoseFeedback => 'You want to lose weight. A healthy goal!';

  @override
  String get onboardingGoalWeightGainFeedback => 'You want to gain weight. Building muscle is great!';

  @override
  String get onboardingGoalWeightMaintainFeedback => 'You want to maintain your weight. Perfect!';

  @override
  String get onboardingPaceTitle => 'Your Pace';

  @override
  String get onboardingPaceSubtitle => 'How fast do you want to reach your goal?';

  @override
  String get onboardingPaceMaintainMessage => 'Since you want to maintain your weight, we will simply calculate your maintenance calories. You don\'t need to set a pace.';

  @override
  String get onboardingPaceWarningTitle => 'Ambitious Pace';

  @override
  String get onboardingPaceWarningLoseMessage => 'Losing more than 0.5 kg per week is quite high. Make sure you still get enough nutrients!';

  @override
  String get onboardingPaceWarningGainMessage => 'Gaining more than 0.5 kg per week is quite high. A more moderate pace helps build muscle without adding too much fat.';

  @override
  String onboardingPacePerWeek(String pace) {
    return '$pace kg / week';
  }

  @override
  String get onboardingInfoTitle => 'Your Plan is Ready! 🎉';

  @override
  String get onboardingInfoSubtitle => 'A few things you should know.';

  @override
  String get onboardingInfoPoint1Title => 'Scan Receipts';

  @override
  String get onboardingInfoPoint1Body => 'No more tedious typing.';

  @override
  String get onboardingInfoPoint2Title => 'AI Recognition';

  @override
  String get onboardingInfoPoint2Body => 'Just tell us what you ate.';

  @override
  String get onboardingInfoPoint3Title => 'Barcode Scanner';

  @override
  String get onboardingInfoPoint3Body => 'One scan, all nutrition facts.';

  @override
  String get onboardingInfoBoxTitle => 'The Learning Week';

  @override
  String get onboardingInfoBoxBody => 'Your first mission: Try not to force any changes in the next 7 days. Eat as usual and just track. Our smart algorithm learns your metabolism and creates your custom calorie goal!';

  @override
  String get onboardingStartDateTitle => 'When to start?';

  @override
  String get onboardingStartDateSubtitle => 'When do you want to start tracking?';

  @override
  String get onboardingStartDateNowLabel => 'Today';

  @override
  String get onboardingStartDateNowDesc => 'I will track everything today (or already did).';

  @override
  String get onboardingStartDateNowQuestion => 'How should we handle today?';

  @override
  String get onboardingStartDateNowExact => 'I will track the whole day exactly';

  @override
  String get onboardingStartDateNowEstimate => 'I will estimate what I ate so far';

  @override
  String get onboardingStartDateLaterLabel => 'Tomorrow';

  @override
  String get onboardingStartDateLaterDesc => 'Today is almost over, I prefer to start fresh tomorrow.';

  @override
  String get onboardingReadyTitle => 'All set!';

  @override
  String get onboardingReadySubtitle => 'Your profile is ready. Let\'s get started!';

  @override
  String get cookflowPrepflowTitle => 'Prepflow';

  @override
  String get cookflowTemplateNotFound => 'Recipe not found.';

  @override
  String get cookflowLoadFailed => 'Cookflow could not be loaded.';

  @override
  String get cookflowStartButton => 'Start flow';

  @override
  String get cookflowLaterButton => 'Later';

  @override
  String get cookflowShoppingListContinueButton => 'Add to shopping list and continue later';

  @override
  String get cookflowShoppingListAddSucceeded => 'Ingredients added to shopping list.';

  @override
  String get cookflowShoppingListAddFailed => 'Shopping list could not be updated.';

  @override
  String get cookflowSessionSaveFailed => 'Cookflow could not be saved.';

  @override
  String get cookflowResolveConflictsButton => 'Resolve conflicts';

  @override
  String get cookflowContinueButton => 'Continue';

  @override
  String cookflowPhaseChip(int currentPhase, int totalPhases) {
    return 'Phase $currentPhase / $totalPhases';
  }

  @override
  String get cookflowSaveMealButton => 'Save meal';

  @override
  String get cookflowSavingMealButton => 'Saving meal';

  @override
  String get cookflowInvalidWeight => 'Please enter a valid gross weight.';

  @override
  String get cookflowMissingWeight => 'Please enter the gross weight.';

  @override
  String get cookflowGrossMustExceedTara => 'Gross weight must be greater than tare.';

  @override
  String get cookflowMissingAssignments => 'Please assign at least one ingredient from inventory.';

  @override
  String get cookflowIngredientContainerMissing => 'Please choose a container for every ingredient.';

  @override
  String get cookflowContainerMissingIngredients => 'Every container needs at least one ingredient.';

  @override
  String get cookflowSaveFailed => 'Meal could not be saved.';

  @override
  String get cookflowSuccessFallbackMealName => 'Your meal';

  @override
  String cookflowSavedMealsCount(int count) {
    return '$count meals saved';
  }

  @override
  String get cookflowIntroHeadline => 'Start cooking session';

  @override
  String get cookflowRecipeLabel => 'Recipe: ';

  @override
  String get cookflowInventoryCheckTitle => 'Inventory check';

  @override
  String get cookflowResetButton => 'Reset';

  @override
  String get cookflowEmptyIngredients => 'No ingredients available.';

  @override
  String get cookflowShoppingCartTooltip => 'Shopping cart';

  @override
  String get cookflowAssignTooltip => 'Assign';

  @override
  String get cookflowIgnoreTooltip => 'Ignore';

  @override
  String get cookflowUnknownAmount => 'Amount open';

  @override
  String get cookflowInventorySelectionTitle => 'Choose inventory';

  @override
  String cookflowInventoryConflictMessage(Object availableAmount, Object missingAmount) {
    return 'Not enough in inventory: Only $availableAmount available. $missingAmount missing.';
  }

  @override
  String cookflowInventoryUsagePreview(Object usedAmount, Object remainingAmount) {
    return 'Subtract $usedAmount · left $remainingAmount';
  }

  @override
  String get cookflowBuyRemainingButton => 'BUY REMAINDER';

  @override
  String get cookflowAdjustTemplateButton => 'ADJUST RECIPE';

  @override
  String cookflowInventoryUnitConflictMessage(Object recipeUnit, Object inventoryUnit) {
    return 'Unit conflict: recipe uses \"$recipeUnit\". Inventory has \"$inventoryUnit\".';
  }

  @override
  String get cookflowInventoryUnitConversionPrefix => '1 piece ≈';

  @override
  String get cookflowInventoryUnitConvertAction => 'Convert';

  @override
  String get cookflowInventoryUnitWeighLaterAction => 'Weigh later while cooking';

  @override
  String get cookflowEditIngredientTooltip => 'Edit ingredient';

  @override
  String get cookflowEditIngredientTitle => 'Edit ingredient';

  @override
  String get cookflowEditIngredientNameLabel => 'Ingredient';

  @override
  String get cookflowEditIngredientAmountLabel => 'Amount';

  @override
  String get cookflowEditIngredientUnitLabel => 'Unit';

  @override
  String get cookflowEditIngredientRequiredField => 'Please fill this field.';

  @override
  String get cookflowEditIngredientSaveAction => 'Save';

  @override
  String get cookflowInventorySelectionEmpty => 'No matching inventory items found.';

  @override
  String get cookflowCancelButton => 'Cancel';

  @override
  String get cookflowInventorySelectionSaveButton => 'Select';

  @override
  String get cookflowInventorySelectionItemLabel => 'Inventory item';

  @override
  String get cookflowInventorySelectionAddIngredient => 'Add ingredient';

  @override
  String get cookflowInventorySelectionAddIngredientSubtitle => 'Choose an optional inventory item.';

  @override
  String get cookflowInventorySelectionWeightLater => 'Set weight later in phase 3.';

  @override
  String get cookflowInventorySelectionAddConfirm => 'Add';

  @override
  String get cookflowInventoryReturnSuggestion => 'Found a new inventory match.';

  @override
  String get cookflowInventoryReturnSuggestionButton => 'Apply';

  @override
  String get cookflowPreparationTitle => '1. Preparation';

  @override
  String get cookflowPreparationBody => 'Before we begin: choose every pot or storage box you will use and enter its empty weight.';

  @override
  String get cookflowTaraFieldTitle => 'Empty weight (tare)';

  @override
  String get cookflowGramUnit => 'Grams';

  @override
  String get cookflowTaraUtensilsTitle => 'Saved utensils';

  @override
  String get cookflowTaraUtensilsLoadFailed => 'Could not load utensils.';

  @override
  String get cookflowPreparationHint => 'If pasta and sauce end up in separate containers, add both now. In phase 3 you assign each ingredient to its container.';

  @override
  String get cookflowPortionScalerTitle => 'Recipe portions';

  @override
  String cookflowOriginalPortionsLabel(int count) {
    return 'Original recipe: $count portions';
  }

  @override
  String cookflowTargetPortionsLabel(int count) {
    return '$count portions';
  }

  @override
  String get cookflowTargetPortionsFieldLabel => 'New portions';

  @override
  String get cookflowCookingTitle => '2. Cooking';

  @override
  String get cookflowCookingBody => 'The ingredients from your inventory are reserved locally.\nEnjoy your meal!';

  @override
  String get cookflowOnTheFlyTitle => 'On-the-fly adjustment';

  @override
  String get cookflowOnTheFlyHint => 'e.g. 150g extra peas...';

  @override
  String get cookflowOnTheFlyRemoveTooltip => 'Remove adjustment';

  @override
  String get cookflowVoiceInputStartTooltip => 'Start voice input';

  @override
  String get cookflowVoiceInputStopTooltip => 'Stop voice input';

  @override
  String get cookflowVoiceInputUnavailable => 'Voice input is not currently supported on this device.';

  @override
  String get cookflowVoiceInputPermissionDenied => 'Please allow microphone access to use voice input.';

  @override
  String get cookflowVoiceInputFailed => 'Voice input could not be started. Please try again.';

  @override
  String get cookflowCookingFallbackNoIngredients => 'Prepare your recipe with the ingredients you have available.';

  @override
  String get cookflowCookingFallbackPrepPrefix => 'Prepare the ingredients:';

  @override
  String get cookflowCookingFallbackCookText => 'Then cook the dish as described in the recipe.';

  @override
  String get cookflowSummaryTitle => '3. Summary';

  @override
  String get cookflowSummaryBody => 'Check the final ingredients, resolve spontaneous changes, and choose where each ingredient is stored.';

  @override
  String get cookflowSummaryIngredientsTitle => 'Base recipe ingredients';

  @override
  String get cookflowSummaryAdjustmentsTitle => 'Unresolved adjustments';

  @override
  String get cookflowSummaryMatchInventoryButton => 'Add as ingredient';

  @override
  String get cookflowSummaryPlaceholderAdjustment => '200g cucumbers';

  @override
  String get cookflowFinalizeTitle => '4. Finalize';

  @override
  String get cookflowFinalizeBody => 'Place each filled container on the scale, then set portions for the meals we will create.';

  @override
  String get cookflowStorageContainersTitle => 'Storage containers';

  @override
  String get cookflowAddStorageContainerButton => 'Add container';

  @override
  String get cookflowContainerLabel => 'Container';

  @override
  String cookflowContainerNameHint(int index) {
    return 'Container $index';
  }

  @override
  String get cookflowRemoveContainerTooltip => 'Remove container';

  @override
  String get cookflowContainerTaraLabel => 'Tare';

  @override
  String get cookflowPortionsUnit => 'portions';

  @override
  String get cookflowIngredientContainerTitle => 'Where is each ingredient stored?';

  @override
  String get cookflowIngredientContainerEmpty => 'No inventory ingredients available for container assignment.';

  @override
  String get cookflowGrossWeightTitle => 'Gross weight (pot + food)';

  @override
  String get cookflowGrossWeightHint => 'e.g. 2500';

  @override
  String get cookflowMinusTaraLabel => 'Minus empty weight (tare)';

  @override
  String get cookflowNetWeightLabel => 'Net final weight';

  @override
  String get cookflowSplitIntoPortionsLabel => 'Adjust portions?';

  @override
  String get cookflowHowManyPortions => 'How many portions is that?';

  @override
  String get cookflowCaloriesShortLabel => 'CALORIES';

  @override
  String get cookflowCarbsShortLabel => 'CARBS';

  @override
  String get cookflowProteinShortLabel => 'PROTEIN';

  @override
  String get cookflowFatShortLabel => 'FAT';

  @override
  String get cookflowSuccessTitle => 'Done';

  @override
  String get cookflowSuccessSubtitle => 'Your meal was saved and is now available in inventory.';

  @override
  String get cookflowSuccessHeadline => 'Meal saved';

  @override
  String get cookflowToInventoryButton => 'Go to inventory';

  @override
  String get cookflowResumeLabel => 'Resume';
}
