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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
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

  /// No description provided for @homeCalories.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get homeCalories;

  /// No description provided for @homeCookbook.
  ///
  /// In en, this message translates to:
  /// **'Cookbook'**
  String get homeCookbook;

  /// No description provided for @homeSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// No description provided for @homeProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get homeProgress;

  /// No description provided for @homeMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get homeMenuTooltip;

  /// No description provided for @aiChefTooltip.
  ///
  /// In en, this message translates to:
  /// **'Let the AI suggest a random recipe'**
  String get aiChefTooltip;

  /// No description provided for @aiChefSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'What should the AI cook?'**
  String get aiChefSetupTitle;

  /// No description provided for @aiChefSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose whether your inventory matters and add any wishes.'**
  String get aiChefSetupSubtitle;

  /// No description provided for @aiChefUseInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Use inventory'**
  String get aiChefUseInventoryTitle;

  /// No description provided for @aiChefUseInventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prefer ingredients that are currently in stock.'**
  String get aiChefUseInventorySubtitle;

  /// No description provided for @aiChefWishesLabel.
  ///
  /// In en, this message translates to:
  /// **'Wishes'**
  String get aiChefWishesLabel;

  /// No description provided for @aiChefWishesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. vegetarian, quick, high protein, no rice'**
  String get aiChefWishesHint;

  /// No description provided for @aiChefGenerateAction.
  ///
  /// In en, this message translates to:
  /// **'Generate recipe'**
  String get aiChefGenerateAction;

  /// No description provided for @aiChefGeneratingTitle.
  ///
  /// In en, this message translates to:
  /// **'AI is cooking...'**
  String get aiChefGeneratingTitle;

  /// No description provided for @aiChefGeneratingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal AI is assembling a delicious recipe...'**
  String get aiChefGeneratingSubtitle;

  /// No description provided for @aiChefSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save to Cookbook'**
  String get aiChefSaveAction;

  /// No description provided for @aiChefCloseAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get aiChefCloseAction;

  /// No description provided for @aiChefSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Recipe successfully saved to Cookbook!'**
  String get aiChefSaveSuccess;

  /// No description provided for @aiChefSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save recipe.'**
  String get aiChefSaveError;

  /// No description provided for @aiChefFromInventory.
  ///
  /// In en, this message translates to:
  /// **'From your stock'**
  String get aiChefFromInventory;

  /// No description provided for @aiChefQuoteLoveGarlic.
  ///
  /// In en, this message translates to:
  /// **'The secret ingredient is always love. And garlic.'**
  String get aiChefQuoteLoveGarlic;

  /// No description provided for @aiChefQuoteCookingMagic.
  ///
  /// In en, this message translates to:
  /// **'Cooking is like magic, except you can eat the results.'**
  String get aiChefQuoteCookingMagic;

  /// No description provided for @aiChefQuoteGoodFood.
  ///
  /// In en, this message translates to:
  /// **'Good food brings good mood.'**
  String get aiChefQuoteGoodFood;

  /// No description provided for @aiChefQuoteKitchenTalks.
  ///
  /// In en, this message translates to:
  /// **'The best conversations always happen in the kitchen.'**
  String get aiChefQuoteKitchenTalks;

  /// No description provided for @aiChefQuoteVirtualOven.
  ///
  /// In en, this message translates to:
  /// **'AI is preheating the virtual oven...'**
  String get aiChefQuoteVirtualOven;

  /// No description provided for @aiChefPortionsLabel.
  ///
  /// In en, this message translates to:
  /// **'{portions, plural, =1{1 portion} other{{portions} portions}}'**
  String aiChefPortionsLabel(int portions);

  /// No description provided for @aiChefCaloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String aiChefCaloriesLabel(int kcal);

  /// No description provided for @aiChefProteinLabel.
  ///
  /// In en, this message translates to:
  /// **'Protein: {grams} g'**
  String aiChefProteinLabel(int grams);

  /// No description provided for @aiChefCarbsLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbs: {grams} g'**
  String aiChefCarbsLabel(int grams);

  /// No description provided for @aiChefFatLabel.
  ///
  /// In en, this message translates to:
  /// **'Fat: {grams} g'**
  String aiChefFatLabel(int grams);

  /// No description provided for @homeQuickActionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Quick action'**
  String get homeQuickActionTooltip;

  /// No description provided for @inventoryFabTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get inventoryFabTooltip;

  /// No description provided for @productSearchHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get productSearchHubTitle;

  /// No description provided for @productSearchHubInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to inventory'**
  String get productSearchHubInventoryTitle;

  /// No description provided for @productSearchHubDiaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Eat food'**
  String get productSearchHubDiaryTitle;

  /// No description provided for @productSearchHubBarcodeAction.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get productSearchHubBarcodeAction;

  /// No description provided for @productSearchHubAiAction.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get productSearchHubAiAction;

  /// No description provided for @productSearchHubCreateOwnAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get productSearchHubCreateOwnAction;

  /// No description provided for @productSearchHubSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Name, brand...'**
  String get productSearchHubSearchHint;

  /// No description provided for @productSearchHubClearSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get productSearchHubClearSearchAction;

  /// No description provided for @productSearchHubSearchLoading.
  ///
  /// In en, this message translates to:
  /// **'Searching products'**
  String get productSearchHubSearchLoading;

  /// No description provided for @productSearchHubSearchLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Product search failed.'**
  String get productSearchHubSearchLoadFailed;

  /// No description provided for @productSearchHubSearchRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get productSearchHubSearchRetryAction;

  /// No description provided for @productSearchHubSearchEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No matching products found.'**
  String get productSearchHubSearchEmptyState;

  /// No description provided for @productSearchHubRequiredFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} *'**
  String productSearchHubRequiredFieldLabel(String label);

  /// No description provided for @eatPageAmountUnknown.
  ///
  /// In en, this message translates to:
  /// **'–'**
  String get eatPageAmountUnknown;

  /// No description provided for @productSearchHubNoBarcodeAction.
  ///
  /// In en, this message translates to:
  /// **'No barcode'**
  String get productSearchHubNoBarcodeAction;

  /// No description provided for @productSearchHubCreateProductAction.
  ///
  /// In en, this message translates to:
  /// **'Create product'**
  String get productSearchHubCreateProductAction;

  /// No description provided for @productSearchHubCartTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected products'**
  String get productSearchHubCartTitle;

  /// No description provided for @productSearchHubCartAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get productSearchHubCartAddAction;

  /// No description provided for @productSearchHubCartRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get productSearchHubCartRemoveAction;

  /// No description provided for @productSearchHubRecentlySelectedTab.
  ///
  /// In en, this message translates to:
  /// **'Recently selected'**
  String get productSearchHubRecentlySelectedTab;

  /// No description provided for @productSearchHubRecentlySelectedLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading recent products'**
  String get productSearchHubRecentlySelectedLoading;

  /// No description provided for @productSearchHubRecentlySelectedLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load recent products.'**
  String get productSearchHubRecentlySelectedLoadFailed;

  /// No description provided for @productSearchHubRecentlySelectedRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get productSearchHubRecentlySelectedRetryAction;

  /// No description provided for @productSearchHubRecentlySelectedEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No recently selected products yet.'**
  String get productSearchHubRecentlySelectedEmptyState;

  /// No description provided for @inventoryPageTitle.
  ///
  /// In en, this message translates to:
  /// **'My inventory'**
  String get inventoryPageTitle;

  /// No description provided for @inventoryActionCameraUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Camera is not supported on this platform.'**
  String get inventoryActionCameraUnsupported;

  /// No description provided for @inventoryActionManualSearch.
  ///
  /// In en, this message translates to:
  /// **'Manual search'**
  String get inventoryActionManualSearch;

  /// No description provided for @inventoryActionAiSuggestion.
  ///
  /// In en, this message translates to:
  /// **'AI suggestion'**
  String get inventoryActionAiSuggestion;

  /// No description provided for @inventoryActionUploadImagePdf.
  ///
  /// In en, this message translates to:
  /// **'Upload image/PDF'**
  String get inventoryActionUploadImagePdf;

  /// No description provided for @inventoryActionCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get inventoryActionCamera;

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

  /// No description provided for @inventoryReceiptReviewConfirmItemAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm item'**
  String get inventoryReceiptReviewConfirmItemAction;

  /// No description provided for @inventoryReceiptReviewUndoConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Undo confirmation'**
  String get inventoryReceiptReviewUndoConfirmAction;

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

  /// No description provided for @inventoryReceiptReviewManualDataRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a product, scan a barcode, or add nutrition.'**
  String get inventoryReceiptReviewManualDataRequired;

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

  /// No description provided for @inventoryViewStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get inventoryViewStock;

  /// No description provided for @inventoryViewHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get inventoryViewHistory;

  /// No description provided for @inventoryRecentSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Foods'**
  String get inventoryRecentSectionTitle;

  /// No description provided for @inventoryActivityLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading history...'**
  String get inventoryActivityLoading;

  /// No description provided for @inventoryActivityLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load history.'**
  String get inventoryActivityLoadFailed;

  /// No description provided for @inventoryActivityEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No inventory history yet.'**
  String get inventoryActivityEmptyTitle;

  /// No description provided for @inventoryActivityActorFallback.
  ///
  /// In en, this message translates to:
  /// **'Household member'**
  String get inventoryActivityActorFallback;

  /// No description provided for @inventoryActivityPieceAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount, plural, =1{1 item} other{{amount} items}}'**
  String inventoryActivityPieceAmount(int amount);

  /// No description provided for @inventoryActivityItemAdded.
  ///
  /// In en, this message translates to:
  /// **'{actor} added {amount} of {item}.'**
  String inventoryActivityItemAdded(String actor, String item, String amount);

  /// No description provided for @inventoryActivityItemConsumed.
  ///
  /// In en, this message translates to:
  /// **'{actor} ate {amount} of {item}.'**
  String inventoryActivityItemConsumed(
    String actor,
    String item,
    String amount,
  );

  /// No description provided for @inventoryActivityItemDiscarded.
  ///
  /// In en, this message translates to:
  /// **'{actor} discarded {amount} of {item}.'**
  String inventoryActivityItemDiscarded(
    String actor,
    String item,
    String amount,
  );

  /// No description provided for @inventoryActivityItemDeleted.
  ///
  /// In en, this message translates to:
  /// **'{actor} deleted {amount} of {item}.'**
  String inventoryActivityItemDeleted(String actor, String item, String amount);

  /// No description provided for @inventoryActivityItemRestored.
  ///
  /// In en, this message translates to:
  /// **'{actor} restored {amount} of {item}.'**
  String inventoryActivityItemRestored(
    String actor,
    String item,
    String amount,
  );

  /// No description provided for @inventoryActivityItemUsedInPreparedMeal.
  ///
  /// In en, this message translates to:
  /// **'{actor} used {amount} of {item} for a prepared meal.'**
  String inventoryActivityItemUsedInPreparedMeal(
    String actor,
    String item,
    String amount,
  );

  /// No description provided for @inventoryActivityItemReturnedFromPreparedMeal.
  ///
  /// In en, this message translates to:
  /// **'{actor} returned {amount} of {item} from a prepared meal.'**
  String inventoryActivityItemReturnedFromPreparedMeal(
    String actor,
    String item,
    String amount,
  );

  /// No description provided for @inventorySearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search inventory'**
  String get inventorySearchLabel;

  /// No description provided for @inventorySearchClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get inventorySearchClearAction;

  /// No description provided for @inventoryFilterAction.
  ///
  /// In en, this message translates to:
  /// **'Filter items'**
  String get inventoryFilterAction;

  /// No description provided for @inventoryFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust view'**
  String get inventoryFiltersTitle;

  /// No description provided for @inventoryFiltersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sort and filter your foods'**
  String get inventoryFiltersSubtitle;

  /// No description provided for @inventoryFiltersShowResultsAction.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get inventoryFiltersShowResultsAction;

  /// No description provided for @inventoryViewSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get inventoryViewSectionTitle;

  /// No description provided for @inventoryViewListAction.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get inventoryViewListAction;

  /// No description provided for @inventoryViewTilesAction.
  ///
  /// In en, this message translates to:
  /// **'Tiles'**
  String get inventoryViewTilesAction;

  /// No description provided for @inventorySortSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get inventorySortSectionTitle;

  /// No description provided for @inventoryFilterSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get inventoryFilterSectionTitle;

  /// No description provided for @inventorySortAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get inventorySortAdded;

  /// No description provided for @inventorySortEaten.
  ///
  /// In en, this message translates to:
  /// **'Eaten'**
  String get inventorySortEaten;

  /// No description provided for @inventorySortAlphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get inventorySortAlphabetical;

  /// No description provided for @inventorySortQuantity.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get inventorySortQuantity;

  /// No description provided for @inventorySortDirectionAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get inventorySortDirectionAscending;

  /// No description provided for @inventorySortDirectionDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get inventorySortDirectionDescending;

  /// No description provided for @inventorySortDirectionAlphaAscending.
  ///
  /// In en, this message translates to:
  /// **'A to Z'**
  String get inventorySortDirectionAlphaAscending;

  /// No description provided for @inventorySortDirectionAlphaDescending.
  ///
  /// In en, this message translates to:
  /// **'Z to A'**
  String get inventorySortDirectionAlphaDescending;

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

  /// No description provided for @inventoryHideConsumedFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide consumed'**
  String get inventoryHideConsumedFilterTitle;

  /// No description provided for @inventoryHideConsumedFilterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide completely empty items'**
  String get inventoryHideConsumedFilterSubtitle;

  /// No description provided for @preparedMealFiltersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sort and filter your meals'**
  String get preparedMealFiltersSubtitle;

  /// No description provided for @preparedMealShowReadyOnlyToggle.
  ///
  /// In en, this message translates to:
  /// **'Only ready meals'**
  String get preparedMealShowReadyOnlyToggle;

  /// No description provided for @preparedMealShowIncompleteOnlyToggle.
  ///
  /// In en, this message translates to:
  /// **'Only incomplete meals'**
  String get preparedMealShowIncompleteOnlyToggle;

  /// No description provided for @preparedMealShowDepletedOnlyToggle.
  ///
  /// In en, this message translates to:
  /// **'Only fully consumed'**
  String get preparedMealShowDepletedOnlyToggle;

  /// No description provided for @preparedMealHideFullyConsumedItemsToggle.
  ///
  /// In en, this message translates to:
  /// **'Hide fully consumed meals'**
  String get preparedMealHideFullyConsumedItemsToggle;

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

  /// No description provided for @inventoryItemDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Item deleted.'**
  String get inventoryItemDeletedMessage;

  /// No description provided for @inventoryItemRemovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Item removed.'**
  String get inventoryItemRemovedMessage;

  /// No description provided for @inventoryItemEatAction.
  ///
  /// In en, this message translates to:
  /// **'Eat'**
  String get inventoryItemEatAction;

  /// No description provided for @inventoryAmountDialogAllRemainingAction.
  ///
  /// In en, this message translates to:
  /// **'All/Rest'**
  String get inventoryAmountDialogAllRemainingAction;

  /// No description provided for @inventoryItemEatSheetDecreasePortionCountAction.
  ///
  /// In en, this message translates to:
  /// **'Decrease portions'**
  String get inventoryItemEatSheetDecreasePortionCountAction;

  /// No description provided for @inventoryItemEatSheetIncreasePortionCountAction.
  ///
  /// In en, this message translates to:
  /// **'Increase portions'**
  String get inventoryItemEatSheetIncreasePortionCountAction;

  /// No description provided for @inventoryItemEatSheetDefaultPortionLabel.
  ///
  /// In en, this message translates to:
  /// **'Portion'**
  String get inventoryItemEatSheetDefaultPortionLabel;

  /// No description provided for @inventoryItemEatSheetUnitPiece.
  ///
  /// In en, this message translates to:
  /// **'Piece'**
  String get inventoryItemEatSheetUnitPiece;

  /// No description provided for @inventoryItemEatSheetInedibleAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtract inedible part'**
  String get inventoryItemEatSheetInedibleAmountLabel;

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

  /// No description provided for @inventoryItemEatSheetConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get inventoryItemEatSheetConfirmAction;

  /// No description provided for @inventoryItemEatSheetAddMoreAction.
  ///
  /// In en, this message translates to:
  /// **'+ More'**
  String get inventoryItemEatSheetAddMoreAction;

  /// No description provided for @eatPageNutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get eatPageNutritionTitle;

  /// No description provided for @eatPageWhen.
  ///
  /// In en, this message translates to:
  /// **'{day} · {meal}'**
  String eatPageWhen(String day, String meal);

  /// No description provided for @eatPagePickDay.
  ///
  /// In en, this message translates to:
  /// **'Other day…'**
  String get eatPagePickDay;

  /// No description provided for @eatPageRememberPortion.
  ///
  /// In en, this message translates to:
  /// **'+ Remember this amount as a portion'**
  String get eatPageRememberPortion;

  /// No description provided for @eatPagePortionNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name for {amount}'**
  String eatPagePortionNameLabel(String amount);

  /// No description provided for @eatPagePortionNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. slice'**
  String get eatPagePortionNameHint;

  /// No description provided for @eatPageSavePortion.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get eatPageSavePortion;

  /// No description provided for @eatPagePieceWeight.
  ///
  /// In en, this message translates to:
  /// **'1 {label} ='**
  String eatPagePieceWeight(String label);

  /// No description provided for @eatPageInStock.
  ///
  /// In en, this message translates to:
  /// **'{amount} in stock'**
  String eatPageInStock(String amount);

  /// No description provided for @eatPageTotal.
  ///
  /// In en, this message translates to:
  /// **'= {amount}'**
  String eatPageTotal(String amount);

  /// No description provided for @eatPageKcal.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String eatPageKcal(int kcal);

  /// No description provided for @eatPageRememberPieceSize.
  ///
  /// In en, this message translates to:
  /// **'+ Remember as piece size'**
  String get eatPageRememberPieceSize;

  /// No description provided for @eatPagePieceSizeNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. L'**
  String get eatPagePieceSizeNameHint;

  /// No description provided for @eatPageAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get eatPageAll;

  /// No description provided for @eatPageMark.
  ///
  /// In en, this message translates to:
  /// **'{label} {amount}'**
  String eatPageMark(String label, String amount);

  /// No description provided for @eatPagePortionMultiple.
  ///
  /// In en, this message translates to:
  /// **'= {count} × {label}'**
  String eatPagePortionMultiple(String count, String label);

  /// No description provided for @eatPageApprox.
  ///
  /// In en, this message translates to:
  /// **'≈ {amount}'**
  String eatPageApprox(String amount);

  /// No description provided for @eatPagePortionsUnit.
  ///
  /// In en, this message translates to:
  /// **'port.'**
  String get eatPagePortionsUnit;

  /// No description provided for @inventoryEatSheetPortionsHeader.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{amount} portion} other{{amount} portions}}'**
  String inventoryEatSheetPortionsHeader(num count, String amount);

  /// No description provided for @inventoryEatSheetAmountCompact.
  ///
  /// In en, this message translates to:
  /// **'{amount}{unit}'**
  String inventoryEatSheetAmountCompact(String amount, String unit);

  /// No description provided for @inventoryEatSheetAmountWithUnit.
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit}'**
  String inventoryEatSheetAmountWithUnit(String amount, String unit);

  /// No description provided for @inventoryItemEatSheetInedibleAmountSummary.
  ///
  /// In en, this message translates to:
  /// **'Inedible part: {amount}'**
  String inventoryItemEatSheetInedibleAmountSummary(String amount);

  /// No description provided for @inventoryItemAddToListAction.
  ///
  /// In en, this message translates to:
  /// **'Add to list'**
  String get inventoryItemAddToListAction;

  /// No description provided for @inventoryItemAddToShoppingListAction.
  ///
  /// In en, this message translates to:
  /// **'Add to shopping list'**
  String get inventoryItemAddToShoppingListAction;

  /// No description provided for @inventoryItemBuyAgainSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Item added to shopping list.'**
  String get inventoryItemBuyAgainSucceeded;

  /// No description provided for @inventoryItemRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get inventoryItemRemoveAction;

  /// No description provided for @inventoryItemRemoveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get inventoryItemRemoveDialogTitle;

  /// No description provided for @inventoryItemRemoveDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Why do you want to remove {name}?'**
  String inventoryItemRemoveDialogMessage(String name);

  /// No description provided for @inventoryItemRemoveDiscardAction.
  ///
  /// In en, this message translates to:
  /// **'Thrown away'**
  String get inventoryItemRemoveDiscardAction;

  /// No description provided for @inventoryItemRemoveDiscardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Expired or spoiled'**
  String get inventoryItemRemoveDiscardSubtitle;

  /// No description provided for @inventoryItemRemoveConsumeElsewhereAction.
  ///
  /// In en, this message translates to:
  /// **'Consumed elsewhere'**
  String get inventoryItemRemoveConsumeElsewhereAction;

  /// No description provided for @inventoryItemRemoveConsumeElsewhereSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Donated, shared or gifted'**
  String get inventoryItemRemoveConsumeElsewhereSubtitle;

  /// No description provided for @inventoryItemRemoveDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete completely'**
  String get inventoryItemRemoveDeleteAction;

  /// No description provided for @inventoryItemRemoveDeleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Input mistake, do not count in statistics'**
  String get inventoryItemRemoveDeleteSubtitle;

  /// No description provided for @inventoryItemThrowAwayAction.
  ///
  /// In en, this message translates to:
  /// **'Throw away'**
  String get inventoryItemThrowAwayAction;

  /// No description provided for @inventoryItemEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit inventory item'**
  String get inventoryItemEditTitle;

  /// No description provided for @inventoryItemUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Inventory item updated.'**
  String get inventoryItemUpdatedMessage;

  /// No description provided for @inventoryItemEditRequiresFullItem.
  ///
  /// In en, this message translates to:
  /// **'You can edit the item only while it is still fully available.'**
  String get inventoryItemEditRequiresFullItem;

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

  /// No description provided for @inventoryBarcodeScanUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Barcode scanning is currently supported on Android and iOS.'**
  String get inventoryBarcodeScanUnsupported;

  /// No description provided for @inventoryManualAddHint.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode. Then you can review the product, save it, or add nutrition values.'**
  String get inventoryManualAddHint;

  /// No description provided for @inventoryManualAddScanBarcodeAction.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get inventoryManualAddScanBarcodeAction;

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

  /// No description provided for @inventoryManualAddCandidateSourceLearned.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get inventoryManualAddCandidateSourceLearned;

  /// No description provided for @inventoryManualAddCandidateSourceOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get inventoryManualAddCandidateSourceOff;

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

  /// No description provided for @inventoryManualAddEatSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Added to diary'**
  String get inventoryManualAddEatSucceeded;

  /// No description provided for @inventoryManualAddPackageSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Package size'**
  String get inventoryManualAddPackageSizeLabel;

  /// No description provided for @inventoryManualAddResultActionInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryManualAddResultActionInventory;

  /// No description provided for @inventoryManualAddResultActionEat.
  ///
  /// In en, this message translates to:
  /// **'Eat'**
  String get inventoryManualAddResultActionEat;

  /// No description provided for @inventoryManualAddNutritionMissing.
  ///
  /// In en, this message translates to:
  /// **'Nutrition missing'**
  String get inventoryManualAddNutritionMissing;

  /// No description provided for @inventoryManualAddNutritionMissingCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories missing'**
  String get inventoryManualAddNutritionMissingCalories;

  /// No description provided for @inventoryManualAddNutritionIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Nutrition incomplete'**
  String get inventoryManualAddNutritionIncomplete;

  /// No description provided for @inventoryManualAddNutritionComplete.
  ///
  /// In en, this message translates to:
  /// **'Nutrition complete'**
  String get inventoryManualAddNutritionComplete;

  /// No description provided for @inventoryManualAddNutritionVerified.
  ///
  /// In en, this message translates to:
  /// **'Nutrition verified'**
  String get inventoryManualAddNutritionVerified;

  /// No description provided for @inventoryManualAddCreateOwnAction.
  ///
  /// In en, this message translates to:
  /// **'Create manually'**
  String get inventoryManualAddCreateOwnAction;

  /// No description provided for @inventoryManualAddEatNowRequiresNutrition.
  ///
  /// In en, this message translates to:
  /// **'Only available when nutrition values are present.'**
  String get inventoryManualAddEatNowRequiresNutrition;

  /// No description provided for @inventoryManualAddMissingBarcodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add barcode?'**
  String get inventoryManualAddMissingBarcodeTitle;

  /// No description provided for @inventoryManualAddMissingBarcodeMessage.
  ///
  /// In en, this message translates to:
  /// **'This product has no barcode yet. Enter one now so it can be recognized next time, or save it without a barcode.'**
  String get inventoryManualAddMissingBarcodeMessage;

  /// No description provided for @inventoryManualAddMissingBarcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get inventoryManualAddMissingBarcodeLabel;

  /// No description provided for @inventoryManualAddMissingBarcodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a barcode or save without one.'**
  String get inventoryManualAddMissingBarcodeRequired;

  /// No description provided for @inventoryManualAddMissingBarcodeSaveWithout.
  ///
  /// In en, this message translates to:
  /// **'Save without barcode'**
  String get inventoryManualAddMissingBarcodeSaveWithout;

  /// No description provided for @inventoryManualAddMissingBarcodeSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get inventoryManualAddMissingBarcodeSave;

  /// No description provided for @inventoryManualAddVoiceSearchStartTooltip.
  ///
  /// In en, this message translates to:
  /// **'Start voice search'**
  String get inventoryManualAddVoiceSearchStartTooltip;

  /// No description provided for @inventoryManualAddVoiceSearchStopTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop voice search'**
  String get inventoryManualAddVoiceSearchStopTooltip;

  /// No description provided for @inventoryManualAddVoiceSearchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice search is not currently supported on this device.'**
  String get inventoryManualAddVoiceSearchUnavailable;

  /// No description provided for @inventoryManualAddVoiceSearchPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Please allow microphone access to use voice search.'**
  String get inventoryManualAddVoiceSearchPermissionDenied;

  /// No description provided for @inventoryManualAddVoiceSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Voice search could not be started. Please try again.'**
  String get inventoryManualAddVoiceSearchFailed;

  /// No description provided for @inventoryManualAddAiSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Create food with AI'**
  String get inventoryManualAddAiSearchTitle;

  /// No description provided for @inventoryManualAddAiSearchPromptLabel.
  ///
  /// In en, this message translates to:
  /// **'Food description'**
  String get inventoryManualAddAiSearchPromptLabel;

  /// No description provided for @inventoryManualAddAiSearchPromptHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Chicken kebab'**
  String get inventoryManualAddAiSearchPromptHint;

  /// No description provided for @inventoryManualAddAiSearchGenerateAction.
  ///
  /// In en, this message translates to:
  /// **'Generate estimate'**
  String get inventoryManualAddAiSearchGenerateAction;

  /// No description provided for @inventoryManualAddAiSearchPromptRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a food description.'**
  String get inventoryManualAddAiSearchPromptRequired;

  /// No description provided for @inventoryManualAddAiSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate a food estimate. Please try again.'**
  String get inventoryManualAddAiSearchFailed;

  /// No description provided for @inventoryManualAddAiSearchReadOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Adjust weight or kcal per 100 g if the estimate feels off.'**
  String get inventoryManualAddAiSearchReadOnlyHint;

  /// No description provided for @inventoryManualAddAiSearchIngredientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ingredients for this portion'**
  String get inventoryManualAddAiSearchIngredientsTitle;

  /// No description provided for @inventoryManualAddAiSearchAmountColumn.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get inventoryManualAddAiSearchAmountColumn;

  /// No description provided for @inventoryManualAddAiSearchTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get inventoryManualAddAiSearchTotalLabel;

  /// No description provided for @inventoryManualAddAiSearchPer100CardTitle.
  ///
  /// In en, this message translates to:
  /// **'PER 100 G'**
  String get inventoryManualAddAiSearchPer100CardTitle;

  /// No description provided for @inventoryManualAddAiSearchPortionCardTitle.
  ///
  /// In en, this message translates to:
  /// **'YOUR PORTION'**
  String get inventoryManualAddAiSearchPortionCardTitle;

  /// No description provided for @inventoryManualAddAiSearchWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get inventoryManualAddAiSearchWeightLabel;

  /// No description provided for @inventoryManualAddAiSearchWeightRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid weight.'**
  String get inventoryManualAddAiSearchWeightRequired;

  /// No description provided for @inventoryManualAddAiSearchDensityTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust kcal density (per 100 g)'**
  String get inventoryManualAddAiSearchDensityTitle;

  /// No description provided for @inventoryManualAddAiSearchDensityHint.
  ///
  /// In en, this message translates to:
  /// **'Was the dish lighter or richer than expected? Scale calories per 100 g. Total nutrition updates automatically.'**
  String get inventoryManualAddAiSearchDensityHint;

  /// No description provided for @inventoryManualAddAiSearchDensityMinLabel.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal/100g (lighter)'**
  String inventoryManualAddAiSearchDensityMinLabel(Object kcal);

  /// No description provided for @inventoryManualAddAiSearchDensityBaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Base: {kcal}'**
  String inventoryManualAddAiSearchDensityBaseLabel(Object kcal);

  /// No description provided for @inventoryManualAddAiSearchDensityMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal/100g (richer)'**
  String inventoryManualAddAiSearchDensityMaxLabel(Object kcal);

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
  /// **'No items match your search or active filters.'**
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

  /// No description provided for @preparedMealAddIngredientAction.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get preparedMealAddIngredientAction;

  /// No description provided for @preparedMealRemoveIngredientAction.
  ///
  /// In en, this message translates to:
  /// **'Remove ingredient'**
  String get preparedMealRemoveIngredientAction;

  /// No description provided for @preparedMealEmptyIngredientsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add at least one ingredient before saving.'**
  String get preparedMealEmptyIngredientsMessage;

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
  /// **'{count, plural, =1{1 ingredient} other{{count} ingredients}}'**
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
  String preparedMealPortionsRemaining(String remaining, int total);

  /// No description provided for @preparedMealUnbundleAction.
  ///
  /// In en, this message translates to:
  /// **'Return to inventory'**
  String get preparedMealUnbundleAction;

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

  /// No description provided for @preparedMealTemplateRecipeGreetingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Simply copy the web address of your favorite recipe and we will read all ingredients automatically.'**
  String get preparedMealTemplateRecipeGreetingSubtitle;

  /// Title shown when prompting the user to paste from clipboard
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard ✨'**
  String get preparedMealTemplateClipboardTitle;

  /// Helper description explaining that tapping will access the clipboard
  ///
  /// In en, this message translates to:
  /// **'Tap here to check your clipboard for a recipe link.'**
  String get preparedMealTemplateClipboardPasteHelper;

  /// Success message when recipe is pasted
  ///
  /// In en, this message translates to:
  /// **'Pasted recipe from {url}!'**
  String preparedMealTemplateClipboardPasteSuccess(String url);

  /// Message shown when clipboard paste was clicked but no valid URL was found
  ///
  /// In en, this message translates to:
  /// **'No valid recipe link found in clipboard.'**
  String get preparedMealTemplateClipboardNoLinkFound;

  /// No description provided for @preparedMealTemplateAdvancedOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'More Options (Optional)'**
  String get preparedMealTemplateAdvancedOptionsTitle;

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

  /// No description provided for @preparedMealTemplateUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Template updated.'**
  String get preparedMealTemplateUpdatedMessage;

  /// No description provided for @kitchenUtensilsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Kitchen utensils'**
  String get kitchenUtensilsPageTitle;

  /// No description provided for @kitchenUtensilsOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Kitchen utensils'**
  String get kitchenUtensilsOpenAction;

  /// No description provided for @kitchenUtensilsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No kitchen utensils saved yet.'**
  String get kitchenUtensilsEmptyState;

  /// No description provided for @kitchenUtensilsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load kitchen utensils.'**
  String get kitchenUtensilsLoadFailed;

  /// No description provided for @kitchenUtensilAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add utensil'**
  String get kitchenUtensilAddAction;

  /// No description provided for @kitchenUtensilEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit utensil'**
  String get kitchenUtensilEditTitle;

  /// No description provided for @kitchenUtensilAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add utensil'**
  String get kitchenUtensilAddTitle;

  /// No description provided for @kitchenUtensilDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete utensil'**
  String get kitchenUtensilDeleteAction;

  /// No description provided for @kitchenUtensilSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Utensil saved.'**
  String get kitchenUtensilSavedMessage;

  /// No description provided for @kitchenUtensilUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Utensil updated.'**
  String get kitchenUtensilUpdatedMessage;

  /// No description provided for @kitchenUtensilDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Utensil deleted.'**
  String get kitchenUtensilDeletedMessage;

  /// No description provided for @kitchenUtensilUnnamedLabel.
  ///
  /// In en, this message translates to:
  /// **'Unnamed utensil'**
  String get kitchenUtensilUnnamedLabel;

  /// No description provided for @kitchenUtensilNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get kitchenUtensilNameLabel;

  /// No description provided for @kitchenUtensilWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (g)'**
  String get kitchenUtensilWeightLabel;

  /// No description provided for @kitchenUtensilWeightValue.
  ///
  /// In en, this message translates to:
  /// **'{grams} g'**
  String kitchenUtensilWeightValue(int grams);

  /// No description provided for @kitchenUtensilImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get kitchenUtensilImageLabel;

  /// No description provided for @kitchenUtensilAddImageAction.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get kitchenUtensilAddImageAction;

  /// No description provided for @kitchenUtensilChangeImageAction.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get kitchenUtensilChangeImageAction;

  /// No description provided for @kitchenUtensilRemoveImageAction.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get kitchenUtensilRemoveImageAction;

  /// No description provided for @kitchenUtensilImageCameraAction.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get kitchenUtensilImageCameraAction;

  /// No description provided for @kitchenUtensilImageHint.
  ///
  /// In en, this message translates to:
  /// **'Add a photo or name so you can recognize this utensil later.'**
  String get kitchenUtensilImageHint;

  /// No description provided for @kitchenUtensilImagePickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not pick the utensil photo.'**
  String get kitchenUtensilImagePickFailed;

  /// No description provided for @kitchenUtensilImageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Utensil photo could not be uploaded.'**
  String get kitchenUtensilImageUploadFailed;

  /// No description provided for @kitchenUtensilSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Utensil could not be saved.'**
  String get kitchenUtensilSaveFailed;

  /// No description provided for @kitchenUtensilDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Utensil could not be deleted.'**
  String get kitchenUtensilDeleteFailed;

  /// No description provided for @kitchenUtensilInvalidWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a weight greater than 0.'**
  String get kitchenUtensilInvalidWeight;

  /// No description provided for @kitchenUtensilIdentityRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a name or photo.'**
  String get kitchenUtensilIdentityRequired;

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

  /// No description provided for @preparedMealTemplatePortions.
  ///
  /// In en, this message translates to:
  /// **'{count} portions'**
  String preparedMealTemplatePortions(int count);

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

  /// No description provided for @caloriesBarcodeNotFoundOcrAction.
  ///
  /// In en, this message translates to:
  /// **'Scan nutrition label'**
  String get caloriesBarcodeNotFoundOcrAction;

  /// No description provided for @caloriesOcrScanning.
  ///
  /// In en, this message translates to:
  /// **'Reading nutrition label…'**
  String get caloriesOcrScanning;

  /// No description provided for @caloriesOcrScanningSemantics.
  ///
  /// In en, this message translates to:
  /// **'Captured nutrition label is being scanned'**
  String get caloriesOcrScanningSemantics;

  /// No description provided for @caloriesOcrFailed.
  ///
  /// In en, this message translates to:
  /// **'Nutrition label scan failed. Please try again.'**
  String get caloriesOcrFailed;

  /// No description provided for @caloriesOcrAppCheckThrottled.
  ///
  /// In en, this message translates to:
  /// **'Nutrition scan is temporarily blocked. Please try again later.'**
  String get caloriesOcrAppCheckThrottled;

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

  /// No description provided for @caloriesShiftGoalStartAction.
  ///
  /// In en, this message translates to:
  /// **'Move goal start'**
  String get caloriesShiftGoalStartAction;

  /// No description provided for @caloriesCalculatorAction.
  ///
  /// In en, this message translates to:
  /// **'Recalculate goal'**
  String get caloriesCalculatorAction;

  /// No description provided for @caloriesGoalSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save calorie goal.'**
  String get caloriesGoalSaveFailed;

  /// No description provided for @caloriesGoalStartDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Move goal start'**
  String get caloriesGoalStartDialogTitle;

  /// No description provided for @caloriesGoalStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get caloriesGoalStartDateLabel;

  /// No description provided for @caloriesGoalStartSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update goal start.'**
  String get caloriesGoalStartSaveFailed;

  /// No description provided for @caloriesCalculatorSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Calorie calculator'**
  String get caloriesCalculatorSheetTitle;

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

  /// No description provided for @settingsGoalArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal archive'**
  String get settingsGoalArchiveTitle;

  /// No description provided for @settingsGoalArchiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your current and previous goals'**
  String get settingsGoalArchiveSubtitle;

  /// No description provided for @goalArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal archive'**
  String get goalArchiveTitle;

  /// No description provided for @goalArchiveLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The goals could not be loaded.'**
  String get goalArchiveLoadFailed;

  /// No description provided for @goalArchiveRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get goalArchiveRetryAction;

  /// No description provided for @goalArchiveActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get goalArchiveActive;

  /// No description provided for @goalArchiveCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get goalArchiveCompleted;

  /// No description provided for @goalArchiveGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalArchiveGoalLabel;

  /// No description provided for @goalArchiveSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get goalArchiveSpeedLabel;

  /// No description provided for @goalArchiveSpeedValue.
  ///
  /// In en, this message translates to:
  /// **'{speed} kg/week'**
  String goalArchiveSpeedValue(String speed);

  /// No description provided for @goalArchiveStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get goalArchiveStartLabel;

  /// No description provided for @goalArchiveStartWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Starting weight'**
  String get goalArchiveStartWeightLabel;

  /// No description provided for @goalArchiveEndWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Ending weight'**
  String get goalArchiveEndWeightLabel;

  /// No description provided for @goalArchiveEstimatedEndLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated end'**
  String get goalArchiveEstimatedEndLabel;

  /// No description provided for @goalArchiveEndLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get goalArchiveEndLabel;

  /// No description provided for @goalArchiveReachedLabel.
  ///
  /// In en, this message translates to:
  /// **'Reached'**
  String get goalArchiveReachedLabel;

  /// No description provided for @goalArchiveUnlimited.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get goalArchiveUnlimited;

  /// No description provided for @goalArchiveSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Select one or more goals for one continuous timeline.'**
  String get goalArchiveSelectHint;

  /// No description provided for @goalArchiveOpenAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Open timeline'**
  String get goalArchiveOpenAnalytics;

  /// No description provided for @tdeeChartEstimateMarker.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get tdeeChartEstimateMarker;

  /// No description provided for @tdeeAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'TDEE & expenditure'**
  String get tdeeAnalyticsTitle;

  /// No description provided for @tdeeAnalyticsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the analysis.'**
  String get tdeeAnalyticsLoadFailed;

  /// No description provided for @tdeeAnalyticsNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data for this period.'**
  String get tdeeAnalyticsNotEnoughData;

  /// No description provided for @tdeeDateRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String tdeeDateRange(String start, String end);

  /// No description provided for @tdeeHeaderAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get tdeeHeaderAverage;

  /// No description provided for @tdeeChangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get tdeeChangeLabel;

  /// No description provided for @tdeeLegendFlux.
  ///
  /// In en, this message translates to:
  /// **'Flux range'**
  String get tdeeLegendFlux;

  /// No description provided for @tdeeLegendTdee.
  ///
  /// In en, this message translates to:
  /// **'Expenditure (TDEE)'**
  String get tdeeLegendTdee;

  /// No description provided for @tdeeRangeDays.
  ///
  /// In en, this message translates to:
  /// **'{count} d'**
  String tdeeRangeDays(int count);

  /// No description provided for @tdeeRangeMonth.
  ///
  /// In en, this message translates to:
  /// **'1 mo'**
  String get tdeeRangeMonth;

  /// No description provided for @tdeeRangeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tdeeRangeAll;

  /// No description provided for @tdeeInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights & changes'**
  String get tdeeInsightsTitle;

  /// No description provided for @tdeeInsightsDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String tdeeInsightsDays(int count);

  /// No description provided for @tdeeGoalAchieved.
  ///
  /// In en, this message translates to:
  /// **'🎉 Target weight of {target} already reached!'**
  String tdeeGoalAchieved(String target);

  /// No description provided for @tdeeGoalMovingAway.
  ///
  /// In en, this message translates to:
  /// **'⚠️ The current trend is moving away from your goal ({target}).'**
  String tdeeGoalMovingAway(String target);

  /// No description provided for @tdeeGoalProjection.
  ///
  /// In en, this message translates to:
  /// **'Goal {target}: expected {date}'**
  String tdeeGoalProjection(String target, String date);

  /// No description provided for @tdeeGoalRemaining.
  ///
  /// In en, this message translates to:
  /// **'In about {days} days at the current trend ({speed} kg/week)'**
  String tdeeGoalRemaining(int days, String speed);

  /// No description provided for @tdeeShowProjection.
  ///
  /// In en, this message translates to:
  /// **'Show forecast in chart'**
  String get tdeeShowProjection;

  /// No description provided for @tdeeWeightChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight trend & goal'**
  String get tdeeWeightChartTitle;

  /// No description provided for @tdeeWeightTargetLine.
  ///
  /// In en, this message translates to:
  /// **'Goal {weight} kg'**
  String tdeeWeightTargetLine(String weight);

  /// No description provided for @tdeeWeightTrendValue.
  ///
  /// In en, this message translates to:
  /// **'Trend {weight} kg'**
  String tdeeWeightTrendValue(String weight);

  /// No description provided for @tdeeWeightScaleValue.
  ///
  /// In en, this message translates to:
  /// **'Scale {weight} kg'**
  String tdeeWeightScaleValue(String weight);

  /// No description provided for @tdeeWeightStatTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend weight'**
  String get tdeeWeightStatTrend;

  /// No description provided for @tdeeWeightStatRate.
  ///
  /// In en, this message translates to:
  /// **'Per week'**
  String get tdeeWeightStatRate;

  /// No description provided for @caloriesCalculatorTargetWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Target weight (kg)'**
  String get caloriesCalculatorTargetWeightLabel;

  /// No description provided for @caloriesMaintainUntilTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintain weight until'**
  String get caloriesMaintainUntilTitle;

  /// No description provided for @caloriesMaintainUntilUnlimited.
  ///
  /// In en, this message translates to:
  /// **'No end date – until you choose a new goal'**
  String get caloriesMaintainUntilUnlimited;

  /// No description provided for @caloriesMaintainUntilChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose end date'**
  String get caloriesMaintainUntilChoose;

  /// No description provided for @caloriesMaintainUntilClear.
  ///
  /// In en, this message translates to:
  /// **'Remove end date'**
  String get caloriesMaintainUntilClear;

  /// No description provided for @caloriesGoalReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal reached!'**
  String get caloriesGoalReachedTitle;

  /// No description provided for @caloriesGoalReachedBody.
  ///
  /// In en, this message translates to:
  /// **'You reached your target weight. Would you like to continue the current 7-day run or set a new goal now?'**
  String get caloriesGoalReachedBody;

  /// No description provided for @caloriesGoalReachedContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue run'**
  String get caloriesGoalReachedContinue;

  /// No description provided for @caloriesGoalReachedNewGoal.
  ///
  /// In en, this message translates to:
  /// **'Set new goal'**
  String get caloriesGoalReachedNewGoal;

  /// No description provided for @caloriesNewGoalCurrentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current weight: {weight} kg'**
  String caloriesNewGoalCurrentWeight(String weight);

  /// No description provided for @caloriesWeeklyCheckInNewGoalAction.
  ///
  /// In en, this message translates to:
  /// **'Choose new goal'**
  String get caloriesWeeklyCheckInNewGoalAction;

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

  /// No description provided for @caloriesCalculatorGoalStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal start'**
  String get caloriesCalculatorGoalStartLabel;

  /// No description provided for @caloriesCalculatorGoalStartHint.
  ///
  /// In en, this message translates to:
  /// **'Your calorie target history begins from this day.'**
  String get caloriesCalculatorGoalStartHint;

  /// No description provided for @caloriesCalculatorGoalStartChangeAction.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get caloriesCalculatorGoalStartChangeAction;

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

  /// No description provided for @caloriesGoalStartFoodTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Did you track today\'s food?'**
  String get caloriesGoalStartFoodTrackingTitle;

  /// No description provided for @caloriesGoalStartFoodTrackingBody.
  ///
  /// In en, this message translates to:
  /// **'I found {entryCount} food entries today. Count today as a full tracking day for this new target?'**
  String caloriesGoalStartFoodTrackingBody(int entryCount);

  /// No description provided for @caloriesGoalStartNoFoodTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'No food tracked today'**
  String get caloriesGoalStartNoFoodTrackingTitle;

  /// No description provided for @caloriesGoalStartNoFoodTrackingBody.
  ///
  /// In en, this message translates to:
  /// **'Today will be a starter day. Your new target starts now, but weekly learning starts tomorrow.'**
  String get caloriesGoalStartNoFoodTrackingBody;

  /// No description provided for @caloriesGoalStartFoodTrackingNoAction.
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get caloriesGoalStartFoodTrackingNoAction;

  /// No description provided for @caloriesGoalStartFoodTrackingYesAction.
  ///
  /// In en, this message translates to:
  /// **'Count today'**
  String get caloriesGoalStartFoodTrackingYesAction;

  /// No description provided for @caloriesGoalStartFoodTrackingOkAction.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get caloriesGoalStartFoodTrackingOkAction;

  /// No description provided for @caloriesLearnedTdeeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Recalculate from learned TDEE'**
  String get caloriesLearnedTdeeSheetTitle;

  /// No description provided for @caloriesLearnedTdeeSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your last successful weekly check-in instead of an activity estimate.'**
  String get caloriesLearnedTdeeSheetSubtitle;

  /// No description provided for @caloriesLearnedTdeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Learned TDEE'**
  String get caloriesLearnedTdeeLabel;

  /// No description provided for @caloriesLearnedTdeeResultLabel.
  ///
  /// In en, this message translates to:
  /// **'New daily target'**
  String get caloriesLearnedTdeeResultLabel;

  /// No description provided for @caloriesLearnedTdeeUseProfileResetAction.
  ///
  /// In en, this message translates to:
  /// **'Use profile reset'**
  String get caloriesLearnedTdeeUseProfileResetAction;

  /// No description provided for @caloriesLearnedTdeeSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the learned TDEE target.'**
  String get caloriesLearnedTdeeSaveFailed;

  /// No description provided for @caloriesWeeklyCheckInDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly check-in'**
  String get caloriesWeeklyCheckInDialogTitle;

  /// No description provided for @caloriesWeeklyCheckInDialogReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Review your last 7 completed days. Your target already uses this learning automatically.'**
  String get caloriesWeeklyCheckInDialogReadyBody;

  /// No description provided for @caloriesWeeklyCheckInDialogBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'We still need a bit more data before this weekly summary is complete.'**
  String get caloriesWeeklyCheckInDialogBlockedBody;

  /// No description provided for @caloriesWeeklyCheckInDialogWindowLabel.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get caloriesWeeklyCheckInDialogWindowLabel;

  /// No description provided for @caloriesWeeklyCheckInDialogTrendLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight trend'**
  String get caloriesWeeklyCheckInDialogTrendLabel;

  /// No description provided for @caloriesWeeklyCheckInDialogMeasuredTotalTdeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Measured total TDEE'**
  String get caloriesWeeklyCheckInDialogMeasuredTotalTdeeLabel;

  /// No description provided for @caloriesWeeklyCheckInDialogNewTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'New target'**
  String get caloriesWeeklyCheckInDialogNewTargetLabel;

  /// No description provided for @caloriesWeeklyCheckInDialogLowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Low confidence: only start and end weights were available.'**
  String get caloriesWeeklyCheckInDialogLowConfidence;

  /// No description provided for @caloriesWeeklyCheckInBlockedUnstableWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight data was too noisy this week for a reliable TDEE update. Add steadier weigh-ins and try again.'**
  String get caloriesWeeklyCheckInBlockedUnstableWeight;

  /// No description provided for @caloriesWeeklyCheckInApplyAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get caloriesWeeklyCheckInApplyAction;

  /// No description provided for @caloriesWeeklyCheckInRejectAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get caloriesWeeklyCheckInRejectAction;

  /// No description provided for @caloriesWeeklyCheckInLaterAction.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get caloriesWeeklyCheckInLaterAction;

  /// No description provided for @caloriesWeeklyCheckInApplyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not close the weekly check-in.'**
  String get caloriesWeeklyCheckInApplyFailed;

  /// No description provided for @caloriesWeeklyCheckInRejectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reject the weekly check-in.'**
  String get caloriesWeeklyCheckInRejectFailed;

  /// No description provided for @caloriesWeeklyCheckInHintReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly check-in ready'**
  String get caloriesWeeklyCheckInHintReadyTitle;

  /// No description provided for @caloriesWeeklyCheckInHintReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your last 7 completed days are ready to review.'**
  String get caloriesWeeklyCheckInHintReadyBody;

  /// No description provided for @caloriesWeeklyCheckInHintBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly check-in needs data'**
  String get caloriesWeeklyCheckInHintBlockedTitle;

  /// No description provided for @caloriesWeeklyCheckInHintBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Finish the missing intake or weight data to complete the summary.'**
  String get caloriesWeeklyCheckInHintBlockedBody;

  /// No description provided for @caloriesWeeklyCheckInHintContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get caloriesWeeklyCheckInHintContinueAction;

  /// No description provided for @caloriesWeeklyCheckInHintStaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Target getting stale'**
  String get caloriesWeeklyCheckInHintStaleTitle;

  /// No description provided for @caloriesWeeklyCheckInHintStaleBody.
  ///
  /// In en, this message translates to:
  /// **'Use your next weekly check-in to keep your target current.'**
  String get caloriesWeeklyCheckInHintStaleBody;

  /// No description provided for @caloriesWeeklyCheckInHintUrgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Target needs refresh'**
  String get caloriesWeeklyCheckInHintUrgentTitle;

  /// No description provided for @caloriesWeeklyCheckInHintUrgentBody.
  ///
  /// In en, this message translates to:
  /// **'You have been using older target data for a while now.'**
  String get caloriesWeeklyCheckInHintUrgentBody;

  /// No description provided for @caloriesWeeklyCheckInShowAgainAction.
  ///
  /// In en, this message translates to:
  /// **'Show weekly check-in'**
  String get caloriesWeeklyCheckInShowAgainAction;

  /// No description provided for @caloriesWeeklyCheckInShowAgainFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reopen the weekly check-in.'**
  String get caloriesWeeklyCheckInShowAgainFailed;

  /// No description provided for @caloriesWeeklyCheckInSkipDayAction.
  ///
  /// In en, this message translates to:
  /// **'Mark day as skipped'**
  String get caloriesWeeklyCheckInSkipDayAction;

  /// No description provided for @caloriesWeeklyCheckInUnskipDayAction.
  ///
  /// In en, this message translates to:
  /// **'Undo skipped day'**
  String get caloriesWeeklyCheckInUnskipDayAction;

  /// No description provided for @caloriesWeeklyCheckInAutoAdjustedHint.
  ///
  /// In en, this message translates to:
  /// **'Target updated from weekly check-in:'**
  String get caloriesWeeklyCheckInAutoAdjustedHint;

  /// No description provided for @caloriesWeeklyCheckInTrackMissingWeightAction.
  ///
  /// In en, this message translates to:
  /// **'Add missing weight'**
  String get caloriesWeeklyCheckInTrackMissingWeightAction;

  /// No description provided for @caloriesWeeklyCheckInBlockedMissingIntake.
  ///
  /// In en, this message translates to:
  /// **'One or more days in this window have no intake yet. Log them or mark 1 or 2 empty days as skipped.'**
  String get caloriesWeeklyCheckInBlockedMissingIntake;

  /// No description provided for @caloriesWeeklyCheckInBlockedTooManyMissingIntake.
  ///
  /// In en, this message translates to:
  /// **'This window has 3 or more missing intake days. We will keep your last learned target until you log more complete days.'**
  String get caloriesWeeklyCheckInBlockedTooManyMissingIntake;

  /// No description provided for @caloriesWeeklyCheckInBlockedSkippedWithoutAverage.
  ///
  /// In en, this message translates to:
  /// **'A skipped day needs earlier logged intake in the same window before we can estimate it.'**
  String get caloriesWeeklyCheckInBlockedSkippedWithoutAverage;

  /// No description provided for @caloriesWeeklyCheckInBlockedMissingStartWeightOn.
  ///
  /// In en, this message translates to:
  /// **'Add a weight for the first day of this window ({date}) to continue.'**
  String caloriesWeeklyCheckInBlockedMissingStartWeightOn(Object date);

  /// No description provided for @caloriesWeeklyCheckInBlockedMissingEndWeightOn.
  ///
  /// In en, this message translates to:
  /// **'Add a weight for the last day of this window ({date}) to continue.'**
  String caloriesWeeklyCheckInBlockedMissingEndWeightOn(Object date);

  /// No description provided for @caloriesWeeklyCheckInBlockedMissingWeightDates.
  ///
  /// In en, this message translates to:
  /// **'Add weights for these dates to continue: {dates}.'**
  String caloriesWeeklyCheckInBlockedMissingWeightDates(Object dates);

  /// No description provided for @caloriesGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get caloriesGoalLabel;

  /// No description provided for @caloriesDebugActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Calorie debug actions'**
  String get caloriesDebugActionsTooltip;

  /// No description provided for @caloriesDebugDumpAction.
  ///
  /// In en, this message translates to:
  /// **'Download calorie debug TXT'**
  String get caloriesDebugDumpAction;

  /// No description provided for @caloriesDebugDumpSaveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save calorie debug TXT'**
  String get caloriesDebugDumpSaveDialogTitle;

  /// No description provided for @caloriesDebugDumpPrinted.
  ///
  /// In en, this message translates to:
  /// **'Downloaded calorie debug TXT ({rowCount} rows).'**
  String caloriesDebugDumpPrinted(int rowCount);

  /// No description provided for @caloriesDebugDumpCanceled.
  ///
  /// In en, this message translates to:
  /// **'Calorie debug TXT download canceled.'**
  String get caloriesDebugDumpCanceled;

  /// No description provided for @caloriesDebugDumpFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not download calorie debug TXT.'**
  String get caloriesDebugDumpFailed;

  /// No description provided for @caloriesSettingsDebugDumpAction.
  ///
  /// In en, this message translates to:
  /// **'Print calorie settings JSON'**
  String get caloriesSettingsDebugDumpAction;

  /// No description provided for @caloriesSettingsDebugDumpPrinted.
  ///
  /// In en, this message translates to:
  /// **'Printed calorie settings debug dump ({entryCount} goal entries).'**
  String caloriesSettingsDebugDumpPrinted(int entryCount);

  /// No description provided for @caloriesSettingsDebugDumpFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not print calorie settings debug dump.'**
  String get caloriesSettingsDebugDumpFailed;

  /// No description provided for @caloriesWeeklyCheckInDebugDumpAction.
  ///
  /// In en, this message translates to:
  /// **'Print weekly check-in state'**
  String get caloriesWeeklyCheckInDebugDumpAction;

  /// No description provided for @caloriesWeeklyCheckInDebugDumpPrinted.
  ///
  /// In en, this message translates to:
  /// **'Printed weekly check-in debug dump.'**
  String get caloriesWeeklyCheckInDebugDumpPrinted;

  /// No description provided for @caloriesWeeklyCheckInDebugDumpFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not print weekly check-in debug dump.'**
  String get caloriesWeeklyCheckInDebugDumpFailed;

  /// No description provided for @burnWeekRunOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Run over'**
  String get burnWeekRunOverTitle;

  /// No description provided for @burnWeekRunRestartsOn.
  ///
  /// In en, this message translates to:
  /// **'Fresh run starts on {date}.'**
  String burnWeekRunRestartsOn(Object date);

  /// No description provided for @burnWeekPracticeDayBadge.
  ///
  /// In en, this message translates to:
  /// **'Practice day · counts from {date}'**
  String burnWeekPracticeDayBadge(Object date);

  /// No description provided for @burnWeekWeekDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Week {week} day {day}'**
  String burnWeekWeekDayLabel(int week, int day);

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

  /// No description provided for @caloriesCarbsShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get caloriesCarbsShortLabel;

  /// No description provided for @caloriesFatLabel.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get caloriesFatLabel;

  /// No description provided for @diaryWeightDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Set weight for {date}'**
  String diaryWeightDialogTitle(String date);

  /// No description provided for @diaryWeightSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get diaryWeightSaveAction;

  /// No description provided for @diaryWeightClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear override'**
  String get diaryWeightClearAction;

  /// No description provided for @diaryWeightSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save weight.'**
  String get diaryWeightSaveFailed;

  /// No description provided for @diaryWeightClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not clear manual weight.'**
  String get diaryWeightClearFailed;

  /// No description provided for @caloriesRemoveEntryAction.
  ///
  /// In en, this message translates to:
  /// **'Remove entry'**
  String get caloriesRemoveEntryAction;

  /// No description provided for @caloriesRemoveEntryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove entry'**
  String get caloriesRemoveEntryDialogTitle;

  /// No description provided for @caloriesRemoveEntryDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Would you like to return this food to the inventory?'**
  String get caloriesRemoveEntryDialogMessage;

  /// No description provided for @caloriesRemoveEntryPreparedMealMessage.
  ///
  /// In en, this message translates to:
  /// **'Would you like to return this meal to the inventory?'**
  String get caloriesRemoveEntryPreparedMealMessage;

  /// No description provided for @caloriesRemoveEntryOnlyAction.
  ///
  /// In en, this message translates to:
  /// **'Delete from diary only'**
  String get caloriesRemoveEntryOnlyAction;

  /// No description provided for @caloriesRemoveAndRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Return to inventory'**
  String get caloriesRemoveAndRestoreAction;

  /// No description provided for @caloriesReturnPreparedMealFailed.
  ///
  /// In en, this message translates to:
  /// **'The meal could not be returned to inventory.'**
  String get caloriesReturnPreparedMealFailed;

  /// No description provided for @caloriesDeleteRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'The food could not be added back to inventory.'**
  String get caloriesDeleteRestoreFailed;

  /// No description provided for @caloriesMissingInventorySourceDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Food no longer in inventory'**
  String get caloriesMissingInventorySourceDialogTitle;

  /// No description provided for @caloriesMissingInventorySourceDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is no longer in inventory, so it cannot be returned. Delete it from the diary only?'**
  String caloriesMissingInventorySourceDialogMessage(String name);

  /// No description provided for @caloriesDeleteDiaryOnlyConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete from diary'**
  String get caloriesDeleteDiaryOnlyConfirmAction;

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

  /// No description provided for @caloriesEntryDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Calorie entry details'**
  String get caloriesEntryDetailsTitle;

  /// No description provided for @caloriesEntryUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Entry updated'**
  String get caloriesEntryUpdatedMessage;

  /// No description provided for @caloriesNutritionTableNutrient.
  ///
  /// In en, this message translates to:
  /// **'Nutrient'**
  String get caloriesNutritionTableNutrient;

  /// No description provided for @caloriesNutritionTableEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get caloriesNutritionTableEnergy;

  /// No description provided for @caloriesUnitKilojoule.
  ///
  /// In en, this message translates to:
  /// **'kJ'**
  String get caloriesUnitKilojoule;

  /// No description provided for @caloriesNutritionTableSaturatedFat.
  ///
  /// In en, this message translates to:
  /// **'of which saturates'**
  String get caloriesNutritionTableSaturatedFat;

  /// No description provided for @caloriesNutritionTablePolyunsaturatedFat.
  ///
  /// In en, this message translates to:
  /// **'of which polyunsaturates'**
  String get caloriesNutritionTablePolyunsaturatedFat;

  /// No description provided for @caloriesNutritionTableSugar.
  ///
  /// In en, this message translates to:
  /// **'of which sugars'**
  String get caloriesNutritionTableSugar;

  /// No description provided for @caloriesNutritionTableFiber.
  ///
  /// In en, this message translates to:
  /// **'Fibre'**
  String get caloriesNutritionTableFiber;

  /// No description provided for @caloriesNutritionTableSalt.
  ///
  /// In en, this message translates to:
  /// **'Salt'**
  String get caloriesNutritionTableSalt;

  /// No description provided for @caloriesEntryDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Entry removed'**
  String get caloriesEntryDeletedMessage;

  /// No description provided for @caloriesEntryReturnedToInventoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Returned to inventory'**
  String get caloriesEntryReturnedToInventoryMessage;

  /// No description provided for @caloriesEatAgainDoneMessage.
  ///
  /// In en, this message translates to:
  /// **'Logged again'**
  String get caloriesEatAgainDoneMessage;

  /// No description provided for @caloriesEatAgainAction.
  ///
  /// In en, this message translates to:
  /// **'Log again'**
  String get caloriesEatAgainAction;

  /// No description provided for @caloriesEntryGoalShare.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of your daily goal'**
  String caloriesEntryGoalShare(int percent);

  /// No description provided for @caloriesEntryPer100Label.
  ///
  /// In en, this message translates to:
  /// **'Per 100 {unit}'**
  String caloriesEntryPer100Label(String unit);

  /// No description provided for @caloriesEntryAmountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Change amount'**
  String get caloriesEntryAmountDialogTitle;

  /// No description provided for @caloriesEntryAmountStockExhaustedMessage.
  ///
  /// In en, this message translates to:
  /// **'Amount changed. Your inventory ran out, so it is empty now.'**
  String get caloriesEntryAmountStockExhaustedMessage;

  /// No description provided for @caloriesEntryAmountSourceMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'Amount changed. The product is no longer in your inventory.'**
  String get caloriesEntryAmountSourceMissingMessage;

  /// No description provided for @caloriesEditAmountTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change amount'**
  String get caloriesEditAmountTooltip;

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

  /// No description provided for @caloriesPer100SaturatedFatLabel.
  ///
  /// In en, this message translates to:
  /// **'Saturated fat (g)'**
  String get caloriesPer100SaturatedFatLabel;

  /// No description provided for @caloriesPer100PolyunsaturatedFatLabel.
  ///
  /// In en, this message translates to:
  /// **'Polyunsaturated fat (g)'**
  String get caloriesPer100PolyunsaturatedFatLabel;

  /// No description provided for @caloriesPer100SugarLabel.
  ///
  /// In en, this message translates to:
  /// **'Sugar (g)'**
  String get caloriesPer100SugarLabel;

  /// No description provided for @caloriesPer100FiberLabel.
  ///
  /// In en, this message translates to:
  /// **'Fiber (g)'**
  String get caloriesPer100FiberLabel;

  /// No description provided for @caloriesPer100SaltLabel.
  ///
  /// In en, this message translates to:
  /// **'Salt (g)'**
  String get caloriesPer100SaltLabel;

  /// No description provided for @inventoryReceiptReviewManualAddNutritionAction.
  ///
  /// In en, this message translates to:
  /// **'Add more nutrients'**
  String get inventoryReceiptReviewManualAddNutritionAction;

  /// No description provided for @inventoryReceiptReviewManualNutritionValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get inventoryReceiptReviewManualNutritionValueLabel;

  /// No description provided for @inventoryReceiptReviewManualNutritionUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get inventoryReceiptReviewManualNutritionUnitLabel;

  /// No description provided for @inventoryReceiptReviewManualNutritionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Nutrient'**
  String get inventoryReceiptReviewManualNutritionTypeLabel;

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

  /// No description provided for @caloriesUnitKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get caloriesUnitKcal;

  /// No description provided for @caloriesUnitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get caloriesUnitKg;

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

  /// No description provided for @diaryTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get diaryTodayTitle;

  /// No description provided for @diaryYesterdayTitle.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get diaryYesterdayTitle;

  /// No description provided for @diaryDayRelativeWeekday.
  ///
  /// In en, this message translates to:
  /// **'{relative} · {weekday}'**
  String diaryDayRelativeWeekday(String relative, String weekday);

  /// No description provided for @diaryDayTypeTraining.
  ///
  /// In en, this message translates to:
  /// **'Training day'**
  String get diaryDayTypeTraining;

  /// No description provided for @diaryDayTypeRest.
  ///
  /// In en, this message translates to:
  /// **'Rest day'**
  String get diaryDayTypeRest;

  /// No description provided for @diaryDayTypePause.
  ///
  /// In en, this message translates to:
  /// **'Pause day'**
  String get diaryDayTypePause;

  /// No description provided for @diaryDayTypeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose day type'**
  String get diaryDayTypeSheetTitle;

  /// No description provided for @diaryDayTypeSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Adjust your calorie target to your activity plan.'**
  String get diaryDayTypeSheetBody;

  /// No description provided for @diaryDayTypeTrainingOffsetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'+{kcal} kcal higher calorie target'**
  String diaryDayTypeTrainingOffsetSubtitle(int kcal);

  /// No description provided for @diaryDayTypeTrainingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Training day (calorie target active)'**
  String get diaryDayTypeTrainingSubtitle;

  /// No description provided for @diaryDayTypeRestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Balanced calorie target for recovery'**
  String get diaryDayTypeRestSubtitle;

  /// No description provided for @diaryDayTypePauseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Neutral day (vacation, illness). Doesn\'t break your streak.'**
  String get diaryDayTypePauseSubtitle;

  /// No description provided for @diaryMealsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Meals could not be loaded'**
  String get diaryMealsLoadFailed;

  /// No description provided for @diaryQuickEatSourceInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get diaryQuickEatSourceInventory;

  /// No description provided for @diaryQuickEatSourceBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get diaryQuickEatSourceBarcode;

  /// No description provided for @diaryQuickEatSourceManualSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get diaryQuickEatSourceManualSearch;

  /// No description provided for @diaryQuickEatSourceAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get diaryQuickEatSourceAi;

  /// No description provided for @diaryQuickEatInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Eat from inventory'**
  String get diaryQuickEatInventoryTitle;

  /// No description provided for @diaryQuickEatInventoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No available food in inventory.'**
  String get diaryQuickEatInventoryEmpty;

  /// No description provided for @diaryBalanceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Balance could not be loaded'**
  String get diaryBalanceLoadFailed;

  /// No description provided for @diaryNutritionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Nutrition could not be loaded'**
  String get diaryNutritionLoadFailed;

  /// No description provided for @diaryNutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Macronutrients'**
  String get diaryNutritionTitle;

  /// No description provided for @diaryBalanceEatenLabel.
  ///
  /// In en, this message translates to:
  /// **'Eaten'**
  String get diaryBalanceEatenLabel;

  /// No description provided for @diaryBalanceLeftTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Left today'**
  String get diaryBalanceLeftTodayLabel;

  /// No description provided for @diaryBalanceOverGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Over goal'**
  String get diaryBalanceOverGoalLabel;

  /// No description provided for @diaryBalanceShowDetails.
  ///
  /// In en, this message translates to:
  /// **'Show all numbers'**
  String get diaryBalanceShowDetails;

  /// No description provided for @diaryBalanceHideDetails.
  ///
  /// In en, this message translates to:
  /// **'Show fewer numbers'**
  String get diaryBalanceHideDetails;

  /// No description provided for @diaryMealsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing eaten yet'**
  String get diaryMealsEmptyTitle;

  /// No description provided for @diaryMealsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Log food below with the barcode, inventory, search, or AI.'**
  String get diaryMealsEmptyHint;

  /// No description provided for @diaryBalanceEatenAmount.
  ///
  /// In en, this message translates to:
  /// **'{kcal} eaten'**
  String diaryBalanceEatenAmount(String kcal);

  /// No description provided for @diaryBalanceOfTarget.
  ///
  /// In en, this message translates to:
  /// **'of {kcal}'**
  String diaryBalanceOfTarget(String kcal);

  /// No description provided for @diaryBalanceScaleTarget.
  ///
  /// In en, this message translates to:
  /// **'Goal {kcal}'**
  String diaryBalanceScaleTarget(String kcal);

  /// No description provided for @diaryMacroLeftSuffix.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get diaryMacroLeftSuffix;

  /// No description provided for @diaryMacroOverSuffix.
  ///
  /// In en, this message translates to:
  /// **'over'**
  String get diaryMacroOverSuffix;

  /// No description provided for @diaryMacroEatenOfTarget.
  ///
  /// In en, this message translates to:
  /// **'{eaten} / {target} g'**
  String diaryMacroEatenOfTarget(String eaten, String target);

  /// No description provided for @diaryAmountLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String diaryAmountLeft(String amount);

  /// No description provided for @diaryAmountOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} over'**
  String diaryAmountOver(String amount);

  /// No description provided for @diaryMealEntryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry} other{{count} entries}}'**
  String diaryMealEntryCount(int count);

  /// No description provided for @progressTdeeTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'TDEE and weight trend'**
  String get progressTdeeTrendTitle;

  /// No description provided for @progressTdeeTrendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Burn curve, fluctuation range and goal forecast'**
  String get progressTdeeTrendSubtitle;

  /// No description provided for @diaryBalanceBaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get diaryBalanceBaseLabel;

  /// No description provided for @diaryBalancePlannedWithCarryoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Planned with carryover'**
  String get diaryBalancePlannedWithCarryoverLabel;

  /// No description provided for @diaryBalanceWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week {week}'**
  String diaryBalanceWeekLabel(Object week);

  /// No description provided for @diaryBalanceDayProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String diaryBalanceDayProgressLabel(Object day, Object total);

  /// No description provided for @diaryBalanceTargetMarkerLabel.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get diaryBalanceTargetMarkerLabel;

  /// No description provided for @diaryBalanceRealEatenLabel.
  ///
  /// In en, this message translates to:
  /// **'Real {kcal}'**
  String diaryBalanceRealEatenLabel(Object kcal);

  /// No description provided for @diaryBalanceBufferAdjustmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Buffer {kcal}'**
  String diaryBalanceBufferAdjustmentLabel(Object kcal);

  /// No description provided for @diaryBalanceRealLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'Real {kcal}'**
  String diaryBalanceRealLeftLabel(Object kcal);

  /// No description provided for @diaryBalancePauseDayValue.
  ///
  /// In en, this message translates to:
  /// **'Pause day'**
  String get diaryBalancePauseDayValue;

  /// No description provided for @diaryBalancePauseDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ignored for learning'**
  String get diaryBalancePauseDaySubtitle;

  /// No description provided for @diaryBalanceBaseGoalShort.
  ///
  /// In en, this message translates to:
  /// **'Base {value}'**
  String diaryBalanceBaseGoalShort(String value);

  /// No description provided for @diaryBalanceCarryoverShort.
  ///
  /// In en, this message translates to:
  /// **'Carryover {value}'**
  String diaryBalanceCarryoverShort(String value);

  /// No description provided for @diaryBudgetDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily budget details'**
  String get diaryBudgetDetailsTitle;

  /// No description provided for @diaryBudgetDetailsButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get diaryBudgetDetailsButtonLabel;

  /// No description provided for @diaryBudgetDetailsTodaySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s calculation'**
  String get diaryBudgetDetailsTodaySectionTitle;

  /// No description provided for @diaryBudgetDetailsWeeklyAverageGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Base goal (weekly average)'**
  String get diaryBudgetDetailsWeeklyAverageGoalLabel;

  /// No description provided for @diaryBudgetDetailsTrainingDayAdjustmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Training day adjustment'**
  String get diaryBudgetDetailsTrainingDayAdjustmentLabel;

  /// No description provided for @diaryBudgetDetailsRestDayAdjustmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Rest day adjustment'**
  String get diaryBudgetDetailsRestDayAdjustmentLabel;

  /// No description provided for @diaryBudgetDetailsBaseGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Base daily goal'**
  String get diaryBudgetDetailsBaseGoalLabel;

  /// No description provided for @diaryBudgetDetailsBaseGoalWithoutActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Base daily goal (without activity)'**
  String get diaryBudgetDetailsBaseGoalWithoutActivityLabel;

  /// No description provided for @diaryBudgetDetailsExpectedActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected activity'**
  String get diaryBudgetDetailsExpectedActivityLabel;

  /// No description provided for @diaryBudgetDetailsCarryoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Carryover from previous days'**
  String get diaryBudgetDetailsCarryoverLabel;

  /// No description provided for @diaryBudgetDetailsEffectiveGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Effective daily goal'**
  String get diaryBudgetDetailsEffectiveGoalLabel;

  /// No description provided for @diaryBudgetDetailsEatenLabel.
  ///
  /// In en, this message translates to:
  /// **'Food eaten so far'**
  String get diaryBudgetDetailsEatenLabel;

  /// No description provided for @diaryBudgetDetailsLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'Left today'**
  String get diaryBudgetDetailsLeftLabel;

  /// No description provided for @diaryBudgetDetailsCarryoverSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Carryover origin'**
  String get diaryBudgetDetailsCarryoverSectionTitle;

  /// No description provided for @diaryBudgetDetailsCarryoverExplanation.
  ///
  /// In en, this message translates to:
  /// **'Carryover is the balance of completed days spread across the remaining days in this 7-day run.'**
  String get diaryBudgetDetailsCarryoverExplanation;

  /// No description provided for @diaryBudgetDetailsDaySavedLabel.
  ///
  /// In en, this message translates to:
  /// **'saved'**
  String get diaryBudgetDetailsDaySavedLabel;

  /// No description provided for @diaryBudgetDetailsDayOverLabel.
  ///
  /// In en, this message translates to:
  /// **'over'**
  String get diaryBudgetDetailsDayOverLabel;

  /// No description provided for @diaryBudgetDetailsDayExactLabel.
  ///
  /// In en, this message translates to:
  /// **'on target'**
  String get diaryBudgetDetailsDayExactLabel;

  /// No description provided for @diaryBudgetDetailsPauseDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Pause day'**
  String get diaryBudgetDetailsPauseDayLabel;

  /// No description provided for @diaryBudgetDetailsTotalCarryoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Total previous-day balance'**
  String get diaryBudgetDetailsTotalCarryoverLabel;

  /// No description provided for @diaryBudgetDetailsDistributionFormula.
  ///
  /// In en, this message translates to:
  /// **'{total} spread across {days} remaining days = {daily} / day'**
  String diaryBudgetDetailsDistributionFormula(
    String total,
    int days,
    String daily,
  );

  /// No description provided for @diaryBudgetDetailsMacroAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Macro impact: Protein {protein} · Carbs {carbs} · Fat {fat}'**
  String diaryBudgetDetailsMacroAdjustment(
    String protein,
    String carbs,
    String fat,
  );

  /// No description provided for @diaryBudgetDetailsSafetyCapActive.
  ///
  /// In en, this message translates to:
  /// **'Safety limit active: Daily reduction was capped to prevent extreme restriction.'**
  String get diaryBudgetDetailsSafetyCapActive;

  /// No description provided for @diaryBudgetDetailsNoPreviousDays.
  ///
  /// In en, this message translates to:
  /// **'This is the first day of your active run. There is no carryover yet.'**
  String get diaryBudgetDetailsNoPreviousDays;

  /// No description provided for @diaryActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get diaryActivityTitle;

  /// No description provided for @diaryActivityWeightLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Activity and weight could not be loaded'**
  String get diaryActivityWeightLoadFailed;

  /// No description provided for @diaryWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get diaryWeightTitle;

  /// No description provided for @diarySevenDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get diarySevenDaysLabel;

  /// No description provided for @diaryProfileWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile: {weight} kg'**
  String diaryProfileWeightLabel(String weight);

  /// No description provided for @diaryWeightMissingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Log your weight for better calculation.'**
  String get diaryWeightMissingPrompt;

  /// No description provided for @diaryWeightTrackNowAction.
  ///
  /// In en, this message translates to:
  /// **'Track now'**
  String get diaryWeightTrackNowAction;

  /// No description provided for @diaryWeightEmpty.
  ///
  /// In en, this message translates to:
  /// **'No weights'**
  String get diaryWeightEmpty;

  /// No description provided for @diaryWeightAddAction.
  ///
  /// In en, this message translates to:
  /// **'Log weight'**
  String get diaryWeightAddAction;

  /// No description provided for @diaryOkAction.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get diaryOkAction;

  /// No description provided for @diaryCounterLabel.
  ///
  /// In en, this message translates to:
  /// **'x {count}'**
  String diaryCounterLabel(int count);

  /// No description provided for @diaryStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get diaryStepsTitle;

  /// No description provided for @diaryStepsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Steps could not be loaded'**
  String get diaryStepsLoadFailed;

  /// No description provided for @diaryStepDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Step details'**
  String get diaryStepDetailsTitle;

  /// No description provided for @diaryStepsDuringOtherActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Other active steps'**
  String get diaryStepsDuringOtherActivityLabel;

  /// No description provided for @caloriesBundlePortions.
  ///
  /// In en, this message translates to:
  /// **'{consumed}/{total} portions'**
  String caloriesBundlePortions(String consumed, int total);

  /// No description provided for @homeSettingsActionContextPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Settings action coming soon.'**
  String get homeSettingsActionContextPlaceholder;

  /// No description provided for @settingsManagePreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your preferences'**
  String get settingsManagePreferencesSubtitle;

  /// No description provided for @settingsProfileGuestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get settingsProfileGuestSubtitle;

  /// No description provided for @settingsAccountHouseholdSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get settingsAccountHouseholdSectionTitle;

  /// No description provided for @settingsHealthGoalsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Health & Goals'**
  String get settingsHealthGoalsSectionTitle;

  /// No description provided for @settingsMacroGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Macro Goals'**
  String get settingsMacroGoalsTitle;

  /// No description provided for @settingsMacroGoalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Protein, fat & carbohydrate distribution'**
  String get settingsMacroGoalsSubtitle;

  /// No description provided for @settingsMacroGoalsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Macro Distribution'**
  String get settingsMacroGoalsSheetTitle;

  /// No description provided for @settingsMacroGoalsSportActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Sport & workouts active'**
  String get settingsMacroGoalsSportActiveLabel;

  /// No description provided for @settingsMacroGoalsSportActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjusts recommendations for training'**
  String get settingsMacroGoalsSportActiveSubtitle;

  /// No description provided for @settingsMacroGoalsProteinLabel.
  ///
  /// In en, this message translates to:
  /// **'Protein multiplier'**
  String get settingsMacroGoalsProteinLabel;

  /// No description provided for @settingsMacroGoalsFatLabel.
  ///
  /// In en, this message translates to:
  /// **'Fat multiplier'**
  String get settingsMacroGoalsFatLabel;

  /// No description provided for @settingsMacroGoalsCarbsAutoLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates are filled with remaining calories'**
  String get settingsMacroGoalsCarbsAutoLabel;

  /// No description provided for @macroAdjustedWeightNote.
  ///
  /// In en, this message translates to:
  /// **'For protein and fat we use an adjusted body weight of {weight} kg, because fat tissue needs hardly any protein. These are guidelines, not medical advice. With severe overweight or conditions such as diabetes or kidney disease, talk to your doctor about your diet.'**
  String macroAdjustedWeightNote(String weight);

  /// No description provided for @settingsMacroGoalsPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily target preview'**
  String get settingsMacroGoalsPreviewTitle;

  /// No description provided for @settingsMacroGoalsResetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset to recommendations'**
  String get settingsMacroGoalsResetButton;

  /// No description provided for @settingsMacroGoalsSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsMacroGoalsSaveButton;

  /// No description provided for @settingsMacroGoalsGramPerKg.
  ///
  /// In en, this message translates to:
  /// **'{value} g/kg'**
  String settingsMacroGoalsGramPerKg(String value);

  /// No description provided for @settingsMacroGoalsWarningBudgetExceeded.
  ///
  /// In en, this message translates to:
  /// **'Protein and fat exceed the daily calorie goal'**
  String get settingsMacroGoalsWarningBudgetExceeded;

  /// No description provided for @settingsAppearanceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceSectionTitle;

  /// No description provided for @settingsAppSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsAppSectionTitle;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get settingsLanguageGerman;

  /// No description provided for @settingsDiaryGoalSetGoalFirst.
  ///
  /// In en, this message translates to:
  /// **'Set a goal first'**
  String get settingsDiaryGoalSetGoalFirst;

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

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions and data controls'**
  String get settingsPrivacySubtitle;

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

  /// No description provided for @settingsHealthConnectPlatformTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Connect'**
  String get settingsHealthConnectPlatformTitle;

  /// No description provided for @settingsHealthConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect health'**
  String get settingsHealthConnectTitle;

  /// No description provided for @settingsHealthConnectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow YAMT to read and save your weight in Health Connect.'**
  String get settingsHealthConnectSubtitle;

  /// No description provided for @settingsAppleHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Apple Health'**
  String get settingsAppleHealthTitle;

  /// No description provided for @settingsAppleHealthConnectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow YAMT to read and save your weight in Apple Health.'**
  String get settingsAppleHealthConnectSubtitle;

  /// No description provided for @settingsHealthHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow older Health Connect history so earlier weigh-ins can load.'**
  String get settingsHealthHistorySubtitle;

  /// No description provided for @settingsHealthInstallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Install Health Connect before you can connect health data here.'**
  String get settingsHealthInstallSubtitle;

  /// No description provided for @settingsHealthDisconnectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Health Connect access for YAMT.'**
  String get settingsHealthDisconnectSubtitle;

  /// No description provided for @settingsAppleHealthDisconnectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stop using Apple Health in YAMT.'**
  String get settingsAppleHealthDisconnectSubtitle;

  /// No description provided for @settingsHealthDisconnectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect health access?'**
  String get settingsHealthDisconnectDialogTitle;

  /// No description provided for @settingsHealthDisconnectDialogBody.
  ///
  /// In en, this message translates to:
  /// **'YAMT will lose access to Health Connect until you connect it again.'**
  String get settingsHealthDisconnectDialogBody;

  /// No description provided for @settingsAppleHealthDisconnectDialogBody.
  ///
  /// In en, this message translates to:
  /// **'YAMT will stop using Apple Health data until you connect it again. Apple Health permissions on your iPhone stay unchanged.'**
  String get settingsAppleHealthDisconnectDialogBody;

  /// No description provided for @settingsHealthDisconnectAction.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get settingsHealthDisconnectAction;

  /// No description provided for @settingsHealthDisconnectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Health access disconnected. Restart YAMT before reconnecting Health Connect.'**
  String get settingsHealthDisconnectSuccess;

  /// No description provided for @settingsAppleHealthDisconnectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Apple Health disconnected in YAMT. You can reconnect it anytime from Settings.'**
  String get settingsAppleHealthDisconnectSuccess;

  /// No description provided for @settingsHealthDisconnectOpenedSettings.
  ///
  /// In en, this message translates to:
  /// **'Opened Settings so you can manage Apple Health access.'**
  String get settingsHealthDisconnectOpenedSettings;

  /// No description provided for @settingsHealthDisconnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Health access could not be disconnected.'**
  String get settingsHealthDisconnectFailed;

  /// No description provided for @settingsHealthConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Health access could not be connected.'**
  String get settingsHealthConnectFailed;

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

  /// No description provided for @healthInstallAction.
  ///
  /// In en, this message translates to:
  /// **'Install Health Connect'**
  String get healthInstallAction;

  /// No description provided for @healthHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'Allow older history'**
  String get healthHistoryAction;

  /// No description provided for @healthUnsupportedHint.
  ///
  /// In en, this message translates to:
  /// **'Health Connect or Apple Health is not available on this device.'**
  String get healthUnsupportedHint;

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

  /// No description provided for @householdJoinLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite link'**
  String get householdJoinLinkLabel;

  /// No description provided for @householdJoinLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Paste link or scan QR code'**
  String get householdJoinLinkHint;

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
  /// **'Invalid invite.'**
  String get householdJoinInvalidCode;

  /// No description provided for @householdJoinExpiredCode.
  ///
  /// In en, this message translates to:
  /// **'This invite has expired.'**
  String get householdJoinExpiredCode;

  /// No description provided for @householdJoinOwnCode.
  ///
  /// In en, this message translates to:
  /// **'You cannot join your own household.'**
  String get householdJoinOwnCode;

  /// No description provided for @householdJoinNameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get householdJoinNameDialogTitle;

  /// No description provided for @householdJoinNameDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name so other household members can recognize you.'**
  String get householdJoinNameDialogMessage;

  /// No description provided for @householdJoinNameDialogFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get householdJoinNameDialogFieldLabel;

  /// No description provided for @householdJoinNameDialogRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name.'**
  String get householdJoinNameDialogRequiredError;

  /// No description provided for @householdJoinNameDialogAction.
  ///
  /// In en, this message translates to:
  /// **'Save & Join'**
  String get householdJoinNameDialogAction;

  /// No description provided for @householdInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite members'**
  String get householdInviteTitle;

  /// No description provided for @householdInviteCreate.
  ///
  /// In en, this message translates to:
  /// **'Create invite'**
  String get householdInviteCreate;

  /// No description provided for @householdInviteValidFor.
  ///
  /// In en, this message translates to:
  /// **'Invite valid for 24 hours'**
  String get householdInviteValidFor;

  /// No description provided for @householdInviteCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get householdInviteCopyLink;

  /// No description provided for @householdInviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied.'**
  String get householdInviteLinkCopied;

  /// No description provided for @householdInviteRefresh.
  ///
  /// In en, this message translates to:
  /// **'Create new invite'**
  String get householdInviteRefresh;

  /// No description provided for @householdInviteVerificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Verify your account with Google or email before you lead a household.'**
  String get householdInviteVerificationRequired;

  /// No description provided for @householdJoinScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get householdJoinScanQr;

  /// No description provided for @householdRejoinRequired.
  ///
  /// In en, this message translates to:
  /// **'Please join the household again with a QR code to read the shared data.'**
  String get householdRejoinRequired;

  /// No description provided for @householdKeyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your key is still loading. Please try again in a moment.'**
  String get householdKeyUnavailable;

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

  /// No description provided for @settingsHomeWidgetVerboseModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed home screen widget'**
  String get settingsHomeWidgetVerboseModeTitle;

  /// No description provided for @settingsHomeWidgetVerboseModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show meals and macros, not just kcal left'**
  String get settingsHomeWidgetVerboseModeSubtitle;

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

  /// No description provided for @commonUndoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndoAction;

  /// No description provided for @commonUndoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not undo.'**
  String get commonUndoFailed;

  /// No description provided for @commonNotImplementedYet.
  ///
  /// In en, this message translates to:
  /// **'Not implemented yet'**
  String get commonNotImplementedYet;

  /// No description provided for @onboardingNextAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNextAction;

  /// No description provided for @onboardingGoalWeightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set your goal weight.'**
  String get onboardingGoalWeightSubtitle;

  /// No description provided for @onboardingGoalWeightTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal weight (kg)'**
  String get onboardingGoalWeightTargetLabel;

  /// No description provided for @onboardingGoalWeightLoseFeedback.
  ///
  /// In en, this message translates to:
  /// **'You want to lose weight.'**
  String get onboardingGoalWeightLoseFeedback;

  /// No description provided for @onboardingGoalWeightGainFeedback.
  ///
  /// In en, this message translates to:
  /// **'You want to gain weight.'**
  String get onboardingGoalWeightGainFeedback;

  /// No description provided for @onboardingGoalWeightMaintainFeedback.
  ///
  /// In en, this message translates to:
  /// **'You want to maintain your weight.'**
  String get onboardingGoalWeightMaintainFeedback;

  /// No description provided for @onboardingPaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Pace'**
  String get onboardingPaceTitle;

  /// No description provided for @onboardingPaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How fast do you want to reach your goal?'**
  String get onboardingPaceSubtitle;

  /// No description provided for @onboardingPaceMaintainMessage.
  ///
  /// In en, this message translates to:
  /// **'Since you want to maintain your weight, we will simply calculate your maintenance calories. You don\'t need to set a pace.'**
  String get onboardingPaceMaintainMessage;

  /// No description provided for @onboardingPaceWarningLoseMessage.
  ///
  /// In en, this message translates to:
  /// **'Losing more than 0.5 kg per week is quite high. Make sure you still get enough nutrients!'**
  String get onboardingPaceWarningLoseMessage;

  /// No description provided for @onboardingPaceWarningGainMessage.
  ///
  /// In en, this message translates to:
  /// **'Gaining more than 0.5 kg per week is quite high. A more moderate pace helps build muscle without adding too much fat.'**
  String get onboardingPaceWarningGainMessage;

  /// No description provided for @onboardingTrainingDaysExtraKcalLabel.
  ///
  /// In en, this message translates to:
  /// **'Eat more on workout days (+200 kcal)'**
  String get onboardingTrainingDaysExtraKcalLabel;

  /// No description provided for @onboardingTrainingDaysTrainingResult.
  ///
  /// In en, this message translates to:
  /// **'🏋️ Training ({days} days)'**
  String onboardingTrainingDaysTrainingResult(int days);

  /// No description provided for @onboardingTrainingDaysRestResult.
  ///
  /// In en, this message translates to:
  /// **'🛋️ Rest day ({days} days)'**
  String onboardingTrainingDaysRestResult(int days);

  /// No description provided for @onboardingReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'All set!'**
  String get onboardingReadyTitle;

  /// No description provided for @introWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to YAMT'**
  String get introWelcomeTitle;

  /// No description provided for @introWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Track what you eat, learn what your body really burns, and keep your kitchen in order.'**
  String get introWelcomeBody;

  /// No description provided for @introStartAction.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get introStartAction;

  /// No description provided for @introLoginAction.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get introLoginAction;

  /// No description provided for @introCalorieModelTitle.
  ///
  /// In en, this message translates to:
  /// **'It all starts with what you put in.'**
  String get introCalorieModelTitle;

  /// No description provided for @introCalorieModelBody.
  ///
  /// In en, this message translates to:
  /// **'Your weight follows a simple equation: the energy you eat against the energy your body burns. Eat more than you burn and you gain. Eat less and you lose.'**
  String get introCalorieModelBody;

  /// No description provided for @introInputQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Your body is a furnace that never sleeps.'**
  String get introInputQualityTitle;

  /// No description provided for @introInputQualityBody.
  ///
  /// In en, this message translates to:
  /// **'Around the clock you burn energy: for your heartbeat, your brain, your breathing and steady warmth. On top comes every small motion of the day — stairs, fidgeting, shivering, walking.'**
  String get introInputQualityBody;

  /// No description provided for @introFollowTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Your scale corrects the estimate.'**
  String get introFollowTargetTitle;

  /// No description provided for @introFollowTargetBody.
  ///
  /// In en, this message translates to:
  /// **'After the first seven days we compare that starting value with how your weight actually moved, and correct it. Then again week after week.'**
  String get introFollowTargetBody;

  /// No description provided for @introGoalDirectionBody.
  ///
  /// In en, this message translates to:
  /// **'To lose weight we subtract calories from your burn, to gain weight we add some. To maintain, your target simply matches it.'**
  String get introGoalDirectionBody;

  /// No description provided for @introGoalDirectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your goal bends the number.'**
  String get introGoalDirectionTitle;

  /// No description provided for @introTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'One weigh-in says nothing. The week says everything.'**
  String get introTrendTitle;

  /// No description provided for @introTrendBody.
  ///
  /// In en, this message translates to:
  /// **'Water, salt and a late dinner move the scale by a kilo overnight. That is noise, not fat.'**
  String get introTrendBody;

  /// No description provided for @introExtrasTitle.
  ///
  /// In en, this message translates to:
  /// **'And the rest of your kitchen comes along.'**
  String get introExtrasTitle;

  /// No description provided for @introExtrasBody.
  ///
  /// In en, this message translates to:
  /// **'Save recipes and plan with a shopping list, scan barcodes to see what is in stock, take food off a receipt, or describe it and let the AI fill in the details.'**
  String get introExtrasBody;

  /// No description provided for @introIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'First we need a rough picture of you.'**
  String get introIdentityTitle;

  /// No description provided for @introIdentitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Before the app learns your real numbers, we need a scientific starting point for your basal metabolism.'**
  String get introIdentitySubtitle;

  /// No description provided for @introBirthDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get introBirthDateLabel;

  /// No description provided for @introBirthDateEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please pick your birthday.'**
  String get introBirthDateEmpty;

  /// No description provided for @introCalorieModelHighlight.
  ///
  /// In en, this message translates to:
  /// **'what you put in'**
  String get introCalorieModelHighlight;

  /// No description provided for @introCalorieModelNote.
  ///
  /// In en, this message translates to:
  /// **'The food half of the equation is tangible: what you eat can be weighed, seen and logged almost to the gram.'**
  String get introCalorieModelNote;

  /// No description provided for @introInputQualityHighlight.
  ///
  /// In en, this message translates to:
  /// **'never sleeps'**
  String get introInputQualityHighlight;

  /// No description provided for @introInputQualityNote.
  ///
  /// In en, this message translates to:
  /// **'The catch: nobody can measure that burn directly. So we begin with a starting value, estimated from your details.'**
  String get introInputQualityNote;

  /// No description provided for @introFollowTargetHighlight.
  ///
  /// In en, this message translates to:
  /// **'corrects the estimate'**
  String get introFollowTargetHighlight;

  /// No description provided for @introFollowTargetNote.
  ///
  /// In en, this message translates to:
  /// **'So the first week is a measurement, not a verdict. Do not read too much into it.'**
  String get introFollowTargetNote;

  /// No description provided for @introGoalDirectionHighlight.
  ///
  /// In en, this message translates to:
  /// **'bends the number'**
  String get introGoalDirectionHighlight;

  /// No description provided for @introGoalDirectionNote.
  ///
  /// In en, this message translates to:
  /// **'You pick the pace. We do the arithmetic every single day.'**
  String get introGoalDirectionNote;

  /// No description provided for @introTrendHighlight.
  ///
  /// In en, this message translates to:
  /// **'The week says everything'**
  String get introTrendHighlight;

  /// No description provided for @introTrendNote.
  ///
  /// In en, this message translates to:
  /// **'That is why the correction reads the trend across the whole week, so a bad morning never rewrites your plan.'**
  String get introTrendNote;

  /// No description provided for @introExtrasHighlight.
  ///
  /// In en, this message translates to:
  /// **'the rest of your kitchen'**
  String get introExtrasHighlight;

  /// No description provided for @introExtrasNote.
  ///
  /// In en, this message translates to:
  /// **'Logging stops being homework when the food is already in the app.'**
  String get introExtrasNote;

  /// No description provided for @introSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is your estimated starting value. From your start day YAMT compares your food with your weight for seven days and corrects the number, then again every week.'**
  String get introSummarySubtitle;

  /// No description provided for @introBodyTitle.
  ///
  /// In en, this message translates to:
  /// **'What are your current numbers?'**
  String get introBodyTitle;

  /// No description provided for @introBodySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Body weight and height decide how many cells have to be supplied with oxygen and glucose at rest.'**
  String get introBodySubtitle;

  /// No description provided for @introWeightKgUnit.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get introWeightKgUnit;

  /// No description provided for @introSportTitle.
  ///
  /// In en, this message translates to:
  /// **'On which days do you train?'**
  String get introSportTitle;

  /// No description provided for @introSportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Training days get more, rest days less. The weekly total stays the same.'**
  String get introSportSubtitle;

  /// No description provided for @introWeekDepotTitle.
  ///
  /// In en, this message translates to:
  /// **'Calories per day across the week'**
  String get introWeekDepotTitle;

  /// No description provided for @introIdentityPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your details are used for the energy calculation only.'**
  String get introIdentityPrivacyNote;

  /// No description provided for @introBodyWeighInNote.
  ///
  /// In en, this message translates to:
  /// **'Weigh yourself in the morning after getting up. That keeps your values comparable.'**
  String get introBodyWeighInNote;

  /// No description provided for @introSummaryDepotHint.
  ///
  /// In en, this message translates to:
  /// **'Training days borrow from rest days. The weekly sum stays the same.'**
  String get introSummaryDepotHint;

  /// No description provided for @introStartDayTitle.
  ///
  /// In en, this message translates to:
  /// **'When does your first week start?'**
  String get introStartDayTitle;

  /// No description provided for @introStartDayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get introStartDayToday;

  /// No description provided for @introStartDayTodayHint.
  ///
  /// In en, this message translates to:
  /// **'Also log what you have already eaten today.'**
  String get introStartDayTodayHint;

  /// No description provided for @introStartDayTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get introStartDayTomorrow;

  /// No description provided for @introStartDayTomorrowHint.
  ///
  /// In en, this message translates to:
  /// **'Try the app today. It does not count yet.'**
  String get introStartDayTomorrowHint;

  /// No description provided for @introStartDayOther.
  ///
  /// In en, this message translates to:
  /// **'Another day'**
  String get introStartDayOther;

  /// No description provided for @introStartDayOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Until then you practice and nothing counts.'**
  String get introStartDayOtherHint;

  /// No description provided for @introStartTodayAction.
  ///
  /// In en, this message translates to:
  /// **'Start today'**
  String get introStartTodayAction;

  /// No description provided for @introStartTomorrowAction.
  ///
  /// In en, this message translates to:
  /// **'Start tomorrow'**
  String get introStartTomorrowAction;

  /// No description provided for @introStartOnDateAction.
  ///
  /// In en, this message translates to:
  /// **'Start on {date}'**
  String introStartOnDateAction(String date);

  /// No description provided for @introCategoryHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How YAMT calculates'**
  String get introCategoryHowItWorks;

  /// No description provided for @introCategoryYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get introCategoryYourProfile;

  /// No description provided for @introCategoryYourStart.
  ///
  /// In en, this message translates to:
  /// **'Your start'**
  String get introCategoryYourStart;

  /// No description provided for @introCategoryBeyondCalories.
  ///
  /// In en, this message translates to:
  /// **'Beyond calories'**
  String get introCategoryBeyondCalories;

  /// No description provided for @introChapterEnergyBalance.
  ///
  /// In en, this message translates to:
  /// **'Energy balance'**
  String get introChapterEnergyBalance;

  /// No description provided for @introChapterStartValue.
  ///
  /// In en, this message translates to:
  /// **'The starting value'**
  String get introChapterStartValue;

  /// No description provided for @introChapterCorrection.
  ///
  /// In en, this message translates to:
  /// **'The correction'**
  String get introChapterCorrection;

  /// No description provided for @introChapterGoalDirection.
  ///
  /// In en, this message translates to:
  /// **'Your goal'**
  String get introChapterGoalDirection;

  /// No description provided for @introChapterTrend.
  ///
  /// In en, this message translates to:
  /// **'The trend'**
  String get introChapterTrend;

  /// No description provided for @introChapterKitchen.
  ///
  /// In en, this message translates to:
  /// **'Your kitchen'**
  String get introChapterKitchen;

  /// No description provided for @introChapterProfile.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get introChapterProfile;

  /// No description provided for @introChapterBody.
  ///
  /// In en, this message translates to:
  /// **'Body measurements'**
  String get introChapterBody;

  /// No description provided for @introChapterTargetWeight.
  ///
  /// In en, this message translates to:
  /// **'Target weight'**
  String get introChapterTargetWeight;

  /// No description provided for @introChapterActivity.
  ///
  /// In en, this message translates to:
  /// **'Everyday activity'**
  String get introChapterActivity;

  /// No description provided for @introChapterTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get introChapterTraining;

  /// No description provided for @introChapterPace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get introChapterPace;

  /// No description provided for @introChapterResult.
  ///
  /// In en, this message translates to:
  /// **'Your starting value'**
  String get introChapterResult;

  /// No description provided for @introChapterKicker.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number} · {name}'**
  String introChapterKicker(int number, String name);

  /// No description provided for @introNextChapterAction.
  ///
  /// In en, this message translates to:
  /// **'Next: {name}'**
  String introNextChapterAction(String name);

  /// No description provided for @introChapterCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String introChapterCounter(String current, String total);

  /// No description provided for @introTargetWeightHint.
  ///
  /// In en, this message translates to:
  /// **'Turn the wheel, or leave it to maintain your weight.'**
  String get introTargetWeightHint;

  /// No description provided for @introTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to go?'**
  String get introTargetTitle;

  /// No description provided for @introBirthDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get introBirthDayLabel;

  /// No description provided for @introBirthMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get introBirthMonthLabel;

  /// No description provided for @introBirthYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get introBirthYearLabel;

  /// No description provided for @introHeightCmUnit.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get introHeightCmUnit;

  /// No description provided for @introCurrentWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Current weight'**
  String get introCurrentWeightLabel;

  /// No description provided for @introPaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get introPaceLabel;

  /// No description provided for @introPacePerWeekUnit.
  ///
  /// In en, this message translates to:
  /// **'kg / week'**
  String get introPacePerWeekUnit;

  /// No description provided for @introActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'How active is your typical week?'**
  String get introActivityTitle;

  /// No description provided for @introActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Count daily life and sport together: your job, walking and your training.'**
  String get introActivitySubtitle;

  /// No description provided for @introActivitySittingTitle.
  ///
  /// In en, this message translates to:
  /// **'Barely active'**
  String get introActivitySittingTitle;

  /// No description provided for @introActivitySittingBody.
  ///
  /// In en, this message translates to:
  /// **'Desk, car, sofa, hardly any sport'**
  String get introActivitySittingBody;

  /// No description provided for @introActivityLightTitle.
  ///
  /// In en, this message translates to:
  /// **'Lightly active'**
  String get introActivityLightTitle;

  /// No description provided for @introActivityLightBody.
  ///
  /// In en, this message translates to:
  /// **'Walking daily or 1–2 easy workouts a week'**
  String get introActivityLightBody;

  /// No description provided for @introActivityOnFeetTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderately active'**
  String get introActivityOnFeetTitle;

  /// No description provided for @introActivityOnFeetBody.
  ///
  /// In en, this message translates to:
  /// **'On your feet a lot or 3–4 workouts a week'**
  String get introActivityOnFeetBody;

  /// No description provided for @introActivityHardLabourTitle.
  ///
  /// In en, this message translates to:
  /// **'Very active'**
  String get introActivityHardLabourTitle;

  /// No description provided for @introActivityHardLabourBody.
  ///
  /// In en, this message translates to:
  /// **'Hard physical work or training on most days'**
  String get introActivityHardLabourBody;

  /// No description provided for @introSummaryExpenditureLabel.
  ///
  /// In en, this message translates to:
  /// **'Your calculated expenditure'**
  String get introSummaryExpenditureLabel;

  /// No description provided for @introSummaryExpenditureHint.
  ///
  /// In en, this message translates to:
  /// **'What your body burns on a normal day.'**
  String get introSummaryExpenditureHint;

  /// No description provided for @introSummaryTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Your daily target'**
  String get introSummaryTargetLabel;

  /// No description provided for @introSummaryTargetMaintainHint.
  ///
  /// In en, this message translates to:
  /// **'Matches your expenditure, so your weight stays where it is.'**
  String get introSummaryTargetMaintainHint;

  /// No description provided for @introSummaryKcalValue.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String introSummaryKcalValue(int kcal);

  /// No description provided for @introSummaryTargetDeficitHint.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal below your expenditure, so you lose weight.'**
  String introSummaryTargetDeficitHint(int kcal);

  /// No description provided for @introSummaryTargetSurplusHint.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal above your expenditure, so you gain weight.'**
  String introSummaryTargetSurplusHint(int kcal);

  /// No description provided for @introBirthDateValue.
  ///
  /// In en, this message translates to:
  /// **'{date} ({age} years)'**
  String introBirthDateValue(String date, String age);

  /// No description provided for @introTargetDateEstimate.
  ///
  /// In en, this message translates to:
  /// **'At this pace you reach your goal around {date}.'**
  String introTargetDateEstimate(String date);

  /// No description provided for @cookflowPrepflowTitle.
  ///
  /// In en, this message translates to:
  /// **'Prepflow'**
  String get cookflowPrepflowTitle;

  /// No description provided for @cookflowTemplateNotFound.
  ///
  /// In en, this message translates to:
  /// **'Recipe not found.'**
  String get cookflowTemplateNotFound;

  /// No description provided for @cookflowLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Cookflow could not be loaded.'**
  String get cookflowLoadFailed;

  /// No description provided for @cookflowStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start flow'**
  String get cookflowStartButton;

  /// No description provided for @cookflowLaterButton.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get cookflowLaterButton;

  /// No description provided for @cookflowShoppingListContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Add to shopping list and continue later'**
  String get cookflowShoppingListContinueButton;

  /// No description provided for @cookflowShoppingListAddSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Ingredients added to shopping list.'**
  String get cookflowShoppingListAddSucceeded;

  /// No description provided for @cookflowShoppingListAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Shopping list could not be updated.'**
  String get cookflowShoppingListAddFailed;

  /// No description provided for @cookflowSessionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Cookflow could not be saved.'**
  String get cookflowSessionSaveFailed;

  /// No description provided for @cookflowResolveConflictsButton.
  ///
  /// In en, this message translates to:
  /// **'Resolve conflicts'**
  String get cookflowResolveConflictsButton;

  /// No description provided for @cookflowContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get cookflowContinueButton;

  /// No description provided for @cookflowPhaseChip.
  ///
  /// In en, this message translates to:
  /// **'Phase {currentPhase} / {totalPhases}'**
  String cookflowPhaseChip(int currentPhase, int totalPhases);

  /// No description provided for @cookflowSaveMealButton.
  ///
  /// In en, this message translates to:
  /// **'Save meal'**
  String get cookflowSaveMealButton;

  /// No description provided for @cookflowSavingMealButton.
  ///
  /// In en, this message translates to:
  /// **'Saving meal'**
  String get cookflowSavingMealButton;

  /// No description provided for @cookflowInvalidWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid gross weight.'**
  String get cookflowInvalidWeight;

  /// No description provided for @cookflowMissingWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter the gross weight.'**
  String get cookflowMissingWeight;

  /// No description provided for @cookflowGrossMustExceedTara.
  ///
  /// In en, this message translates to:
  /// **'Gross weight must be greater than tare.'**
  String get cookflowGrossMustExceedTara;

  /// No description provided for @cookflowMissingAssignments.
  ///
  /// In en, this message translates to:
  /// **'Please assign at least one ingredient from inventory.'**
  String get cookflowMissingAssignments;

  /// No description provided for @cookflowIngredientContainerMissing.
  ///
  /// In en, this message translates to:
  /// **'Please choose a container for every ingredient.'**
  String get cookflowIngredientContainerMissing;

  /// No description provided for @cookflowContainerMissingIngredients.
  ///
  /// In en, this message translates to:
  /// **'Every container needs at least one ingredient.'**
  String get cookflowContainerMissingIngredients;

  /// No description provided for @cookflowSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Meal could not be saved.'**
  String get cookflowSaveFailed;

  /// No description provided for @cookflowSuccessFallbackMealName.
  ///
  /// In en, this message translates to:
  /// **'Your meal'**
  String get cookflowSuccessFallbackMealName;

  /// No description provided for @cookflowSavedMealsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} meals saved'**
  String cookflowSavedMealsCount(int count);

  /// No description provided for @cookflowIntroHeadline.
  ///
  /// In en, this message translates to:
  /// **'Start cooking session'**
  String get cookflowIntroHeadline;

  /// No description provided for @cookflowRecipeLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipe: '**
  String get cookflowRecipeLabel;

  /// No description provided for @cookflowInventoryCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory check'**
  String get cookflowInventoryCheckTitle;

  /// No description provided for @cookflowResetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get cookflowResetButton;

  /// No description provided for @cookflowEmptyIngredients.
  ///
  /// In en, this message translates to:
  /// **'No ingredients available.'**
  String get cookflowEmptyIngredients;

  /// No description provided for @cookflowShoppingCartTooltip.
  ///
  /// In en, this message translates to:
  /// **'Shopping cart'**
  String get cookflowShoppingCartTooltip;

  /// No description provided for @cookflowAssignTooltip.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get cookflowAssignTooltip;

  /// No description provided for @cookflowIgnoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get cookflowIgnoreTooltip;

  /// No description provided for @cookflowUnknownAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount open'**
  String get cookflowUnknownAmount;

  /// No description provided for @cookflowInventorySelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose inventory'**
  String get cookflowInventorySelectionTitle;

  /// No description provided for @cookflowInventoryConflictMessage.
  ///
  /// In en, this message translates to:
  /// **'Not enough in inventory: Only {availableAmount} available. {missingAmount} missing.'**
  String cookflowInventoryConflictMessage(
    Object availableAmount,
    Object missingAmount,
  );

  /// No description provided for @cookflowInventoryUsagePreview.
  ///
  /// In en, this message translates to:
  /// **'Subtract {usedAmount} · left {remainingAmount}'**
  String cookflowInventoryUsagePreview(
    Object usedAmount,
    Object remainingAmount,
  );

  /// No description provided for @cookflowBuyRemainingButton.
  ///
  /// In en, this message translates to:
  /// **'BUY REMAINDER'**
  String get cookflowBuyRemainingButton;

  /// No description provided for @cookflowAdjustTemplateButton.
  ///
  /// In en, this message translates to:
  /// **'ADJUST RECIPE'**
  String get cookflowAdjustTemplateButton;

  /// No description provided for @cookflowInventoryUnitConflictMessage.
  ///
  /// In en, this message translates to:
  /// **'Unit conflict: recipe uses \"{recipeUnit}\". Inventory has \"{inventoryUnit}\".'**
  String cookflowInventoryUnitConflictMessage(
    Object recipeUnit,
    Object inventoryUnit,
  );

  /// No description provided for @cookflowInventoryUnitConversionPrefix.
  ///
  /// In en, this message translates to:
  /// **'1 piece ≈'**
  String get cookflowInventoryUnitConversionPrefix;

  /// No description provided for @cookflowInventoryUnitConvertAction.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get cookflowInventoryUnitConvertAction;

  /// No description provided for @cookflowInventoryUnitWeighLaterAction.
  ///
  /// In en, this message translates to:
  /// **'Weigh later while cooking'**
  String get cookflowInventoryUnitWeighLaterAction;

  /// No description provided for @cookflowEditIngredientTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit ingredient'**
  String get cookflowEditIngredientTooltip;

  /// No description provided for @cookflowEditIngredientTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit ingredient'**
  String get cookflowEditIngredientTitle;

  /// No description provided for @cookflowEditIngredientNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Ingredient'**
  String get cookflowEditIngredientNameLabel;

  /// No description provided for @cookflowEditIngredientAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get cookflowEditIngredientAmountLabel;

  /// No description provided for @cookflowEditIngredientUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get cookflowEditIngredientUnitLabel;

  /// No description provided for @cookflowEditIngredientRequiredField.
  ///
  /// In en, this message translates to:
  /// **'Please fill this field.'**
  String get cookflowEditIngredientRequiredField;

  /// No description provided for @cookflowEditIngredientSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get cookflowEditIngredientSaveAction;

  /// No description provided for @cookflowInventorySelectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching inventory items found.'**
  String get cookflowInventorySelectionEmpty;

  /// No description provided for @cookflowCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cookflowCancelButton;

  /// No description provided for @cookflowInventorySelectionSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get cookflowInventorySelectionSaveButton;

  /// No description provided for @cookflowInventorySelectionItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Inventory item'**
  String get cookflowInventorySelectionItemLabel;

  /// No description provided for @cookflowInventorySelectionAddIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get cookflowInventorySelectionAddIngredient;

  /// No description provided for @cookflowInventorySelectionAddIngredientSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an optional inventory item.'**
  String get cookflowInventorySelectionAddIngredientSubtitle;

  /// No description provided for @cookflowInventorySelectionWeightLater.
  ///
  /// In en, this message translates to:
  /// **'Set weight later in phase 3.'**
  String get cookflowInventorySelectionWeightLater;

  /// No description provided for @cookflowInventorySelectionAddConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get cookflowInventorySelectionAddConfirm;

  /// No description provided for @cookflowInventoryReturnSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Found a new inventory match.'**
  String get cookflowInventoryReturnSuggestion;

  /// No description provided for @cookflowInventoryReturnSuggestionButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get cookflowInventoryReturnSuggestionButton;

  /// No description provided for @cookflowPreparationTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Preparation'**
  String get cookflowPreparationTitle;

  /// No description provided for @cookflowPreparationBody.
  ///
  /// In en, this message translates to:
  /// **'Before we begin: choose every pot or storage box you will use and enter its empty weight.'**
  String get cookflowPreparationBody;

  /// No description provided for @cookflowGramUnit.
  ///
  /// In en, this message translates to:
  /// **'Grams'**
  String get cookflowGramUnit;

  /// No description provided for @cookflowTaraUtensilsTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved utensils'**
  String get cookflowTaraUtensilsTitle;

  /// No description provided for @cookflowTaraUtensilsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load utensils.'**
  String get cookflowTaraUtensilsLoadFailed;

  /// No description provided for @cookflowPreparationHint.
  ///
  /// In en, this message translates to:
  /// **'If pasta and sauce end up in separate containers, add both now. In phase 3 you assign each ingredient to its container.'**
  String get cookflowPreparationHint;

  /// No description provided for @cookflowPortionScalerTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipe portions'**
  String get cookflowPortionScalerTitle;

  /// No description provided for @cookflowOriginalPortionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Original recipe: {count} portions'**
  String cookflowOriginalPortionsLabel(int count);

  /// No description provided for @cookflowTargetPortionsFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'New portions'**
  String get cookflowTargetPortionsFieldLabel;

  /// No description provided for @cookflowCookingTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Cooking'**
  String get cookflowCookingTitle;

  /// No description provided for @cookflowCookingBody.
  ///
  /// In en, this message translates to:
  /// **'The ingredients from your inventory are reserved locally.\nEnjoy your meal!'**
  String get cookflowCookingBody;

  /// No description provided for @cookflowOnTheFlyTitle.
  ///
  /// In en, this message translates to:
  /// **'On-the-fly adjustment'**
  String get cookflowOnTheFlyTitle;

  /// No description provided for @cookflowOnTheFlyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 150g extra peas...'**
  String get cookflowOnTheFlyHint;

  /// No description provided for @cookflowOnTheFlyRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove adjustment'**
  String get cookflowOnTheFlyRemoveTooltip;

  /// No description provided for @cookflowVoiceInputStartTooltip.
  ///
  /// In en, this message translates to:
  /// **'Start voice input'**
  String get cookflowVoiceInputStartTooltip;

  /// No description provided for @cookflowVoiceInputStopTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop voice input'**
  String get cookflowVoiceInputStopTooltip;

  /// No description provided for @cookflowVoiceInputUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input is not currently supported on this device.'**
  String get cookflowVoiceInputUnavailable;

  /// No description provided for @cookflowVoiceInputPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Please allow microphone access to use voice input.'**
  String get cookflowVoiceInputPermissionDenied;

  /// No description provided for @cookflowVoiceInputFailed.
  ///
  /// In en, this message translates to:
  /// **'Voice input could not be started. Please try again.'**
  String get cookflowVoiceInputFailed;

  /// No description provided for @cookflowCookingFallbackNoIngredients.
  ///
  /// In en, this message translates to:
  /// **'Prepare your recipe with the ingredients you have available.'**
  String get cookflowCookingFallbackNoIngredients;

  /// No description provided for @cookflowCookingFallbackPrepPrefix.
  ///
  /// In en, this message translates to:
  /// **'Prepare the ingredients:'**
  String get cookflowCookingFallbackPrepPrefix;

  /// No description provided for @cookflowCookingFallbackCookText.
  ///
  /// In en, this message translates to:
  /// **'Then cook the dish as described in the recipe.'**
  String get cookflowCookingFallbackCookText;

  /// No description provided for @cookflowSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Summary'**
  String get cookflowSummaryTitle;

  /// No description provided for @cookflowSummaryBody.
  ///
  /// In en, this message translates to:
  /// **'Check the final ingredients, resolve spontaneous changes, and choose where each ingredient is stored.'**
  String get cookflowSummaryBody;

  /// No description provided for @cookflowSummaryIngredientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Base recipe ingredients'**
  String get cookflowSummaryIngredientsTitle;

  /// No description provided for @cookflowSummaryAdjustmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Unresolved adjustments'**
  String get cookflowSummaryAdjustmentsTitle;

  /// No description provided for @cookflowSummaryMatchInventoryButton.
  ///
  /// In en, this message translates to:
  /// **'Add as ingredient'**
  String get cookflowSummaryMatchInventoryButton;

  /// No description provided for @cookflowFinalizeTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Finalize'**
  String get cookflowFinalizeTitle;

  /// No description provided for @cookflowFinalizeBody.
  ///
  /// In en, this message translates to:
  /// **'Place each filled container on the scale, then set portions for the meals we will create.'**
  String get cookflowFinalizeBody;

  /// No description provided for @cookflowStorageContainersTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage containers'**
  String get cookflowStorageContainersTitle;

  /// No description provided for @cookflowAddStorageContainerButton.
  ///
  /// In en, this message translates to:
  /// **'Add container'**
  String get cookflowAddStorageContainerButton;

  /// No description provided for @cookflowContainerLabel.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get cookflowContainerLabel;

  /// No description provided for @cookflowContainerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Container {index}'**
  String cookflowContainerNameHint(int index);

  /// No description provided for @cookflowRemoveContainerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove container'**
  String get cookflowRemoveContainerTooltip;

  /// No description provided for @cookflowContainerTaraLabel.
  ///
  /// In en, this message translates to:
  /// **'Tare'**
  String get cookflowContainerTaraLabel;

  /// No description provided for @cookflowIngredientContainerTitle.
  ///
  /// In en, this message translates to:
  /// **'Where is each ingredient stored?'**
  String get cookflowIngredientContainerTitle;

  /// No description provided for @cookflowIngredientContainerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No inventory ingredients available for container assignment.'**
  String get cookflowIngredientContainerEmpty;

  /// No description provided for @cookflowGrossWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Gross weight (pot + food)'**
  String get cookflowGrossWeightTitle;

  /// No description provided for @cookflowGrossWeightHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2500'**
  String get cookflowGrossWeightHint;

  /// No description provided for @cookflowNetWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Net final weight'**
  String get cookflowNetWeightLabel;

  /// No description provided for @cookflowSplitIntoPortionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Adjust portions?'**
  String get cookflowSplitIntoPortionsLabel;

  /// No description provided for @cookflowHowManyPortions.
  ///
  /// In en, this message translates to:
  /// **'How many portions is that?'**
  String get cookflowHowManyPortions;

  /// No description provided for @cookflowCaloriesShortLabel.
  ///
  /// In en, this message translates to:
  /// **'CALORIES'**
  String get cookflowCaloriesShortLabel;

  /// No description provided for @cookflowCarbsShortLabel.
  ///
  /// In en, this message translates to:
  /// **'CARBS'**
  String get cookflowCarbsShortLabel;

  /// No description provided for @cookflowProteinShortLabel.
  ///
  /// In en, this message translates to:
  /// **'PROTEIN'**
  String get cookflowProteinShortLabel;

  /// No description provided for @cookflowFatShortLabel.
  ///
  /// In en, this message translates to:
  /// **'FAT'**
  String get cookflowFatShortLabel;

  /// No description provided for @cookflowSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cookflowSuccessTitle;

  /// No description provided for @cookflowSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your meal was saved and is now available in inventory.'**
  String get cookflowSuccessSubtitle;

  /// No description provided for @cookflowSuccessHeadline.
  ///
  /// In en, this message translates to:
  /// **'Meal saved'**
  String get cookflowSuccessHeadline;

  /// No description provided for @cookflowToInventoryButton.
  ///
  /// In en, this message translates to:
  /// **'Go to inventory'**
  String get cookflowToInventoryButton;

  /// No description provided for @cookflowResumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get cookflowResumeLabel;

  /// No description provided for @caloriesProteinShortLetter.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get caloriesProteinShortLetter;

  /// No description provided for @caloriesCarbsShortLetter.
  ///
  /// In en, this message translates to:
  /// **'C'**
  String get caloriesCarbsShortLetter;

  /// No description provided for @caloriesFatShortLetter.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get caloriesFatShortLetter;

  /// No description provided for @shoppingListSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get shoppingListSuggestionsTitle;

  /// No description provided for @shoppingListSuggestionsExplanation.
  ///
  /// In en, this message translates to:
  /// **'Low stock and frequently purchased products from your receipts.'**
  String get shoppingListSuggestionsExplanation;

  /// No description provided for @shoppingListSuggestionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No suggestions yet. Low stock or repeated purchases on different receipts will appear here.'**
  String get shoppingListSuggestionsEmpty;

  /// No description provided for @shoppingListSuggestionsRetry.
  ///
  /// In en, this message translates to:
  /// **'Reload suggestions'**
  String get shoppingListSuggestionsRetry;

  /// No description provided for @shoppingListConsumptionDays.
  ///
  /// In en, this message translates to:
  /// **'Consumed on {count} days'**
  String shoppingListConsumptionDays(int count);

  /// No description provided for @shoppingListOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'To buy'**
  String get shoppingListOpenTitle;

  /// No description provided for @shoppingListDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get shoppingListDoneTitle;

  /// No description provided for @shoppingListLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get shoppingListLowStock;

  /// No description provided for @shoppingListPurchaseCount.
  ///
  /// In en, this message translates to:
  /// **'Purchased {count} times'**
  String shoppingListPurchaseCount(int count);

  /// No description provided for @shoppingListSchedule.
  ///
  /// In en, this message translates to:
  /// **'Recurring item'**
  String get shoppingListSchedule;

  /// No description provided for @shoppingListScheduleExplanation.
  ///
  /// In en, this message translates to:
  /// **'Due items are added when you open this list. Items already on the list are not duplicated.'**
  String get shoppingListScheduleExplanation;

  /// No description provided for @shoppingListScheduleDays.
  ///
  /// In en, this message translates to:
  /// **'Interval in days'**
  String get shoppingListScheduleDays;

  /// No description provided for @shoppingListFirstDue.
  ///
  /// In en, this message translates to:
  /// **'First due'**
  String get shoppingListFirstDue;

  /// No description provided for @shoppingListStopSchedule.
  ///
  /// In en, this message translates to:
  /// **'Stop repeating'**
  String get shoppingListStopSchedule;

  /// No description provided for @shoppingListSaveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get shoppingListSaveSettings;

  /// No description provided for @shoppingListNumberRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 1 to {max}.'**
  String shoppingListNumberRange(int max);

  /// No description provided for @shoppingListProductSettings.
  ///
  /// In en, this message translates to:
  /// **'Item settings'**
  String get shoppingListProductSettings;

  /// No description provided for @shoppingListRemoveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove favorite'**
  String get shoppingListRemoveFavorite;

  /// No description provided for @shoppingListAddFavorite.
  ///
  /// In en, this message translates to:
  /// **'Save as favorite'**
  String get shoppingListAddFavorite;

  /// No description provided for @shoppingListSettingsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save settings.'**
  String get shoppingListSettingsFailed;

  /// No description provided for @shoppingListSavedProducts.
  ///
  /// In en, this message translates to:
  /// **'Favorites & recurring items'**
  String get shoppingListSavedProducts;

  /// No description provided for @shoppingListRepeatSummary.
  ///
  /// In en, this message translates to:
  /// **'{quantity} items every {days} days'**
  String shoppingListRepeatSummary(int quantity, int days);

  /// No description provided for @shoppingListNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due: {date}'**
  String shoppingListNextDue(String date);

  /// No description provided for @shoppingListFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get shoppingListFavorite;

  /// No description provided for @shoppingListOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get shoppingListOutOfStock;

  /// No description provided for @receiptReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review receipt'**
  String get receiptReviewTitle;

  /// No description provided for @receiptReviewAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get receiptReviewAddItem;

  /// No description provided for @receiptReviewConfirmAllSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Accept all suggestions'**
  String get receiptReviewConfirmAllSuggestions;

  /// No description provided for @receiptReviewSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Add to inventory'**
  String get receiptReviewSaveAction;

  /// No description provided for @receiptReviewStoreEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit store'**
  String get receiptReviewStoreEdit;

  /// No description provided for @receiptReviewStoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get receiptReviewStoreLabel;

  /// No description provided for @receiptReviewAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing receipt...'**
  String get receiptReviewAnalyzing;

  /// No description provided for @receiptReviewProcessingFailed.
  ///
  /// In en, this message translates to:
  /// **'Receipt processing failed: {error}'**
  String receiptReviewProcessingFailed(String error);

  /// No description provided for @receiptReviewNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date detected'**
  String get receiptReviewNoDate;

  /// No description provided for @receiptReviewUnknownStore.
  ///
  /// In en, this message translates to:
  /// **'Unknown store'**
  String get receiptReviewUnknownStore;

  /// No description provided for @receiptReviewPrintedTotal.
  ///
  /// In en, this message translates to:
  /// **'Receipt total'**
  String get receiptReviewPrintedTotal;

  /// No description provided for @receiptReviewCalculatedTotal.
  ///
  /// In en, this message translates to:
  /// **'Calculated total'**
  String get receiptReviewCalculatedTotal;

  /// No description provided for @receiptReviewDifference.
  ///
  /// In en, this message translates to:
  /// **'Difference: {difference}'**
  String receiptReviewDifference(String difference);

  /// No description provided for @receiptReviewSumMatches.
  ///
  /// In en, this message translates to:
  /// **'Total matches'**
  String get receiptReviewSumMatches;

  /// No description provided for @receiptReviewDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount: -{amount}'**
  String receiptReviewDiscount(String amount);

  /// No description provided for @receiptReviewDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit: {amount}'**
  String receiptReviewDeposit(String amount);

  /// No description provided for @receiptReviewOpenItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}} still pending'**
  String receiptReviewOpenItemsCount(int count);

  /// No description provided for @receiptReviewReceiptPrefix.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptReviewReceiptPrefix;

  /// No description provided for @receiptReviewDepositBadge.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get receiptReviewDepositBadge;

  /// No description provided for @receiptReviewConfirmSuggestionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Accept suggestion'**
  String get receiptReviewConfirmSuggestionTooltip;

  /// No description provided for @receiptReviewOriginalReceiptText.
  ///
  /// In en, this message translates to:
  /// **'Original text from receipt'**
  String get receiptReviewOriginalReceiptText;

  /// No description provided for @receiptReviewQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity:'**
  String get receiptReviewQuantityLabel;

  /// No description provided for @receiptReviewScanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get receiptReviewScanBarcode;

  /// No description provided for @receiptReviewSearchProduct.
  ///
  /// In en, this message translates to:
  /// **'Search product'**
  String get receiptReviewSearchProduct;

  /// No description provided for @receiptReviewIncludeItem.
  ///
  /// In en, this message translates to:
  /// **'Include'**
  String get receiptReviewIncludeItem;

  /// No description provided for @receiptReviewIgnoreItem.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get receiptReviewIgnoreItem;

  /// No description provided for @receiptReviewDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get receiptReviewDeleteItem;

  /// No description provided for @receiptReviewSuggestedAlternatives.
  ///
  /// In en, this message translates to:
  /// **'Suggested alternatives:'**
  String get receiptReviewSuggestedAlternatives;

  /// No description provided for @receiptReviewSelectCandidateAction.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get receiptReviewSelectCandidateAction;

  /// No description provided for @receiptReviewNoProductAssigned.
  ///
  /// In en, this message translates to:
  /// **'No product assigned'**
  String get receiptReviewNoProductAssigned;

  /// No description provided for @receiptReviewClearProductMatchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear assignment'**
  String get receiptReviewClearProductMatchTooltip;

  /// No description provided for @receiptReviewSwitchProductAction.
  ///
  /// In en, this message translates to:
  /// **'Switch product'**
  String get receiptReviewSwitchProductAction;

  /// No description provided for @receiptReviewSearchProductAction.
  ///
  /// In en, this message translates to:
  /// **'Search product'**
  String get receiptReviewSearchProductAction;

  /// No description provided for @receiptReviewItemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get receiptReviewItemNameLabel;

  /// No description provided for @receiptReviewItemNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Oat Milk Barista'**
  String get receiptReviewItemNameHint;

  /// No description provided for @receiptReviewItemQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get receiptReviewItemQuantityLabel;

  /// No description provided for @receiptReviewPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get receiptReviewPriceLabel;

  /// No description provided for @receiptReviewIsDepositLabel.
  ///
  /// In en, this message translates to:
  /// **'Deposit item'**
  String get receiptReviewIsDepositLabel;

  /// No description provided for @receiptReviewAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get receiptReviewAddAction;

  /// No description provided for @receiptReviewPriceEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit price'**
  String get receiptReviewPriceEditTitle;

  /// No description provided for @receiptReviewBarcodeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter / scan barcode'**
  String get receiptReviewBarcodeDialogTitle;

  /// No description provided for @receiptReviewBarcodeDialogLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode (EAN)'**
  String get receiptReviewBarcodeDialogLabel;

  /// No description provided for @receiptReviewConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get receiptReviewConfirmAction;

  /// No description provided for @receiptReviewManualInputTooltip.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get receiptReviewManualInputTooltip;

  /// No description provided for @receiptReviewSearchProductDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Search item'**
  String get receiptReviewSearchProductDialogTitle;

  /// No description provided for @receiptReviewSearchProductHint.
  ///
  /// In en, this message translates to:
  /// **'Enter product name...'**
  String get receiptReviewSearchProductHint;

  /// No description provided for @receiptReviewNoProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get receiptReviewNoProductsFound;

  /// No description provided for @receiptReviewNutritionPer100g.
  ///
  /// In en, this message translates to:
  /// **'Nutrition per 100 g/ml'**
  String get receiptReviewNutritionPer100g;

  /// No description provided for @receiptReviewPackageSize.
  ///
  /// In en, this message translates to:
  /// **'Package: {size}'**
  String receiptReviewPackageSize(String size);

  /// No description provided for @receiptReviewNutritionEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get receiptReviewNutritionEnergy;

  /// No description provided for @receiptReviewNutritionFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get receiptReviewNutritionFat;

  /// No description provided for @receiptReviewNutritionCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get receiptReviewNutritionCarbs;

  /// No description provided for @receiptReviewNutritionProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get receiptReviewNutritionProtein;

  /// No description provided for @recoveryKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery key'**
  String get recoveryKeyTitle;

  /// No description provided for @recoveryKeyExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your diary, weight, and body data are encrypted before they leave this phone. A new phone with the same Google or Apple account usually gets the key automatically. You need this recovery key only when you switch between Android and iPhone or lose your phone. Nobody can recover it for you, not even us.'**
  String get recoveryKeyExplanation;

  /// No description provided for @recoveryKeySaveToPasswordManagerAction.
  ///
  /// In en, this message translates to:
  /// **'Save in password manager'**
  String get recoveryKeySaveToPasswordManagerAction;

  /// No description provided for @recoveryKeySaved.
  ///
  /// In en, this message translates to:
  /// **'Recovery key saved'**
  String get recoveryKeySaved;

  /// No description provided for @recoveryKeySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the recovery key.'**
  String get recoveryKeySaveFailed;

  /// No description provided for @recoveryKeyNotSavedHint.
  ///
  /// In en, this message translates to:
  /// **'Not saved yet'**
  String get recoveryKeyNotSavedHint;

  /// No description provided for @recoveryKeyCopyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy recovery key'**
  String get recoveryKeyCopyTooltip;

  /// No description provided for @recoveryKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'Recovery key copied'**
  String get recoveryKeyCopied;

  /// No description provided for @recoveryKeyConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'I saved it'**
  String get recoveryKeyConfirmAction;

  /// No description provided for @recoveryKeyConfirmFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your confirmation.'**
  String get recoveryKeyConfirmFailed;

  /// No description provided for @recoveryKeyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Guests have no recovery key. Link an account to get one.'**
  String get recoveryKeyUnavailable;

  /// No description provided for @dataKeyRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore your data'**
  String get dataKeyRestoreTitle;

  /// No description provided for @dataKeyRestoreExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your data is encrypted. Enter the recovery key that you saved when you created your account.'**
  String get dataKeyRestoreExplanation;

  /// No description provided for @dataKeyRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get dataKeyRestoreAction;

  /// No description provided for @dataKeyRestoreInvalid.
  ///
  /// In en, this message translates to:
  /// **'This recovery key is not correct.'**
  String get dataKeyRestoreInvalid;

  /// No description provided for @dataKeyRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not restore your data.'**
  String get dataKeyRestoreFailed;

  /// No description provided for @dataKeyStartFreshAction.
  ///
  /// In en, this message translates to:
  /// **'Start fresh without old data'**
  String get dataKeyStartFreshAction;

  /// No description provided for @dataKeyStartFreshDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete old data?'**
  String get dataKeyStartFreshDialogTitle;

  /// No description provided for @dataKeyStartFreshDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Without the recovery key, your diary, weight, and goals cannot be read. They will be deleted.'**
  String get dataKeyStartFreshDialogMessage;

  /// No description provided for @dataKeyStartFreshConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete and start fresh'**
  String get dataKeyStartFreshConfirmAction;

  /// No description provided for @dataKeyStartFreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start fresh.'**
  String get dataKeyStartFreshFailed;

  /// No description provided for @dataKeyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your data key. Check your connection.'**
  String get dataKeyLoadFailed;

  /// No description provided for @dataKeyRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get dataKeyRetryAction;

  /// No description provided for @dataKeyPickFromPasswordManagerAction.
  ///
  /// In en, this message translates to:
  /// **'Paste from password manager'**
  String get dataKeyPickFromPasswordManagerAction;

  /// No description provided for @dataKeyPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the password manager.'**
  String get dataKeyPickFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
