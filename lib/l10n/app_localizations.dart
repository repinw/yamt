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

  /// No description provided for @homeStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get homeStatistics;

  /// No description provided for @homeCalories.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
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

  /// No description provided for @inventoryFabTooltip.
  ///
  /// In en, this message translates to:
  /// **'Receipt actions'**
  String get inventoryFabTooltip;

  /// No description provided for @inventoryPageTitle.
  ///
  /// In en, this message translates to:
  /// **'My inventory'**
  String get inventoryPageTitle;

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

  /// No description provided for @inventoryActionManualAdd.
  ///
  /// In en, this message translates to:
  /// **'Add food manually'**
  String get inventoryActionManualAdd;

  /// No description provided for @inventorySharedReceiptConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan shared receipt?'**
  String get inventorySharedReceiptConfirmTitle;

  /// No description provided for @inventorySharedReceiptConfirmSingleMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to scan this shared file as a receipt?'**
  String get inventorySharedReceiptConfirmSingleMessage;

  /// No description provided for @inventorySharedReceiptConfirmMultipleMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to scan {count} shared files as receipts?'**
  String inventorySharedReceiptConfirmMultipleMessage(int count);

  /// No description provided for @inventorySharedReceiptConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get inventorySharedReceiptConfirmAction;

  /// No description provided for @inventoryReceiptSelectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not select a receipt. Please try again.'**
  String get inventoryReceiptSelectionFailed;

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
  /// **'Review receipt'**
  String get inventoryReceiptReviewTitle;

  /// No description provided for @inventoryReceiptReviewPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get inventoryReceiptReviewPriceTitle;

  /// No description provided for @inventoryReceiptReviewPriceTotal.
  ///
  /// In en, this message translates to:
  /// **'According to detected receipt'**
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

  /// No description provided for @inventoryReceiptReviewFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get inventoryReceiptReviewFieldName;

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

  /// No description provided for @inventoryReceiptReviewFieldWeightUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get inventoryReceiptReviewFieldWeightUnit;

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

  /// No description provided for @inventoryUnitGram.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get inventoryUnitGram;

  /// No description provided for @inventoryUnitMilliliter.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get inventoryUnitMilliliter;

  /// No description provided for @inventoryUnitPiece.
  ///
  /// In en, this message translates to:
  /// **'pc'**
  String get inventoryUnitPiece;

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

  /// No description provided for @inventoryReceiptReviewDetectedItems.
  ///
  /// In en, this message translates to:
  /// **'Detected items'**
  String get inventoryReceiptReviewDetectedItems;

  /// No description provided for @inventoryReceiptReviewOriginalReceiptAction.
  ///
  /// In en, this message translates to:
  /// **'View original receipt'**
  String get inventoryReceiptReviewOriginalReceiptAction;

  /// No description provided for @inventoryReceiptReviewOriginalReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Original receipt preview'**
  String get inventoryReceiptReviewOriginalReceiptTitle;

  /// No description provided for @inventoryReceiptReviewOriginalReceiptUnavailable.
  ///
  /// In en, this message translates to:
  /// **'(The receipt photo would appear here)'**
  String get inventoryReceiptReviewOriginalReceiptUnavailable;

  /// No description provided for @inventoryReceiptReviewReadAsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Read as'**
  String get inventoryReceiptReviewReadAsPrefix;

  /// No description provided for @inventoryReceiptReviewCandidatesAction.
  ///
  /// In en, this message translates to:
  /// **'Candidates'**
  String get inventoryReceiptReviewCandidatesAction;

  /// No description provided for @inventoryReceiptReviewProductSelectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Select product'**
  String get inventoryReceiptReviewProductSelectionLabel;

  /// No description provided for @inventoryReceiptReviewManualSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search product'**
  String get inventoryReceiptReviewManualSearchLabel;

  /// No description provided for @inventoryReceiptReviewRecentProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get inventoryReceiptReviewRecentProductsTitle;

  /// No description provided for @inventoryReceiptReviewManualDataAction.
  ///
  /// In en, this message translates to:
  /// **'Search product or scan barcode'**
  String get inventoryReceiptReviewManualDataAction;

  /// No description provided for @inventoryReceiptReviewManualDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Search product or scan barcode'**
  String get inventoryReceiptReviewManualDataTitle;

  /// No description provided for @inventoryReceiptReviewManualDataHint.
  ///
  /// In en, this message translates to:
  /// **'Search product or scan barcode. Add nutrition later.'**
  String get inventoryReceiptReviewManualDataHint;

  /// No description provided for @inventoryReceiptReviewManualDataSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get inventoryReceiptReviewManualDataSaveAction;

  /// No description provided for @inventoryReceiptReviewManualDataBarcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get inventoryReceiptReviewManualDataBarcodeLabel;

  /// No description provided for @inventoryReceiptReviewManualDataRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a product, scan a barcode, or add nutrition.'**
  String get inventoryReceiptReviewManualDataRequired;

  /// No description provided for @inventoryReceiptReviewRequestEnrichmentAction.
  ///
  /// In en, this message translates to:
  /// **'Let AI enrich it later'**
  String get inventoryReceiptReviewRequestEnrichmentAction;

  /// No description provided for @inventoryReceiptReviewRequestEnrichmentHint.
  ///
  /// In en, this message translates to:
  /// **'Saves the item now and marks it for later AI enrichment.'**
  String get inventoryReceiptReviewRequestEnrichmentHint;

  /// No description provided for @inventoryReceiptReviewSwitchAction.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get inventoryReceiptReviewSwitchAction;

  /// No description provided for @inventoryReceiptReviewCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get inventoryReceiptReviewCancelAction;

  /// No description provided for @inventoryReceiptReviewSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
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

  /// No description provided for @inventoryListModeByReceipt.
  ///
  /// In en, this message translates to:
  /// **'By receipt'**
  String get inventoryListModeByReceipt;

  /// No description provided for @inventoryListModeAllItems.
  ///
  /// In en, this message translates to:
  /// **'All foods'**
  String get inventoryListModeAllItems;

  /// No description provided for @inventoryRecentSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get inventoryRecentSectionTitle;

  /// No description provided for @inventoryFilterAction.
  ///
  /// In en, this message translates to:
  /// **'Filter items'**
  String get inventoryFilterAction;

  /// No description provided for @inventoryFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter items'**
  String get inventoryFiltersTitle;

  /// No description provided for @inventoryNutritionCaloriesShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Kcal'**
  String get inventoryNutritionCaloriesShortLabel;

  /// No description provided for @inventoryNutritionCarbsShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get inventoryNutritionCarbsShortLabel;

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

  /// No description provided for @inventoryItemDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get inventoryItemDeleteAction;

  /// No description provided for @inventoryItemDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Item deleted.'**
  String get inventoryItemDeletedMessage;

  /// No description provided for @inventoryItemEatAction.
  ///
  /// In en, this message translates to:
  /// **'Eat'**
  String get inventoryItemEatAction;

  /// No description provided for @inventoryItemEatSheetEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get inventoryItemEatSheetEyebrow;

  /// No description provided for @inventoryItemEatSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Eat: {name}'**
  String inventoryItemEatSheetTitle(String name);

  /// No description provided for @inventoryItemEatSheetAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get inventoryItemEatSheetAmountLabel;

  /// No description provided for @inventoryItemEatSheetQuickSelectLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick select'**
  String get inventoryItemEatSheetQuickSelectLabel;

  /// No description provided for @inventoryItemEatSheetAllAction.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get inventoryItemEatSheetAllAction;

  /// No description provided for @inventoryItemEatSheetInedibleAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtract inedible part'**
  String get inventoryItemEatSheetInedibleAmountLabel;

  /// No description provided for @inventoryItemEatSheetInedibleAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Optional, e.g. bones or shells. Calories are calculated only for the edible remainder.'**
  String get inventoryItemEatSheetInedibleAmountHint;

  /// No description provided for @inventoryItemEatSheetInedibleAmountFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Inedible amount'**
  String get inventoryItemEatSheetInedibleAmountFieldLabel;

  /// No description provided for @inventoryItemEatSheetInedibleAmountError.
  ///
  /// In en, this message translates to:
  /// **'The deducted amount must be smaller than the eaten amount.'**
  String get inventoryItemEatSheetInedibleAmountError;

  /// No description provided for @inventoryItemEatSheetWhenLabel.
  ///
  /// In en, this message translates to:
  /// **'When?'**
  String get inventoryItemEatSheetWhenLabel;

  /// No description provided for @inventoryItemEatSheetNowValue.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get inventoryItemEatSheetNowValue;

  /// No description provided for @inventoryItemEatSheetNutritionLabel.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get inventoryItemEatSheetNutritionLabel;

  /// No description provided for @inventoryItemEatSheetConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get inventoryItemEatSheetConfirmAction;

  /// No description provided for @inventoryItemEatSheetClearAmountAction.
  ///
  /// In en, this message translates to:
  /// **'Clear amount'**
  String get inventoryItemEatSheetClearAmountAction;

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

  /// No description provided for @inventoryItemSwapCandidateAction.
  ///
  /// In en, this message translates to:
  /// **'Swap candidate'**
  String get inventoryItemSwapCandidateAction;

  /// No description provided for @inventoryItemSwapCandidateRequiresFullItem.
  ///
  /// In en, this message translates to:
  /// **'You can swap the candidate only while the item is still fully available.'**
  String get inventoryItemSwapCandidateRequiresFullItem;

  /// No description provided for @inventoryItemActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed. Please try again.'**
  String get inventoryItemActionFailed;

  /// No description provided for @inventoryBarcodeStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Barcode lookup pending'**
  String get inventoryBarcodeStatusPending;

  /// No description provided for @inventoryBarcodeStatusUncertain.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get inventoryBarcodeStatusUncertain;

  /// No description provided for @inventoryBarcodeStatusMissing.
  ///
  /// In en, this message translates to:
  /// **'Barcode missing'**
  String get inventoryBarcodeStatusMissing;

  /// No description provided for @inventoryBarcodeMissingPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Barcode missing'**
  String get inventoryBarcodeMissingPromptTitle;

  /// No description provided for @inventoryBarcodeMissingPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Scan now to log calories immediately, or continue and let AI backfill it.'**
  String get inventoryBarcodeMissingPromptMessage;

  /// No description provided for @inventoryBarcodeMissingPromptScanNow.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode now'**
  String get inventoryBarcodeMissingPromptScanNow;

  /// No description provided for @inventoryBarcodeMissingPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get inventoryBarcodeMissingPromptLater;

  /// No description provided for @inventoryBarcodeLookupQueued.
  ///
  /// In en, this message translates to:
  /// **'Barcode search finished. The result is saved on the inventory item.'**
  String get inventoryBarcodeLookupQueued;

  /// No description provided for @inventoryBarcodeScanUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Barcode scanning is currently supported on Android and iOS.'**
  String get inventoryBarcodeScanUnsupported;

  /// No description provided for @inventoryManualAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add food manually'**
  String get inventoryManualAddTitle;

  /// No description provided for @inventoryManualAddHint.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode. Then you can review the product, save it, or add nutrition values.'**
  String get inventoryManualAddHint;

  /// No description provided for @inventoryManualAddResolving.
  ///
  /// In en, this message translates to:
  /// **'Looking up barcode...'**
  String get inventoryManualAddResolving;

  /// No description provided for @inventoryManualAddCandidateTitle.
  ///
  /// In en, this message translates to:
  /// **'Select product'**
  String get inventoryManualAddCandidateTitle;

  /// No description provided for @inventoryManualAddCandidateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Multiple matching products were found for this barcode.'**
  String get inventoryManualAddCandidateSubtitle;

  /// No description provided for @inventoryManualAddUnknownBrand.
  ///
  /// In en, this message translates to:
  /// **'Unknown brand'**
  String get inventoryManualAddUnknownBrand;

  /// No description provided for @inventoryManualAddNotFound.
  ///
  /// In en, this message translates to:
  /// **'No matching product was found for this barcode.'**
  String get inventoryManualAddNotFound;

  /// No description provided for @inventoryManualAddLookupFailed.
  ///
  /// In en, this message translates to:
  /// **'Barcode lookup failed. Please try again.'**
  String get inventoryManualAddLookupFailed;

  /// No description provided for @inventoryManualAddSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The product could not be added to the inventory.'**
  String get inventoryManualAddSaveFailed;

  /// No description provided for @inventoryManualAddSaved.
  ///
  /// In en, this message translates to:
  /// **'Product added to inventory.'**
  String get inventoryManualAddSaved;

  /// No description provided for @inventoryManualAddEatNowOption.
  ///
  /// In en, this message translates to:
  /// **'Eat now'**
  String get inventoryManualAddEatNowOption;

  /// No description provided for @inventoryManualAddEatNowRequiresNutrition.
  ///
  /// In en, this message translates to:
  /// **'Only available when nutrition values are present.'**
  String get inventoryManualAddEatNowRequiresNutrition;

  /// No description provided for @inventoryManualAddStoreName.
  ///
  /// In en, this message translates to:
  /// **'Added manually'**
  String get inventoryManualAddStoreName;

  /// No description provided for @inventoryBarcodePortionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter consumed amount'**
  String get inventoryBarcodePortionDialogTitle;

  /// No description provided for @inventoryBarcodePortionDialogConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get inventoryBarcodePortionDialogConfirmAction;

  /// No description provided for @inventoryEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No items in your fridge yet. Scan a receipt or add foods manually.'**
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

  /// No description provided for @preparedMealSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Prepared meals'**
  String get preparedMealSectionTitle;

  /// No description provided for @preparedMealCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create prepared meal'**
  String get preparedMealCreateTitle;

  /// No description provided for @preparedMealEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit prepared meal'**
  String get preparedMealEditTitle;

  /// No description provided for @preparedMealNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal name'**
  String get preparedMealNameLabel;

  /// No description provided for @preparedMealClearNameAction.
  ///
  /// In en, this message translates to:
  /// **'Clear name'**
  String get preparedMealClearNameAction;

  /// No description provided for @preparedMealInvalidName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a meal name.'**
  String get preparedMealInvalidName;

  /// No description provided for @preparedMealPortionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Portions'**
  String get preparedMealPortionsLabel;

  /// No description provided for @preparedMealInvalidPortions.
  ///
  /// In en, this message translates to:
  /// **'Please enter at least one portion.'**
  String get preparedMealInvalidPortions;

  /// No description provided for @preparedMealFixFormErrorsMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted fields.'**
  String get preparedMealFixFormErrorsMessage;

  /// No description provided for @preparedMealInvalidPortionsRange.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid portion count within the available range.'**
  String get preparedMealInvalidPortionsRange;

  /// No description provided for @preparedMealImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover image'**
  String get preparedMealImageLabel;

  /// No description provided for @preparedMealAddImageAction.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get preparedMealAddImageAction;

  /// No description provided for @preparedMealChangeImageAction.
  ///
  /// In en, this message translates to:
  /// **'Change image'**
  String get preparedMealChangeImageAction;

  /// No description provided for @preparedMealRemoveImageAction.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get preparedMealRemoveImageAction;

  /// No description provided for @preparedMealImageHint.
  ///
  /// In en, this message translates to:
  /// **'Add a photo for this meal or use the default cover.'**
  String get preparedMealImageHint;

  /// No description provided for @preparedMealImageCameraAction.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get preparedMealImageCameraAction;

  /// No description provided for @preparedMealImagePickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not pick the meal image.'**
  String get preparedMealImagePickFailed;

  /// No description provided for @preparedMealImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The selected image is too large.'**
  String get preparedMealImageTooLarge;

  /// No description provided for @preparedMealIngredientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get preparedMealIngredientsTitle;

  /// No description provided for @preparedMealCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create meal'**
  String get preparedMealCreateAction;

  /// No description provided for @preparedMealBindAction.
  ///
  /// In en, this message translates to:
  /// **'Bind meal'**
  String get preparedMealBindAction;

  /// No description provided for @preparedMealUsedAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Used amount'**
  String get preparedMealUsedAmountLabel;

  /// No description provided for @preparedMealAvailableAmount.
  ///
  /// In en, this message translates to:
  /// **'Available: {amount} {unit}'**
  String preparedMealAvailableAmount(int amount, String unit);

  /// No description provided for @preparedMealInvalidIngredientAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid ingredient amount.'**
  String get preparedMealInvalidIngredientAmount;

  /// No description provided for @preparedMealNutritionPerPieceHint.
  ///
  /// In en, this message translates to:
  /// **'Add nutrition values per used piece.'**
  String get preparedMealNutritionPerPieceHint;

  /// No description provided for @preparedMealNutritionPerHundredHint.
  ///
  /// In en, this message translates to:
  /// **'Add nutrition values per 100 g/ml.'**
  String get preparedMealNutritionPerHundredHint;

  /// No description provided for @preparedMealNutritionModePerHundred.
  ///
  /// In en, this message translates to:
  /// **'100 g/ml'**
  String get preparedMealNutritionModePerHundred;

  /// No description provided for @preparedMealNutritionModePerPortion.
  ///
  /// In en, this message translates to:
  /// **'Portion'**
  String get preparedMealNutritionModePerPortion;

  /// No description provided for @preparedMealNutritionModeTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get preparedMealNutritionModeTotal;

  /// No description provided for @preparedMealPricePerHundred.
  ///
  /// In en, this message translates to:
  /// **'Price per 100 g/ml'**
  String get preparedMealPricePerHundred;

  /// No description provided for @preparedMealPricePerPortion.
  ///
  /// In en, this message translates to:
  /// **'Price per portion'**
  String get preparedMealPricePerPortion;

  /// No description provided for @preparedMealPriceTotal.
  ///
  /// In en, this message translates to:
  /// **'Total price'**
  String get preparedMealPriceTotal;

  /// No description provided for @preparedMealSelectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String preparedMealSelectionCount(int count);

  /// No description provided for @preparedMealCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Prepared meal created.'**
  String get preparedMealCreatedMessage;

  /// No description provided for @preparedMealUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Prepared meal updated.'**
  String get preparedMealUpdatedMessage;

  /// No description provided for @preparedMealInsufficientAmountMessage.
  ///
  /// In en, this message translates to:
  /// **'At least one selected ingredient is no longer available in a sufficient amount.'**
  String get preparedMealInsufficientAmountMessage;

  /// No description provided for @preparedMealMissingNutritionMessage.
  ///
  /// In en, this message translates to:
  /// **'At least one selected ingredient is missing complete nutrition values.'**
  String get preparedMealMissingNutritionMessage;

  /// No description provided for @preparedMealItemUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'At least one selected ingredient is no longer available in inventory.'**
  String get preparedMealItemUnavailableMessage;

  /// No description provided for @preparedMealActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Prepared meal action failed. Please try again.'**
  String get preparedMealActionFailed;

  /// No description provided for @preparedMealIngredientsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ingredients'**
  String preparedMealIngredientsCount(int count);

  /// No description provided for @preparedMealIncompleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get preparedMealIncompleteLabel;

  /// No description provided for @preparedMealIncompleteHint.
  ///
  /// In en, this message translates to:
  /// **'This meal is not complete yet and can only be eaten once all missing ingredients have been added.'**
  String get preparedMealIncompleteHint;

  /// No description provided for @preparedMealPendingIngredientUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Not linked yet'**
  String get preparedMealPendingIngredientUnassigned;

  /// No description provided for @preparedMealPendingIngredientAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get preparedMealPendingIngredientAddAction;

  /// No description provided for @preparedMealPendingIngredientIgnoreAction.
  ///
  /// In en, this message translates to:
  /// **'Ignore ingredient'**
  String get preparedMealPendingIngredientIgnoreAction;

  /// No description provided for @preparedMealPendingIngredientSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient from inventory'**
  String get preparedMealPendingIngredientSelectionTitle;

  /// No description provided for @preparedMealPendingIngredientSelectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No inventory items available.'**
  String get preparedMealPendingIngredientSelectionEmpty;

  /// No description provided for @preparedMealPendingIngredientFillFailed.
  ///
  /// In en, this message translates to:
  /// **'Ingredient could not be added to the meal.'**
  String get preparedMealPendingIngredientFillFailed;

  /// No description provided for @preparedMealPendingIngredientIgnoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Ingredient could not be ignored.'**
  String get preparedMealPendingIngredientIgnoreFailed;

  /// No description provided for @preparedMealPortionsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining}/{total} portions'**
  String preparedMealPortionsRemaining(int remaining, int total);

  /// No description provided for @preparedMealUnbundleAction.
  ///
  /// In en, this message translates to:
  /// **'Return to inventory'**
  String get preparedMealUnbundleAction;

  /// No description provided for @preparedMealEatTitle.
  ///
  /// In en, this message translates to:
  /// **'Eat prepared meal'**
  String get preparedMealEatTitle;

  /// No description provided for @preparedMealDiaryDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Diary day'**
  String get preparedMealDiaryDayLabel;

  /// No description provided for @preparedMealThrowAwayTitle.
  ///
  /// In en, this message translates to:
  /// **'Throw away portions'**
  String get preparedMealThrowAwayTitle;

  /// No description provided for @preparedMealPortionsToUseLabel.
  ///
  /// In en, this message translates to:
  /// **'Portions to use'**
  String get preparedMealPortionsToUseLabel;

  /// No description provided for @preparedMealConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get preparedMealConfirmAction;

  /// No description provided for @inventoryDiscardReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Why are you throwing this away?'**
  String get inventoryDiscardReasonTitle;

  /// No description provided for @inventoryDiscardReasonExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get inventoryDiscardReasonExpired;

  /// No description provided for @inventoryDiscardReasonSpoiled.
  ///
  /// In en, this message translates to:
  /// **'Spoiled'**
  String get inventoryDiscardReasonSpoiled;

  /// No description provided for @inventoryDiscardReasonCookedTooMuch.
  ///
  /// In en, this message translates to:
  /// **'Cooked too much'**
  String get inventoryDiscardReasonCookedTooMuch;

  /// No description provided for @inventoryDiscardReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get inventoryDiscardReasonOther;

  /// No description provided for @preparedMealSaveTemplateAction.
  ///
  /// In en, this message translates to:
  /// **'Save as template'**
  String get preparedMealSaveTemplateAction;

  /// No description provided for @preparedMealTemplateSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Template saved.'**
  String get preparedMealTemplateSavedMessage;

  /// No description provided for @preparedMealTemplatesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get preparedMealTemplatesPageTitle;

  /// No description provided for @preparedMealTemplatesEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No templates saved yet.'**
  String get preparedMealTemplatesEmptyState;

  /// No description provided for @preparedMealTemplatesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load templates.'**
  String get preparedMealTemplatesLoadFailed;

  /// No description provided for @preparedMealTemplateDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete template'**
  String get preparedMealTemplateDeleteAction;

  /// No description provided for @preparedMealTemplateDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Template deleted.'**
  String get preparedMealTemplateDeletedMessage;

  /// No description provided for @preparedMealTemplateAddRecipeAction.
  ///
  /// In en, this message translates to:
  /// **'Add recipe template'**
  String get preparedMealTemplateAddRecipeAction;

  /// No description provided for @preparedMealTemplateCreateFromRecipeAction.
  ///
  /// In en, this message translates to:
  /// **'Create from recipe'**
  String get preparedMealTemplateCreateFromRecipeAction;

  /// No description provided for @preparedMealTemplateCreateFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Template could not be created.'**
  String get preparedMealTemplateCreateFailedMessage;

  /// No description provided for @preparedMealTemplateRecipeImportFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Recipe data could not be imported.'**
  String get preparedMealTemplateRecipeImportFailedMessage;

  /// No description provided for @preparedMealTemplateRecipeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Create template from recipe'**
  String get preparedMealTemplateRecipeSheetTitle;

  /// No description provided for @preparedMealTemplateRecipeEditSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit recipe template'**
  String get preparedMealTemplateRecipeEditSheetTitle;

  /// No description provided for @preparedMealTemplateRecipeSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste a recipe link, for example from Chefkoch.'**
  String get preparedMealTemplateRecipeSheetSubtitle;

  /// No description provided for @preparedMealTemplateRecipeUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipe link'**
  String get preparedMealTemplateRecipeUrlLabel;

  /// No description provided for @preparedMealTemplateRecipeUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://www.chefkoch.de/...'**
  String get preparedMealTemplateRecipeUrlHint;

  /// No description provided for @preparedMealTemplateRecipeUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid recipe link.'**
  String get preparedMealTemplateRecipeUrlInvalid;

  /// No description provided for @preparedMealTemplateNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get preparedMealTemplateNameLabel;

  /// No description provided for @preparedMealTemplateNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. If empty, the name is derived from the link.'**
  String get preparedMealTemplateNameHelper;

  /// No description provided for @preparedMealTemplatePortionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Portions'**
  String get preparedMealTemplatePortionsLabel;

  /// No description provided for @preparedMealTemplatePortionsHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. If empty, the servings from the recipe are used.'**
  String get preparedMealTemplatePortionsHelper;

  /// No description provided for @preparedMealTemplateRecipePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Recipe link'**
  String get preparedMealTemplateRecipePlaceholder;

  /// No description provided for @preparedMealTemplateNoIngredientsYet.
  ///
  /// In en, this message translates to:
  /// **'No ingredients linked yet.'**
  String get preparedMealTemplateNoIngredientsYet;

  /// No description provided for @preparedMealTemplateOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open template'**
  String get preparedMealTemplateOpenAction;

  /// No description provided for @preparedMealTemplateUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Template updated.'**
  String get preparedMealTemplateUpdatedMessage;

  /// No description provided for @preparedMealTemplateImportReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review recipe'**
  String get preparedMealTemplateImportReviewTitle;

  /// No description provided for @preparedMealTemplateImportReviewInstructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Short instructions'**
  String get preparedMealTemplateImportReviewInstructionsTitle;

  /// No description provided for @preparedMealTemplateImportReviewSavingAction.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get preparedMealTemplateImportReviewSavingAction;

  /// No description provided for @preparedMealTemplateRecipeSource.
  ///
  /// In en, this message translates to:
  /// **'Recipe: {host}'**
  String preparedMealTemplateRecipeSource(String host);

  /// No description provided for @preparedMealTemplatePortions.
  ///
  /// In en, this message translates to:
  /// **'{count} portions'**
  String preparedMealTemplatePortions(int count);

  /// No description provided for @preparedMealTemplateDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get preparedMealTemplateDetailTitle;

  /// No description provided for @preparedMealTemplateDetailMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Ingredient Matching: {name}'**
  String preparedMealTemplateDetailMatchTitle(String name);

  /// No description provided for @preparedMealTemplateDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Template not found.'**
  String get preparedMealTemplateDetailNotFound;

  /// No description provided for @preparedMealTemplateDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Template could not be loaded.'**
  String get preparedMealTemplateDetailLoadFailed;

  /// No description provided for @preparedMealTemplateDetailBasePortions.
  ///
  /// In en, this message translates to:
  /// **'Base: {count} portions'**
  String preparedMealTemplateDetailBasePortions(int count);

  /// No description provided for @preparedMealTemplateDetailScaleHint.
  ///
  /// In en, this message translates to:
  /// **'Ingredients are scaled to this number of portions.'**
  String get preparedMealTemplateDetailScaleHint;

  /// No description provided for @preparedMealTemplateDetailNoIngredients.
  ///
  /// In en, this message translates to:
  /// **'No ingredients available yet.'**
  String get preparedMealTemplateDetailNoIngredients;

  /// No description provided for @preparedMealTemplateDetailSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Update template'**
  String get preparedMealTemplateDetailSaveAction;

  /// No description provided for @preparedMealTemplateDetailSavingAction.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get preparedMealTemplateDetailSavingAction;

  /// No description provided for @preparedMealTemplateDetailIngredientsToShoppingListAction.
  ///
  /// In en, this message translates to:
  /// **'Ingredients to shopping list'**
  String get preparedMealTemplateDetailIngredientsToShoppingListAction;

  /// No description provided for @preparedMealTemplateDetailCreateMealHint.
  ///
  /// In en, this message translates to:
  /// **'This template needs at least one ingredient before you can create a meal.'**
  String get preparedMealTemplateDetailCreateMealHint;

  /// No description provided for @preparedMealTemplateDetailAssignAction.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get preparedMealTemplateDetailAssignAction;

  /// No description provided for @preparedMealTemplateDetailChangeAssignmentAction.
  ///
  /// In en, this message translates to:
  /// **'Change assignment'**
  String get preparedMealTemplateDetailChangeAssignmentAction;

  /// No description provided for @preparedMealTemplateDetailAssignedFromInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Covered from inventory'**
  String get preparedMealTemplateDetailAssignedFromInventoryTitle;

  /// No description provided for @preparedMealTemplateDetailMatchingInventoryItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Matching inventory items'**
  String get preparedMealTemplateDetailMatchingInventoryItemsTitle;

  /// No description provided for @preparedMealTemplateDetailMissingAssignedItems.
  ///
  /// In en, this message translates to:
  /// **'{count} assigned items are no longer in inventory.'**
  String preparedMealTemplateDetailMissingAssignedItems(int count);

  /// No description provided for @preparedMealTemplateDetailIgnoredAmount.
  ///
  /// In en, this message translates to:
  /// **'Ignored • {amount}'**
  String preparedMealTemplateDetailIgnoredAmount(String amount);

  /// No description provided for @preparedMealTemplateDetailAssignedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items assigned'**
  String preparedMealTemplateDetailAssignedCount(int count);

  /// No description provided for @preparedMealTemplateDetailSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose inventory items'**
  String get preparedMealTemplateDetailSelectionTitle;

  /// No description provided for @preparedMealTemplateDetailSelectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No inventory items available.'**
  String get preparedMealTemplateDetailSelectionEmpty;

  /// No description provided for @preparedMealTemplateDetailSelectionConversionLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount per {sourceUnit} ({unit})'**
  String preparedMealTemplateDetailSelectionConversionLabel(String sourceUnit, String unit);

  /// No description provided for @preparedMealTemplateDetailSelectionConversionHint.
  ///
  /// In en, this message translates to:
  /// **'How much {unit} does 1 {sourceUnit} of \"{ingredient}\" use?'**
  String preparedMealTemplateDetailSelectionConversionHint(String sourceUnit, String unit, String ingredient);

  /// No description provided for @preparedMealTemplateDetailSelectionConversionError.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount greater than 0.'**
  String get preparedMealTemplateDetailSelectionConversionError;

  /// No description provided for @preparedMealTemplateDetailConversionSummary.
  ///
  /// In en, this message translates to:
  /// **'1 {sourceUnit} = {amount} {unit}'**
  String preparedMealTemplateDetailConversionSummary(String sourceUnit, int amount, String unit);

  /// No description provided for @preparedMealTemplateDetailListAction.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get preparedMealTemplateDetailListAction;

  /// No description provided for @preparedMealTemplateDetailSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get preparedMealTemplateDetailSearchAction;

  /// No description provided for @preparedMealTemplateDetailSwapAction.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get preparedMealTemplateDetailSwapAction;

  /// No description provided for @preparedMealTemplateDetailRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get preparedMealTemplateDetailRestoreAction;

  /// No description provided for @preparedMealTemplateDetailAddToShoppingListAction.
  ///
  /// In en, this message translates to:
  /// **'Add to shopping list'**
  String get preparedMealTemplateDetailAddToShoppingListAction;

  /// No description provided for @preparedMealTemplateDetailIgnoreAction.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get preparedMealTemplateDetailIgnoreAction;

  /// No description provided for @preparedMealTemplateDetailUnignoreAction.
  ///
  /// In en, this message translates to:
  /// **'Do not ignore'**
  String get preparedMealTemplateDetailUnignoreAction;

  /// No description provided for @preparedMealTemplateDetailAddIngredientShoppingFailed.
  ///
  /// In en, this message translates to:
  /// **'Ingredient could not be added to the shopping list.'**
  String get preparedMealTemplateDetailAddIngredientShoppingFailed;

  /// No description provided for @preparedMealTemplateDetailAddIngredientsShoppingFailed.
  ///
  /// In en, this message translates to:
  /// **'Ingredients could not be added to the shopping list.'**
  String get preparedMealTemplateDetailAddIngredientsShoppingFailed;

  /// No description provided for @preparedMealTemplateDetailAddIngredientsShoppingSucceeded.
  ///
  /// In en, this message translates to:
  /// **'{count} ingredients were added to the shopping list.'**
  String preparedMealTemplateDetailAddIngredientsShoppingSucceeded(int count);

  /// No description provided for @preparedMealTemplateDetailIgnoreSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Ingredient status could not be saved.'**
  String get preparedMealTemplateDetailIgnoreSaveFailed;

  /// No description provided for @preparedMealTemplateDetailInvalidMealMessage.
  ///
  /// In en, this message translates to:
  /// **'The template needs at least one valid ingredient.'**
  String get preparedMealTemplateDetailInvalidMealMessage;

  /// No description provided for @preparedMealTemplateDetailSaveFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Template could not be updated.'**
  String get preparedMealTemplateDetailSaveFailedMessage;

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

  /// No description provided for @caloriesTodayAction.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get caloriesTodayAction;

  /// No description provided for @caloriesSetGoalAction.
  ///
  /// In en, this message translates to:
  /// **'Set goal'**
  String get caloriesSetGoalAction;

  /// No description provided for @caloriesCalculatorAction.
  ///
  /// In en, this message translates to:
  /// **'Calorie calculator'**
  String get caloriesCalculatorAction;

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

  /// No description provided for @caloriesGoalClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not clear calorie goal.'**
  String get caloriesGoalClearFailed;

  /// No description provided for @caloriesCalculatorSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Calorie calculator'**
  String get caloriesCalculatorSheetTitle;

  /// No description provided for @caloriesCalculatorOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your calorie goal'**
  String get caloriesCalculatorOnboardingTitle;

  /// No description provided for @caloriesCalculatorOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We use a few details to calculate a daily calorie target for you.'**
  String get caloriesCalculatorOnboardingSubtitle;

  /// No description provided for @caloriesCalculatorStepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String caloriesCalculatorStepProgress(int current, int total);

  /// No description provided for @caloriesCalculatorBackAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get caloriesCalculatorBackAction;

  /// No description provided for @caloriesCalculatorNextAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get caloriesCalculatorNextAction;

  /// No description provided for @caloriesCalculatorSexLabel.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get caloriesCalculatorSexLabel;

  /// No description provided for @caloriesCalculatorSexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get caloriesCalculatorSexMale;

  /// No description provided for @caloriesCalculatorSexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get caloriesCalculatorSexFemale;

  /// No description provided for @caloriesCalculatorWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get caloriesCalculatorWeightLabel;

  /// No description provided for @caloriesCalculatorWeightEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your weight.'**
  String get caloriesCalculatorWeightEmpty;

  /// No description provided for @caloriesCalculatorWeightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid weight.'**
  String get caloriesCalculatorWeightInvalid;

  /// No description provided for @caloriesCalculatorHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get caloriesCalculatorHeightLabel;

  /// No description provided for @caloriesCalculatorHeightEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your height.'**
  String get caloriesCalculatorHeightEmpty;

  /// No description provided for @caloriesCalculatorHeightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid height.'**
  String get caloriesCalculatorHeightInvalid;

  /// No description provided for @caloriesCalculatorAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age (years)'**
  String get caloriesCalculatorAgeLabel;

  /// No description provided for @caloriesCalculatorAgeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your age.'**
  String get caloriesCalculatorAgeEmpty;

  /// No description provided for @caloriesCalculatorAgeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid age.'**
  String get caloriesCalculatorAgeInvalid;

  /// No description provided for @caloriesCalculatorActivityLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity level (PAL)'**
  String get caloriesCalculatorActivityLevelLabel;

  /// No description provided for @caloriesCalculatorActivityLevelHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose the option that best matches your typical week.'**
  String get caloriesCalculatorActivityLevelHelp;

  /// No description provided for @caloriesCalculatorActivityLevelNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get caloriesCalculatorActivityLevelNoneTitle;

  /// No description provided for @caloriesCalculatorActivityLevelNoneDescription.
  ///
  /// In en, this message translates to:
  /// **'Office work, lots of sitting, few steps, and little to no exercise.'**
  String get caloriesCalculatorActivityLevelNoneDescription;

  /// No description provided for @caloriesCalculatorActivityLevelLowTitle.
  ///
  /// In en, this message translates to:
  /// **'Lightly active'**
  String get caloriesCalculatorActivityLevelLowTitle;

  /// No description provided for @caloriesCalculatorActivityLevelLowDescription.
  ///
  /// In en, this message translates to:
  /// **'Mostly sitting, but with some daily movement or 1 to 2 light workouts per week.'**
  String get caloriesCalculatorActivityLevelLowDescription;

  /// No description provided for @caloriesCalculatorActivityLevelMediumTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderately active'**
  String get caloriesCalculatorActivityLevelMediumTitle;

  /// No description provided for @caloriesCalculatorActivityLevelMediumDescription.
  ///
  /// In en, this message translates to:
  /// **'Regular daily movement or 3 to 4 training sessions per week.'**
  String get caloriesCalculatorActivityLevelMediumDescription;

  /// No description provided for @caloriesCalculatorActivityLevelHighTitle.
  ///
  /// In en, this message translates to:
  /// **'Very active'**
  String get caloriesCalculatorActivityLevelHighTitle;

  /// No description provided for @caloriesCalculatorActivityLevelHighDescription.
  ///
  /// In en, this message translates to:
  /// **'A physically active daily life or intense training on most days.'**
  String get caloriesCalculatorActivityLevelHighDescription;

  /// No description provided for @caloriesCalculatorActivityLevelExtremeTitle.
  ///
  /// In en, this message translates to:
  /// **'Extremely active'**
  String get caloriesCalculatorActivityLevelExtremeTitle;

  /// No description provided for @caloriesCalculatorActivityLevelExtremeDescription.
  ///
  /// In en, this message translates to:
  /// **'Very high training volume, physically demanding work, or competitive sports.'**
  String get caloriesCalculatorActivityLevelExtremeDescription;

  /// No description provided for @caloriesCalculatorActivityLevelHint.
  ///
  /// In en, this message translates to:
  /// **'For example 1.2 to 2.0'**
  String get caloriesCalculatorActivityLevelHint;

  /// No description provided for @caloriesCalculatorActivityLevelEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your activity level.'**
  String get caloriesCalculatorActivityLevelEmpty;

  /// No description provided for @caloriesCalculatorActivityLevelInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid activity level.'**
  String get caloriesCalculatorActivityLevelInvalid;

  /// No description provided for @caloriesCalculatorGoalModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal mode'**
  String get caloriesCalculatorGoalModeLabel;

  /// No description provided for @caloriesCalculatorGoalModeLose.
  ///
  /// In en, this message translates to:
  /// **'Lose'**
  String get caloriesCalculatorGoalModeLose;

  /// No description provided for @caloriesCalculatorGoalModeMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain'**
  String get caloriesCalculatorGoalModeMaintain;

  /// No description provided for @caloriesCalculatorGoalModeGain.
  ///
  /// In en, this message translates to:
  /// **'Gain'**
  String get caloriesCalculatorGoalModeGain;

  /// No description provided for @caloriesCalculatorGoalSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal speed (kg/week)'**
  String get caloriesCalculatorGoalSpeedLabel;

  /// No description provided for @caloriesCalculatorGoalSpeedHint.
  ///
  /// In en, this message translates to:
  /// **'For example 0.25, 0.5 or 0.75'**
  String get caloriesCalculatorGoalSpeedHint;

  /// No description provided for @caloriesCalculatorGoalSpeedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a goal speed.'**
  String get caloriesCalculatorGoalSpeedEmpty;

  /// No description provided for @caloriesCalculatorGoalSpeedInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid goal speed.'**
  String get caloriesCalculatorGoalSpeedInvalid;

  /// No description provided for @caloriesCalculatorResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get caloriesCalculatorResultsTitle;

  /// No description provided for @caloriesCalculatorBmrLabel.
  ///
  /// In en, this message translates to:
  /// **'Basal metabolic rate'**
  String get caloriesCalculatorBmrLabel;

  /// No description provided for @caloriesCalculatorTdeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Maintenance calories'**
  String get caloriesCalculatorTdeeLabel;

  /// No description provided for @caloriesCalculatorDailyGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily calorie target'**
  String get caloriesCalculatorDailyGoalLabel;

  /// No description provided for @caloriesCalculatorMinimumGoalWarning.
  ///
  /// In en, this message translates to:
  /// **'For weight loss, the daily target cannot go below {minimumKcal} kcal. The result was capped at this minimum.'**
  String caloriesCalculatorMinimumGoalWarning(int minimumKcal);

  /// No description provided for @caloriesCalculatorSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save target'**
  String get caloriesCalculatorSaveAction;

  /// No description provided for @caloriesCalculatorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the calculated calorie target.'**
  String get caloriesCalculatorSaveFailed;

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

  /// No description provided for @caloriesSummaryViewClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get caloriesSummaryViewClassic;

  /// No description provided for @caloriesSummaryViewBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get caloriesSummaryViewBalance;

  /// No description provided for @caloriesBalanceCarryoverLabel.
  ///
  /// In en, this message translates to:
  /// **'7-day balance'**
  String get caloriesBalanceCarryoverLabel;

  /// No description provided for @caloriesBalanceFlexGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Flex goal'**
  String get caloriesBalanceFlexGoalLabel;

  /// No description provided for @caloriesBalancePaceNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Pace now'**
  String get caloriesBalancePaceNowLabel;

  /// No description provided for @caloriesBalancePaceFinalLabel.
  ///
  /// In en, this message translates to:
  /// **'Final pace'**
  String get caloriesBalancePaceFinalLabel;

  /// No description provided for @caloriesBalanceScaleBufferLabel.
  ///
  /// In en, this message translates to:
  /// **'Deficit'**
  String get caloriesBalanceScaleBufferLabel;

  /// No description provided for @caloriesBalanceScaleOnTrackLabel.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get caloriesBalanceScaleOnTrackLabel;

  /// No description provided for @caloriesBalanceScaleOverLabel.
  ///
  /// In en, this message translates to:
  /// **'Surplus'**
  String get caloriesBalanceScaleOverLabel;

  /// No description provided for @caloriesBalanceStatusBalancedNow.
  ///
  /// In en, this message translates to:
  /// **'Well balanced for now'**
  String get caloriesBalanceStatusBalancedNow;

  /// No description provided for @caloriesBalanceStatusEatNow.
  ///
  /// In en, this message translates to:
  /// **'Eat about {kcal} kcal now'**
  String caloriesBalanceStatusEatNow(int kcal);

  /// No description provided for @caloriesBalanceStatusWaitNow.
  ///
  /// In en, this message translates to:
  /// **'Wait a bit before eating again'**
  String get caloriesBalanceStatusWaitNow;

  /// No description provided for @caloriesBalanceStatusOnTrack.
  ///
  /// In en, this message translates to:
  /// **'Right on pace'**
  String get caloriesBalanceStatusOnTrack;

  /// No description provided for @caloriesBalanceStatusBuffer.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal under pace'**
  String caloriesBalanceStatusBuffer(int kcal);

  /// No description provided for @caloriesBalanceStatusOver.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal over pace'**
  String caloriesBalanceStatusOver(int kcal);

  /// No description provided for @caloriesBalanceStatusLoseUnder.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal buffer for weight loss'**
  String caloriesBalanceStatusLoseUnder(int kcal);

  /// No description provided for @caloriesBalanceStatusLoseOver.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal over pace for weight loss'**
  String caloriesBalanceStatusLoseOver(int kcal);

  /// No description provided for @caloriesBalanceStatusGainUnder.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal under pace for weight gain'**
  String caloriesBalanceStatusGainUnder(int kcal);

  /// No description provided for @caloriesBalanceStatusFinishedOnTrack.
  ///
  /// In en, this message translates to:
  /// **'The day ended on target'**
  String get caloriesBalanceStatusFinishedOnTrack;

  /// No description provided for @caloriesBalanceStatusFinishedBuffer.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal under the flex target'**
  String caloriesBalanceStatusFinishedBuffer(int kcal);

  /// No description provided for @caloriesBalanceStatusFinishedOver.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal over the flex target'**
  String caloriesBalanceStatusFinishedOver(int kcal);

  /// No description provided for @caloriesBalanceStatusFinishedLoseUnder.
  ///
  /// In en, this message translates to:
  /// **'Ended with a {kcal} kcal buffer for weight loss'**
  String caloriesBalanceStatusFinishedLoseUnder(int kcal);

  /// No description provided for @caloriesBalanceStatusFinishedLoseOver.
  ///
  /// In en, this message translates to:
  /// **'Ended {kcal} kcal over the flex target for weight loss'**
  String caloriesBalanceStatusFinishedLoseOver(int kcal);

  /// No description provided for @caloriesBalanceStatusFinishedGainUnder.
  ///
  /// In en, this message translates to:
  /// **'Ended {kcal} kcal under the flex target for weight gain'**
  String caloriesBalanceStatusFinishedGainUnder(int kcal);

  /// No description provided for @caloriesBalanceStatusFinishedGainOver.
  ///
  /// In en, this message translates to:
  /// **'Ended with {kcal} kcal extra for weight gain'**
  String caloriesBalanceStatusFinishedGainOver(int kcal);

  /// No description provided for @caloriesBalanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Balance view is unavailable right now.'**
  String get caloriesBalanceUnavailable;

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

  /// No description provided for @caloriesWeekBufferTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly balance'**
  String get caloriesWeekBufferTitle;

  /// No description provided for @caloriesWeekBufferRemaining.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal left this week'**
  String caloriesWeekBufferRemaining(int kcal);

  /// No description provided for @caloriesWeekBufferOverspent.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal over this week'**
  String caloriesWeekBufferOverspent(int kcal);

  /// No description provided for @caloriesWeekBalanceTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get caloriesWeekBalanceTodayLabel;

  /// No description provided for @caloriesWeekBalanceSaved.
  ///
  /// In en, this message translates to:
  /// **'You saved {kcal} kcal since your goal started. Today\'s target was increased.'**
  String caloriesWeekBalanceSaved(int kcal);

  /// No description provided for @caloriesWeekBalanceOverspent.
  ///
  /// In en, this message translates to:
  /// **'You are {kcal} kcal over since your goal started.'**
  String caloriesWeekBalanceOverspent(int kcal);

  /// No description provided for @caloriesWeekBalanceStable.
  ///
  /// In en, this message translates to:
  /// **'You are balanced since your goal started. Today\'s target stays unchanged.'**
  String get caloriesWeekBalanceStable;

  /// No description provided for @caloriesWeekBalanceStartedToday.
  ///
  /// In en, this message translates to:
  /// **'Your goal starts today. The balance will build up from here.'**
  String get caloriesWeekBalanceStartedToday;

  /// No description provided for @caloriesSectionEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No entries yet.'**
  String get caloriesSectionEmptyState;

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

  /// No description provided for @caloriesReturnPreparedMealDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Return meal to inventory?'**
  String get caloriesReturnPreparedMealDialogTitle;

  /// No description provided for @caloriesReturnPreparedMealDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Return \"{name}\" to inventory and remove it from the diary?'**
  String caloriesReturnPreparedMealDialogMessage(String name);

  /// No description provided for @caloriesReturnPreparedMealConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Return to inventory'**
  String get caloriesReturnPreparedMealConfirmAction;

  /// No description provided for @caloriesReturnPreparedMealFailed.
  ///
  /// In en, this message translates to:
  /// **'The meal could not be returned to inventory.'**
  String get caloriesReturnPreparedMealFailed;

  /// No description provided for @caloriesDeleteRestoreInventoryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add the food back to inventory?'**
  String get caloriesDeleteRestoreInventoryQuestion;

  /// No description provided for @caloriesDeleteRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'The food could not be added back to inventory.'**
  String get caloriesDeleteRestoreFailed;

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

  /// No description provided for @caloriesWeekdayShortMonday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get caloriesWeekdayShortMonday;

  /// No description provided for @caloriesWeekdayShortTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get caloriesWeekdayShortTuesday;

  /// No description provided for @caloriesWeekdayShortWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get caloriesWeekdayShortWednesday;

  /// No description provided for @caloriesWeekdayShortThursday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get caloriesWeekdayShortThursday;

  /// No description provided for @caloriesWeekdayShortFriday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get caloriesWeekdayShortFriday;

  /// No description provided for @caloriesWeekdayShortSaturday.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get caloriesWeekdayShortSaturday;

  /// No description provided for @caloriesWeekdayShortSunday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get caloriesWeekdayShortSunday;

  /// No description provided for @caloriesUnitKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get caloriesUnitKcal;

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

  /// No description provided for @caloriesBundlePortions.
  ///
  /// In en, this message translates to:
  /// **'{consumed}/{total} portions'**
  String caloriesBundlePortions(int consumed, int total);

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

  /// No description provided for @settingsHouseholdTitle.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get settingsHouseholdTitle;

  /// No description provided for @settingsHouseholdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite members and manage shared access'**
  String get settingsHouseholdSubtitle;

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

  /// No description provided for @householdTitle.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get householdTitle;

  /// No description provided for @householdJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join household'**
  String get householdJoinTitle;

  /// No description provided for @householdJoinCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get householdJoinCodeLabel;

  /// No description provided for @householdJoinCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit invite code'**
  String get householdJoinCodeHint;

  /// No description provided for @householdJoinAction.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get householdJoinAction;

  /// No description provided for @householdJoinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Household joined.'**
  String get householdJoinSuccess;

  /// No description provided for @householdJoinInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid household code.'**
  String get householdJoinInvalidCode;

  /// No description provided for @householdJoinExpiredCode.
  ///
  /// In en, this message translates to:
  /// **'This household code has expired.'**
  String get householdJoinExpiredCode;

  /// No description provided for @householdJoinOwnCode.
  ///
  /// In en, this message translates to:
  /// **'You cannot join your own household.'**
  String get householdJoinOwnCode;

  /// No description provided for @householdInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite members'**
  String get householdInviteTitle;

  /// No description provided for @householdInviteGenerateCode.
  ///
  /// In en, this message translates to:
  /// **'Generate code'**
  String get householdInviteGenerateCode;

  /// No description provided for @householdInviteCodeValidFor.
  ///
  /// In en, this message translates to:
  /// **'Code valid for 24 hours'**
  String get householdInviteCodeValidFor;

  /// No description provided for @householdInviteCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get householdInviteCopyCode;

  /// No description provided for @householdInviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied.'**
  String get householdInviteCodeCopied;

  /// No description provided for @householdInviteRefreshCode.
  ///
  /// In en, this message translates to:
  /// **'Generate new code'**
  String get householdInviteRefreshCode;

  /// No description provided for @householdInviteVerificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Verify your account with Google or email before you lead a household.'**
  String get householdInviteVerificationRequired;

  /// No description provided for @householdHostVerificationHint.
  ///
  /// In en, this message translates to:
  /// **'To invite other people into your household, link your guest account with Google or email & password.'**
  String get householdHostVerificationHint;

  /// No description provided for @householdMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get householdMembersTitle;

  /// No description provided for @householdLeaderBadge.
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get householdLeaderBadge;

  /// No description provided for @householdYouBadge.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get householdYouBadge;

  /// No description provided for @householdRemoveMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove member?'**
  String get householdRemoveMemberTitle;

  /// No description provided for @householdRemoveMemberMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this household?'**
  String householdRemoveMemberMessage(Object name);

  /// No description provided for @householdRemoveMemberAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get householdRemoveMemberAction;

  /// No description provided for @householdRemoveMemberSuccess.
  ///
  /// In en, this message translates to:
  /// **'Member removed.'**
  String get householdRemoveMemberSuccess;

  /// No description provided for @householdRemoveMemberFailed.
  ///
  /// In en, this message translates to:
  /// **'This member cannot be removed.'**
  String get householdRemoveMemberFailed;

  /// No description provided for @householdLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave household?'**
  String get householdLeaveTitle;

  /// No description provided for @householdLeaveMessage.
  ///
  /// In en, this message translates to:
  /// **'You will lose access to the shared household until you join again.'**
  String get householdLeaveMessage;

  /// No description provided for @householdLeaveAction.
  ///
  /// In en, this message translates to:
  /// **'Leave household'**
  String get householdLeaveAction;

  /// No description provided for @householdLeaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Household left.'**
  String get householdLeaveSuccess;

  /// No description provided for @householdLeaderOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the household leader can do that.'**
  String get householdLeaderOnly;

  /// No description provided for @householdActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Household action failed. Please try again.'**
  String get householdActionFailed;

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

  /// No description provided for @commonOr.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get commonOr;

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

  /// No description provided for @authBrandTitle.
  ///
  /// In en, this message translates to:
  /// **'Yamt'**
  String get authBrandTitle;

  /// No description provided for @authBrandSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Yet Another Meal Tracker'**
  String get authBrandSubtitle;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account and get started.'**
  String get authRegisterSubtitle;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get authContinueAsGuest;

  /// No description provided for @authFooterNoAccountPrefix.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authFooterNoAccountPrefix;

  /// No description provided for @authFooterHasAccountPrefix.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authFooterHasAccountPrefix;

  /// No description provided for @authSwitchRegisterAction.
  ///
  /// In en, this message translates to:
  /// **'Register now'**
  String get authSwitchRegisterAction;

  /// No description provided for @authSwitchLoginAction.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authSwitchLoginAction;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot?'**
  String get authForgotPassword;

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

  /// No description provided for @statisticsPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Patterns from inventory, food waste, and nutrition at a glance.'**
  String get statisticsPageSubtitle;

  /// No description provided for @statisticsContextHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get statisticsContextHousehold;

  /// No description provided for @statisticsContextPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get statisticsContextPersonal;

  /// No description provided for @statisticsTimeframeWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get statisticsTimeframeWeek;

  /// No description provided for @statisticsTimeframeMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get statisticsTimeframeMonth;

  /// No description provided for @statisticsTimeframeYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get statisticsTimeframeYear;

  /// No description provided for @statisticsTimeframeTotal.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get statisticsTimeframeTotal;

  /// No description provided for @statisticsTabSpending.
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get statisticsTabSpending;

  /// No description provided for @statisticsTabWaste.
  ///
  /// In en, this message translates to:
  /// **'Food Waste'**
  String get statisticsTabWaste;

  /// No description provided for @statisticsTabCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get statisticsTabCalories;

  /// No description provided for @statisticsHouseholdHintTitle.
  ///
  /// In en, this message translates to:
  /// **'MVP note'**
  String get statisticsHouseholdHintTitle;

  /// No description provided for @statisticsHouseholdHintBody.
  ///
  /// In en, this message translates to:
  /// **'Household figures currently use tracked inventory items and available receipt data. A full timeline view will come later.'**
  String get statisticsHouseholdHintBody;

  /// No description provided for @statisticsWasteHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare waste tracking'**
  String get statisticsWasteHintTitle;

  /// No description provided for @statisticsWasteHintBody.
  ///
  /// In en, this message translates to:
  /// **'Real food-waste statistics need durable discard events and discard reasons in the throw-away flow.'**
  String get statisticsWasteHintBody;

  /// No description provided for @statisticsSpendingTotalTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracked spending'**
  String get statisticsSpendingTotalTitle;

  /// No description provided for @statisticsSpendingTotalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'sum of captured purchases in the selected period'**
  String get statisticsSpendingTotalSubtitle;

  /// No description provided for @statisticsSpendingTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Price trend'**
  String get statisticsSpendingTrendTitle;

  /// No description provided for @statisticsSpendingTrendEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recurring products with usable price history in the selected period yet.'**
  String get statisticsSpendingTrendEmpty;

  /// No description provided for @statisticsSpendingStoresTitle.
  ///
  /// In en, this message translates to:
  /// **'Top stores'**
  String get statisticsSpendingStoresTitle;

  /// No description provided for @statisticsTopStoresEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stores with useful values in this period yet.'**
  String get statisticsTopStoresEmpty;

  /// No description provided for @statisticsSpendingChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending by receipt date'**
  String get statisticsSpendingChartTitle;

  /// No description provided for @statisticsSpendingChartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The chart uses the real receiptDate and shows the latest shopping days for the selected filter.'**
  String get statisticsSpendingChartSubtitle;

  /// No description provided for @statisticsSpendingChartEmpty.
  ///
  /// In en, this message translates to:
  /// **'As soon as dated receipt data exists, your spending timeline will show up here.'**
  String get statisticsSpendingChartEmpty;

  /// No description provided for @statisticsSpendingItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Most expensive items'**
  String get statisticsSpendingItemsTitle;

  /// No description provided for @statisticsExpensiveItemsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cost-relevant items in this period yet.'**
  String get statisticsExpensiveItemsEmpty;

  /// No description provided for @statisticsWasteOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Food waste overview'**
  String get statisticsWasteOverviewTitle;

  /// No description provided for @statisticsWasteTrackingMissingValue.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get statisticsWasteTrackingMissingValue;

  /// No description provided for @statisticsWasteTrackingMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'Discard events and reasons are not persisted yet.'**
  String get statisticsWasteTrackingMissingMessage;

  /// No description provided for @statisticsWasteOverviewSummary.
  ///
  /// In en, this message translates to:
  /// **'{eventCount, plural, =1{1 discard event · {lossValue} tracked loss} other{{eventCount} discard events · {lossValue} tracked loss}}'**
  String statisticsWasteOverviewSummary(int eventCount, Object lossValue);

  /// No description provided for @statisticsWasteRatioTitle.
  ///
  /// In en, this message translates to:
  /// **'Ratio & money loss'**
  String get statisticsWasteRatioTitle;

  /// No description provided for @statisticsWasteMoneyLossMissing.
  ///
  /// In en, this message translates to:
  /// **'Once discarded values are tracked, the ratio and exact money loss will appear here.'**
  String get statisticsWasteMoneyLossMissing;

  /// No description provided for @statisticsWasteMoneyLossTracked.
  ///
  /// In en, this message translates to:
  /// **'Tracked value of thrown-away food in this period.'**
  String get statisticsWasteMoneyLossTracked;

  /// No description provided for @statisticsWasteReasonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Waste reasons'**
  String get statisticsWasteReasonsTitle;

  /// No description provided for @statisticsWasteReasonsMissing.
  ///
  /// In en, this message translates to:
  /// **'Add reasons such as expired or cooked too much when throwing items away so we can surface patterns.'**
  String get statisticsWasteReasonsMissing;

  /// No description provided for @statisticsWasteReasonsTopSummary.
  ///
  /// In en, this message translates to:
  /// **'Most common reason across {count} discard events.'**
  String statisticsWasteReasonsTopSummary(int count);

  /// No description provided for @statisticsWasteItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Often discarded'**
  String get statisticsWasteItemsTitle;

  /// No description provided for @statisticsWasteItemsMissing.
  ///
  /// In en, this message translates to:
  /// **'Once enough discard events exist, your most frequent problem items will show up here.'**
  String get statisticsWasteItemsMissing;

  /// No description provided for @statisticsWasteItemsTopSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{discarded once} other{discarded {count} times}}'**
  String statisticsWasteItemsTopSummary(int count);

  /// No description provided for @statisticsCaloriesOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Calories overview'**
  String get statisticsCaloriesOverviewTitle;

  /// No description provided for @statisticsCaloriesOverviewSummary.
  ///
  /// In en, this message translates to:
  /// **'{trackedDays} tracked days · {entries} entries'**
  String statisticsCaloriesOverviewSummary(int trackedDays, int entries);

  /// No description provided for @statisticsCaloriesStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal streak'**
  String get statisticsCaloriesStreakTitle;

  /// No description provided for @statisticsCaloriesStreakSummary.
  ///
  /// In en, this message translates to:
  /// **'{goalDays} of {trackedDays} days within goal'**
  String statisticsCaloriesStreakSummary(int goalDays, int trackedDays);

  /// No description provided for @statisticsCaloriesBufferTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly balance'**
  String get statisticsCaloriesBufferTitle;

  /// No description provided for @statisticsCaloriesBufferSubtitle.
  ///
  /// In en, this message translates to:
  /// **'current balance against your goal'**
  String get statisticsCaloriesBufferSubtitle;

  /// No description provided for @statisticsCaloriesChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily view'**
  String get statisticsCaloriesChartTitle;

  /// No description provided for @statisticsCaloriesChartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recent days with eaten calories and goal marker.'**
  String get statisticsCaloriesChartSubtitle;

  /// No description provided for @statisticsCaloriesChartEmpty.
  ///
  /// In en, this message translates to:
  /// **'As soon as calorie entries exist, your daily view will show up here.'**
  String get statisticsCaloriesChartEmpty;

  /// No description provided for @statisticsCaloriesMacrosTitle.
  ///
  /// In en, this message translates to:
  /// **'Macro split'**
  String get statisticsCaloriesMacrosTitle;

  /// No description provided for @statisticsCaloriesMacroChartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share of calories coming from carbs, protein, and fat.'**
  String get statisticsCaloriesMacroChartSubtitle;

  /// No description provided for @statisticsCaloriesNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No calorie entries in this period yet.'**
  String get statisticsCaloriesNoEntries;

  /// No description provided for @statisticsChartGoalLegend.
  ///
  /// In en, this message translates to:
  /// **'Goal marker'**
  String get statisticsChartGoalLegend;

  /// No description provided for @statisticsMetricNoTrend.
  ///
  /// In en, this message translates to:
  /// **'No trend yet'**
  String get statisticsMetricNoTrend;

  /// No description provided for @statisticsMetricNoData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get statisticsMetricNoData;

  /// No description provided for @statisticsMetricAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get statisticsMetricAverage;

  /// No description provided for @statisticsMetricEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get statisticsMetricEntries;

  /// No description provided for @statisticsMetricTrackedDays.
  ///
  /// In en, this message translates to:
  /// **'Tracked days'**
  String get statisticsMetricTrackedDays;

  /// No description provided for @statisticsMetricGoalDays.
  ///
  /// In en, this message translates to:
  /// **'Within goal'**
  String get statisticsMetricGoalDays;

  /// No description provided for @statisticsMetricReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get statisticsMetricReceipts;

  /// No description provided for @statisticsWasteSignalsTitle.
  ///
  /// In en, this message translates to:
  /// **'What is still missing'**
  String get statisticsWasteSignalsTitle;

  /// No description provided for @statisticsWasteChecklistEvents.
  ///
  /// In en, this message translates to:
  /// **'durable discard events with amount and timestamp'**
  String get statisticsWasteChecklistEvents;

  /// No description provided for @statisticsWasteChecklistReasons.
  ///
  /// In en, this message translates to:
  /// **'discard reasons such as expired, moldy, or cooked too much'**
  String get statisticsWasteChecklistReasons;

  /// No description provided for @statisticsWasteChecklistEatingOut.
  ///
  /// In en, this message translates to:
  /// **'prices for outside meals so household spending becomes more complete'**
  String get statisticsWasteChecklistEatingOut;

  /// No description provided for @statisticsCaloriesBalanceWindow.
  ///
  /// In en, this message translates to:
  /// **'Balance window from {startDate} to {endDate}'**
  String statisticsCaloriesBalanceWindow(String startDate, String endDate);

  /// No description provided for @statisticsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load statistics.'**
  String get statisticsLoadFailed;

  /// No description provided for @commonUndoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndoAction;

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
