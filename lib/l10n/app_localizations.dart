import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get homeInventory;

  /// No description provided for @homeShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get homeShopping;

  /// No description provided for @homeCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get homeCalories;

  /// No description provided for @homeSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// No description provided for @homeQuickActionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Quick action'**
  String get homeQuickActionTooltip;

  /// No description provided for @homeQuickActionTapped.
  ///
  /// In en, this message translates to:
  /// **'Quick action tapped'**
  String get homeQuickActionTapped;

  /// No description provided for @inventoryFabTooltip.
  ///
  /// In en, this message translates to:
  /// **'Receipt actions'**
  String get inventoryFabTooltip;

  /// No description provided for @inventoryActionScanCamera.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt (camera)'**
  String get inventoryActionScanCamera;

  /// No description provided for @inventoryActionUploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload receipt (image/PDF)'**
  String get inventoryActionUploadFile;

  /// No description provided for @inventoryActionCameraUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Camera is not supported on this platform.'**
  String get inventoryActionCameraUnsupported;

  /// No description provided for @inventoryReceiptSelectedCamera.
  ///
  /// In en, this message translates to:
  /// **'Receipt image captured.'**
  String get inventoryReceiptSelectedCamera;

  /// No description provided for @inventoryReceiptSelectedFile.
  ///
  /// In en, this message translates to:
  /// **'Receipt file selected.'**
  String get inventoryReceiptSelectedFile;

  /// No description provided for @inventoryReceiptSelectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not select a receipt. Please try again.'**
  String get inventoryReceiptSelectionFailed;

  /// No description provided for @inventoryReceiptAnalysisSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Receipt analyzed successfully.'**
  String get inventoryReceiptAnalysisSucceeded;

  /// No description provided for @inventoryReceiptAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Receipt analysis failed. Please try again.'**
  String get inventoryReceiptAnalysisFailed;

  /// No description provided for @inventoryReceiptBatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Processing receipts'**
  String get inventoryReceiptBatchTitle;

  /// No description provided for @inventoryReceiptBatchProgress.
  ///
  /// In en, this message translates to:
  /// **'{processed}/{total}'**
  String inventoryReceiptBatchProgress(int processed, int total);

  /// No description provided for @inventoryReceiptBatchQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get inventoryReceiptBatchQueued;

  /// No description provided for @inventoryReceiptBatchProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get inventoryReceiptBatchProcessing;

  /// No description provided for @inventoryReceiptBatchSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get inventoryReceiptBatchSucceeded;

  /// No description provided for @inventoryReceiptBatchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get inventoryReceiptBatchFailed;

  /// No description provided for @inventoryReceiptBatchReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get inventoryReceiptBatchReviewAction;

  /// No description provided for @inventoryReceiptBatchReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get inventoryReceiptBatchReviewed;

  /// No description provided for @inventoryReceiptBatchCloseAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get inventoryReceiptBatchCloseAction;

  /// No description provided for @inventoryReceiptReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review receipt items'**
  String get inventoryReceiptReviewTitle;

  /// No description provided for @inventoryReceiptReviewPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Price overview'**
  String get inventoryReceiptReviewPriceTitle;

  /// No description provided for @inventoryReceiptReviewPriceTotal.
  ///
  /// In en, this message translates to:
  /// **'Total receipt'**
  String get inventoryReceiptReviewPriceTotal;

  /// No description provided for @inventoryReceiptReviewPriceSavable.
  ///
  /// In en, this message translates to:
  /// **'Saved to inventory'**
  String get inventoryReceiptReviewPriceSavable;

  /// No description provided for @inventoryReceiptReviewPriceExcluded.
  ///
  /// In en, this message translates to:
  /// **'Excluded lines'**
  String get inventoryReceiptReviewPriceExcluded;

  /// No description provided for @inventoryReceiptReviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items found on this receipt.'**
  String get inventoryReceiptReviewEmpty;

  /// No description provided for @inventoryReceiptReviewExcludedTag.
  ///
  /// In en, this message translates to:
  /// **'Review only'**
  String get inventoryReceiptReviewExcludedTag;

  /// No description provided for @inventoryReceiptReviewEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get inventoryReceiptReviewEditAction;

  /// No description provided for @inventoryReceiptReviewEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit receipt item'**
  String get inventoryReceiptReviewEditTitle;

  /// No description provided for @inventoryReceiptReviewApplyItemAction.
  ///
  /// In en, this message translates to:
  /// **'Apply changes'**
  String get inventoryReceiptReviewApplyItemAction;

  /// No description provided for @inventoryReceiptReviewFieldId.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get inventoryReceiptReviewFieldId;

  /// No description provided for @inventoryReceiptReviewFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get inventoryReceiptReviewFieldName;

  /// No description provided for @inventoryReceiptReviewFieldEntryDate.
  ///
  /// In en, this message translates to:
  /// **'Entry date'**
  String get inventoryReceiptReviewFieldEntryDate;

  /// No description provided for @inventoryReceiptReviewFieldStoreName.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get inventoryReceiptReviewFieldStoreName;

  /// No description provided for @inventoryReceiptReviewFieldQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get inventoryReceiptReviewFieldQuantity;

  /// No description provided for @inventoryReceiptReviewFieldInitialQuantity.
  ///
  /// In en, this message translates to:
  /// **'Initial quantity'**
  String get inventoryReceiptReviewFieldInitialQuantity;

  /// No description provided for @inventoryReceiptReviewFieldUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get inventoryReceiptReviewFieldUnitPrice;

  /// No description provided for @inventoryReceiptReviewFieldWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get inventoryReceiptReviewFieldWeight;

  /// No description provided for @inventoryReceiptReviewFieldWeightUnitFallback.
  ///
  /// In en, this message translates to:
  /// **'Fallback unit'**
  String get inventoryReceiptReviewFieldWeightUnitFallback;

  /// No description provided for @inventoryReceiptReviewWeightUnitAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get inventoryReceiptReviewWeightUnitAuto;

  /// No description provided for @inventoryReceiptReviewWeightUnitGram.
  ///
  /// In en, this message translates to:
  /// **'Gram (g)'**
  String get inventoryReceiptReviewWeightUnitGram;

  /// No description provided for @inventoryReceiptReviewWeightUnitMilliliter.
  ///
  /// In en, this message translates to:
  /// **'Milliliter (ml)'**
  String get inventoryReceiptReviewWeightUnitMilliliter;

  /// No description provided for @inventoryReceiptReviewWeightUnitPiece.
  ///
  /// In en, this message translates to:
  /// **'Piece'**
  String get inventoryReceiptReviewWeightUnitPiece;

  /// No description provided for @inventoryReceiptReviewFieldBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get inventoryReceiptReviewFieldBrand;

  /// No description provided for @inventoryReceiptReviewFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get inventoryReceiptReviewFieldCategory;

  /// No description provided for @inventoryReceiptReviewFieldDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get inventoryReceiptReviewFieldDiscounts;

  /// No description provided for @inventoryReceiptReviewDiscountNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount label'**
  String get inventoryReceiptReviewDiscountNameLabel;

  /// No description provided for @inventoryReceiptReviewDiscountAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get inventoryReceiptReviewDiscountAmountLabel;

  /// No description provided for @inventoryReceiptReviewAddDiscountAction.
  ///
  /// In en, this message translates to:
  /// **'Add discount row'**
  String get inventoryReceiptReviewAddDiscountAction;

  /// No description provided for @inventoryReceiptReviewFieldReceiptId.
  ///
  /// In en, this message translates to:
  /// **'Receipt ID'**
  String get inventoryReceiptReviewFieldReceiptId;

  /// No description provided for @inventoryReceiptReviewFieldReceiptDate.
  ///
  /// In en, this message translates to:
  /// **'Receipt date'**
  String get inventoryReceiptReviewFieldReceiptDate;

  /// No description provided for @inventoryReceiptReviewFieldLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get inventoryReceiptReviewFieldLanguage;

  /// No description provided for @inventoryReceiptReviewFieldIsDeposit.
  ///
  /// In en, this message translates to:
  /// **'Is deposit item'**
  String get inventoryReceiptReviewFieldIsDeposit;

  /// No description provided for @inventoryReceiptReviewFieldIsDiscount.
  ///
  /// In en, this message translates to:
  /// **'Is discount item'**
  String get inventoryReceiptReviewFieldIsDiscount;

  /// No description provided for @inventoryReceiptReviewSelectDateAction.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get inventoryReceiptReviewSelectDateAction;

  /// No description provided for @inventoryReceiptReviewClearDateAction.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get inventoryReceiptReviewClearDateAction;

  /// No description provided for @inventoryReceiptReviewNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get inventoryReceiptReviewNoDate;

  /// No description provided for @inventoryReceiptReviewInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid numbers.'**
  String get inventoryReceiptReviewInvalidNumber;

  /// No description provided for @inventoryReceiptReviewInvalidWeightUnit.
  ///
  /// In en, this message translates to:
  /// **'Please add a unit (e.g. g or ml).'**
  String get inventoryReceiptReviewInvalidWeightUnit;

  /// No description provided for @inventoryReceiptReviewInvalidDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Use JSON or key=value pairs.'**
  String get inventoryReceiptReviewInvalidDiscounts;

  /// No description provided for @inventoryReceiptReviewCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get inventoryReceiptReviewCancelAction;

  /// No description provided for @inventoryReceiptReviewSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save to inventory'**
  String get inventoryReceiptReviewSaveAction;

  /// No description provided for @inventoryReceiptSaveSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Items added to inventory.'**
  String get inventoryReceiptSaveSucceeded;

  /// No description provided for @inventoryReceiptSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save receipt items. Please try again.'**
  String get inventoryReceiptSaveFailed;

  /// No description provided for @inventorySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get inventorySummaryTitle;

  /// No description provided for @inventorySummaryEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get inventorySummaryEntries;

  /// No description provided for @inventorySummaryQuantity.
  ///
  /// In en, this message translates to:
  /// **'Total quantity'**
  String get inventorySummaryQuantity;

  /// No description provided for @inventorySummaryEstimatedValue.
  ///
  /// In en, this message translates to:
  /// **'Estimated value'**
  String get inventorySummaryEstimatedValue;

  /// No description provided for @inventoryListSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get inventoryListSectionTitle;

  /// No description provided for @inventoryListModeByReceipt.
  ///
  /// In en, this message translates to:
  /// **'By receipt'**
  String get inventoryListModeByReceipt;

  /// No description provided for @inventoryListModeAllItems.
  ///
  /// In en, this message translates to:
  /// **'All items'**
  String get inventoryListModeAllItems;

  /// No description provided for @inventoryFilterConsumed.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get inventoryFilterConsumed;

  /// No description provided for @inventoryFilterNotConsumed.
  ///
  /// In en, this message translates to:
  /// **'Not consumed'**
  String get inventoryFilterNotConsumed;

  /// No description provided for @inventoryReceiptGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get inventoryReceiptGroupTitle;

  /// No description provided for @inventoryReceiptGroupNoReceipt.
  ///
  /// In en, this message translates to:
  /// **'No receipt'**
  String get inventoryReceiptGroupNoReceipt;

  /// No description provided for @inventoryReceiptGroupItems.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get inventoryReceiptGroupItems;

  /// No description provided for @inventoryItemNoPrice.
  ///
  /// In en, this message translates to:
  /// **'No price'**
  String get inventoryItemNoPrice;

  /// No description provided for @inventoryItemDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get inventoryItemDeleteAction;

  /// No description provided for @inventoryItemEatAction.
  ///
  /// In en, this message translates to:
  /// **'Eat'**
  String get inventoryItemEatAction;

  /// No description provided for @inventoryItemBuyAgainAction.
  ///
  /// In en, this message translates to:
  /// **'Buy again'**
  String get inventoryItemBuyAgainAction;

  /// No description provided for @inventoryItemBuyAgainSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Item added to shopping list.'**
  String get inventoryItemBuyAgainSucceeded;

  /// No description provided for @inventoryItemThrowAwayAction.
  ///
  /// In en, this message translates to:
  /// **'Throw away'**
  String get inventoryItemThrowAwayAction;

  /// No description provided for @inventoryItemActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed. Please try again.'**
  String get inventoryItemActionFailed;

  /// No description provided for @inventoryEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No items in your fridge yet. Scan a receipt to get started.'**
  String get inventoryEmptyState;

  /// No description provided for @inventoryFilteredEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No items match the selected filters.'**
  String get inventoryFilteredEmptyState;

  /// No description provided for @inventoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load inventory items.'**
  String get inventoryLoadFailed;

  /// No description provided for @inventoryRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get inventoryRetryAction;

  /// No description provided for @homeShoppingActionContextPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Shopping action coming soon.'**
  String get homeShoppingActionContextPlaceholder;

  /// No description provided for @shoppingListStatsEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get shoppingListStatsEntries;

  /// No description provided for @shoppingListStatsQuantity.
  ///
  /// In en, this message translates to:
  /// **'Total quantity'**
  String get shoppingListStatsQuantity;

  /// No description provided for @shoppingListStatsEstimatedTotal.
  ///
  /// In en, this message translates to:
  /// **'Estimated total'**
  String get shoppingListStatsEstimatedTotal;

  /// No description provided for @shoppingListNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get shoppingListNameFieldLabel;

  /// No description provided for @shoppingListBrandFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand (optional)'**
  String get shoppingListBrandFieldLabel;

  /// No description provided for @shoppingListAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get shoppingListAddAction;

  /// No description provided for @shoppingListEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Your shopping list is empty.'**
  String get shoppingListEmptyState;

  /// No description provided for @shoppingListInvalidNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter an item name.'**
  String get shoppingListInvalidNameError;

  /// No description provided for @shoppingListAddFailedError.
  ///
  /// In en, this message translates to:
  /// **'Could not add item. Please try again.'**
  String get shoppingListAddFailedError;

  /// No description provided for @shoppingListLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load shopping list items.'**
  String get shoppingListLoadFailed;

  /// No description provided for @shoppingListRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get shoppingListRetryAction;

  /// No description provided for @shoppingListQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get shoppingListQuantityLabel;

  /// No description provided for @shoppingListIncreaseQuantityAction.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get shoppingListIncreaseQuantityAction;

  /// No description provided for @shoppingListDecreaseQuantityAction.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get shoppingListDecreaseQuantityAction;

  /// No description provided for @shoppingListClearCrossedOffAction.
  ///
  /// In en, this message translates to:
  /// **'Clear crossed-off ({count})'**
  String shoppingListClearCrossedOffAction(int count);

  /// No description provided for @shoppingListClearCrossedOffDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear crossed-off items?'**
  String get shoppingListClearCrossedOffDialogTitle;

  /// No description provided for @shoppingListClearCrossedOffDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'All crossed-off items will be removed from the shopping list.'**
  String get shoppingListClearCrossedOffDialogMessage;

  /// No description provided for @shoppingListClearCrossedOffConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get shoppingListClearCrossedOffConfirmAction;

  /// No description provided for @homeCaloriesActionContextPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Calories action coming soon.'**
  String get homeCaloriesActionContextPlaceholder;

  /// No description provided for @caloriesAddOptionManual.
  ///
  /// In en, this message translates to:
  /// **'Manual entry'**
  String get caloriesAddOptionManual;

  /// No description provided for @caloriesAddOptionBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get caloriesAddOptionBarcode;

  /// No description provided for @caloriesFabTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add calorie entry'**
  String get caloriesFabTooltip;

  /// No description provided for @caloriesBarcodeScannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get caloriesBarcodeScannerTitle;

  /// No description provided for @caloriesBarcodeResolving.
  ///
  /// In en, this message translates to:
  /// **'Looking up product...'**
  String get caloriesBarcodeResolving;

  /// No description provided for @caloriesBarcodeLookupFailed.
  ///
  /// In en, this message translates to:
  /// **'Barcode lookup failed. Please try again.'**
  String get caloriesBarcodeLookupFailed;

  /// No description provided for @caloriesBarcodeCandidateTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose product'**
  String get caloriesBarcodeCandidateTitle;

  /// No description provided for @caloriesBarcodeCandidateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Multiple products were found for this barcode.'**
  String get caloriesBarcodeCandidateSubtitle;

  /// No description provided for @caloriesBarcodeUnknownBrand.
  ///
  /// In en, this message translates to:
  /// **'Unknown brand'**
  String get caloriesBarcodeUnknownBrand;

  /// No description provided for @caloriesBarcodeNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get caloriesBarcodeNotFoundTitle;

  /// No description provided for @caloriesBarcodeNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No product was found for this barcode.'**
  String get caloriesBarcodeNotFoundMessage;

  /// No description provided for @caloriesBarcodeNotFoundManualAction.
  ///
  /// In en, this message translates to:
  /// **'Manual entry'**
  String get caloriesBarcodeNotFoundManualAction;

  /// No description provided for @caloriesBarcodeNotFoundOcrAction.
  ///
  /// In en, this message translates to:
  /// **'Scan nutrition label'**
  String get caloriesBarcodeNotFoundOcrAction;

  /// No description provided for @caloriesOcrFailed.
  ///
  /// In en, this message translates to:
  /// **'Nutrition label scan failed. Please try again.'**
  String get caloriesOcrFailed;

  /// No description provided for @caloriesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load calorie entries.'**
  String get caloriesLoadFailed;

  /// No description provided for @caloriesRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get caloriesRetryAction;

  /// No description provided for @caloriesAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to manage calories.'**
  String get caloriesAuthRequired;

  /// No description provided for @caloriesTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get caloriesTodayTitle;

  /// No description provided for @caloriesTodayAction.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get caloriesTodayAction;

  /// No description provided for @caloriesPreviousDayAction.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get caloriesPreviousDayAction;

  /// No description provided for @caloriesNextDayAction.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get caloriesNextDayAction;

  /// No description provided for @caloriesSetGoalAction.
  ///
  /// In en, this message translates to:
  /// **'Set goal'**
  String get caloriesSetGoalAction;

  /// No description provided for @caloriesGoalDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Set daily goal'**
  String get caloriesGoalDialogTitle;

  /// No description provided for @caloriesGoalFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily kcal goal'**
  String get caloriesGoalFieldLabel;

  /// No description provided for @caloriesGoalSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save goal'**
  String get caloriesGoalSaveAction;

  /// No description provided for @caloriesGoalClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear goal'**
  String get caloriesGoalClearAction;

  /// No description provided for @caloriesGoalInvalidValue.
  ///
  /// In en, this message translates to:
  /// **'Please enter a number greater than zero.'**
  String get caloriesGoalInvalidValue;

  /// No description provided for @caloriesGoalSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save calorie goal.'**
  String get caloriesGoalSaveFailed;

  /// No description provided for @caloriesConsumedLabel.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get caloriesConsumedLabel;

  /// No description provided for @caloriesGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get caloriesGoalLabel;

  /// No description provided for @caloriesRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get caloriesRemainingLabel;

  /// No description provided for @caloriesProteinLabel.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get caloriesProteinLabel;

  /// No description provided for @caloriesCarbsLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get caloriesCarbsLabel;

  /// No description provided for @caloriesFatLabel.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get caloriesFatLabel;

  /// No description provided for @caloriesSectionEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No entries yet.'**
  String get caloriesSectionEmptyState;

  /// No description provided for @caloriesDeleteEntryAction.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get caloriesDeleteEntryAction;

  /// No description provided for @caloriesDeleteEntryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete entry?'**
  String get caloriesDeleteEntryDialogTitle;

  /// No description provided for @caloriesDeleteEntryDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" from this day?'**
  String caloriesDeleteEntryDialogMessage(String name);

  /// No description provided for @caloriesDeleteEntryConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get caloriesDeleteEntryConfirmAction;

  /// No description provided for @caloriesDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete entry.'**
  String get caloriesDeleteFailed;

  /// No description provided for @caloriesAddEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add calorie entry'**
  String get caloriesAddEntryTitle;

  /// No description provided for @caloriesEditEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit calorie entry'**
  String get caloriesEditEntryTitle;

  /// No description provided for @caloriesEntryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Entry not found.'**
  String get caloriesEntryNotFound;

  /// No description provided for @caloriesEntryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get caloriesEntryNameLabel;

  /// No description provided for @caloriesEntryBrandLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand (optional)'**
  String get caloriesEntryBrandLabel;

  /// No description provided for @caloriesEntryMealLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get caloriesEntryMealLabel;

  /// No description provided for @caloriesEntryAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Consumed amount'**
  String get caloriesEntryAmountLabel;

  /// No description provided for @caloriesEntryUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get caloriesEntryUnitLabel;

  /// No description provided for @caloriesPer100SectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition per 100'**
  String get caloriesPer100SectionTitle;

  /// No description provided for @caloriesPer100KcalLabel.
  ///
  /// In en, this message translates to:
  /// **'Energy (kcal)'**
  String get caloriesPer100KcalLabel;

  /// No description provided for @caloriesPer100ProteinLabel.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get caloriesPer100ProteinLabel;

  /// No description provided for @caloriesPer100CarbsLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get caloriesPer100CarbsLabel;

  /// No description provided for @caloriesPer100FatLabel.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get caloriesPer100FatLabel;

  /// No description provided for @caloriesEntryDateTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get caloriesEntryDateTimeLabel;

  /// No description provided for @caloriesSaveEntryAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get caloriesSaveEntryAction;

  /// No description provided for @caloriesSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save entry.'**
  String get caloriesSaveFailed;

  /// No description provided for @caloriesRequiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get caloriesRequiredField;

  /// No description provided for @caloriesInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid numbers.'**
  String get caloriesInvalidNumber;

  /// No description provided for @caloriesPositiveNumberValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a number greater than zero.'**
  String get caloriesPositiveNumberValidation;

  /// No description provided for @caloriesNonNegativeNumberValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a number equal to or greater than zero.'**
  String get caloriesNonNegativeNumberValidation;

  /// No description provided for @caloriesMealBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get caloriesMealBreakfast;

  /// No description provided for @caloriesMealLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get caloriesMealLunch;

  /// No description provided for @caloriesMealDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get caloriesMealDinner;

  /// No description provided for @caloriesMealSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get caloriesMealSnack;

  /// No description provided for @caloriesUnitGram.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get caloriesUnitGram;

  /// No description provided for @caloriesUnitMilliliter.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get caloriesUnitMilliliter;

  /// No description provided for @homeSettingsActionContextPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Settings action coming soon.'**
  String get homeSettingsActionContextPlaceholder;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose app language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeTitle;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get settingsColorTitle;

  /// No description provided for @settingsColorLime.
  ///
  /// In en, this message translates to:
  /// **'Lime'**
  String get settingsColorLime;

  /// No description provided for @settingsColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get settingsColorBlue;

  /// No description provided for @settingsColorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get settingsColorTeal;

  /// No description provided for @settingsColorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get settingsColorPink;

  /// No description provided for @settingsColorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get settingsColorOrange;

  /// No description provided for @settingsAiProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'AI processing'**
  String get settingsAiProcessingTitle;

  /// No description provided for @settingsAiProcessingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control OCR and analysis intensity'**
  String get settingsAiProcessingSubtitle;

  /// No description provided for @settingsAiProcessingInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Processing level info'**
  String get settingsAiProcessingInfoLabel;

  /// No description provided for @settingsAiProcessingInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Processing level'**
  String get settingsAiProcessingInfoTitle;

  /// No description provided for @settingsAiProcessingInfoMessage.
  ///
  /// In en, this message translates to:
  /// **'Speed and result quality depend on the selected level.'**
  String get settingsAiProcessingInfoMessage;

  /// No description provided for @settingsAiProcessingMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get settingsAiProcessingMinimal;

  /// No description provided for @settingsAiProcessingLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get settingsAiProcessingLow;

  /// No description provided for @settingsAiProcessingBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get settingsAiProcessingBalanced;

  /// No description provided for @settingsAiProcessingHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get settingsAiProcessingHigh;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage reminders and alerts'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountTitle;

  /// No description provided for @settingsAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage profile and sign-in'**
  String get settingsAccountSubtitle;

  /// No description provided for @accountPageNoSession.
  ///
  /// In en, this message translates to:
  /// **'No active account session.'**
  String get accountPageNoSession;

  /// No description provided for @accountPageGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Guest account'**
  String get accountPageGuestTitle;

  /// No description provided for @accountPageGuestDescription.
  ///
  /// In en, this message translates to:
  /// **'Link your guest account with Google to keep access across devices.'**
  String get accountPageGuestDescription;

  /// No description provided for @accountPageLinkGoogle.
  ///
  /// In en, this message translates to:
  /// **'Link with Google'**
  String get accountPageLinkGoogle;

  /// No description provided for @accountPageLinkEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Link with email & password'**
  String get accountPageLinkEmailPassword;

  /// No description provided for @accountPageLinkEmailPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Link guest account'**
  String get accountPageLinkEmailPasswordTitle;

  /// No description provided for @accountPageLinkEmailPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Create email sign-in credentials for this guest account.'**
  String get accountPageLinkEmailPasswordDescription;

  /// No description provided for @accountPageLinkEmailPasswordConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Link account'**
  String get accountPageLinkEmailPasswordConfirmAction;

  /// No description provided for @accountPageLinkSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account linked successfully.'**
  String get accountPageLinkSuccess;

  /// No description provided for @accountPageLinkNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Account linking was not completed. Please try again.'**
  String get accountPageLinkNotCompleted;

  /// No description provided for @accountPageLinkConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Account already in use'**
  String get accountPageLinkConflictTitle;

  /// No description provided for @accountPageLinkConflictDescription.
  ///
  /// In en, this message translates to:
  /// **'This sign-in credential is already linked to another profile. Choose how to continue.'**
  String get accountPageLinkConflictDescription;

  /// No description provided for @accountPageLinkConflictOverwriteAction.
  ///
  /// In en, this message translates to:
  /// **'Overwrite with this guest'**
  String get accountPageLinkConflictOverwriteAction;

  /// No description provided for @accountPageLinkConflictOverwriteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep this guest account and replace the old linked account.'**
  String get accountPageLinkConflictOverwriteSubtitle;

  /// No description provided for @accountPageLinkConflictDeleteGuestAction.
  ///
  /// In en, this message translates to:
  /// **'Delete guest and sign in'**
  String get accountPageLinkConflictDeleteGuestAction;

  /// No description provided for @accountPageLinkConflictDeleteGuestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this guest account and continue with the existing account.'**
  String get accountPageLinkConflictDeleteGuestSubtitle;

  /// No description provided for @accountPageLinkConflictOverwriteDone.
  ///
  /// In en, this message translates to:
  /// **'Credential moved to this guest account.'**
  String get accountPageLinkConflictOverwriteDone;

  /// No description provided for @accountPageLinkConflictDeleteGuestDone.
  ///
  /// In en, this message translates to:
  /// **'Guest account deleted. Signed in with existing account.'**
  String get accountPageLinkConflictDeleteGuestDone;

  /// No description provided for @accountPageGuestSessionRequired.
  ///
  /// In en, this message translates to:
  /// **'This action is only available for guest accounts.'**
  String get accountPageGuestSessionRequired;

  /// No description provided for @accountPageSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountPageSignOut;

  /// No description provided for @accountPageDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountPageDeleteAction;

  /// No description provided for @accountPageDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get accountPageDeleteDialogTitle;

  /// No description provided for @accountPageDeleteDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and cannot be undone.'**
  String get accountPageDeleteDialogMessage;

  /// No description provided for @accountPageDeleteDialogConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get accountPageDeleteDialogConfirmAction;

  /// No description provided for @accountPageDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account deleted.'**
  String get accountPageDeleteSuccess;

  /// No description provided for @accountPageDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get accountPageDisplayName;

  /// No description provided for @accountPageEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountPageEmail;

  /// No description provided for @accountPageUserId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get accountPageUserId;

  /// No description provided for @accountPageNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get accountPageNotSet;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App version and information'**
  String get settingsAboutSubtitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Yet Another Meal Tracker'**
  String get appSubtitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @loginAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Login as guest'**
  String get loginAsGuest;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get loginWithGoogle;

  /// No description provided for @registerWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Register with Google'**
  String get registerWithGoogle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @authSwitchToRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get authSwitchToRegister;

  /// No description provided for @authSwitchToLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get authSwitchToLogin;

  /// No description provided for @authGuestNameSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your guest name'**
  String get authGuestNameSetupTitle;

  /// No description provided for @authGuestNameSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a display name so your guest session is easier to recognize.'**
  String get authGuestNameSetupSubtitle;

  /// No description provided for @authGuestNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get authGuestNameFieldLabel;

  /// No description provided for @authGuestNameSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authGuestNameSaveAction;

  /// No description provided for @authGuestNameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a display name.'**
  String get authGuestNameRequiredError;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @validationPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsDoNotMatch;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authFailed;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'The email address is not valid.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This user account has been disabled.'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found for this email.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is incorrect.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'The login credentials are invalid.'**
  String get authErrorInvalidCredential;

  /// No description provided for @authErrorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this email.'**
  String get authErrorEmailAlreadyInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is too weak.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not enabled.'**
  String get authErrorOperationNotAllowed;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNetworkRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get authErrorNetworkRequestFailed;

  /// No description provided for @authErrorRequiresRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Please log in again to continue.'**
  String get authErrorRequiresRecentLogin;

  /// No description provided for @authErrorAccountExistsWithDifferentCredential.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with a different sign-in method.'**
  String get authErrorAccountExistsWithDifferentCredential;

  /// No description provided for @authErrorCredentialAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This credential is already used by another account.'**
  String get authErrorCredentialAlreadyInUse;

  /// No description provided for @authErrorProviderAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'This sign-in provider is already linked to your account.'**
  String get authErrorProviderAlreadyLinked;

  /// No description provided for @authErrorGoogleSignInCanceled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get authErrorGoogleSignInCanceled;

  /// No description provided for @authErrorGoogleIdTokenMissing.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in did not return a valid token.'**
  String get authErrorGoogleIdTokenMissing;

  /// No description provided for @commonNotImplementedYet.
  ///
  /// In en, this message translates to:
  /// **'Not implemented yet'**
  String get commonNotImplementedYet;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
