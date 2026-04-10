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
  String get homeStatistics => 'Statistics';

  @override
  String get homeCalories => 'Diary';

  @override
  String get homeSettings => 'Settings';

  @override
  String get homeQuickActionTooltip => 'Quick action';

  @override
  String get inventoryFabTooltip => 'Receipt actions';

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
  String get inventoryReceiptReviewManualDataBarcodeLabel => 'Barcode';

  @override
  String get inventoryReceiptReviewManualDataRequired => 'Please select a product, scan a barcode, or add nutrition.';

  @override
  String get inventoryReceiptReviewRequestEnrichmentAction => 'Let AI enrich it later';

  @override
  String get inventoryReceiptReviewRequestEnrichmentHint => 'Saves the item now and marks it for later AI enrichment.';

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
  String get inventoryRecentSectionTitle => 'Recently added';

  @override
  String get inventorySearchLabel => 'Search inventory';

  @override
  String get inventorySearchClearAction => 'Clear search';

  @override
  String get inventoryFilterAction => 'Filter items';

  @override
  String get inventoryFiltersTitle => 'Filter items';

  @override
  String get inventoryNutritionCaloriesShortLabel => 'Kcal';

  @override
  String get inventoryNutritionCarbsShortLabel => 'Carbs';

  @override
  String get inventoryFilterConsumed => 'Consumed';

  @override
  String get inventoryFilterNotConsumed => 'Not consumed';

  @override
  String get inventoryHideFullyConsumedItemsToggle => 'Hide fully consumed items';

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
  String get inventoryItemEatAction => 'Eat';

  @override
  String get inventoryItemEatSheetEyebrow => 'Log';

  @override
  String inventoryItemEatSheetTitle(String name) {
    return 'Eat: $name';
  }

  @override
  String get inventoryItemEatSheetAmountLabel => 'Enter amount';

  @override
  String get inventoryItemEatSheetQuickSelectLabel => 'Quick select';

  @override
  String get inventoryItemEatSheetAllAction => 'All';

  @override
  String get inventoryItemEatSheetInedibleAmountLabel => 'Subtract inedible part';

  @override
  String get inventoryItemEatSheetInedibleAmountHint => 'Optional, e.g. bones or shells. Calories are calculated only for the edible remainder.';

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
  String get inventoryItemEatSheetConfirmAction => 'Log';

  @override
  String get inventoryItemEatSheetClearAmountAction => 'Clear amount';

  @override
  String get inventoryItemBuyAgainAction => 'Buy again';

  @override
  String get inventoryItemBuyAgainSucceeded => 'Item added to shopping list.';

  @override
  String get inventoryItemThrowAwayAction => 'Throw away';

  @override
  String get inventoryItemSwapCandidateAction => 'Swap candidate';

  @override
  String get inventoryItemSwapCandidateRequiresFullItem => 'You can swap the candidate only while the item is still fully available.';

  @override
  String get inventoryItemActionFailed => 'Action failed. Please try again.';

  @override
  String get inventoryBarcodeStatusPending => 'Barcode lookup pending';

  @override
  String get inventoryBarcodeStatusUncertain => 'Not sure';

  @override
  String get inventoryBarcodeStatusMissing => 'Barcode missing';

  @override
  String get inventoryBarcodeMissingPromptTitle => 'Barcode missing';

  @override
  String get inventoryBarcodeMissingPromptMessage => 'Scan now to log calories immediately, or continue and let AI backfill it.';

  @override
  String get inventoryBarcodeMissingPromptScanNow => 'Scan barcode now';

  @override
  String get inventoryBarcodeMissingPromptLater => 'Later';

  @override
  String get inventoryBarcodeLookupQueued => 'Barcode search finished. The result is saved on the inventory item.';

  @override
  String get inventoryBarcodeScanUnsupported => 'Barcode scanning is currently supported on Android and iOS.';

  @override
  String get inventoryManualAddTitle => 'Add food manually';

  @override
  String get inventoryManualAddHint => 'Scan a barcode. Then you can review the product, save it, or add nutrition values.';

  @override
  String get inventoryManualAddResolving => 'Looking up barcode...';

  @override
  String get inventoryManualAddCandidateTitle => 'Select product';

  @override
  String get inventoryManualAddCandidateSubtitle => 'Multiple matching products were found for this barcode.';

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
  String get inventoryManualAddEatNowOption => 'Eat now';

  @override
  String get inventoryManualAddEatNowRequiresNutrition => 'Only available when nutrition values are present.';

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
  String preparedMealPortionsRemaining(int remaining, int total) {
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
  String get preparedMealTemplateDetailTitle => 'Template';

  @override
  String preparedMealTemplateDetailMatchTitle(String name) {
    return 'Ingredient Matching: $name';
  }

  @override
  String get preparedMealTemplateDetailNotFound => 'Template not found.';

  @override
  String get preparedMealTemplateDetailLoadFailed => 'Template could not be loaded.';

  @override
  String preparedMealTemplateDetailBasePortions(int count) {
    return 'Base: $count portions';
  }

  @override
  String get preparedMealTemplateDetailScaleHint => 'Ingredients are scaled to this number of portions.';

  @override
  String get preparedMealTemplateDetailNoIngredients => 'No ingredients available yet.';

  @override
  String get preparedMealTemplateDetailSaveAction => 'Update template';

  @override
  String get preparedMealTemplateDetailSavingAction => 'Saving...';

  @override
  String get preparedMealTemplateDetailIngredientsToShoppingListAction => 'Ingredients to shopping list';

  @override
  String get preparedMealTemplateDetailCreateMealHint => 'This template needs at least one ingredient before you can create a meal.';

  @override
  String get preparedMealTemplateDetailAssignAction => 'Assign';

  @override
  String get preparedMealTemplateDetailChangeAssignmentAction => 'Change assignment';

  @override
  String get preparedMealTemplateDetailAssignedFromInventoryTitle => 'Covered from inventory';

  @override
  String get preparedMealTemplateDetailMatchingInventoryItemsTitle => 'Matching inventory items';

  @override
  String preparedMealTemplateDetailMissingAssignedItems(int count) {
    return '$count assigned items are no longer in inventory.';
  }

  @override
  String preparedMealTemplateDetailIgnoredAmount(String amount) {
    return 'Ignored • $amount';
  }

  @override
  String preparedMealTemplateDetailAssignedCount(int count) {
    return '$count items assigned';
  }

  @override
  String get preparedMealTemplateDetailSelectionTitle => 'Choose inventory items';

  @override
  String get preparedMealTemplateDetailSelectionEmpty => 'No inventory items available.';

  @override
  String preparedMealTemplateDetailSelectionConversionLabel(String sourceUnit, String unit) {
    return 'Amount per $sourceUnit ($unit)';
  }

  @override
  String preparedMealTemplateDetailSelectionConversionHint(String sourceUnit, String unit, String ingredient) {
    return 'How much $unit does 1 $sourceUnit of \"$ingredient\" use?';
  }

  @override
  String get preparedMealTemplateDetailSelectionConversionError => 'Please enter an amount greater than 0.';

  @override
  String preparedMealTemplateDetailConversionSummary(String sourceUnit, int amount, String unit) {
    return '1 $sourceUnit = $amount $unit';
  }

  @override
  String get preparedMealTemplateDetailListAction => 'List';

  @override
  String get preparedMealTemplateDetailSearchAction => 'Search';

  @override
  String get preparedMealTemplateDetailSwapAction => 'Swap';

  @override
  String get preparedMealTemplateDetailRestoreAction => 'Restore';

  @override
  String get preparedMealTemplateDetailAddToShoppingListAction => 'Add to shopping list';

  @override
  String get preparedMealTemplateDetailIgnoreAction => 'Ignore';

  @override
  String get preparedMealTemplateDetailUnignoreAction => 'Do not ignore';

  @override
  String get preparedMealTemplateDetailAddIngredientShoppingFailed => 'Ingredient could not be added to the shopping list.';

  @override
  String get preparedMealTemplateDetailAddIngredientsShoppingFailed => 'Ingredients could not be added to the shopping list.';

  @override
  String preparedMealTemplateDetailAddIngredientsShoppingSucceeded(int count) {
    return '$count ingredients were added to the shopping list.';
  }

  @override
  String get preparedMealTemplateDetailIgnoreSaveFailed => 'Ingredient status could not be saved.';

  @override
  String get preparedMealTemplateDetailInvalidMealMessage => 'The template needs at least one valid ingredient.';

  @override
  String get preparedMealTemplateDetailSaveFailedMessage => 'Template could not be updated.';

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
  String get caloriesGoalStartTimeLabel => 'Time';

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
  String get caloriesCalculatorGoalStartHint => 'Your calorie target history begins from this point.';

  @override
  String get caloriesCalculatorGoalStartChangeAction => 'Change';

  @override
  String get caloriesCalculatorGoalStartFutureError => 'Goal start can\'t be in the future.';

  @override
  String caloriesCalculatorMinimumGoalWarning(int minimumKcal) {
    return 'For weight loss, the daily target cannot go below $minimumKcal kcal. The result was capped at this minimum.';
  }

  @override
  String get caloriesCalculatorSaveAction => 'Save target';

  @override
  String get caloriesCalculatorSaveFailed => 'Could not save the calculated calorie target.';

  @override
  String get caloriesConsumedLabel => 'Consumed';

  @override
  String get caloriesGoalLabel => 'Goal';

  @override
  String get caloriesRemainingLabel => 'Remaining';

  @override
  String get caloriesSummaryViewClassic => 'Classic';

  @override
  String get caloriesSummaryViewBalance => 'Balance';

  @override
  String get caloriesBalanceCarryoverLabel => '7-day balance';

  @override
  String get caloriesBalanceFlexGoalLabel => 'Flex goal';

  @override
  String get caloriesBalancePaceNowLabel => 'Pace now';

  @override
  String get caloriesBalancePaceFinalLabel => 'Final pace';

  @override
  String get caloriesBalanceScaleBufferLabel => 'Deficit';

  @override
  String get caloriesBalanceScaleOnTrackLabel => 'On track';

  @override
  String get caloriesBalanceScaleOverLabel => 'Surplus';

  @override
  String get caloriesBalanceStatusBalancedNow => 'Well balanced for now';

  @override
  String caloriesBalanceStatusEatNow(int kcal) {
    return 'Eat about $kcal kcal now';
  }

  @override
  String get caloriesBalanceStatusWaitNow => 'Wait a bit before eating again';

  @override
  String caloriesBalanceStatusWaitUntil(String time) {
    return 'Back on pace around $time';
  }

  @override
  String get caloriesBalanceStatusWaitRestOfDay => 'Likely off pace for the rest of today';

  @override
  String get caloriesBalanceStatusRecommendFast => 'Recommendation: fast today';

  @override
  String get caloriesBalanceStatusRecommendFastRestOfDay => 'Recommendation: fast for the rest of today';

  @override
  String get caloriesBalanceStatusOnTrack => 'Right on pace';

  @override
  String caloriesBalanceStatusBuffer(int kcal) {
    return '$kcal kcal under pace';
  }

  @override
  String caloriesBalanceStatusOver(int kcal) {
    return '$kcal kcal over pace';
  }

  @override
  String caloriesBalanceStatusLoseUnder(int kcal) {
    return '$kcal kcal buffer for weight loss';
  }

  @override
  String caloriesBalanceStatusLoseOver(int kcal) {
    return '$kcal kcal over pace for weight loss';
  }

  @override
  String caloriesBalanceStatusGainUnder(int kcal) {
    return '$kcal kcal under pace for weight gain';
  }

  @override
  String get caloriesBalanceStatusFinishedOnTrack => 'The day ended on target';

  @override
  String caloriesBalanceStatusFinishedBuffer(int kcal) {
    return '$kcal kcal under the flex target';
  }

  @override
  String caloriesBalanceStatusFinishedOver(int kcal) {
    return '$kcal kcal over the flex target';
  }

  @override
  String caloriesBalanceStatusFinishedLoseUnder(int kcal) {
    return 'Ended with a $kcal kcal buffer for weight loss';
  }

  @override
  String caloriesBalanceStatusFinishedLoseOver(int kcal) {
    return 'Ended $kcal kcal over the flex target for weight loss';
  }

  @override
  String caloriesBalanceStatusFinishedGainUnder(int kcal) {
    return 'Ended $kcal kcal under the flex target for weight gain';
  }

  @override
  String caloriesBalanceStatusFinishedGainOver(int kcal) {
    return 'Ended with $kcal kcal extra for weight gain';
  }

  @override
  String get caloriesBalanceUnavailable => 'Balance view is unavailable right now.';

  @override
  String get caloriesProteinLabel => 'Protein';

  @override
  String get caloriesCarbsLabel => 'Carbs';

  @override
  String get caloriesFatLabel => 'Fat';

  @override
  String get caloriesWeekBufferTitle => 'Weekly balance';

  @override
  String caloriesWeekBufferRemaining(int kcal) {
    return '$kcal kcal left this week';
  }

  @override
  String caloriesWeekBufferOverspent(int kcal) {
    return '$kcal kcal over this week';
  }

  @override
  String get caloriesWeekBalanceTodayLabel => 'Today';

  @override
  String caloriesWeekBalanceSaved(int kcal) {
    return 'You saved $kcal kcal since your goal started. Today\'s target was increased.';
  }

  @override
  String caloriesWeekBalanceOverspent(int kcal) {
    return 'You are $kcal kcal over since your goal started.';
  }

  @override
  String get caloriesWeekBalanceStable => 'You are balanced since your goal started. Today\'s target stays unchanged.';

  @override
  String caloriesWeekBalanceStartsLater(String date) {
    return 'Your goal starts on $date. The balance will begin automatically then.';
  }

  @override
  String get caloriesWeekBalanceStartedToday => 'Your goal starts today. The balance will build up from here.';

  @override
  String get caloriesSectionEmptyState => 'No entries yet.';

  @override
  String get caloriesDeleteEntryDialogTitle => 'Delete entry?';

  @override
  String caloriesDeleteEntryDialogMessage(String name) {
    return 'Delete \"$name\" from this day?';
  }

  @override
  String get caloriesDeleteEntryConfirmAction => 'Delete';

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
  String get caloriesDeleteFailed => 'Could not delete entry.';

  @override
  String get caloriesAddEntryTitle => 'Add calorie entry';

  @override
  String get caloriesEditEntryTitle => 'Edit calorie entry';

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
  String get caloriesUnitGram => 'g';

  @override
  String get caloriesUnitMilliliter => 'ml';

  @override
  String caloriesBundlePortions(int consumed, int total) {
    return '$consumed/$total portions';
  }

  @override
  String get homeSettingsActionContextPlaceholder => 'Settings action coming soon.';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose app language';

  @override
  String get settingsThemeTitle => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

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
  String get settingsHouseholdTitle => 'Household';

  @override
  String get settingsHouseholdSubtitle => 'Invite members and manage shared access';

  @override
  String get settingsAccountTitle => 'Account';

  @override
  String get settingsAccountSubtitle => 'Manage profile and sign-in';

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
  String get statisticsPageSubtitle => 'Patterns from inventory, food waste, and nutrition at a glance.';

  @override
  String get statisticsContextHousehold => 'Household';

  @override
  String get statisticsContextPersonal => 'Personal';

  @override
  String get statisticsTimeframeWeek => '7 days';

  @override
  String get statisticsTimeframeMonth => 'Month';

  @override
  String get statisticsTimeframeYear => 'Year';

  @override
  String get statisticsTimeframeTotal => 'All';

  @override
  String get statisticsTabSpending => 'Spending';

  @override
  String get statisticsTabWaste => 'Food Waste';

  @override
  String get statisticsTabCalories => 'Calories';

  @override
  String get statisticsHouseholdHintTitle => 'MVP note';

  @override
  String get statisticsHouseholdHintBody => 'Household figures currently use tracked inventory items and available receipt data. A full timeline view will come later.';

  @override
  String get statisticsWasteHintTitle => 'Prepare waste tracking';

  @override
  String get statisticsWasteHintBody => 'Real food-waste statistics need durable discard events and discard reasons in the throw-away flow.';

  @override
  String get statisticsSpendingTotalTitle => 'Tracked spending';

  @override
  String get statisticsSpendingTotalSubtitle => 'sum of captured purchases in the selected period';

  @override
  String get statisticsSpendingTrendTitle => 'Price trend';

  @override
  String get statisticsSpendingTrendEmpty => 'No recurring products with usable price history in the selected period yet.';

  @override
  String get statisticsSpendingStoresTitle => 'Top stores';

  @override
  String get statisticsTopStoresEmpty => 'No stores with useful values in this period yet.';

  @override
  String get statisticsSpendingChartTitle => 'Spending by receipt date';

  @override
  String get statisticsSpendingChartSubtitle => 'The chart uses the real receiptDate and shows the latest shopping days for the selected filter.';

  @override
  String get statisticsSpendingChartEmpty => 'As soon as dated receipt data exists, your spending timeline will show up here.';

  @override
  String get statisticsSpendingItemsTitle => 'Most expensive items';

  @override
  String get statisticsExpensiveItemsEmpty => 'No cost-relevant items in this period yet.';

  @override
  String get statisticsWasteOverviewTitle => 'Food waste overview';

  @override
  String get statisticsWasteTrackingMissingValue => 'No history yet';

  @override
  String get statisticsWasteTrackingMissingMessage => 'Discard events and reasons are not persisted yet.';

  @override
  String statisticsWasteOverviewSummary(int eventCount, Object lossValue) {
    String _temp0 = intl.Intl.pluralLogic(
      eventCount,
      locale: localeName,
      other: '$eventCount discard events · $lossValue tracked loss',
      one: '1 discard event · $lossValue tracked loss',
    );
    return '$_temp0';
  }

  @override
  String get statisticsWasteRatioTitle => 'Ratio & money loss';

  @override
  String get statisticsWasteMoneyLossMissing => 'Once discarded values are tracked, the ratio and exact money loss will appear here.';

  @override
  String get statisticsWasteMoneyLossTracked => 'Tracked value of thrown-away food in this period.';

  @override
  String get statisticsWasteReasonsTitle => 'Waste reasons';

  @override
  String get statisticsWasteReasonsMissing => 'Add reasons such as expired or cooked too much when throwing items away so we can surface patterns.';

  @override
  String statisticsWasteReasonsTopSummary(int count) {
    return 'Most common reason across $count discard events.';
  }

  @override
  String get statisticsWasteItemsTitle => 'Often discarded';

  @override
  String get statisticsWasteItemsMissing => 'Once enough discard events exist, your most frequent problem items will show up here.';

  @override
  String statisticsWasteItemsTopSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'discarded $count times',
      one: 'discarded once',
    );
    return '$_temp0';
  }

  @override
  String get statisticsCaloriesOverviewTitle => 'Calories overview';

  @override
  String statisticsCaloriesOverviewSummary(int trackedDays, int entries) {
    return '$trackedDays tracked days · $entries entries';
  }

  @override
  String get statisticsCaloriesStreakTitle => 'Goal streak';

  @override
  String statisticsCaloriesStreakSummary(int goalDays, int trackedDays) {
    return '$goalDays of $trackedDays days within goal';
  }

  @override
  String get statisticsCaloriesBufferTitle => 'Weekly balance';

  @override
  String get statisticsCaloriesBufferSubtitle => 'current balance against your goal';

  @override
  String get statisticsCaloriesChartTitle => 'Daily view';

  @override
  String get statisticsCaloriesChartSubtitle => 'Recent days with eaten calories and goal marker.';

  @override
  String get statisticsCaloriesChartEmpty => 'As soon as calorie entries exist, your daily view will show up here.';

  @override
  String get statisticsCaloriesMacrosTitle => 'Macro split';

  @override
  String get statisticsCaloriesMacroChartSubtitle => 'Share of calories coming from carbs, protein, and fat.';

  @override
  String get statisticsCaloriesNoEntries => 'No calorie entries in this period yet.';

  @override
  String get statisticsChartGoalLegend => 'Goal marker';

  @override
  String get statisticsMetricNoTrend => 'No trend yet';

  @override
  String get statisticsMetricNoData => 'No data yet';

  @override
  String get statisticsMetricAverage => 'Average';

  @override
  String get statisticsMetricEntries => 'Entries';

  @override
  String get statisticsMetricTrackedDays => 'Tracked days';

  @override
  String get statisticsMetricGoalDays => 'Within goal';

  @override
  String get statisticsMetricReceipts => 'Receipts';

  @override
  String get statisticsWasteSignalsTitle => 'What is still missing';

  @override
  String get statisticsWasteChecklistEvents => 'durable discard events with amount and timestamp';

  @override
  String get statisticsWasteChecklistReasons => 'discard reasons such as expired, moldy, or cooked too much';

  @override
  String get statisticsWasteChecklistEatingOut => 'prices for outside meals so household spending becomes more complete';

  @override
  String statisticsCaloriesBalanceWindow(String startDate, String endDate) {
    return 'Balance window from $startDate to $endDate';
  }

  @override
  String get statisticsLoadFailed => 'Could not load statistics.';

  @override
  String get commonUndoAction => 'Undo';

  @override
  String get commonNotImplementedYet => 'Not implemented yet';
}
