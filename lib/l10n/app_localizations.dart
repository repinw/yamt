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

  /// No description provided for @homeProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeProfile;

  /// No description provided for @homeProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get homeProgress;

  /// No description provided for @homeMenuTool.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get homeMenuTool;

  /// No description provided for @aiChefIdeaDescription.
  ///
  /// In en, this message translates to:
  /// **'The AI suggests a random recipe'**
  String get aiChefIdeaDescription;

  /// No description provided for @aiChefIdeaTitle.
  ///
  /// In en, this message translates to:
  /// **'AI recipe idea'**
  String get aiChefIdeaTitle;

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

  /// Shown instead of the empty search result while the device is offline.
  ///
  /// In en, this message translates to:
  /// **'No search without a connection. The search runs again once you are online.'**
  String get productSearchHubSearchOfflineState;

  /// No description provided for @eatPageAmountUnknown.
  ///
  /// In en, this message translates to:
  /// **'–'**
  String get eatPageAmountUnknown;

  /// No description provided for @productSearchHubMissingNutritionHint.
  ///
  /// In en, this message translates to:
  /// **'Required values are missing. Every EU nutrition label lists them.'**
  String get productSearchHubMissingNutritionHint;

  /// No description provided for @productEditorPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Two photos fill in the product. You only check it.'**
  String get productEditorPhotosHint;

  /// No description provided for @productEditorFrontPhoto.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get productEditorFrontPhoto;

  /// No description provided for @productEditorCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get productEditorCreateAction;

  /// No description provided for @productEditorSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get productEditorSaveAction;

  /// No description provided for @productEditorSaveChangesAction.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get productEditorSaveChangesAction;

  /// No description provided for @productEditorDoneAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get productEditorDoneAction;

  /// No description provided for @productEditorFrontPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Name, brand, size'**
  String get productEditorFrontPhotoHint;

  /// No description provided for @productEditorNutritionTablePhoto.
  ///
  /// In en, this message translates to:
  /// **'Nutrition table'**
  String get productEditorNutritionTablePhoto;

  /// No description provided for @productEditorNutritionTablePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Nutrition values'**
  String get productEditorNutritionTablePhotoHint;

  /// No description provided for @productEditorPhotoReading.
  ///
  /// In en, this message translates to:
  /// **'Reading …'**
  String get productEditorPhotoReading;

  /// No description provided for @productEditorMissing.
  ///
  /// In en, this message translates to:
  /// **'Still missing: {fields}'**
  String productEditorMissing(String fields);

  /// No description provided for @productEditorMissingValues.
  ///
  /// In en, this message translates to:
  /// **'{count} nutrition values'**
  String productEditorMissingValues(int count);

  /// No description provided for @productEditorMissingBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode – scan or “Has none”'**
  String get productEditorMissingBarcode;

  /// No description provided for @productMissingValuesHint.
  ///
  /// In en, this message translates to:
  /// **'Missing: {values} – add'**
  String productMissingValuesHint(String values);

  /// No description provided for @productPieceWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Grams per piece'**
  String get productPieceWeightLabel;

  /// Label before the choice between the serving the nutrition table read and the piece the package front read.
  ///
  /// In en, this message translates to:
  /// **'Serving'**
  String get productServingChoiceLabel;

  /// Chip of a serving without a name in the serving choice, such as "25 g".
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit}'**
  String productServingAmount(String amount, String unit);

  /// No description provided for @productEditorPhotoReadName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get productEditorPhotoReadName;

  /// No description provided for @productEditorPhotoReadValues.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 value} other{{count} values}}'**
  String productEditorPhotoReadValues(int count);

  /// No description provided for @productEditorPhotoRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get productEditorPhotoRead;

  /// No description provided for @productEditorPhotoRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get productEditorPhotoRetake;

  /// No description provided for @productEditorScanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get productEditorScanBarcode;

  /// No description provided for @productEditorNoBarcode.
  ///
  /// In en, this message translates to:
  /// **'Has none'**
  String get productEditorNoBarcode;

  /// No description provided for @productEditorBarcodeFromPhoto.
  ///
  /// In en, this message translates to:
  /// **'Found on the photo'**
  String get productEditorBarcodeFromPhoto;

  /// No description provided for @productEditorBarcodeFromAi.
  ///
  /// In en, this message translates to:
  /// **'Read by the AI, please check'**
  String get productEditorBarcodeFromAi;

  /// No description provided for @productEditorBarcodeMissing.
  ///
  /// In en, this message translates to:
  /// **'No barcode on the photos'**
  String get productEditorBarcodeMissing;

  /// No description provided for @productEditorCameraFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not take the photo.'**
  String get productEditorCameraFailed;

  /// No description provided for @productEditorCameraUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This device cannot take photos.'**
  String get productEditorCameraUnsupported;

  /// No description provided for @productEditorPhotosNotSaved.
  ///
  /// In en, this message translates to:
  /// **'The photos could not be stored. The product is saved without them.'**
  String get productEditorPhotosNotSaved;

  /// No description provided for @photoUploadQueued.
  ///
  /// In en, this message translates to:
  /// **'Photos will be uploaded later.'**
  String get photoUploadQueued;

  /// No description provided for @productEditorTakeNutritionTablePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photograph the nutrition table'**
  String get productEditorTakeNutritionTablePhoto;

  /// No description provided for @productSearchHubCreateProductAction.
  ///
  /// In en, this message translates to:
  /// **'Create product'**
  String get productSearchHubCreateProductAction;

  /// No description provided for @productSearchHubStoredInVorrat.
  ///
  /// In en, this message translates to:
  /// **'{name} is in stock'**
  String productSearchHubStoredInVorrat(String name);

  /// No description provided for @inventoryRestToStockQuestion.
  ///
  /// In en, this message translates to:
  /// **'Put the rest ({amount}) into stock?'**
  String inventoryRestToStockQuestion(String amount);

  /// No description provided for @inventoryRestToStockNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get inventoryRestToStockNo;

  /// No description provided for @inventoryRestToStockYes.
  ///
  /// In en, this message translates to:
  /// **'To stock'**
  String get inventoryRestToStockYes;

  /// No description provided for @inventoryPackChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Take from inventory?'**
  String get inventoryPackChoiceTitle;

  /// No description provided for @inventoryPackChoiceSkip.
  ///
  /// In en, this message translates to:
  /// **'Don\'t take'**
  String get inventoryPackChoiceSkip;

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
  /// **'Inventory'**
  String get inventoryPageTitle;

  /// No description provided for @inventoryPageKicker.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 food} other{{count} foods}}'**
  String inventoryPageKicker(int count);

  /// No description provided for @inventorySortAction.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get inventorySortAction;

  /// No description provided for @inventoryQuickFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get inventoryQuickFilterAll;

  /// No description provided for @inventoryQuickFilterPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get inventoryQuickFilterPlanned;

  /// No description provided for @inventoryQuickFilterOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get inventoryQuickFilterOpen;

  /// No description provided for @inventoryQuickFilterMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get inventoryQuickFilterMeals;

  /// No description provided for @inventoryQuickFilterLow.
  ///
  /// In en, this message translates to:
  /// **'Almost empty'**
  String get inventoryQuickFilterLow;

  /// No description provided for @inventoryRowOfAmount.
  ///
  /// In en, this message translates to:
  /// **'of {amount}'**
  String inventoryRowOfAmount(String amount);

  /// No description provided for @inventoryRowPlanMissing.
  ///
  /// In en, this message translates to:
  /// **'{amount} missing'**
  String inventoryRowPlanMissing(String amount);

  /// No description provided for @inventoryRowPlanned.
  ///
  /// In en, this message translates to:
  /// **'{amount} planned'**
  String inventoryRowPlanned(String amount);

  /// No description provided for @inventoryRowLow.
  ///
  /// In en, this message translates to:
  /// **'almost empty'**
  String get inventoryRowLow;

  /// No description provided for @inventoryRowInfo.
  ///
  /// In en, this message translates to:
  /// **'{first} · {second}'**
  String inventoryRowInfo(String first, String second);

  /// No description provided for @inventoryRowKcalPer100.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal/100 g'**
  String inventoryRowKcalPer100(String kcal);

  /// No description provided for @inventoryRowMealFromRecipe.
  ///
  /// In en, this message translates to:
  /// **'From recipe · {left} of {total} portions'**
  String inventoryRowMealFromRecipe(String left, int total);

  /// No description provided for @inventoryRowMealCombined.
  ///
  /// In en, this message translates to:
  /// **'Combined · {left} of {total} portions'**
  String inventoryRowMealCombined(String left, int total);

  /// No description provided for @inventoryMealInPot.
  ///
  /// In en, this message translates to:
  /// **'In the pot'**
  String get inventoryMealInPot;

  /// No description provided for @inventoryRowMealMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ingredient missing} other{{count} ingredients missing}}'**
  String inventoryRowMealMissing(int count);

  /// No description provided for @inventorySortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get inventorySortNewestFirst;

  /// No description provided for @inventorySortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get inventorySortOldestFirst;

  /// No description provided for @inventorySortLeastFirst.
  ///
  /// In en, this message translates to:
  /// **'Least first'**
  String get inventorySortLeastFirst;

  /// No description provided for @inventorySortMostFirst.
  ///
  /// In en, this message translates to:
  /// **'Most first'**
  String get inventorySortMostFirst;

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

  /// No description provided for @inventoryDockAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get inventoryDockAddAction;

  /// No description provided for @inventoryDockReceiptTool.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get inventoryDockReceiptTool;

  /// No description provided for @inventoryAddManualSearchDescription.
  ///
  /// In en, this message translates to:
  /// **'Find a food by name or brand'**
  String get inventoryAddManualSearchDescription;

  /// No description provided for @inventoryAddAiDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe a food and the AI estimates its nutrition'**
  String get inventoryAddAiDescription;

  /// No description provided for @inventoryAddCreateDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your own product, from photos or by hand'**
  String get inventoryAddCreateDescription;

  /// No description provided for @inventoryAddUploadDescription.
  ///
  /// In en, this message translates to:
  /// **'Read a receipt from an image or PDF'**
  String get inventoryAddUploadDescription;

  /// No description provided for @inventoryReceiptPhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Photograph receipt'**
  String get inventoryReceiptPhotoAction;

  /// No description provided for @inventoryReceiptPhotoDescription.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the receipt with the camera'**
  String get inventoryReceiptPhotoDescription;

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

  /// No description provided for @inventoryReceiptReviewFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get inventoryReceiptReviewFieldName;

  /// No description provided for @inventoryReceiptReviewFieldQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get inventoryReceiptReviewFieldQuantity;

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

  /// No description provided for @inventorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get inventorySearchHint;

  /// No description provided for @inventorySearchClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get inventorySearchClearAction;

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
  /// **'To diary'**
  String get inventoryItemEatSheetConfirmAction;

  /// No description provided for @eatPagePlanIconTooltip.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get eatPagePlanIconTooltip;

  /// No description provided for @eatPageStoreIconTooltip.
  ///
  /// In en, this message translates to:
  /// **'To stock'**
  String get eatPageStoreIconTooltip;

  /// No description provided for @eatPotWeighTitle.
  ///
  /// In en, this message translates to:
  /// **'Pot on the scale'**
  String get eatPotWeighTitle;

  /// No description provided for @eatPotWeighReminder.
  ///
  /// In en, this message translates to:
  /// **'Water may have evaporated since the last weighing. Weigh the pot again so it is right for everyone.'**
  String get eatPotWeighReminder;

  /// No description provided for @eatPotNetWeight.
  ///
  /// In en, this message translates to:
  /// **'− empty pot {tare} g = {net} g in the pot'**
  String eatPotNetWeight(int tare, int net);

  /// No description provided for @eatPotTakeOutHint.
  ///
  /// In en, this message translates to:
  /// **'Then tare the scale and enter the grams you took.'**
  String get eatPotTakeOutHint;

  /// No description provided for @eatPageRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get eatPageRest;

  /// No description provided for @eatPageRestHint.
  ///
  /// In en, this message translates to:
  /// **'Rest takes everything in the pot, so the sum is right without a scale.'**
  String get eatPageRestHint;

  /// No description provided for @eatPagePlanReminderHint.
  ///
  /// In en, this message translates to:
  /// **'A plan counts only once every row is filled. Until then it is a reminder without kcal.'**
  String get eatPagePlanReminderHint;

  /// No description provided for @eatPageMealPortionGrams.
  ///
  /// In en, this message translates to:
  /// **'{portions} · {grams} g'**
  String eatPageMealPortionGrams(String portions, int grams);

  /// No description provided for @eatPagePotUnit.
  ///
  /// In en, this message translates to:
  /// **'pot'**
  String get eatPagePotUnit;

  /// No description provided for @eatPagePlanAction.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get eatPagePlanAction;

  /// No description provided for @eatPageNutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get eatPageNutritionTitle;

  /// No description provided for @eatPageItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get eatPageItemTitle;

  /// No description provided for @eatPageMealTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get eatPageMealTitle;

  /// No description provided for @eatPageIngredientMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing – not taken from stock'**
  String get eatPageIngredientMissing;

  /// No description provided for @eatPageIngredientIgnored.
  ///
  /// In en, this message translates to:
  /// **'Ignored – not counted'**
  String get eatPageIngredientIgnored;

  /// No description provided for @eatPageIngredientNutritionIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Nutrition values incomplete'**
  String get eatPageIngredientNutritionIncomplete;

  /// No description provided for @eatPageReplaceProduct.
  ///
  /// In en, this message translates to:
  /// **'Replace product'**
  String get eatPageReplaceProduct;

  /// No description provided for @eatPageOnShoppingList.
  ///
  /// In en, this message translates to:
  /// **'On the shopping list'**
  String get eatPageOnShoppingList;

  /// No description provided for @eatPageCombineLink.
  ///
  /// In en, this message translates to:
  /// **'Combine with another food'**
  String get eatPageCombineLink;

  /// No description provided for @eatPageCombineAdd.
  ///
  /// In en, this message translates to:
  /// **'+ Add food'**
  String get eatPageCombineAdd;

  /// No description provided for @eatPageCombinePickConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get eatPageCombinePickConfirm;

  /// No description provided for @eatPageCombineNoMoreStock.
  ///
  /// In en, this message translates to:
  /// **'Every fitting food from your stock is already in the meal.'**
  String get eatPageCombineNoMoreStock;

  /// No description provided for @eatPageCombineNeedsNutrition.
  ///
  /// In en, this message translates to:
  /// **'This food has no nutrition values to add up.'**
  String get eatPageCombineNeedsNutrition;

  /// No description provided for @eatPageCombineAddFood.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get eatPageCombineAddFood;

  /// No description provided for @eatPageCombineStore.
  ///
  /// In en, this message translates to:
  /// **'Keep in stock'**
  String get eatPageCombineStore;

  /// No description provided for @eatPageMealTotal.
  ///
  /// In en, this message translates to:
  /// **'total {amount}'**
  String eatPageMealTotal(String amount);

  /// No description provided for @eatPageRemovePortion.
  ///
  /// In en, this message translates to:
  /// **'One portion less'**
  String get eatPageRemovePortion;

  /// No description provided for @eatPageAddPortion.
  ///
  /// In en, this message translates to:
  /// **'One portion more'**
  String get eatPageAddPortion;

  /// No description provided for @inventoryStockAddConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add to stock (1 package)} other{Add to stock ({count} packages)}}'**
  String inventoryStockAddConfirm(int count);

  /// No description provided for @eatPagePackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get eatPagePackages;

  /// No description provided for @eatPageRemovePackage.
  ///
  /// In en, this message translates to:
  /// **'One package less'**
  String get eatPageRemovePackage;

  /// No description provided for @eatPageAddPackage.
  ///
  /// In en, this message translates to:
  /// **'One package more'**
  String get eatPageAddPackage;

  /// No description provided for @eatPageMealPortions.
  ///
  /// In en, this message translates to:
  /// **'Portions'**
  String get eatPageMealPortions;

  /// No description provided for @eatPageMealPerPortion.
  ///
  /// In en, this message translates to:
  /// **'portion {amount}'**
  String eatPageMealPerPortion(String amount);

  /// No description provided for @eatPageMealUnknownValue.
  ///
  /// In en, this message translates to:
  /// **'–'**
  String get eatPageMealUnknownValue;

  /// No description provided for @eatPageCombineConfirm.
  ///
  /// In en, this message translates to:
  /// **'Meal to diary'**
  String get eatPageCombineConfirm;

  /// No description provided for @eatPageCombineRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from the list'**
  String get eatPageCombineRemove;

  /// No description provided for @eatPageCombineAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get eatPageCombineAmount;

  /// No description provided for @eatPageCombineSaved.
  ///
  /// In en, this message translates to:
  /// **'Meal logged.'**
  String get eatPageCombineSaved;

  /// No description provided for @eatPageCombineFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not log the meal.'**
  String get eatPageCombineFailed;

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

  /// Ruler chip name for the amount eaten last time, e.g. Last 80 g.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get eatPageRecentMark;

  /// Ruler chip name for the product's own serving when it has no name, e.g. Serving 25 g.
  ///
  /// In en, this message translates to:
  /// **'Serving'**
  String get eatPageServingMark;

  /// Ruler chip name for a quarter package, e.g. ¼ 125 g.
  ///
  /// In en, this message translates to:
  /// **'¼'**
  String get eatPageQuarterMark;

  /// Ruler chip name for half a package, e.g. ½ 250 g.
  ///
  /// In en, this message translates to:
  /// **'½'**
  String get eatPageHalfMark;

  /// Name of the portion count wheel on the eat page and title of the field that types a count.
  ///
  /// In en, this message translates to:
  /// **'Number of portions'**
  String get eatPageCountLabel;

  /// Name of the count wheel on the eat page of a food counted in pieces, and title of the field that types a count.
  ///
  /// In en, this message translates to:
  /// **'Number of pieces'**
  String get eatPagePieceCountLabel;

  /// Sign between the portion count wheel and the weight of one portion on the eat page.
  ///
  /// In en, this message translates to:
  /// **'×'**
  String get eatPageTimes;

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

  /// No description provided for @inventoryItemReanalyzeFailed.
  ///
  /// In en, this message translates to:
  /// **'The new estimate could not be applied.'**
  String get inventoryItemReanalyzeFailed;

  /// No description provided for @inventoryItemCannotPlan.
  ///
  /// In en, this message translates to:
  /// **'Could not plan: this amount needs the calorie editor'**
  String get inventoryItemCannotPlan;

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

  /// No description provided for @inventoryManualAddLookupOffline.
  ///
  /// In en, this message translates to:
  /// **'Without a connection, the barcode cannot be looked up. Try again once you are online.'**
  String get inventoryManualAddLookupOffline;

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

  /// No description provided for @inventoryManualAddAiSearchPer100CardTitle.
  ///
  /// In en, this message translates to:
  /// **'PER 100 G'**
  String get inventoryManualAddAiSearchPer100CardTitle;

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

  /// No description provided for @preparedMealEditLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Portions of this meal are already eaten, so its ingredients and portions stay fixed. You can still change the name and picture.'**
  String get preparedMealEditLockedHint;

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

  /// No description provided for @preparedMealEmptyIngredientsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add at least one ingredient before saving.'**
  String get preparedMealEmptyIngredientsMessage;

  /// No description provided for @preparedMealBindAction.
  ///
  /// In en, this message translates to:
  /// **'Combine foods'**
  String get preparedMealBindAction;

  /// Hint above the selection count when only catalog foods are selected; a meal needs one food from the inventory before it can be confirmed.
  ///
  /// In en, this message translates to:
  /// **'Pick a food from the inventory'**
  String get preparedMealSelectionNeedsStockFood;

  /// No description provided for @preparedMealSelectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String preparedMealSelectionCount(int count);

  /// No description provided for @inventorySelectionCatalogSearch.
  ///
  /// In en, this message translates to:
  /// **'Search the catalog'**
  String get inventorySelectionCatalogSearch;

  /// No description provided for @inventorySelectionCatalogSearchQuery.
  ///
  /// In en, this message translates to:
  /// **'Search “{query}” in the catalog'**
  String inventorySelectionCatalogSearchQuery(String query);

  /// No description provided for @inventorySelectionCatalogFoodRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from the meal'**
  String get inventorySelectionCatalogFoodRemove;

  /// No description provided for @preparedMealUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Prepared meal updated.'**
  String get preparedMealUpdatedMessage;

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
  /// **'Add ingredient from stock'**
  String get preparedMealPendingIngredientSelectionTitle;

  /// No description provided for @preparedMealPendingIngredientSelectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No item in stock fits this ingredient.'**
  String get preparedMealPendingIngredientSelectionEmpty;

  /// No description provided for @preparedMealPendingIngredientSelectionUnitHint.
  ///
  /// In en, this message translates to:
  /// **'Only items that supply the amount in its unit.'**
  String get preparedMealPendingIngredientSelectionUnitHint;

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

  /// No description provided for @preparedMealPendingIngredientUnignoreAction.
  ///
  /// In en, this message translates to:
  /// **'Stop ignoring'**
  String get preparedMealPendingIngredientUnignoreAction;

  /// No description provided for @preparedMealPendingIngredientUnignoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Ingredient could not be opened again.'**
  String get preparedMealPendingIngredientUnignoreFailed;

  /// No description provided for @preparedMealUnassignAction.
  ///
  /// In en, this message translates to:
  /// **'Remove assignment'**
  String get preparedMealUnassignAction;

  /// No description provided for @preparedMealUnassignFailed.
  ///
  /// In en, this message translates to:
  /// **'Assignment could not be removed.'**
  String get preparedMealUnassignFailed;

  /// No description provided for @preparedMealEditDeleteRowAction.
  ///
  /// In en, this message translates to:
  /// **'Delete row'**
  String get preparedMealEditDeleteRowAction;

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

  /// No description provided for @preparedMealWeightAction.
  ///
  /// In en, this message translates to:
  /// **'Change weight'**
  String get preparedMealWeightAction;

  /// No description provided for @preparedMealWeightWholeHint.
  ///
  /// In en, this message translates to:
  /// **'Weigh the whole dish, ideally once it has cooled. Grams per portion and per 100 g are worked out again from it.'**
  String get preparedMealWeightWholeHint;

  /// Hint of the weight dialog of a cooked meal with portions already eaten
  ///
  /// In en, this message translates to:
  /// **'Weigh what is left: {portions} of {total} portions. Grams per portion and per 100 g are worked out again from it. Diary entries stay as they are.'**
  String preparedMealWeightLeftHint(String portions, int total);

  /// No description provided for @preparedMealWeightFoodLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight of the food'**
  String get preparedMealWeightFoodLabel;

  /// Helper under the weight field: the weight of the food left that the app knows now
  ///
  /// In en, this message translates to:
  /// **'So far {grams} g'**
  String preparedMealWeightCurrent(int grams);

  /// No description provided for @preparedMealWeightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a weight in grams.'**
  String get preparedMealWeightInvalid;

  /// No description provided for @preparedMealWeightFailed.
  ///
  /// In en, this message translates to:
  /// **'The weight could not be saved.'**
  String get preparedMealWeightFailed;

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

  /// No description provided for @preparedMealTemplateNameSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get preparedMealTemplateNameSave;

  /// No description provided for @preparedMealTemplateNoFoods.
  ///
  /// In en, this message translates to:
  /// **'No food in your stock has an amount left and full nutrition values.'**
  String get preparedMealTemplateNoFoods;

  /// No description provided for @preparedMealTemplateCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the template.'**
  String get preparedMealTemplateCreateFailed;

  /// No description provided for @preparedMealTemplateSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Template saved.'**
  String get preparedMealTemplateSavedMessage;

  /// No description provided for @preparedMealTemplatesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load templates.'**
  String get preparedMealTemplatesLoadFailed;

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

  /// No description provided for @preparedMealTemplateAddRecipeDescription.
  ///
  /// In en, this message translates to:
  /// **'Import a recipe from a web page'**
  String get preparedMealTemplateAddRecipeDescription;

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

  /// No description provided for @kitchenUtensilsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Kitchen utensils'**
  String get kitchenUtensilsPageTitle;

  /// No description provided for @kitchenUtensilsToolLabel.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get kitchenUtensilsToolLabel;

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

  /// No description provided for @caloriesOcrRetakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Not every mandatory value of the nutrition table was clearly readable. Please take a sharp photo of the whole table without glare.'**
  String get caloriesOcrRetakePhoto;

  /// No description provided for @caloriesOcrRetakePhotoAction.
  ///
  /// In en, this message translates to:
  /// **'New photo'**
  String get caloriesOcrRetakePhotoAction;

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
  /// **'Choose what matches your daily life. Training counts separately through your training days.'**
  String get caloriesCalculatorActivityLevelHelp;

  /// No description provided for @caloriesCalculatorActivityLevelNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get caloriesCalculatorActivityLevelNoneTitle;

  /// No description provided for @caloriesCalculatorActivityLevelNoneDescription.
  ///
  /// In en, this message translates to:
  /// **'Office work, lots of sitting, few steps.'**
  String get caloriesCalculatorActivityLevelNoneDescription;

  /// No description provided for @caloriesCalculatorActivityLevelLowTitle.
  ///
  /// In en, this message translates to:
  /// **'Lightly active'**
  String get caloriesCalculatorActivityLevelLowTitle;

  /// No description provided for @caloriesCalculatorActivityLevelLowDescription.
  ///
  /// In en, this message translates to:
  /// **'Mostly sitting, but with some daily movement.'**
  String get caloriesCalculatorActivityLevelLowDescription;

  /// No description provided for @caloriesCalculatorActivityLevelMediumTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderately active'**
  String get caloriesCalculatorActivityLevelMediumTitle;

  /// No description provided for @caloriesCalculatorActivityLevelMediumDescription.
  ///
  /// In en, this message translates to:
  /// **'On your feet a lot, at work or in daily life.'**
  String get caloriesCalculatorActivityLevelMediumDescription;

  /// No description provided for @caloriesCalculatorActivityLevelHighTitle.
  ///
  /// In en, this message translates to:
  /// **'Very active'**
  String get caloriesCalculatorActivityLevelHighTitle;

  /// No description provided for @caloriesCalculatorActivityLevelHighDescription.
  ///
  /// In en, this message translates to:
  /// **'A physically active job with lots of walking and carrying.'**
  String get caloriesCalculatorActivityLevelHighDescription;

  /// No description provided for @caloriesCalculatorActivityLevelExtremeTitle.
  ///
  /// In en, this message translates to:
  /// **'Extremely active'**
  String get caloriesCalculatorActivityLevelExtremeTitle;

  /// No description provided for @caloriesCalculatorActivityLevelExtremeDescription.
  ///
  /// In en, this message translates to:
  /// **'Heavy physical work all day.'**
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

  /// No description provided for @tdeeWeightStatTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend weight'**
  String get tdeeWeightStatTrend;

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

  /// No description provided for @caloriesNewGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get caloriesNewGoalTitle;

  /// No description provided for @caloriesNewGoalStartsOn.
  ///
  /// In en, this message translates to:
  /// **'Daily target from {date}'**
  String caloriesNewGoalStartsOn(String date);

  /// No description provided for @caloriesNewGoalTdee.
  ///
  /// In en, this message translates to:
  /// **'TDEE {kcal} kcal'**
  String caloriesNewGoalTdee(String kcal);

  /// No description provided for @caloriesNewGoalTargetDetail.
  ///
  /// In en, this message translates to:
  /// **'Current weight: {weight} kg · {mode}'**
  String caloriesNewGoalTargetDetail(String weight, String mode);

  /// No description provided for @caloriesNewGoalTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target weight'**
  String get caloriesNewGoalTargetLabel;

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

  /// No description provided for @caloriesLearnedTdeeRunRestartFailed.
  ///
  /// In en, this message translates to:
  /// **'Goal saved, but the run could not restart.'**
  String get caloriesLearnedTdeeRunRestartFailed;

  /// No description provided for @caloriesWeeklyCheckInDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly check-in'**
  String get caloriesWeeklyCheckInDialogTitle;

  /// No description provided for @caloriesWeeklyCheckInDialogBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'We still need a bit more data before this weekly summary is complete.'**
  String get caloriesWeeklyCheckInDialogBlockedBody;

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

  /// No description provided for @caloriesWeeklyCheckInRedoAction.
  ///
  /// In en, this message translates to:
  /// **'Redo check-in'**
  String get caloriesWeeklyCheckInRedoAction;

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

  /// No description provided for @diaryWeightSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save weight.'**
  String get diaryWeightSaveFailed;

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

  /// A nutrition label value that is a minimum: some foods of the meal do not list the nutrient, so the true value can only be higher.
  ///
  /// In en, this message translates to:
  /// **'≥ {value}'**
  String caloriesNutritionTableAtLeast(String value);

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

  /// No description provided for @caloriesEatAgainMissedStockMessage.
  ///
  /// In en, this message translates to:
  /// **'Logged again. Your inventory ran out, so it is empty now.'**
  String get caloriesEatAgainMissedStockMessage;

  /// No description provided for @diaryEntryAgainAction.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get diaryEntryAgainAction;

  /// No description provided for @caloriesEntryPer100Label.
  ///
  /// In en, this message translates to:
  /// **'Per 100 {unit}'**
  String caloriesEntryPer100Label(String unit);

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

  /// No description provided for @inventoryReceiptReviewManualAddNutritionAction.
  ///
  /// In en, this message translates to:
  /// **'Add more nutrients'**
  String get inventoryReceiptReviewManualAddNutritionAction;

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

  /// Screen reader label of the Today button in the diary top bar, shown while another day is selected.
  ///
  /// In en, this message translates to:
  /// **'Go to today'**
  String get diaryJumpToTodayAction;

  /// No description provided for @diaryYesterdayTitle.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get diaryYesterdayTitle;

  /// No description provided for @diaryTomorrowTitle.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get diaryTomorrowTitle;

  /// No description provided for @diaryDayAfterTomorrowTitle.
  ///
  /// In en, this message translates to:
  /// **'In 2 days'**
  String get diaryDayAfterTomorrowTitle;

  /// No description provided for @diaryDayTypeTraining.
  ///
  /// In en, this message translates to:
  /// **'Training day'**
  String get diaryDayTypeTraining;

  /// No description provided for @diaryDayTypeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal day'**
  String get diaryDayTypeNormal;

  /// No description provided for @diaryDayTypePause.
  ///
  /// In en, this message translates to:
  /// **'Pause day'**
  String get diaryDayTypePause;

  /// No description provided for @diaryDayTypeTrainingShort.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get diaryDayTypeTrainingShort;

  /// No description provided for @diaryDayTypeNormalShort.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get diaryDayTypeNormalShort;

  /// No description provided for @diaryDayTypePauseShort.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get diaryDayTypePauseShort;

  /// No description provided for @diaryMealsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Meals could not be loaded'**
  String get diaryMealsLoadFailed;

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

  /// No description provided for @diaryQuickEatSourceQuickEntry.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get diaryQuickEatSourceQuickEntry;

  /// No description provided for @diaryQuickEntryDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Quick entry'**
  String get diaryQuickEntryDefaultName;

  /// No description provided for @diaryQuickEntryKcalLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get diaryQuickEntryKcalLabel;

  /// No description provided for @diaryQuickEntryValuesHeader.
  ///
  /// In en, this message translates to:
  /// **'Eaten'**
  String get diaryQuickEntryValuesHeader;

  /// No description provided for @diaryQuickEntryKcalMissing.
  ///
  /// In en, this message translates to:
  /// **'Still missing: calories'**
  String get diaryQuickEntryKcalMissing;

  /// No description provided for @diaryQuickEntryAiHint.
  ///
  /// In en, this message translates to:
  /// **'Missing macros count as 0 g. The AI estimate is more precise.'**
  String get diaryQuickEntryAiHint;

  /// No description provided for @diaryQuickEntryAiAction.
  ///
  /// In en, this message translates to:
  /// **'Estimate with AI instead'**
  String get diaryQuickEntryAiAction;

  /// No description provided for @diaryQuickEntrySaved.
  ///
  /// In en, this message translates to:
  /// **'Added to diary'**
  String get diaryQuickEntrySaved;

  /// No description provided for @diaryPlanSavedFor.
  ///
  /// In en, this message translates to:
  /// **'Planned for {day}'**
  String diaryPlanSavedFor(String day);

  /// No description provided for @diaryPlanSavedToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get diaryPlanSavedToday;

  /// No description provided for @diaryPlanSavedTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get diaryPlanSavedTomorrow;

  /// No description provided for @diaryPlanSaved.
  ///
  /// In en, this message translates to:
  /// **'Planned for the day'**
  String get diaryPlanSaved;

  /// No description provided for @diaryPlanDeleted.
  ///
  /// In en, this message translates to:
  /// **'Plan deleted'**
  String get diaryPlanDeleted;

  /// No description provided for @diaryPlanDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Plan could not be deleted'**
  String get diaryPlanDeleteFailed;

  /// No description provided for @diaryPlanSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save plan'**
  String get diaryPlanSaveAction;

  /// No description provided for @diaryPlanChanged.
  ///
  /// In en, this message translates to:
  /// **'Plan changed'**
  String get diaryPlanChanged;

  /// No description provided for @diaryPlanChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Plan could not be changed'**
  String get diaryPlanChangeFailed;

  /// No description provided for @diaryPlanCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Also plan for…'**
  String get diaryPlanCopyAction;

  /// No description provided for @diaryPlanCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'Also plan for'**
  String get diaryPlanCopyTitle;

  /// No description provided for @diaryPlanCopyRange.
  ///
  /// In en, this message translates to:
  /// **'{month} · 2 weeks'**
  String diaryPlanCopyRange(String month);

  /// No description provided for @diaryPlanCopyPlannedLegend.
  ///
  /// In en, this message translates to:
  /// **'• already planned'**
  String get diaryPlanCopyPlannedLegend;

  /// No description provided for @diaryPlanCopyMealLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get diaryPlanCopyMealLabel;

  /// No description provided for @diaryPlanCopyConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Pick days} =1{Plan 1 day} other{Plan {count} days}}'**
  String diaryPlanCopyConfirm(int count);

  /// No description provided for @diaryPlanCopyConfirmKcal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Plan 1 day} other{Plan {count} days}} · {kcal} kcal'**
  String diaryPlanCopyConfirmKcal(int count, int kcal);

  /// No description provided for @diaryPlanCopied.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Planned on 1 more day} other{Planned on {count} more days}}'**
  String diaryPlanCopied(int count);

  /// No description provided for @diaryMealCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy as plan'**
  String get diaryMealCopyAction;

  /// No description provided for @diaryMealCopyPickMeal.
  ///
  /// In en, this message translates to:
  /// **'Pick a meal'**
  String get diaryMealCopyPickMeal;

  /// No description provided for @diaryMealCopyDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'To which days'**
  String get diaryMealCopyDaysLabel;

  /// No description provided for @diaryPlanCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Plans could not be saved'**
  String get diaryPlanCopyFailed;

  /// No description provided for @diaryPlanSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get diaryPlanSemanticsLabel;

  /// No description provided for @diaryPlanAcceptAction.
  ///
  /// In en, this message translates to:
  /// **'Eaten as planned'**
  String get diaryPlanAcceptAction;

  /// No description provided for @diaryPlanAccepted.
  ///
  /// In en, this message translates to:
  /// **'Eaten as planned'**
  String get diaryPlanAccepted;

  /// No description provided for @diaryPlanAcceptedWithoutStock.
  ///
  /// In en, this message translates to:
  /// **'Logged – no longer in stock'**
  String get diaryPlanAcceptedWithoutStock;

  /// No description provided for @diaryPlanAcceptedRecipe.
  ///
  /// In en, this message translates to:
  /// **'Logged – stock not deducted'**
  String get diaryPlanAcceptedRecipe;

  /// No description provided for @diaryPlanAcceptFailed.
  ///
  /// In en, this message translates to:
  /// **'Plan could not be logged'**
  String get diaryPlanAcceptFailed;

  /// No description provided for @diaryPlanRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove from plan'**
  String get diaryPlanRemoveAction;

  /// No description provided for @diaryOverduePlansHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Open plans from {day}} other{Open plans on {count} days, last {day}}}'**
  String diaryOverduePlansHint(int count, String day);

  /// No description provided for @diaryPlanAcceptLaterHint.
  ///
  /// In en, this message translates to:
  /// **'From the planned day on'**
  String get diaryPlanAcceptLaterHint;

  /// No description provided for @diaryPlanAcceptAllAction.
  ///
  /// In en, this message translates to:
  /// **'Eat all as planned'**
  String get diaryPlanAcceptAllAction;

  /// No description provided for @diaryPlansAccepted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 plan eaten} other{{count} plans eaten}}'**
  String diaryPlansAccepted(int count);

  /// No description provided for @diaryPlansAcceptedPartly.
  ///
  /// In en, this message translates to:
  /// **'{eaten} of {total} plans eaten'**
  String diaryPlansAcceptedPartly(int eaten, int total);

  /// No description provided for @diaryPlansAcceptedWithoutStock.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 plan eaten – not all in stock} other{{count} plans eaten – not all in stock}}'**
  String diaryPlansAcceptedWithoutStock(int count);

  /// No description provided for @diaryPlanAcceptMealInPot.
  ///
  /// In en, this message translates to:
  /// **'Mark the meal as cooked first'**
  String get diaryPlanAcceptMealInPot;

  /// No description provided for @diaryPlanAcceptMealGone.
  ///
  /// In en, this message translates to:
  /// **'The meal is no longer in stock'**
  String get diaryPlanAcceptMealGone;

  /// No description provided for @diaryPlanAcceptNutritionPending.
  ///
  /// In en, this message translates to:
  /// **'Fill the open rows of the meal first'**
  String get diaryPlanAcceptNutritionPending;

  /// No description provided for @diaryPlanAcceptRecipePending.
  ///
  /// In en, this message translates to:
  /// **'Match every ingredient of the recipe to a stock item first'**
  String get diaryPlanAcceptRecipePending;

  /// No description provided for @diaryPlanAcceptRecipeGone.
  ///
  /// In en, this message translates to:
  /// **'The recipe is no longer in the cookbook'**
  String get diaryPlanAcceptRecipeGone;

  /// No description provided for @diaryPlanNutritionPending.
  ///
  /// In en, this message translates to:
  /// **'kcal open'**
  String get diaryPlanNutritionPending;

  /// No description provided for @diaryPlanShortTag.
  ///
  /// In en, this message translates to:
  /// **'Not in stock'**
  String get diaryPlanShortTag;

  /// No description provided for @diaryPlanMealPrepTag.
  ///
  /// In en, this message translates to:
  /// **'Meal Prep'**
  String get diaryPlanMealPrepTag;

  /// No description provided for @diaryBalanceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Balance could not be loaded'**
  String get diaryBalanceLoadFailed;

  /// No description provided for @diaryBalanceEatenLabel.
  ///
  /// In en, this message translates to:
  /// **'Eaten'**
  String get diaryBalanceEatenLabel;

  /// No description provided for @diaryBalanceLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get diaryBalanceLeftLabel;

  /// No description provided for @diaryBalanceAfterPlanChip.
  ///
  /// In en, this message translates to:
  /// **'After plan'**
  String get diaryBalanceAfterPlanChip;

  /// No description provided for @diaryBalanceLeftAfterPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Left after plan'**
  String get diaryBalanceLeftAfterPlanLabel;

  /// No description provided for @diaryMealsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing eaten yet'**
  String get diaryMealsEmptyTitle;

  /// No description provided for @diaryMealsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap “Eat” below to log food by barcode, from the inventory, search, or AI.'**
  String get diaryMealsEmptyHint;

  /// No description provided for @diaryMealsPlanEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned yet'**
  String get diaryMealsPlanEmptyTitle;

  /// No description provided for @diaryMealsPlanEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap “Eat” below to add what you want to eat on this day.'**
  String get diaryMealsPlanEmptyHint;

  /// No description provided for @diaryMacroEatenOfTarget.
  ///
  /// In en, this message translates to:
  /// **'{eaten} / {target} g'**
  String diaryMacroEatenOfTarget(String eaten, String target);

  /// No description provided for @diaryMealEntryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry} other{{count} entries}}'**
  String diaryMealEntryCount(int count);

  /// No description provided for @progressGoalAverageKcal.
  ///
  /// In en, this message translates to:
  /// **'Ø {kcal} kcal/day'**
  String progressGoalAverageKcal(String kcal);

  /// No description provided for @progressGoalAboveStart.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg above start'**
  String progressGoalAboveStart(String kg);

  /// No description provided for @progressGoalBelowStart.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg below start'**
  String progressGoalBelowStart(String kg);

  /// No description provided for @progressAveragePerDay.
  ///
  /// In en, this message translates to:
  /// **'average per day'**
  String get progressAveragePerDay;

  /// No description provided for @progressScopeGoal.
  ///
  /// In en, this message translates to:
  /// **'Current goal'**
  String get progressScopeGoal;

  /// No description provided for @progressScopeAll.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get progressScopeAll;

  /// No description provided for @progressScopePastGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get progressScopePastGoal;

  /// No description provided for @progressRunKicker.
  ///
  /// In en, this message translates to:
  /// **'Run {run} · day {day} of {total}'**
  String progressRunKicker(int run, int day, int total);

  /// No description provided for @progressDayTypeKickerGoal.
  ///
  /// In en, this message translates to:
  /// **'Since goal start · average'**
  String get progressDayTypeKickerGoal;

  /// Kicker above the day-type stats when a past goal is selected; the average is over that goal.
  ///
  /// In en, this message translates to:
  /// **'Goal {number} · average'**
  String progressDayTypeKickerPastGoal(int number);

  /// No description provided for @progressDayTypeKickerAll.
  ///
  /// In en, this message translates to:
  /// **'All goals · average'**
  String get progressDayTypeKickerAll;

  /// No description provided for @progressGoalMarker.
  ///
  /// In en, this message translates to:
  /// **'Goal {number}'**
  String progressGoalMarker(int number);

  /// No description provided for @progressGoalMenuRunning.
  ///
  /// In en, this message translates to:
  /// **'Goal {number} · running'**
  String progressGoalMenuRunning(int number);

  /// No description provided for @progressGoalMenuSince.
  ///
  /// In en, this message translates to:
  /// **'since {date}'**
  String progressGoalMenuSince(String date);

  /// No description provided for @progressGoalMenuRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String progressGoalMenuRange(String start, String end);

  /// No description provided for @progressGoalWeightValue.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg'**
  String progressGoalWeightValue(String weight);

  /// No description provided for @progressGoalSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get progressGoalSpeedLabel;

  /// No description provided for @progressGoalSpeedValue.
  ///
  /// In en, this message translates to:
  /// **'{speed} kg/week'**
  String progressGoalSpeedValue(String speed);

  /// No description provided for @progressGoalStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get progressGoalStartLabel;

  /// No description provided for @progressGoalStartWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Starting weight'**
  String get progressGoalStartWeightLabel;

  /// No description provided for @progressGoalEndWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Ending weight'**
  String get progressGoalEndWeightLabel;

  /// No description provided for @progressGoalEndLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get progressGoalEndLabel;

  /// No description provided for @progressGoalReachedLabel.
  ///
  /// In en, this message translates to:
  /// **'Reached'**
  String get progressGoalReachedLabel;

  /// No description provided for @progressWeekKicker.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String progressWeekKicker(String start, String end);

  /// No description provided for @progressGoalKcal.
  ///
  /// In en, this message translates to:
  /// **'Goal {kcal}'**
  String progressGoalKcal(String kcal);

  /// No description provided for @progressKcalUnderGoal.
  ///
  /// In en, this message translates to:
  /// **'{kcal} under goal'**
  String progressKcalUnderGoal(String kcal);

  /// No description provided for @progressKcalOverGoal.
  ///
  /// In en, this message translates to:
  /// **'{kcal} over goal'**
  String progressKcalOverGoal(String kcal);

  /// No description provided for @progressWeekBudgetKicker.
  ///
  /// In en, this message translates to:
  /// **'Week budget · {start} – {end}'**
  String progressWeekBudgetKicker(String start, String end);

  /// No description provided for @progressWeekBudgetValue.
  ///
  /// In en, this message translates to:
  /// **'{eaten} / {goal} kcal'**
  String progressWeekBudgetValue(String eaten, String goal);

  /// No description provided for @progressWeekBudgetLeft.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal left'**
  String progressWeekBudgetLeft(String kcal);

  /// No description provided for @progressWeekBudgetOver.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal over'**
  String progressWeekBudgetOver(String kcal);

  /// No description provided for @progressDayBarLegend.
  ///
  /// In en, this message translates to:
  /// **'Bar = daily goal in quarters'**
  String get progressDayBarLegend;

  /// No description provided for @progressMacroGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal {grams} g'**
  String progressMacroGoal(String grams);

  /// No description provided for @progressGrams.
  ///
  /// In en, this message translates to:
  /// **'{grams} g'**
  String progressGrams(String grams);

  /// No description provided for @progressWeightKicker.
  ///
  /// In en, this message translates to:
  /// **'Weight · trend'**
  String get progressWeightKicker;

  /// No description provided for @progressWeightPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg / week'**
  String progressWeightPerWeek(String kg);

  /// No description provided for @progressWeightForecast.
  ///
  /// In en, this message translates to:
  /// **'expected {date}'**
  String progressWeightForecast(String date);

  /// No description provided for @progressWeightGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached'**
  String get progressWeightGoalReached;

  /// No description provided for @progressWeightLegendWeighIn.
  ///
  /// In en, this message translates to:
  /// **'Weigh-in'**
  String get progressWeightLegendWeighIn;

  /// No description provided for @progressWeightLegendTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get progressWeightLegendTrend;

  /// No description provided for @progressWeightEmpty.
  ///
  /// In en, this message translates to:
  /// **'No weigh-ins in the last four weeks.'**
  String get progressWeightEmpty;

  /// No description provided for @progressToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get progressToday;

  /// No description provided for @progressTdeeKicker.
  ///
  /// In en, this message translates to:
  /// **'TDEE · daily'**
  String get progressTdeeKicker;

  /// No description provided for @progressTdeeChange.
  ///
  /// In en, this message translates to:
  /// **'{kcal} since yesterday'**
  String progressTdeeChange(String kcal);

  /// No description provided for @progressTdeeWeekChange.
  ///
  /// In en, this message translates to:
  /// **'{kcal} this week'**
  String progressTdeeWeekChange(String kcal);

  /// No description provided for @progressTdeeNextCheckIn.
  ///
  /// In en, this message translates to:
  /// **'next check-in {date}'**
  String progressTdeeNextCheckIn(String date);

  /// No description provided for @progressTdeeCheckInOpen.
  ///
  /// In en, this message translates to:
  /// **'Check-in waits in the diary'**
  String get progressTdeeCheckInOpen;

  /// No description provided for @progressTdeeLegendLine.
  ///
  /// In en, this message translates to:
  /// **'TDEE'**
  String get progressTdeeLegendLine;

  /// No description provided for @progressTdeeLegendDay.
  ///
  /// In en, this message translates to:
  /// **'Daily value'**
  String get progressTdeeLegendDay;

  /// No description provided for @progressTdeeLegendCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get progressTdeeLegendCheckIn;

  /// No description provided for @progressTdeeEmpty.
  ///
  /// In en, this message translates to:
  /// **'The curve starts with your first goal.'**
  String get progressTdeeEmpty;

  /// No description provided for @progressDayTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Training vs. normal day'**
  String get progressDayTypeTitle;

  /// No description provided for @progressDayTypeDays.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {type} · {count, plural, =1{1 day} other{{count} days}}'**
  String progressDayTypeDays(String emoji, String type, int count);

  /// No description provided for @progressKcal.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String progressKcal(String kcal);

  /// No description provided for @progressEaten.
  ///
  /// In en, this message translates to:
  /// **'Eaten'**
  String get progressEaten;

  /// No description provided for @progressDayTypeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Log a few days to compare training and normal days.'**
  String get progressDayTypeEmpty;

  /// No description provided for @progressLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this section.'**
  String get progressLoadFailed;

  /// No description provided for @diaryBalanceBaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get diaryBalanceBaseLabel;

  /// No description provided for @diaryBalancePlannedLabel.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get diaryBalancePlannedLabel;

  /// No description provided for @diaryPreviousDayCloseAction.
  ///
  /// In en, this message translates to:
  /// **'Close {weekday}'**
  String diaryPreviousDayCloseAction(String weekday);

  /// No description provided for @diaryPreviousDayClosed.
  ///
  /// In en, this message translates to:
  /// **'{weekday} closed'**
  String diaryPreviousDayClosed(String weekday);

  /// Snack bar when a day type change (normal, training, pause) from the diary budget card was not saved.
  ///
  /// In en, this message translates to:
  /// **'Could not change the day type.'**
  String get diaryDayTypeSaveFailed;

  /// No description provided for @diaryPreviousDayCloseFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not close {weekday}.'**
  String diaryPreviousDayCloseFailed(String weekday);

  /// No description provided for @diaryPreviousDayReopenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reopen {weekday}.'**
  String diaryPreviousDayReopenFailed(String weekday);

  /// No description provided for @diaryPreviousDayReopenAction.
  ///
  /// In en, this message translates to:
  /// **'Reopen {weekday}'**
  String diaryPreviousDayReopenAction(String weekday);

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
  /// **'Day\'s calculation'**
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
  /// **'Normal day adjustment'**
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

  /// No description provided for @diaryBudgetDetailsPlannedLabel.
  ///
  /// In en, this message translates to:
  /// **'Open plans'**
  String get diaryBudgetDetailsPlannedLabel;

  /// No description provided for @diaryBudgetDetailsLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'Left'**
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
  /// **'Macro impact: Carbs {carbs} · Fat {fat}'**
  String diaryBudgetDetailsMacroAdjustment(String carbs, String fat);

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

  /// No description provided for @caloriesCombinedFoodCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 food} other{{count} foods}}'**
  String caloriesCombinedFoodCount(int count);

  /// No description provided for @caloriesCombinedEntryLabel.
  ///
  /// In en, this message translates to:
  /// **'Combined'**
  String get caloriesCombinedEntryLabel;

  /// Diary amount of an entry eaten as a named portion, e.g. 2× 40 g Brotscheibe.
  ///
  /// In en, this message translates to:
  /// **'{count}× {amount} {unit} {label}'**
  String caloriesCountedPortion(
    String count,
    String amount,
    String unit,
    String label,
  );

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

  /// No description provided for @settingsProfileSummaryHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get settingsProfileSummaryHeightLabel;

  /// No description provided for @settingsProfileSummaryHeightValue.
  ///
  /// In en, this message translates to:
  /// **'{height} cm'**
  String settingsProfileSummaryHeightValue(String height);

  /// No description provided for @settingsProfileSummaryAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get settingsProfileSummaryAgeLabel;

  /// No description provided for @settingsProfileSummaryAgeValue.
  ///
  /// In en, this message translates to:
  /// **'{age, plural, =1{1 year} other{{age} years}}'**
  String settingsProfileSummaryAgeValue(int age);

  /// No description provided for @settingsProfileSummaryNoProfile.
  ///
  /// In en, this message translates to:
  /// **'No body data yet. The calorie calculator saves it.'**
  String get settingsProfileSummaryNoProfile;

  /// No description provided for @settingsProfileSummaryCaloriesValue.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal/day'**
  String settingsProfileSummaryCaloriesValue(String kcal);

  /// No description provided for @settingsProfileSummaryWeightValue.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg'**
  String settingsProfileSummaryWeightValue(String weight);

  /// No description provided for @settingsProfileSummaryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile.'**
  String get settingsProfileSummaryLoadFailed;

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
  /// **'Carbohydrates fill the remaining calories, up to {percent}%'**
  String settingsMacroGoalsCarbsAutoLabel(int percent);

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

  /// No description provided for @settingsThemeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeModeTitle;

  /// No description provided for @settingsThemeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeModeSystem;

  /// No description provided for @settingsThemeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeModeLight;

  /// No description provided for @settingsThemeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeModeDark;

  /// No description provided for @settingsAccentTitle.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get settingsAccentTitle;

  /// No description provided for @settingsAccentLime.
  ///
  /// In en, this message translates to:
  /// **'Lime'**
  String get settingsAccentLime;

  /// No description provided for @settingsAccentPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get settingsAccentPink;

  /// No description provided for @settingsAccentViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get settingsAccentViolet;

  /// No description provided for @settingsAccentCyan.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get settingsAccentCyan;

  /// No description provided for @settingsAccentEmerald.
  ///
  /// In en, this message translates to:
  /// **'Emerald'**
  String get settingsAccentEmerald;

  /// No description provided for @settingsDesignCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get settingsDesignCustom;

  /// No description provided for @settingsCustomBaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Start from which design?'**
  String get settingsCustomBaseTitle;

  /// No description provided for @settingsCustomBaseMessage.
  ///
  /// In en, this message translates to:
  /// **'Custom starts as a copy. Then you can change every color.'**
  String get settingsCustomBaseMessage;

  /// No description provided for @settingsCustomColorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit colors'**
  String get settingsCustomColorsTitle;

  /// No description provided for @settingsCustomColorsBasedOnLight.
  ///
  /// In en, this message translates to:
  /// **'Based on Light'**
  String get settingsCustomColorsBasedOnLight;

  /// No description provided for @settingsCustomColorsBasedOnDark.
  ///
  /// In en, this message translates to:
  /// **'Based on Dark'**
  String get settingsCustomColorsBasedOnDark;

  /// No description provided for @settingsCustomColorsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset colors'**
  String get settingsCustomColorsReset;

  /// No description provided for @settingsCustomColorsUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo last change'**
  String get settingsCustomColorsUndo;

  /// No description provided for @settingsCustomColorApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get settingsCustomColorApply;

  /// No description provided for @settingsCustomColorRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get settingsCustomColorRecent;

  /// No description provided for @settingsCustomColorRecentSwatch.
  ///
  /// In en, this message translates to:
  /// **'Recently used: {hex}'**
  String settingsCustomColorRecentSwatch(String hex);

  /// No description provided for @settingsCustomAllMacrosColored.
  ///
  /// In en, this message translates to:
  /// **'Macros always in color'**
  String get settingsCustomAllMacrosColored;

  /// No description provided for @settingsCustomAllMacrosColoredHint.
  ///
  /// In en, this message translates to:
  /// **'Off: only the lowest macro shows its color'**
  String get settingsCustomAllMacrosColoredHint;

  /// No description provided for @settingsCustomColorPaper.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get settingsCustomColorPaper;

  /// No description provided for @settingsCustomColorCard.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get settingsCustomColorCard;

  /// No description provided for @settingsCustomColorInk.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get settingsCustomColorInk;

  /// No description provided for @settingsCustomColorMuted.
  ///
  /// In en, this message translates to:
  /// **'Secondary text'**
  String get settingsCustomColorMuted;

  /// No description provided for @settingsCustomColorLines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get settingsCustomColorLines;

  /// No description provided for @settingsCustomColorAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get settingsCustomColorAccent;

  /// No description provided for @settingsCustomColorPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get settingsCustomColorPlan;

  /// No description provided for @settingsCustomColorSignal.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get settingsCustomColorSignal;

  /// No description provided for @settingsCustomPreviewCurry.
  ///
  /// In en, this message translates to:
  /// **'Lentil curry'**
  String get settingsCustomPreviewCurry;

  /// No description provided for @settingsCustomPreviewBar.
  ///
  /// In en, this message translates to:
  /// **'Protein bar'**
  String get settingsCustomPreviewBar;

  /// No description provided for @settingsCustomPreviewLogged.
  ///
  /// In en, this message translates to:
  /// **'Curry logged'**
  String get settingsCustomPreviewLogged;

  /// No description provided for @settingsCustomPreviewScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get settingsCustomPreviewScan;

  /// No description provided for @colorPickerHue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get colorPickerHue;

  /// No description provided for @colorPickerSaturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get colorPickerSaturation;

  /// No description provided for @colorPickerBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get colorPickerBrightness;

  /// No description provided for @colorPickerPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String colorPickerPercent(int value);

  /// No description provided for @colorPickerDegrees.
  ///
  /// In en, this message translates to:
  /// **'{value}°'**
  String colorPickerDegrees(int value);

  /// No description provided for @settingsDiaryGoalSetGoalFirst.
  ///
  /// In en, this message translates to:
  /// **'Set a goal first'**
  String get settingsDiaryGoalSetGoalFirst;

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
  /// **'You are already in this household.'**
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

  /// No description provided for @householdInviteCreate.
  ///
  /// In en, this message translates to:
  /// **'Invite members'**
  String get householdInviteCreate;

  /// No description provided for @householdInviteValidFor.
  ///
  /// In en, this message translates to:
  /// **'For one person, valid for 24 hours'**
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
  /// **'Verify your account with Google or email before you invite people.'**
  String get householdInviteVerificationRequired;

  /// No description provided for @householdJoinScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get householdJoinScanQr;

  /// No description provided for @householdKeyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your key is still loading. Please try again in a moment.'**
  String get householdKeyUnavailable;

  /// No description provided for @householdKeyRestoreMemberMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} started fresh and can no longer read the shared pantry. Create an unlock code and give it to them.'**
  String householdKeyRestoreMemberMessage(Object name);

  /// No description provided for @householdKeyRestoreCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Unlock code'**
  String get householdKeyRestoreCodeLabel;

  /// No description provided for @householdKeyRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Unlock pantry'**
  String get householdKeyRestoreAction;

  /// No description provided for @householdKeyRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pantry unlocked.'**
  String get householdKeyRestoreSuccess;

  /// No description provided for @householdKeyRestoreInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'This unlock code does not work.'**
  String get householdKeyRestoreInvalidCode;

  /// No description provided for @householdKeyRestoreCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create unlock code'**
  String get householdKeyRestoreCreateAction;

  /// No description provided for @householdKeyRestoreCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Give this code to {name}. It works until it is used or you create a new one.'**
  String householdKeyRestoreCodeHint(Object name);

  /// No description provided for @householdKeyRestoreCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get householdKeyRestoreCopyAction;

  /// No description provided for @householdKeyRestoreCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied.'**
  String get householdKeyRestoreCopied;

  /// No description provided for @householdHostVerificationHint.
  ///
  /// In en, this message translates to:
  /// **'To invite other people into your household, link your guest account with Google or email & password.'**
  String get householdHostVerificationHint;

  /// No description provided for @householdRemoveMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove member?'**
  String get householdRemoveMemberTitle;

  /// No description provided for @householdRemoveMemberMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this household? The shared items stay here.'**
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

  /// No description provided for @householdLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave household?'**
  String get householdLeaveTitle;

  /// No description provided for @householdLeaveMessage.
  ///
  /// In en, this message translates to:
  /// **'You go back to your own household. The shared items stay here.'**
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

  /// No description provided for @householdActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Household action failed. Please try again.'**
  String get householdActionFailed;

  /// No description provided for @householdLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the household.'**
  String get householdLoadFailed;

  /// No description provided for @householdKeyRestoreSelfMessage.
  ///
  /// In en, this message translates to:
  /// **'You started fresh, so the pantry of this household is locked. Ask another member for an unlock code and enter it here.'**
  String get householdKeyRestoreSelfMessage;

  /// No description provided for @householdAdminBadge.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get householdAdminBadge;

  /// No description provided for @householdMemberSelf.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String householdMemberSelf(Object name);

  /// No description provided for @householdMemberNoName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get householdMemberNoName;

  /// No description provided for @householdMemberActions.
  ///
  /// In en, this message translates to:
  /// **'Member actions'**
  String get householdMemberActions;

  /// No description provided for @householdMakeAdminAction.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get householdMakeAdminAction;

  /// No description provided for @householdMakeAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Make {name} admin?'**
  String householdMakeAdminTitle(Object name);

  /// No description provided for @householdMakeAdminMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will invite and remove members. You stay in the household as a member.'**
  String householdMakeAdminMessage(Object name);

  /// No description provided for @householdMakeAdminSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} is now the admin.'**
  String householdMakeAdminSuccess(Object name);

  /// No description provided for @householdMemberNotFound.
  ///
  /// In en, this message translates to:
  /// **'This person is no longer in the household.'**
  String get householdMemberNotFound;

  /// No description provided for @householdChanged.
  ///
  /// In en, this message translates to:
  /// **'The household changed in the meantime. Check it and try again.'**
  String get householdChanged;

  /// No description provided for @householdAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the admin can do that.'**
  String get householdAdminOnly;

  /// No description provided for @householdJoinLeaveFirst.
  ///
  /// In en, this message translates to:
  /// **'Leave your shared household before you join another one.'**
  String get householdJoinLeaveFirst;

  /// No description provided for @householdLeaveOwnMessage.
  ///
  /// In en, this message translates to:
  /// **'You get a new, empty household. The others keep everything here.'**
  String get householdLeaveOwnMessage;

  /// No description provided for @householdLeaveSuccessorLabel.
  ///
  /// In en, this message translates to:
  /// **'Who leads the household after you?'**
  String get householdLeaveSuccessorLabel;

  /// No description provided for @householdDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete household?'**
  String get householdDeleteTitle;

  /// No description provided for @householdDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'You are the last member. Leaving deletes this household with all its items.'**
  String get householdDeleteMessage;

  /// No description provided for @householdDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Leave and delete'**
  String get householdDeleteAction;

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

  /// No description provided for @settingsPlanShortageReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder for missing ingredients'**
  String get settingsPlanShortageReminderTitle;

  /// No description provided for @settingsPlanShortageReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The day before, when planned food lacks something'**
  String get settingsPlanShortageReminderSubtitle;

  /// Subtitle of the reminder switch when it is on but the system blocks the app's notifications; a tap opens the system settings.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. Tap to allow them.'**
  String get settingsPlanShortageReminderBlocked;

  /// No description provided for @settingsPlanShortageReminderTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get settingsPlanShortageReminderTimeTitle;

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

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get loginWithGoogle;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

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

  /// No description provided for @authContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get authContinueAsGuest;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot?'**
  String get authForgotPassword;

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

  /// No description provided for @onboardingFinishOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Your answers are kept, so try again once you are online.'**
  String get onboardingFinishOffline;

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

  /// No description provided for @onboardingTrainingDaysTrainingResult.
  ///
  /// In en, this message translates to:
  /// **'🏋️ Training ({days} days)'**
  String onboardingTrainingDaysTrainingResult(int days);

  /// No description provided for @onboardingTrainingDaysRestResult.
  ///
  /// In en, this message translates to:
  /// **'🛋️ Normal day ({days} days)'**
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
  /// **'Every session counts toward your energy use. Training days get it, normal days a little less.'**
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
  /// **'Your sessions are part of the weekly budget. A training day gets one session more than a normal day.'**
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
  /// **'Only your daily life: job and getting around. We ask about your training next.'**
  String get introActivitySubtitle;

  /// No description provided for @introActivitySittingTitle.
  ///
  /// In en, this message translates to:
  /// **'Barely active'**
  String get introActivitySittingTitle;

  /// No description provided for @introActivitySittingBody.
  ///
  /// In en, this message translates to:
  /// **'Desk, car, sofa, few steps'**
  String get introActivitySittingBody;

  /// No description provided for @introActivityLightTitle.
  ///
  /// In en, this message translates to:
  /// **'Lightly active'**
  String get introActivityLightTitle;

  /// No description provided for @introActivityLightBody.
  ///
  /// In en, this message translates to:
  /// **'Mostly sitting, some walking every day'**
  String get introActivityLightBody;

  /// No description provided for @introActivityOnFeetTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderately active'**
  String get introActivityOnFeetTitle;

  /// No description provided for @introActivityOnFeetBody.
  ///
  /// In en, this message translates to:
  /// **'On your feet a lot, e.g. retail or care work'**
  String get introActivityOnFeetBody;

  /// No description provided for @introActivityHardLabourTitle.
  ///
  /// In en, this message translates to:
  /// **'Very active'**
  String get introActivityHardLabourTitle;

  /// No description provided for @introActivityHardLabourBody.
  ///
  /// In en, this message translates to:
  /// **'Hard physical work, e.g. construction or warehouse'**
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

  /// No description provided for @shoppingListPlanNeedMissing.
  ///
  /// In en, this message translates to:
  /// **'{amount} missing'**
  String shoppingListPlanNeedMissing(String amount);

  /// No description provided for @shoppingListPlanNeedAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit}'**
  String shoppingListPlanNeedAmount(String amount, String unit);

  /// No description provided for @shoppingListPlanNeedGroup.
  ///
  /// In en, this message translates to:
  /// **'{day} · {meal}'**
  String shoppingListPlanNeedGroup(String day, String meal);

  /// No description provided for @shoppingListPlanNeedBrand.
  ///
  /// In en, this message translates to:
  /// **'{brand} · {amount}'**
  String shoppingListPlanNeedBrand(String brand, String amount);

  /// No description provided for @shoppingListPlanNeedsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The needs of your plans could not be loaded'**
  String get shoppingListPlanNeedsLoadFailed;

  /// No description provided for @shoppingListPlanNeedsRetry.
  ///
  /// In en, this message translates to:
  /// **'Reload plan needs'**
  String get shoppingListPlanNeedsRetry;

  /// No description provided for @shoppingListPlanNeedsTitle.
  ///
  /// In en, this message translates to:
  /// **'For your plan'**
  String get shoppingListPlanNeedsTitle;

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
  /// **'Could not process the receipt.'**
  String get receiptReviewProcessingFailed;

  /// No description provided for @receiptCameraFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the camera for the receipt.'**
  String get receiptCameraFailed;

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
  /// **'Without the recovery key, your diary, weight, and goals cannot be read. They will be deleted. Your pantry is deleted too, unless other members share your household: then a member can unlock it for you again.'**
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

  /// No description provided for @calorieGoalLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your goal. Check your connection.'**
  String get calorieGoalLoadFailed;

  /// No description provided for @calorieGoalLoadRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get calorieGoalLoadRetryAction;

  /// No description provided for @calorieGoalLoadFailedSignOutAction.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get calorieGoalLoadFailedSignOutAction;

  /// No description provided for @calorieGoalLoadFailedSignOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out. Check your connection.'**
  String get calorieGoalLoadFailedSignOutFailed;

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

  /// No description provided for @foodEstimateHeadline.
  ///
  /// In en, this message translates to:
  /// **'What are you eating?'**
  String get foodEstimateHeadline;

  /// No description provided for @foodEstimateHint.
  ///
  /// In en, this message translates to:
  /// **'Photo, text, or both. One is enough.'**
  String get foodEstimateHint;

  /// No description provided for @foodEstimateDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get foodEstimateDescriptionLabel;

  /// No description provided for @foodEstimateDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. no onions, extra sauce, large plate'**
  String get foodEstimateDescriptionHint;

  /// No description provided for @foodEstimateChipLargePortion.
  ///
  /// In en, this message translates to:
  /// **'large portion'**
  String get foodEstimateChipLargePortion;

  /// No description provided for @foodEstimateChipRestaurant.
  ///
  /// In en, this message translates to:
  /// **'restaurant'**
  String get foodEstimateChipRestaurant;

  /// No description provided for @foodEstimateChipHomemade.
  ///
  /// In en, this message translates to:
  /// **'homemade'**
  String get foodEstimateChipHomemade;

  /// No description provided for @foodEstimateChipHalfEaten.
  ///
  /// In en, this message translates to:
  /// **'half eaten'**
  String get foodEstimateChipHalfEaten;

  /// No description provided for @foodEstimateAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get foodEstimateAnalyze;

  /// No description provided for @foodEstimateAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing …'**
  String get foodEstimateAnalyzing;

  /// No description provided for @foodEstimateNotFood.
  ///
  /// In en, this message translates to:
  /// **'The photos show no food.'**
  String get foodEstimateNotFood;

  /// No description provided for @foodEstimateUnclear.
  ///
  /// In en, this message translates to:
  /// **'The food cannot be recognized. Take a brighter photo or describe it.'**
  String get foodEstimateUnclear;

  /// No description provided for @foodEstimateFailed.
  ///
  /// In en, this message translates to:
  /// **'The estimate did not work. Please try again.'**
  String get foodEstimateFailed;

  /// No description provided for @foodEstimateOverline.
  ///
  /// In en, this message translates to:
  /// **'AI estimate'**
  String get foodEstimateOverline;

  /// No description provided for @foodEstimateReanalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze again'**
  String get foodEstimateReanalyze;

  /// No description provided for @foodEstimateAddToStock.
  ///
  /// In en, this message translates to:
  /// **'Add to stock'**
  String get foodEstimateAddToStock;

  /// No description provided for @foodEstimateApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get foodEstimateApply;

  /// No description provided for @foodEstimateLevelLean.
  ///
  /// In en, this message translates to:
  /// **'lean'**
  String get foodEstimateLevelLean;

  /// No description provided for @foodEstimateLevelNormal.
  ///
  /// In en, this message translates to:
  /// **'normal'**
  String get foodEstimateLevelNormal;

  /// No description provided for @foodEstimateLevelRich.
  ///
  /// In en, this message translates to:
  /// **'rich'**
  String get foodEstimateLevelRich;

  /// No description provided for @foodEstimateTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get foodEstimateTakePhoto;

  /// No description provided for @foodEstimateTakePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Plate, package or menu'**
  String get foodEstimateTakePhotoHint;

  /// No description provided for @foodEstimateFromGallery.
  ///
  /// In en, this message translates to:
  /// **'or pick from gallery'**
  String get foodEstimateFromGallery;

  /// No description provided for @foodEstimateAnotherPhoto.
  ///
  /// In en, this message translates to:
  /// **'One more'**
  String get foodEstimateAnotherPhoto;

  /// No description provided for @foodEstimatePhotoNotSaved.
  ///
  /// In en, this message translates to:
  /// **'The photo could not be saved. The food is saved without an image.'**
  String get foodEstimatePhotoNotSaved;

  /// No description provided for @foodEstimateRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo {index}'**
  String foodEstimateRemovePhoto(int index);

  /// No description provided for @homeMenuClose.
  ///
  /// In en, this message translates to:
  /// **'Close menu'**
  String get homeMenuClose;

  /// No description provided for @homeMenuSectionYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get homeMenuSectionYou;

  /// No description provided for @homeMenuSectionKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get homeMenuSectionKitchen;

  /// No description provided for @homeMenuSectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get homeMenuSectionApp;

  /// No description provided for @homeMenuLinkAccount.
  ///
  /// In en, this message translates to:
  /// **'Link account'**
  String get homeMenuLinkAccount;

  /// No description provided for @homeMenuGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get homeMenuGuest;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'YAMT'**
  String get appName;

  /// No description provided for @profileNoValue.
  ///
  /// In en, this message translates to:
  /// **'–'**
  String get profileNoValue;

  /// No description provided for @profileWeightChartDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String profileWeightChartDays(int days);

  /// No description provided for @profileWeightMeasuredLabel.
  ///
  /// In en, this message translates to:
  /// **'Measured'**
  String get profileWeightMeasuredLabel;

  /// No description provided for @profileWeighInDay.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{today} =1{yesterday} other{{days} days ago}}'**
  String profileWeighInDay(int days);

  /// No description provided for @profileWeightStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get profileWeightStartLabel;

  /// No description provided for @profileWeightStartNote.
  ///
  /// In en, this message translates to:
  /// **'at goal start'**
  String get profileWeightStartNote;

  /// No description provided for @profileWeightTrendLabel.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get profileWeightTrendLabel;

  /// No description provided for @profileWeightPerWeek.
  ///
  /// In en, this message translates to:
  /// **'per week'**
  String get profileWeightPerWeek;

  /// No description provided for @profileBodySection.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get profileBodySection;

  /// No description provided for @profileTrainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get profileTrainingLabel;

  /// No description provided for @profileTrainingNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get profileTrainingNone;

  /// No description provided for @profileTrainingOffset.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal per session'**
  String profileTrainingOffset(String kcal);

  /// No description provided for @profileMacroWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Macro weight'**
  String get profileMacroWeightLabel;

  /// No description provided for @profileMacroWeightSince.
  ///
  /// In en, this message translates to:
  /// **'since {date}'**
  String profileMacroWeightSince(String date);

  /// No description provided for @profileTdeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Expenditure'**
  String get profileTdeeLabel;

  /// No description provided for @profileTdeeLearned.
  ///
  /// In en, this message translates to:
  /// **'learned'**
  String get profileTdeeLearned;

  /// No description provided for @profileTdeeEstimated.
  ///
  /// In en, this message translates to:
  /// **'estimated'**
  String get profileTdeeEstimated;

  /// No description provided for @progressGoalLose.
  ///
  /// In en, this message translates to:
  /// **'Lose weight to {weight} kg'**
  String progressGoalLose(String weight);

  /// No description provided for @progressGoalGain.
  ///
  /// In en, this message translates to:
  /// **'Gain weight to {weight} kg'**
  String progressGoalGain(String weight);

  /// No description provided for @progressGoalMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain weight'**
  String get progressGoalMaintain;

  /// No description provided for @progressGoalStart.
  ///
  /// In en, this message translates to:
  /// **'Start {weight} kg'**
  String progressGoalStart(String weight);

  /// No description provided for @progressGoalRemaining.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg to go · {pace} kg/week'**
  String progressGoalRemaining(String weight, String pace);

  /// No description provided for @progressGoalNone.
  ///
  /// In en, this message translates to:
  /// **'No goal set yet.'**
  String get progressGoalNone;

  /// No description provided for @profileHeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get profileHeightTitle;

  /// No description provided for @profileBirthDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get profileBirthDateTitle;

  /// No description provided for @profileSexTitle.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get profileSexTitle;

  /// No description provided for @profileStartWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Start weight'**
  String get profileStartWeightTitle;

  /// No description provided for @profileWeightSection.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get profileWeightSection;

  /// No description provided for @profileUnitCm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get profileUnitCm;

  /// No description provided for @profileUnitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get profileUnitKg;

  /// No description provided for @profileHeightRange.
  ///
  /// In en, this message translates to:
  /// **'Between {min} and {max} cm'**
  String profileHeightRange(String min, String max);

  /// No description provided for @profileStartWeightRange.
  ///
  /// In en, this message translates to:
  /// **'Between {min} and {max} kg'**
  String profileStartWeightRange(String min, String max);

  /// No description provided for @profileBirthDateRange.
  ///
  /// In en, this message translates to:
  /// **'Age between {min} and {max} years'**
  String profileBirthDateRange(String min, String max);

  /// No description provided for @profileEditCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileEditCancel;

  /// No description provided for @profileEditApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get profileEditApply;

  /// No description provided for @profileEditSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the change.'**
  String get profileEditSaveFailed;

  /// No description provided for @profileEditEffectToday.
  ///
  /// In en, this message translates to:
  /// **'What changes from today'**
  String get profileEditEffectToday;

  /// No description provided for @profileEditEffectFromGoalStart.
  ///
  /// In en, this message translates to:
  /// **'What changes from the goal start on {date}'**
  String profileEditEffectFromGoalStart(String date);

  /// No description provided for @profileEditKcalLabel.
  ///
  /// In en, this message translates to:
  /// **'Calorie goal'**
  String get profileEditKcalLabel;

  /// No description provided for @profileEditKcalStays.
  ///
  /// In en, this message translates to:
  /// **'stays {kcal} kcal'**
  String profileEditKcalStays(String kcal);

  /// No description provided for @profileEditKcalChange.
  ///
  /// In en, this message translates to:
  /// **'{before} → {after} kcal'**
  String profileEditKcalChange(String before, String after);

  /// No description provided for @profileEditGramsChange.
  ///
  /// In en, this message translates to:
  /// **'{before} → {after} g'**
  String profileEditGramsChange(String before, String after);

  /// No description provided for @profileEditMacrosLabel.
  ///
  /// In en, this message translates to:
  /// **'Macros'**
  String get profileEditMacrosLabel;

  /// No description provided for @profileEditMacrosStay.
  ///
  /// In en, this message translates to:
  /// **'stay the same'**
  String get profileEditMacrosStay;

  /// No description provided for @profileEditNoteLearned.
  ///
  /// In en, this message translates to:
  /// **'Your expenditure is learned. So only the macro split changes.'**
  String get profileEditNoteLearned;

  /// No description provided for @profileEditNoteManual.
  ///
  /// In en, this message translates to:
  /// **'You set your calorie goal by hand. So only the macro split changes.'**
  String get profileEditNoteManual;

  /// No description provided for @profileEditNoteCorrection.
  ///
  /// In en, this message translates to:
  /// **'No expenditure is learned yet. So the app works out your calorie goal again from the goal start.'**
  String get profileEditNoteCorrection;

  /// No description provided for @profileEditNoteNoGoal.
  ///
  /// In en, this message translates to:
  /// **'You have no goal right now. The change counts from your next goal.'**
  String get profileEditNoteNoGoal;

  /// No description provided for @profileTrainingRunRange.
  ///
  /// In en, this message translates to:
  /// **'Run {start} – {end}'**
  String profileTrainingRunRange(String start, String end);

  /// No description provided for @profileTrainingRunNote.
  ///
  /// In en, this message translates to:
  /// **'this run until {date}'**
  String profileTrainingRunNote(String date);

  /// No description provided for @profileTrainingEffectTitle.
  ///
  /// In en, this message translates to:
  /// **'What changes in this run'**
  String get profileTrainingEffectTitle;

  /// No description provided for @profileTrainingBecomesTraining.
  ///
  /// In en, this message translates to:
  /// **'{date} becomes a training day'**
  String profileTrainingBecomesTraining(String date);

  /// No description provided for @profileTrainingBecomesRest.
  ///
  /// In en, this message translates to:
  /// **'{date} becomes a normal day'**
  String profileTrainingBecomesRest(String date);

  /// No description provided for @profileTrainingRunSum.
  ///
  /// In en, this message translates to:
  /// **'Run total'**
  String get profileTrainingRunSum;

  /// No description provided for @profileTrainingNote.
  ///
  /// In en, this message translates to:
  /// **'Counts for this run only, like a day type in the diary. The run total stays; the carryover passes what past days got differently on to the days left.'**
  String get profileTrainingNote;

  /// No description provided for @profileTrainingPauseDay.
  ///
  /// In en, this message translates to:
  /// **'Pause day'**
  String get profileTrainingPauseDay;

  /// No description provided for @profileTrainingOtherRestDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Other normal day} other{{count} other normal days}}'**
  String profileTrainingOtherRestDays(int count);

  /// No description provided for @profileTrainingOtherTrainingDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Other training day} other{{count} other training days}}'**
  String profileTrainingOtherTrainingDays(int count);

  /// No description provided for @caloriesGoalBodyStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Your body data'**
  String get caloriesGoalBodyStepTitle;

  /// No description provided for @caloriesGoalBodyEditInProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit in profile'**
  String get caloriesGoalBodyEditInProfile;

  /// No description provided for @caloriesGoalBodyHeightValue.
  ///
  /// In en, this message translates to:
  /// **'{height} cm'**
  String caloriesGoalBodyHeightValue(String height);

  /// No description provided for @caloriesGoalBodyAgeValue.
  ///
  /// In en, this message translates to:
  /// **'{age} years'**
  String caloriesGoalBodyAgeValue(int age);

  /// No description provided for @caloriesGoalBodyAgeWithBirthday.
  ///
  /// In en, this message translates to:
  /// **'{age} years · {birthday}'**
  String caloriesGoalBodyAgeWithBirthday(int age, String birthday);

  /// No description provided for @homeActionEat.
  ///
  /// In en, this message translates to:
  /// **'Eat'**
  String get homeActionEat;

  /// No description provided for @inventoryAddBarcodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan a package and put it into stock'**
  String get inventoryAddBarcodeDescription;

  /// No description provided for @diaryQuickEatBarcodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan a package and log what you ate'**
  String get diaryQuickEatBarcodeDescription;

  /// No description provided for @diaryQuickEatInventoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Eat something from your stock'**
  String get diaryQuickEatInventoryDescription;

  /// No description provided for @diaryQuickEatQuickEntryDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter calories and macros by hand'**
  String get diaryQuickEatQuickEntryDescription;

  /// No description provided for @diaryQuickEatAiDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe a meal, the AI estimates it'**
  String get diaryQuickEatAiDescription;

  /// No description provided for @diaryQuickEatSearchDescription.
  ///
  /// In en, this message translates to:
  /// **'Find a food by name or brand'**
  String get diaryQuickEatSearchDescription;

  /// No description provided for @diaryCheckInRunKicker.
  ///
  /// In en, this message translates to:
  /// **'Run {run} · {range}'**
  String diaryCheckInRunKicker(int run, String range);

  /// No description provided for @diaryCheckInRangeKicker.
  ///
  /// In en, this message translates to:
  /// **'{range}'**
  String diaryCheckInRangeKicker(String range);

  /// No description provided for @diaryCheckInReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Week done'**
  String get diaryCheckInReviewTitle;

  /// No description provided for @diaryCheckInBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Check-in needs data'**
  String get diaryCheckInBlockedTitle;

  /// No description provided for @diaryCheckInGoalSince.
  ///
  /// In en, this message translates to:
  /// **'Goal {weight} kg · since {date}'**
  String diaryCheckInGoalSince(String weight, String date);

  /// No description provided for @diaryCheckInSince.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String diaryCheckInSince(String date);

  /// No description provided for @diaryCheckInTrendFact.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get diaryCheckInTrendFact;

  /// No description provided for @diaryCheckInTrendChange.
  ///
  /// In en, this message translates to:
  /// **'{change} kg since start'**
  String diaryCheckInTrendChange(String change);

  /// No description provided for @diaryCheckInEatenFact.
  ///
  /// In en, this message translates to:
  /// **'Eaten'**
  String get diaryCheckInEatenFact;

  /// No description provided for @diaryCheckInPerDay.
  ///
  /// In en, this message translates to:
  /// **'kcal / day'**
  String get diaryCheckInPerDay;

  /// No description provided for @diaryCheckInTrainingFact.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get diaryCheckInTrainingFact;

  /// No description provided for @diaryCheckInTrainingDaysCaption.
  ///
  /// In en, this message translates to:
  /// **'days in the run'**
  String get diaryCheckInTrainingDaysCaption;

  /// No description provided for @diaryCheckInWeightChart.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get diaryCheckInWeightChart;

  /// No description provided for @diaryCheckInTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get diaryCheckInTrend;

  /// No description provided for @diaryCheckInTdeeChart.
  ///
  /// In en, this message translates to:
  /// **'Expenditure (TDEE) per run'**
  String get diaryCheckInTdeeChart;

  /// No description provided for @diaryCheckInUseMeasured.
  ///
  /// In en, this message translates to:
  /// **'Use the measured one'**
  String get diaryCheckInUseMeasured;

  /// No description provided for @diaryCheckInUseMeasuredDetail.
  ///
  /// In en, this message translates to:
  /// **'TDEE {kcal} from this run'**
  String diaryCheckInUseMeasuredDetail(String kcal);

  /// No description provided for @diaryCheckInKeepPrevious.
  ///
  /// In en, this message translates to:
  /// **'Keep the previous one'**
  String get diaryCheckInKeepPrevious;

  /// No description provided for @diaryCheckInKeepPreviousDetail.
  ///
  /// In en, this message translates to:
  /// **'TDEE {kcal}, goal as last week'**
  String diaryCheckInKeepPreviousDetail(String kcal);

  /// No description provided for @diaryCheckInGoalKcalCaption.
  ///
  /// In en, this message translates to:
  /// **'kcal goal'**
  String get diaryCheckInGoalKcalCaption;

  /// No description provided for @diaryCheckInChangeGoal.
  ///
  /// In en, this message translates to:
  /// **'Change goal'**
  String get diaryCheckInChangeGoal;

  /// No description provided for @diaryCheckInChangeGoalDetail.
  ///
  /// In en, this message translates to:
  /// **'Set a new goal weight or pace'**
  String get diaryCheckInChangeGoalDetail;

  /// No description provided for @diaryCheckInNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get diaryCheckInNext;

  /// No description provided for @diaryCheckInBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get diaryCheckInBack;

  /// No description provided for @diaryCheckInTrainingTitle.
  ///
  /// In en, this message translates to:
  /// **'When do you train?'**
  String get diaryCheckInTrainingTitle;

  /// No description provided for @diaryCheckInTrainingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the days you train'**
  String get diaryCheckInTrainingSubtitle;

  /// No description provided for @diaryCheckInSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get diaryCheckInSessions;

  /// No description provided for @diaryCheckInSameAsLastRun.
  ///
  /// In en, this message translates to:
  /// **'Like last run'**
  String get diaryCheckInSameAsLastRun;

  /// No description provided for @diaryCheckInNoSession.
  ///
  /// In en, this message translates to:
  /// **'No session'**
  String get diaryCheckInNoSession;

  /// No description provided for @diaryCheckInAverageGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily goal on average'**
  String get diaryCheckInAverageGoal;

  /// No description provided for @diaryCheckInMeasuredSource.
  ///
  /// In en, this message translates to:
  /// **'measured'**
  String get diaryCheckInMeasuredSource;

  /// No description provided for @diaryCheckInPreviousSource.
  ///
  /// In en, this message translates to:
  /// **'previous'**
  String get diaryCheckInPreviousSource;

  /// No description provided for @diaryCheckInGoalChange.
  ///
  /// In en, this message translates to:
  /// **'{change} to last week'**
  String diaryCheckInGoalChange(String change);

  /// No description provided for @diaryCheckInDayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String diaryCheckInDayCount(int count);

  /// No description provided for @diaryCheckInMacros.
  ///
  /// In en, this message translates to:
  /// **'Macros'**
  String get diaryCheckInMacros;

  /// No description provided for @diaryCheckInMacrosPrevious.
  ///
  /// In en, this message translates to:
  /// **'before'**
  String get diaryCheckInMacrosPrevious;

  /// No description provided for @diaryCheckInMacrosNew.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get diaryCheckInMacrosNew;

  /// No description provided for @diaryCheckInGramsValue.
  ///
  /// In en, this message translates to:
  /// **'{grams} g'**
  String diaryCheckInGramsValue(int grams);

  /// No description provided for @diaryCheckInMacroWeightDetail.
  ///
  /// In en, this message translates to:
  /// **'Protein and fat count against {weight} kg.'**
  String diaryCheckInMacroWeightDetail(String weight);

  /// No description provided for @diaryCheckInStartWeek.
  ///
  /// In en, this message translates to:
  /// **'Start the week'**
  String get diaryCheckInStartWeek;

  /// No description provided for @diaryCheckInGoalReachedKicker.
  ///
  /// In en, this message translates to:
  /// **'Goal reached'**
  String get diaryCheckInGoalReachedKicker;

  /// No description provided for @diaryCheckInGoalReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get diaryCheckInGoalReachedTitle;

  /// No description provided for @diaryCheckInGoalReachedBody.
  ///
  /// In en, this message translates to:
  /// **'You reached your goal weight in {weeks, plural, =1{1 week} other{{weeks} weeks}}.'**
  String diaryCheckInGoalReachedBody(int weeks);

  /// No description provided for @diaryCheckInStartFact.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get diaryCheckInStartFact;

  /// No description provided for @diaryCheckInTodayFact.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get diaryCheckInTodayFact;

  /// No description provided for @diaryCheckInDoneFact.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get diaryCheckInDoneFact;

  /// No description provided for @diaryCheckInPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{change} kg / week'**
  String diaryCheckInPerWeek(String change);

  /// No description provided for @diaryCheckInStartNewGoal.
  ///
  /// In en, this message translates to:
  /// **'Start a new goal'**
  String get diaryCheckInStartNewGoal;

  /// No description provided for @diaryCheckInClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get diaryCheckInClose;

  /// No description provided for @diaryCheckInLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the check-in.'**
  String get diaryCheckInLoadFailed;

  /// No description provided for @diaryHoloPreviewAction.
  ///
  /// In en, this message translates to:
  /// **'Preview holo budget card'**
  String get diaryHoloPreviewAction;

  /// No description provided for @diaryCheckInPreviewAction.
  ///
  /// In en, this message translates to:
  /// **'Preview weekly check-in'**
  String get diaryCheckInPreviewAction;

  /// No description provided for @diaryCheckInGoalReachedPreviewAction.
  ///
  /// In en, this message translates to:
  /// **'Preview goal reached'**
  String get diaryCheckInGoalReachedPreviewAction;

  /// No description provided for @diaryCheckInPreviewResult.
  ///
  /// In en, this message translates to:
  /// **'Preview: {action}, {days} training days, nothing saved'**
  String diaryCheckInPreviewResult(String action, int days);

  /// No description provided for @diaryCheckInMissingDataPreviewAction.
  ///
  /// In en, this message translates to:
  /// **'Preview missing data'**
  String get diaryCheckInMissingDataPreviewAction;

  /// No description provided for @homeMenuDebugSection.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get homeMenuDebugSection;

  /// No description provided for @diaryCheckInFixedDaysHint.
  ///
  /// In en, this message translates to:
  /// **'Past days and pause days keep their type.'**
  String get diaryCheckInFixedDaysHint;

  /// No description provided for @cookbookRecipeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recipe} other{{count} recipes}}'**
  String cookbookRecipeCount(int count);

  /// No description provided for @cookbookOpenMealsTitle.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get cookbookOpenMealsTitle;

  /// No description provided for @cookbookOpenMealRows.
  ///
  /// In en, this message translates to:
  /// **'In stock · {count, plural, =1{1 row open} other{{count} rows open}}'**
  String cookbookOpenMealRows(int count);

  /// No description provided for @cookbookContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get cookbookContinueAction;

  /// No description provided for @cookbookInPotOpenRows.
  ///
  /// In en, this message translates to:
  /// **'In the pot since {time} · {count, plural, =1{1 row open} other{{count} rows open}}'**
  String cookbookInPotOpenRows(int count, String time);

  /// No description provided for @cookbookTemplatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get cookbookTemplatesTitle;

  /// No description provided for @cookbookTemplatesCaption.
  ///
  /// In en, this message translates to:
  /// **'Combined from stock'**
  String get cookbookTemplatesCaption;

  /// No description provided for @cookbookNewTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get cookbookNewTemplateTitle;

  /// No description provided for @cookbookNewTemplateCaption.
  ///
  /// In en, this message translates to:
  /// **'combine from stock'**
  String get cookbookNewTemplateCaption;

  /// No description provided for @cookbookRecipesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get cookbookRecipesTitle;

  /// No description provided for @cookbookRecipesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recipes yet. Add one from a link or get an AI idea.'**
  String get cookbookRecipesEmpty;

  /// No description provided for @cookbookStockComplete.
  ///
  /// In en, this message translates to:
  /// **'All in stock'**
  String get cookbookStockComplete;

  /// No description provided for @cookbookStockMissing.
  ///
  /// In en, this message translates to:
  /// **'{count} missing'**
  String cookbookStockMissing(int count);

  /// No description provided for @cookbookKcal.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String cookbookKcal(int kcal);

  /// No description provided for @cookbookLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the cookbook.'**
  String get cookbookLoadFailed;

  /// Removes a recipe or Vorlage from the cookbook.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get cookbookRemoveAction;

  /// No description provided for @cookbookEntryMenuHint.
  ///
  /// In en, this message translates to:
  /// **'Show actions'**
  String get cookbookEntryMenuHint;

  /// No description provided for @cookbookRemovedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} removed'**
  String cookbookRemovedMessage(String name);

  /// No description provided for @cookbookRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove {name}.'**
  String cookbookRemoveFailed(String name);

  /// No description provided for @homeActionCook.
  ///
  /// In en, this message translates to:
  /// **'Cook'**
  String get homeActionCook;

  /// No description provided for @homeActionWeigh.
  ///
  /// In en, this message translates to:
  /// **'Weigh in'**
  String get homeActionWeigh;

  /// Fortschritt bar button that opens the weigh-in and photo actions.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get homeActionProgress;

  /// No description provided for @cookbookFreeCookingAction.
  ///
  /// In en, this message translates to:
  /// **'Cook freely'**
  String get cookbookFreeCookingAction;

  /// No description provided for @cookbookFreeCookingDescription.
  ///
  /// In en, this message translates to:
  /// **'Say or type ingredients while you cook'**
  String get cookbookFreeCookingDescription;

  /// No description provided for @freeCookingNameHint.
  ///
  /// In en, this message translates to:
  /// **'What is the dish called?'**
  String get freeCookingNameHint;

  /// No description provided for @freeCookingDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Cooked freely'**
  String get freeCookingDefaultName;

  /// No description provided for @freeCookingIngredientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get freeCookingIngredientsTitle;

  /// No description provided for @freeCookingStockCount.
  ///
  /// In en, this message translates to:
  /// **'{inStock} of {total} in stock'**
  String freeCookingStockCount(int inStock, int total);

  /// No description provided for @freeCookingStockLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} in stock'**
  String freeCookingStockLeft(String amount);

  /// No description provided for @freeCookingAmountWithUnit.
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit}'**
  String freeCookingAmountWithUnit(int amount, String unit);

  /// No description provided for @freeCookingPieces.
  ///
  /// In en, this message translates to:
  /// **'{count} pcs'**
  String freeCookingPieces(int count);

  /// No description provided for @freeCookingMissing.
  ///
  /// In en, this message translates to:
  /// **'missing'**
  String get freeCookingMissing;

  /// No description provided for @freeCookingPickStock.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get freeCookingPickStock;

  /// No description provided for @freeCookingListenTitle.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get freeCookingListenTitle;

  /// No description provided for @freeCookingListenHint.
  ///
  /// In en, this message translates to:
  /// **'Say the amount and the food. A pause starts a new row. Tap anywhere to stop.'**
  String get freeCookingListenHint;

  /// No description provided for @freeCookingIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'Tap and speak'**
  String get freeCookingIdleTitle;

  /// No description provided for @freeCookingIdleHint.
  ///
  /// In en, this message translates to:
  /// **'For example: 500 g chicken, 40 g butter'**
  String get freeCookingIdleHint;

  /// No description provided for @freeCookingTypeAction.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get freeCookingTypeAction;

  /// No description provided for @freeCookingTypeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 200 g rice'**
  String get freeCookingTypeHint;

  /// No description provided for @freeCookingAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get freeCookingAddAction;

  /// No description provided for @freeCookingCookAction.
  ///
  /// In en, this message translates to:
  /// **'Cook'**
  String get freeCookingCookAction;

  /// No description provided for @freeCookingStockLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the stock.'**
  String get freeCookingStockLoadFailed;

  /// No description provided for @freeCookingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the meal.'**
  String get freeCookingSaveFailed;

  /// No description provided for @freeCookingDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard the meal?'**
  String get freeCookingDiscardTitle;

  /// No description provided for @freeCookingDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'The ingredients will be lost.'**
  String get freeCookingDiscardBody;

  /// No description provided for @freeCookingDiscardAction.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get freeCookingDiscardAction;

  /// No description provided for @freeCookingVoiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input does not work on this device.'**
  String get freeCookingVoiceUnavailable;

  /// No description provided for @freeCookingVoicePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow the microphone to say ingredients.'**
  String get freeCookingVoicePermissionDenied;

  /// No description provided for @freeCookingVoiceFailed.
  ///
  /// In en, this message translates to:
  /// **'Voice input could not start.'**
  String get freeCookingVoiceFailed;

  /// No description provided for @preparedMealFillTitle.
  ///
  /// In en, this message translates to:
  /// **'Fill row'**
  String get preparedMealFillTitle;

  /// No description provided for @preparedMealFillStockMatch.
  ///
  /// In en, this message translates to:
  /// **'Found in stock'**
  String get preparedMealFillStockMatch;

  /// No description provided for @preparedMealFillTake.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get preparedMealFillTake;

  /// No description provided for @preparedMealFillStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get preparedMealFillStock;

  /// No description provided for @preparedMealFillStockDescription.
  ///
  /// In en, this message translates to:
  /// **'Pick another food'**
  String get preparedMealFillStockDescription;

  /// No description provided for @preparedMealFillSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get preparedMealFillSearch;

  /// No description provided for @preparedMealFillSearchDescription.
  ///
  /// In en, this message translates to:
  /// **'Find a product in the catalog'**
  String get preparedMealFillSearchDescription;

  /// No description provided for @preparedMealFillBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get preparedMealFillBarcode;

  /// No description provided for @preparedMealFillBarcodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan the package'**
  String get preparedMealFillBarcodeDescription;

  /// No description provided for @preparedMealFillAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get preparedMealFillAi;

  /// No description provided for @preparedMealFillAiDescription.
  ///
  /// In en, this message translates to:
  /// **'Estimate from a photo or text'**
  String get preparedMealFillAiDescription;

  /// No description provided for @preparedMealFillShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Add to shopping list'**
  String get preparedMealFillShoppingList;

  /// No description provided for @preparedMealFillShoppingListFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not put the row on the shopping list.'**
  String get preparedMealFillShoppingListFailed;

  /// No description provided for @preparedMealFillShoppingListDescription.
  ///
  /// In en, this message translates to:
  /// **'The row stays as it is'**
  String get preparedMealFillShoppingListDescription;

  /// No description provided for @preparedMealFillIgnore.
  ///
  /// In en, this message translates to:
  /// **'Ignore row'**
  String get preparedMealFillIgnore;

  /// No description provided for @preparedMealFillStockLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String preparedMealFillStockLeft(String amount);

  /// Button above the iOS number keyboard that closes the keyboard.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get keyboardDoneAction;

  /// No description provided for @cookedKicker.
  ///
  /// In en, this message translates to:
  /// **'Cooked'**
  String get cookedKicker;

  /// No description provided for @cookedOpenRows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row open} other{{count} rows open}}'**
  String cookedOpenRows(int count);

  /// No description provided for @cookedFillRows.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get cookedFillRows;

  /// No description provided for @cookedPotTitle.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get cookedPotTitle;

  /// No description provided for @cookedPortions.
  ///
  /// In en, this message translates to:
  /// **'Portions'**
  String get cookedPortions;

  /// No description provided for @cookedPortionsLess.
  ///
  /// In en, this message translates to:
  /// **'One portion less'**
  String get cookedPortionsLess;

  /// No description provided for @cookedPortionsMore.
  ///
  /// In en, this message translates to:
  /// **'One portion more'**
  String get cookedPortionsMore;

  /// No description provided for @cookedUtensil.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get cookedUtensil;

  /// No description provided for @cookedPickUtensil.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get cookedPickUtensil;

  /// No description provided for @cookedUtensilOption.
  ///
  /// In en, this message translates to:
  /// **'{name} · {grams} g'**
  String cookedUtensilOption(String name, int grams);

  /// No description provided for @cookedUtensilWeight.
  ///
  /// In en, this message translates to:
  /// **'{grams} g'**
  String cookedUtensilWeight(int grams);

  /// No description provided for @cookedGrossWeight.
  ///
  /// In en, this message translates to:
  /// **'On the scale'**
  String get cookedGrossWeight;

  /// No description provided for @cookedWeighTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: weigh once the food has cooled.'**
  String get cookedWeighTip;

  /// No description provided for @cookedNetWeight.
  ///
  /// In en, this message translates to:
  /// **'{grams} g food'**
  String cookedNetWeight(int grams);

  /// No description provided for @cookedTooLight.
  ///
  /// In en, this message translates to:
  /// **'Not heavier than the empty container'**
  String get cookedTooLight;

  /// No description provided for @cookedPerPortionWeighed.
  ///
  /// In en, this message translates to:
  /// **'Portion {grams} g · {kcal} kcal'**
  String cookedPerPortionWeighed(int grams, int kcal);

  /// No description provided for @cookedPerPortion.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal per portion'**
  String cookedPerPortion(int kcal);

  /// No description provided for @cookedPieces.
  ///
  /// In en, this message translates to:
  /// **'Pieces'**
  String get cookedPieces;

  /// No description provided for @cookedPiecesLess.
  ///
  /// In en, this message translates to:
  /// **'One piece less'**
  String get cookedPiecesLess;

  /// No description provided for @cookedPiecesMore.
  ///
  /// In en, this message translates to:
  /// **'One piece more'**
  String get cookedPiecesMore;

  /// No description provided for @cookedPiecesHint.
  ///
  /// In en, this message translates to:
  /// **'Pieces need no weight. Each piece is 1/{count} of the nutrients.'**
  String cookedPiecesHint(int count);

  /// No description provided for @cookedPerPiece.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal per piece'**
  String cookedPerPiece(int kcal);

  /// No description provided for @inventoryRowMealFromRecipePieces.
  ///
  /// In en, this message translates to:
  /// **'From recipe · {left} of {total} pieces'**
  String inventoryRowMealFromRecipePieces(String left, int total);

  /// No description provided for @inventoryEatSheetPiecesHeader.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{amount} piece} other{{amount} pieces}}'**
  String inventoryEatSheetPiecesHeader(num count, String amount);

  /// No description provided for @preparedMealPiecesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining}/{total} pieces'**
  String preparedMealPiecesRemaining(String remaining, int total);

  /// No description provided for @cookedCombinedKicker.
  ///
  /// In en, this message translates to:
  /// **'Combined'**
  String get cookedCombinedKicker;

  /// No description provided for @cookedWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get cookedWeight;

  /// No description provided for @cookedIngredientsWeight.
  ///
  /// In en, this message translates to:
  /// **'{grams} g from the ingredients'**
  String cookedIngredientsWeight(int grams);

  /// No description provided for @cookedWeighInstead.
  ///
  /// In en, this message translates to:
  /// **'Weight wrong? Weigh with a container'**
  String get cookedWeighInstead;

  /// No description provided for @cookedDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'The ingredients go back to the stock.'**
  String get cookedDiscardBody;

  /// No description provided for @cookedDiscardFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not discard the meal. Its foods are not back in the stock yet.'**
  String get cookedDiscardFailed;

  /// No description provided for @cookedSave.
  ///
  /// In en, this message translates to:
  /// **'To stock'**
  String get cookedSave;

  /// No description provided for @cookedNeedsUtensil.
  ///
  /// In en, this message translates to:
  /// **'Pick the container first'**
  String get cookedNeedsUtensil;

  /// No description provided for @cookedSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} is in stock'**
  String cookedSaved(String name);

  /// No description provided for @cookedToCookbook.
  ///
  /// In en, this message translates to:
  /// **'Add to cookbook'**
  String get cookedToCookbook;

  /// No description provided for @cookedToCookbookNote.
  ///
  /// In en, this message translates to:
  /// **'Today’s ingredients and amounts'**
  String get cookedToCookbookNote;

  /// No description provided for @cookedSavedWithCookbook.
  ///
  /// In en, this message translates to:
  /// **'{name} is in stock and in the cookbook'**
  String cookedSavedWithCookbook(String name);

  /// No description provided for @cookedCookbookFailed.
  ///
  /// In en, this message translates to:
  /// **'The meal is in stock, but could not be added to the cookbook.'**
  String get cookedCookbookFailed;

  /// No description provided for @recipeOriginalPortions.
  ///
  /// In en, this message translates to:
  /// **'Original for {count}'**
  String recipeOriginalPortions(int count);

  /// No description provided for @recipeStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get recipeStepsTitle;

  /// No description provided for @recipeStepCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 step} other{{count} steps}}'**
  String recipeStepCount(int count);

  /// No description provided for @recipeWithGuide.
  ///
  /// In en, this message translates to:
  /// **'Cook with instructions'**
  String get recipeWithGuide;

  /// No description provided for @recipeWithGuideHint.
  ///
  /// In en, this message translates to:
  /// **'Opens sentence by sentence, then “Cooked”'**
  String get recipeWithGuideHint;

  /// No description provided for @cookingGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Cooking helper'**
  String get cookingGuideTitle;

  /// No description provided for @cookingGuideKicker.
  ///
  /// In en, this message translates to:
  /// **'Instructions · {count, plural, =1{1 portion} other{{count} portions}}'**
  String cookingGuideKicker(int count);

  /// No description provided for @cookingGuideSentenceNote.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sentence} other{{count} sentences}}. Next comes one sentence per screen, and the screen stays on.'**
  String cookingGuideSentenceNote(int count);

  /// No description provided for @cookingGuideStart.
  ///
  /// In en, this message translates to:
  /// **'Start · sentence by sentence'**
  String get cookingGuideStart;

  /// No description provided for @cookingGuideKeepsScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Screen stays on'**
  String get cookingGuideKeepsScreenOn;

  /// No description provided for @cookingGuideProgress.
  ///
  /// In en, this message translates to:
  /// **'Sentence {sentence} of {count} · step {step}'**
  String cookingGuideProgress(int sentence, int count, int step);

  /// No description provided for @cookingGuideInPot.
  ///
  /// In en, this message translates to:
  /// **'In the pot'**
  String get cookingGuideInPot;

  /// No description provided for @cookingGuideLineCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line} other{{count} lines}}'**
  String cookingGuideLineCount(int count);

  /// No description provided for @recipeGuideAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 addition from the cooking helper} other{{count} additions from the cooking helper}}'**
  String recipeGuideAdded(int count);

  /// No description provided for @cookingGuideJustAdded.
  ///
  /// In en, this message translates to:
  /// **'Just added'**
  String get cookingGuideJustAdded;

  /// No description provided for @cookingGuideVoiceHint.
  ///
  /// In en, this message translates to:
  /// **'“50 g cream” · “no” takes it back'**
  String get cookingGuideVoiceHint;

  /// No description provided for @cookingGuideJumpTitle.
  ///
  /// In en, this message translates to:
  /// **'Jump to'**
  String get cookingGuideJumpTitle;

  /// No description provided for @cookingGuideNext.
  ///
  /// In en, this message translates to:
  /// **'Next sentence'**
  String get cookingGuideNext;

  /// No description provided for @cookingGuideDone.
  ///
  /// In en, this message translates to:
  /// **'Done cooking'**
  String get cookingGuideDone;

  /// No description provided for @recipeNotFound.
  ///
  /// In en, this message translates to:
  /// **'This recipe is gone.'**
  String get recipeNotFound;

  /// No description provided for @recipeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the recipe or the stock.'**
  String get recipeLoadFailed;

  /// No description provided for @recipeCheckChangeKicker.
  ///
  /// In en, this message translates to:
  /// **'{name} · {count, plural, =1{1 portion} other{{count} portions}}'**
  String recipeCheckChangeKicker(String name, int count);

  /// No description provided for @recipeCheckChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change something this time?'**
  String get recipeCheckChangeTitle;

  /// No description provided for @recipeCheckChangeHint.
  ///
  /// In en, this message translates to:
  /// **'For example “more meat” or “without tomatoes”. Only for this time.'**
  String get recipeCheckChangeHint;

  /// No description provided for @recipeCheckChangeYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get recipeCheckChangeYes;

  /// No description provided for @recipeCheckChangeNo.
  ///
  /// In en, this message translates to:
  /// **'No, continue'**
  String get recipeCheckChangeNo;

  /// No description provided for @recipeCheckEditKicker.
  ///
  /// In en, this message translates to:
  /// **'This time only'**
  String get recipeCheckEditKicker;

  /// No description provided for @recipeCheckEditTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you change?'**
  String get recipeCheckEditTitle;

  /// No description provided for @recipeCheckEditAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount of {food}'**
  String recipeCheckEditAmount(String food);

  /// No description provided for @recipeCheckEditRemove.
  ///
  /// In en, this message translates to:
  /// **'Leave out {food}'**
  String recipeCheckEditRemove(String food);

  /// No description provided for @recipeCheckEditAdd.
  ///
  /// In en, this message translates to:
  /// **'+ Ingredient'**
  String get recipeCheckEditAdd;

  /// No description provided for @recipeCheckEditAddHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 200 g peppers'**
  String get recipeCheckEditAddHint;

  /// No description provided for @recipeCheckChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get recipeCheckChanged;

  /// No description provided for @recipeCheckChangeAmount.
  ///
  /// In en, this message translates to:
  /// **'{food} {from} → {to}'**
  String recipeCheckChangeAmount(String food, String from, String to);

  /// No description provided for @recipeCheckChangeRemoved.
  ///
  /// In en, this message translates to:
  /// **'without {food}'**
  String recipeCheckChangeRemoved(String food);

  /// Ingredient check summary: a changed ingredient whose amount has no label for the chosen portions.
  ///
  /// In en, this message translates to:
  /// **'{food}: new amount'**
  String recipeCheckChangeOther(String food);

  /// No description provided for @recipeCheckChangeAdded.
  ///
  /// In en, this message translates to:
  /// **'+ {food}'**
  String recipeCheckChangeAdded(String food);

  /// No description provided for @recipeCheckChangeAddedAmount.
  ///
  /// In en, this message translates to:
  /// **'+ {amount} {food}'**
  String recipeCheckChangeAddedAmount(String amount, String food);

  /// No description provided for @recipeCheckSaveEdits.
  ///
  /// In en, this message translates to:
  /// **'Save the changes in the recipe'**
  String get recipeCheckSaveEdits;

  /// No description provided for @recipeCheckSaveEditsHint.
  ///
  /// In en, this message translates to:
  /// **'Otherwise they count for today only'**
  String get recipeCheckSaveEditsHint;

  /// No description provided for @recipeCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check ingredients'**
  String get recipeCheckTitle;

  /// No description provided for @recipeCheckMissingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} missing'**
  String recipeCheckMissingCount(int count);

  /// No description provided for @recipeCheckPartialCount.
  ///
  /// In en, this message translates to:
  /// **'{count} only partly there'**
  String recipeCheckPartialCount(int count);

  /// No description provided for @recipeCheckOpenBoth.
  ///
  /// In en, this message translates to:
  /// **'{missing} missing, {partial} only partly there'**
  String recipeCheckOpenBoth(int missing, int partial);

  /// No description provided for @recipeCheckStep.
  ///
  /// In en, this message translates to:
  /// **'{step}/{total}'**
  String recipeCheckStep(int step, int total);

  /// No description provided for @recipeCheckSettled.
  ///
  /// In en, this message translates to:
  /// **'All sorted'**
  String get recipeCheckSettled;

  /// No description provided for @recipeCheckFoundKicker.
  ///
  /// In en, this message translates to:
  /// **'Found in the stock · {count}'**
  String recipeCheckFoundKicker(int count);

  /// No description provided for @recipeCheckFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Does this fit?'**
  String get recipeCheckFoundTitle;

  /// No description provided for @recipeCheckFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an ingredient to pick another item.'**
  String get recipeCheckFoundHint;

  /// No description provided for @recipeCheckNextMissing.
  ///
  /// In en, this message translates to:
  /// **'Next · {count} missing'**
  String recipeCheckNextMissing(int count);

  /// No description provided for @recipeCheckMissingKicker.
  ///
  /// In en, this message translates to:
  /// **'Missing · {count}'**
  String recipeCheckMissingKicker(int count);

  /// No description provided for @recipeCheckMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to the shopping list?'**
  String get recipeCheckMissingTitle;

  /// No description provided for @recipeCheckMissingHint.
  ///
  /// In en, this message translates to:
  /// **'“Got it” adds it to the stock and uses it right away.'**
  String get recipeCheckMissingHint;

  /// No description provided for @recipeCheckHave.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get recipeCheckHave;

  /// No description provided for @recipeCheckRest.
  ///
  /// In en, this message translates to:
  /// **'Rest · {amount} in stock'**
  String recipeCheckRest(String amount);

  /// No description provided for @recipeCheckPartialNote.
  ///
  /// In en, this message translates to:
  /// **'{stocked} in stock · {missing} missing'**
  String recipeCheckPartialNote(String stocked, String missing);

  /// No description provided for @recipeCheckUse.
  ///
  /// In en, this message translates to:
  /// **'From the stock'**
  String get recipeCheckUse;

  /// No description provided for @recipeCheckCart.
  ///
  /// In en, this message translates to:
  /// **'On the shopping list'**
  String get recipeCheckCart;

  /// No description provided for @recipeCheckIgnore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get recipeCheckIgnore;

  /// No description provided for @recipeCheckSummaryKicker.
  ///
  /// In en, this message translates to:
  /// **'Checked'**
  String get recipeCheckSummaryKicker;

  /// No description provided for @recipeCheckSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'This is how you cook today'**
  String get recipeCheckSummaryTitle;

  /// No description provided for @recipeCheckFromStock.
  ///
  /// In en, this message translates to:
  /// **'From the stock · {count}'**
  String recipeCheckFromStock(int count);

  /// No description provided for @recipeCheckOnList.
  ///
  /// In en, this message translates to:
  /// **'On the shopping list · {count}'**
  String recipeCheckOnList(int count);

  /// No description provided for @recipeCheckIgnored.
  ///
  /// In en, this message translates to:
  /// **'Ignored · {count}'**
  String recipeCheckIgnored(int count);

  /// No description provided for @recipeCheckNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get recipeCheckNothing;

  /// No description provided for @recipeCheckNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get recipeCheckNext;

  /// No description provided for @recipeCheckFinish.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get recipeCheckFinish;

  /// No description provided for @recipeCheckSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the choices.'**
  String get recipeCheckSaveFailed;

  /// No description provided for @recipeCheckListFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add to the shopping list.'**
  String get recipeCheckListFailed;

  /// No description provided for @recipeCheckHaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add the food to the stock.'**
  String get recipeCheckHaveFailed;

  /// No description provided for @recipePickTitle.
  ///
  /// In en, this message translates to:
  /// **'{food}: take it from'**
  String recipePickTitle(String food);

  /// No description provided for @recipeNotFromStock.
  ///
  /// In en, this message translates to:
  /// **'Not from stock'**
  String get recipeNotFromStock;

  /// No description provided for @cookedDoneElsewhere.
  ///
  /// In en, this message translates to:
  /// **'This meal is already cooked and in your stock.'**
  String get cookedDoneElsewhere;

  /// No description provided for @cookedLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the meal.'**
  String get cookedLoadFailed;

  /// No description provided for @preparedMealGone.
  ///
  /// In en, this message translates to:
  /// **'Meal is no longer in stock'**
  String get preparedMealGone;

  /// No description provided for @cookbookInPotSince.
  ///
  /// In en, this message translates to:
  /// **'In the pot since {time}'**
  String cookbookInPotSince(String time);

  /// Title of the page that blocks an app older than the minimum version.
  ///
  /// In en, this message translates to:
  /// **'Update yamt'**
  String get appUpdateRequiredTitle;

  /// Body of the page that blocks an app older than the minimum version.
  ///
  /// In en, this message translates to:
  /// **'This version of yamt is too old for your data. Update the app to go on.'**
  String get appUpdateRequiredBody;

  /// Button and snackbar action that opens Google Play or TestFlight.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get appUpdateAction;

  /// Snackbar shown once per newer app version.
  ///
  /// In en, this message translates to:
  /// **'yamt {version} is available'**
  String appUpdateAvailable(String version);

  /// Snackbar when neither the store nor TestFlight opens.
  ///
  /// In en, this message translates to:
  /// **'The store could not be opened.'**
  String get appUpdateStoreOpenFailed;

  /// Notice shown once after an update, with the first new point.
  ///
  /// In en, this message translates to:
  /// **'New in {version}: {point}'**
  String whatsNewNotice(String version, String point);

  /// Notice action that opens all release notes.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get whatsNewShowAll;

  /// Title of the release notes sheet.
  ///
  /// In en, this message translates to:
  /// **'New in {version}'**
  String whatsNewTitle(String version);

  /// Release notes section with new features.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get whatsNewAdded;

  /// Release notes section with improvements.
  ///
  /// In en, this message translates to:
  /// **'Improved'**
  String get whatsNewImproved;

  /// Release notes section with fixes.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get whatsNewFixed;

  /// One line of the release notes.
  ///
  /// In en, this message translates to:
  /// **'• {point}'**
  String whatsNewPoint(String point);

  /// Strip under the status bar while the device has no network connection.
  ///
  /// In en, this message translates to:
  /// **'Offline – no connection'**
  String get connectivityOfflineBanner;

  /// Snack bar when the connection returns after an offline phase.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get connectivityBackOnline;

  /// No description provided for @progressPhotoCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get progressPhotoCaptureTitle;

  /// No description provided for @progressPhotoPoseLabel.
  ///
  /// In en, this message translates to:
  /// **'Pose'**
  String get progressPhotoPoseLabel;

  /// No description provided for @progressPhotoPoseFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get progressPhotoPoseFront;

  /// No description provided for @progressPhotoPoseSide.
  ///
  /// In en, this message translates to:
  /// **'Side'**
  String get progressPhotoPoseSide;

  /// No description provided for @progressPhotoPoseBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get progressPhotoPoseBack;

  /// No description provided for @progressPhotoDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get progressPhotoDayLabel;

  /// No description provided for @progressPhotoWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight in kg (optional)'**
  String get progressPhotoWeightLabel;

  /// No description provided for @progressPhotoWeightHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave empty: weight of the day'**
  String get progressPhotoWeightHelper;

  /// No description provided for @progressPhotoWeightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a weight between {min} and {max} kg.'**
  String progressPhotoWeightInvalid(String min, String max);

  /// No description provided for @progressPhotoReplaceHint.
  ///
  /// In en, this message translates to:
  /// **'This day and pose already have a photo. A new one replaces it.'**
  String get progressPhotoReplaceHint;

  /// No description provided for @progressPhotoSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the photo.'**
  String get progressPhotoSaveFailed;

  /// No description provided for @progressPhotoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get progressPhotoFromGallery;

  /// No description provided for @progressPhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get progressPhotoCamera;

  /// No description provided for @progressPhotoPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Encrypted. Only you see your photos.'**
  String get progressPhotoPrivacy;

  /// No description provided for @progressPhotoSaved.
  ///
  /// In en, this message translates to:
  /// **'Photo saved'**
  String get progressPhotoSaved;

  /// Day and weight under a progress photo.
  ///
  /// In en, this message translates to:
  /// **'{day} · {kg} kg'**
  String progressPhotoCaption(String day, String kg);

  /// No description provided for @progressPhotosLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The photos could not be loaded.'**
  String get progressPhotosLoadFailed;

  /// No description provided for @progressPhotoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The photo could not be loaded.'**
  String get progressPhotoLoadFailed;

  /// No description provided for @progressPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress photo'**
  String get progressPhotoLabel;

  /// No description provided for @progressActionWeighDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter today\'s weight'**
  String get progressActionWeighDescription;

  /// No description provided for @progressActionPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get progressActionPhoto;

  /// No description provided for @progressActionPhotoDescription.
  ///
  /// In en, this message translates to:
  /// **'Take a progress photo or pick one from the gallery'**
  String get progressActionPhotoDescription;

  /// No description provided for @diaryCheckInPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Your way so far'**
  String get diaryCheckInPhotoTitle;

  /// No description provided for @diaryCheckInPhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Same pose and light as last time.'**
  String get diaryCheckInPhotoSubtitle;

  /// No description provided for @diaryCheckInPhotoFirst.
  ///
  /// In en, this message translates to:
  /// **'First'**
  String get diaryCheckInPhotoFirst;

  /// No description provided for @diaryCheckInPhotoMiddle.
  ///
  /// In en, this message translates to:
  /// **'Middle'**
  String get diaryCheckInPhotoMiddle;

  /// No description provided for @diaryCheckInPhotoNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get diaryCheckInPhotoNew;

  /// No description provided for @diaryCheckInPhotoAdd.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get diaryCheckInPhotoAdd;

  /// No description provided for @progressPhotosKicker.
  ///
  /// In en, this message translates to:
  /// **'Photos · before / after'**
  String get progressPhotosKicker;

  /// No description provided for @progressPhotosEmpty.
  ///
  /// In en, this message translates to:
  /// **'No photos yet. Add one, or take it at the next check-in.'**
  String get progressPhotosEmpty;

  /// Empty state of the photo list when a past goal is selected.
  ///
  /// In en, this message translates to:
  /// **'No photos from this goal.'**
  String get progressPhotosEmptyPastGoal;

  /// No description provided for @progressPhotosAdd.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get progressPhotosAdd;

  /// No description provided for @progressPhotosAll.
  ///
  /// In en, this message translates to:
  /// **'All photos'**
  String get progressPhotosAll;

  /// No description provided for @progressPhotosCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get progressPhotosCompare;

  /// No description provided for @progressPhotosBefore.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get progressPhotosBefore;

  /// No description provided for @progressPhotosAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get progressPhotosAfter;

  /// No description provided for @progressPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get progressPhotosTitle;

  /// No description provided for @progressPhotosGoalGroup.
  ///
  /// In en, this message translates to:
  /// **'Goal {number} · since {date}'**
  String progressPhotosGoalGroup(int number, String date);

  /// No description provided for @progressPhotosBeforeGoals.
  ///
  /// In en, this message translates to:
  /// **'Before the first goal'**
  String get progressPhotosBeforeGoals;

  /// No description provided for @progressPhotosWeeks.
  ///
  /// In en, this message translates to:
  /// **'{weeks, plural, =0{this week} =1{in 1 week} other{in {weeks} weeks}}'**
  String progressPhotosWeeks(int weeks);

  /// No description provided for @progressPhotoDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete photo?'**
  String get progressPhotoDeleteTitle;

  /// No description provided for @progressPhotoDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The photo is deleted for good.'**
  String get progressPhotoDeleteBody;

  /// No description provided for @progressPhotoDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get progressPhotoDelete;

  /// No description provided for @progressPhotoDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the photo.'**
  String get progressPhotoDeleteFailed;

  /// No description provided for @progressPhotoReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get progressPhotoReplace;

  /// No description provided for @progressPhotoMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get progressPhotoMove;

  /// No description provided for @progressPhotoOpen.
  ///
  /// In en, this message translates to:
  /// **'Open photo'**
  String get progressPhotoOpen;

  /// No description provided for @progressPhotoMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move photo'**
  String get progressPhotoMoveTitle;

  /// No description provided for @progressPhotoMoveReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace photo?'**
  String get progressPhotoMoveReplaceTitle;

  /// No description provided for @progressPhotoMoveReplaceBody.
  ///
  /// In en, this message translates to:
  /// **'There is already a photo of this pose on this day. It will be deleted.'**
  String get progressPhotoMoveReplaceBody;

  /// No description provided for @progressPhotoMoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not move the photo.'**
  String get progressPhotoMoveFailed;

  /// No description provided for @progressPhotoMissing.
  ///
  /// In en, this message translates to:
  /// **'This photo no longer exists.'**
  String get progressPhotoMissing;

  /// No description provided for @progressPhotoViewerCaption.
  ///
  /// In en, this message translates to:
  /// **'{pose} · {caption}'**
  String progressPhotoViewerCaption(String pose, String caption);

  /// No description provided for @progressPhotoCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get progressPhotoCompareTitle;

  /// No description provided for @progressPhotoCompareSlider.
  ///
  /// In en, this message translates to:
  /// **'Compare before and after'**
  String get progressPhotoCompareSlider;

  /// No description provided for @progressWeightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Weights'**
  String get progressWeightsTitle;

  /// No description provided for @progressWeightsAll.
  ///
  /// In en, this message translates to:
  /// **'All weights'**
  String get progressWeightsAll;

  /// No description provided for @progressWeightsRangeGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get progressWeightsRangeGoal;

  /// No description provided for @progressWeightsRangeFourWeeks.
  ///
  /// In en, this message translates to:
  /// **'4 weeks'**
  String get progressWeightsRangeFourWeeks;

  /// No description provided for @progressWeightsRangeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get progressWeightsRangeAll;

  /// No description provided for @progressWeightsSinceGoal.
  ///
  /// In en, this message translates to:
  /// **'Since goal start {date}'**
  String progressWeightsSinceGoal(String date);

  /// No description provided for @progressWeightsSince.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String progressWeightsSince(String date);

  /// No description provided for @progressWeightsTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend {kg} kg'**
  String progressWeightsTrend(String kg);

  /// No description provided for @progressWeightsToTarget.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg to goal'**
  String progressWeightsToTarget(String kg);

  /// No description provided for @progressWeightsTarget.
  ///
  /// In en, this message translates to:
  /// **'Goal {kg} kg'**
  String progressWeightsTarget(String kg);

  /// No description provided for @progressWeightsRun.
  ///
  /// In en, this message translates to:
  /// **'Run {number} · since {date}'**
  String progressWeightsRun(int number, String date);

  /// No description provided for @progressWeightsRunTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend {trend} kg · {change} kg'**
  String progressWeightsRunTrend(String trend, String change);

  /// No description provided for @progressWeightsSourceManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get progressWeightsSourceManual;

  /// No description provided for @progressWeightsSourceScale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get progressWeightsSourceScale;

  /// No description provided for @progressWeightsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No weights in this period yet.'**
  String get progressWeightsEmpty;

  /// No description provided for @progressWeightsHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Take weights from your scale'**
  String get progressWeightsHealthTitle;

  /// No description provided for @progressWeightsHealthBody.
  ///
  /// In en, this message translates to:
  /// **'Connect Health and the weights of your scale arrive on their own.'**
  String get progressWeightsHealthBody;

  /// No description provided for @progressWeightsHealthConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect Health'**
  String get progressWeightsHealthConnect;

  /// No description provided for @progressWeightsHealthDismiss.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get progressWeightsHealthDismiss;

  /// Title of the question after planning a recipe whose ingredients the Vorrat lacks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ingredient missing} other{{count} ingredients missing}}'**
  String shoppingPlanNeedsDialogTitle(int count);

  /// No description provided for @shoppingPlanNeedsDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Put them on the shopping list?'**
  String get shoppingPlanNeedsDialogMessage;

  /// No description provided for @shoppingPlanNeedsDialogSkip.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get shoppingPlanNeedsDialogSkip;

  /// No description provided for @shoppingPlanNeedsDialogAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to list'**
  String get shoppingPlanNeedsDialogAdd;

  /// Button in the missing-ingredients question opened from the day-before reminder; turns the reminder off.
  ///
  /// In en, this message translates to:
  /// **'Don\'t ask again'**
  String get shoppingPlanNeedsDialogNeverAsk;

  /// Android notification channel of the day-before reminder for missing plan ingredients.
  ///
  /// In en, this message translates to:
  /// **'Missing ingredients'**
  String get planShortageReminderChannelName;

  /// Title of the day-before notification when planned food lacks ingredients.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ingredient missing for tomorrow} other{{count} ingredients missing for tomorrow}}'**
  String planShortageReminderTitle(int count);

  /// No description provided for @planShortageReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Put them on the shopping list?'**
  String get planShortageReminderBody;

  /// Snackbar after tapping the day-before reminder when the plans or the stock could not be read.
  ///
  /// In en, this message translates to:
  /// **'Could not check the missing ingredients.'**
  String get planShortageReminderCheckFailed;

  /// Snackbar after tapping the blocked day-before reminder in Settings when the system notification settings did not open.
  ///
  /// In en, this message translates to:
  /// **'Could not open the notification settings.'**
  String get planShortageReminderSettingsFailed;

  /// Snackbar after tapping the day-before reminder when nothing is missing any more.
  ///
  /// In en, this message translates to:
  /// **'Everything for the plan is there.'**
  String get planShortageReminderAllThere;

  /// Edit weight shown in the weights list.
  ///
  /// In en, this message translates to:
  /// **'Edit weight'**
  String get progressWeighingEditTitle;

  /// Label for the day field in the weight edit sheet.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get progressWeighingDayLabel;

  /// Label for the time field in the weight edit sheet.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get progressWeighingTimeLabel;

  /// Button to delete a weight entry.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get progressWeighingDelete;

  /// Button to ignore a weight so it no longer counts.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get progressWeighingIgnore;

  /// Button to count a previously ignored weight again.
  ///
  /// In en, this message translates to:
  /// **'Count again'**
  String get progressWeighingCount;

  /// Button to open the weight entry in the Health app.
  ///
  /// In en, this message translates to:
  /// **'Open in Health'**
  String get progressWeighingOpenHealth;

  /// Note shown when a weight was saved to Health by another device and can only be changed there.
  ///
  /// In en, this message translates to:
  /// **'Saved to Health on another device. You can change it only there.'**
  String get progressWeighingOtherDevice;

  /// Error shown when deleting a weight fails.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the weight.'**
  String get progressWeighingDeleteFailed;

  /// Error shown when ignoring or counting a weight fails.
  ///
  /// In en, this message translates to:
  /// **'Could not change the weight.'**
  String get progressWeighingIgnoreFailed;

  /// Error shown when the Health app cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open Health.'**
  String get progressWeighingOpenHealthFailed;

  /// Error shown when weights cannot be read from Health.
  ///
  /// In en, this message translates to:
  /// **'Could not read Health.'**
  String get progressWeighingHealthReadFailed;

  /// No description provided for @diaryBudgetKcalLeft.
  ///
  /// In en, this message translates to:
  /// **'kcal left'**
  String get diaryBudgetKcalLeft;

  /// No description provided for @diaryBudgetKcalLeftAfterPlan.
  ///
  /// In en, this message translates to:
  /// **'kcal left after plan'**
  String get diaryBudgetKcalLeftAfterPlan;

  /// No description provided for @diaryBudgetKcalOver.
  ///
  /// In en, this message translates to:
  /// **'kcal over'**
  String get diaryBudgetKcalOver;

  /// No description provided for @diaryBudgetOverValue.
  ///
  /// In en, this message translates to:
  /// **'+{kcal}'**
  String diaryBudgetOverValue(String kcal);

  /// No description provided for @diaryBudgetPauseEaten.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal eaten'**
  String diaryBudgetPauseEaten(String kcal);

  /// No description provided for @diaryBudgetPausePlanned.
  ///
  /// In en, this message translates to:
  /// **'+ {kcal} planned'**
  String diaryBudgetPausePlanned(String kcal);

  /// No description provided for @diaryBudgetMacroLeft.
  ///
  /// In en, this message translates to:
  /// **'{grams} g'**
  String diaryBudgetMacroLeft(String grams);

  /// No description provided for @diaryBudgetMacroOver.
  ///
  /// In en, this message translates to:
  /// **'+{grams} g'**
  String diaryBudgetMacroOver(String grams);

  /// Diary budget card: carbohydrates label next to the grams, short enough for the macro column.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get diaryBudgetCarbsLabel;

  /// Diary budget card: switch segment that makes the numbers show what is left of the day's budget.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get diaryBudgetViewLeft;

  /// Diary budget card: switch segment that makes the numbers show what was eaten.
  ///
  /// In en, this message translates to:
  /// **'Eaten'**
  String get diaryBudgetViewEaten;

  /// Diary budget card, eaten view: words under the big kcal number, with the day's target on its own line.
  ///
  /// In en, this message translates to:
  /// **'kcal eaten\nof {target}'**
  String diaryBudgetKcalEatenOf(String target);

  /// Diary budget card, eaten view: words under the big kcal number when planned food is counted in, with the day's target on its own line.
  ///
  /// In en, this message translates to:
  /// **'kcal with plan\nof {target}'**
  String diaryBudgetKcalWithPlanOf(String target);

  /// Details of the diary budget card: kcal eaten (and counted as planned) of the day's target.
  ///
  /// In en, this message translates to:
  /// **'{eaten} / {target} kcal'**
  String diaryBudgetKcalEatenOfTarget(String eaten, String target);

  /// No description provided for @diaryBudgetMacroEaten.
  ///
  /// In en, this message translates to:
  /// **'{grams} g eaten'**
  String diaryBudgetMacroEaten(String grams);

  /// No description provided for @diaryBudgetMacroPlanned.
  ///
  /// In en, this message translates to:
  /// **'{grams} planned'**
  String diaryBudgetMacroPlanned(String grams);

  /// No description provided for @diaryBudgetBufferRow.
  ///
  /// In en, this message translates to:
  /// **'Buffer adjustment'**
  String get diaryBudgetBufferRow;

  /// No description provided for @diaryBudgetCarryoverRow.
  ///
  /// In en, this message translates to:
  /// **'Carryover from the week'**
  String get diaryBudgetCarryoverRow;

  /// No description provided for @diaryBudgetPlannedCountedRow.
  ///
  /// In en, this message translates to:
  /// **'Planned · counted'**
  String get diaryBudgetPlannedCountedRow;

  /// No description provided for @diaryBudgetOverRow.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get diaryBudgetOverRow;

  /// No description provided for @diaryBudgetAllDays.
  ///
  /// In en, this message translates to:
  /// **'All days'**
  String get diaryBudgetAllDays;

  /// No description provided for @diaryBudgetWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Day types in the run'**
  String get diaryBudgetWeekTitle;

  /// No description provided for @diaryBudgetRunEndedNotice.
  ///
  /// In en, this message translates to:
  /// **'Run ended · new run counts from {date}'**
  String diaryBudgetRunEndedNotice(String date);

  /// No description provided for @diaryBudgetWeekDaySemantics.
  ///
  /// In en, this message translates to:
  /// **'{day}: {type}, tap to change'**
  String diaryBudgetWeekDaySemantics(String day, String type);

  /// No description provided for @diaryBudgetWeekPauseDaySemantics.
  ///
  /// In en, this message translates to:
  /// **'{day}: {type}, set with the pause button'**
  String diaryBudgetWeekPauseDaySemantics(String day, String type);

  /// No description provided for @diaryBudgetTrainingDayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 training day} other{{count} training days}}'**
  String diaryBudgetTrainingDayCount(int count);

  /// Meal heading in the diary while the pace marker is on: the meal's counted kcal against its part of the day's kcal target.
  ///
  /// In en, this message translates to:
  /// **'{eaten} / {target} kcal'**
  String diaryMealKcalOfTarget(String eaten, String target);

  /// Label in the budget card menu above the split of the day's kcal over the meals and the times the meals are eaten by.
  ///
  /// In en, this message translates to:
  /// **'Parts of the day'**
  String get diaryMealSharesTitle;

  /// A meal's share of the day and its kcal in the split of the budget card menu.
  ///
  /// In en, this message translates to:
  /// **'{percent} % · {kcal} kcal'**
  String diaryMealSharesPart(String percent, String kcal);

  /// Button in the budget card menu that goes back to the standard split of the day over the meals and the standard meal times.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get diaryMealSharesReset;

  /// A meal's share of the day in the split of the budget card menu, on a day without a kcal target.
  ///
  /// In en, this message translates to:
  /// **'{percent} %'**
  String diaryMealSharesPercent(String percent);

  /// Screen reader label of a draggable border between two meals in the split of the budget card menu.
  ///
  /// In en, this message translates to:
  /// **'Border between {before} and {after}'**
  String diaryMealSharesBorder(String before, String after);

  /// Screen reader value of a border in the split of the budget card menu: the shares of the meal before and after it.
  ///
  /// In en, this message translates to:
  /// **'{before} % / {after} %'**
  String diaryMealSharesBorderValue(String before, String after);

  /// In the budget card menu: the meal has no part of the day.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get diaryMealSharesOff;

  /// Row in the budget card menu with the time the day starts, from which the pace marker on the kcal line moves.
  ///
  /// In en, this message translates to:
  /// **'Day starts'**
  String get diaryMealTimesDayStart;

  /// Button in the budget card menu with the time the day starts; a tap opens a time picker.
  ///
  /// In en, this message translates to:
  /// **'from {time}'**
  String diaryMealTimesFrom(String time);

  /// Button in a meal's row of the budget card menu with the time the meal is eaten by; a tap opens a time picker.
  ///
  /// In en, this message translates to:
  /// **'by {time}'**
  String diaryMealTimesBy(String time);

  /// Screen reader action of the daily budget card that opens its menu, which a long press opens too.
  ///
  /// In en, this message translates to:
  /// **'Open the daily budget menu'**
  String get diaryBudgetMenuOpen;

  /// Heading of the menu that a long press on the daily budget card opens.
  ///
  /// In en, this message translates to:
  /// **'Daily budget'**
  String get diaryBudgetMenuTitle;

  /// Switch in the budget card menu that marks on today's kcal line how many kcal the day should be at by now, from the parts of the day and the meal times, and shows each meal heading's kcal against its part of the day's target.
  ///
  /// In en, this message translates to:
  /// **'Pace marker'**
  String get diaryBudgetMenuPace;

  /// Hint below the pace marker switch in the budget card menu.
  ///
  /// In en, this message translates to:
  /// **'Marks on today\'s kcal line where you should be by now and shows each meal\'s target'**
  String get diaryBudgetMenuPaceHint;

  /// No description provided for @diaryBudgetMenuAllMacros.
  ///
  /// In en, this message translates to:
  /// **'Macros always in color'**
  String get diaryBudgetMenuAllMacros;

  /// No description provided for @diaryBudgetMenuAllMacrosHint.
  ///
  /// In en, this message translates to:
  /// **'Off: only the lowest macro shows its color'**
  String get diaryBudgetMenuAllMacrosHint;

  /// Title of the data export page and its menu entry in Fortschritt.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get dataExportTitle;

  /// One-line description of the export entry in menus.
  ///
  /// In en, this message translates to:
  /// **'Share food, weight, and goals with an AI, an advisor, or yourself'**
  String get dataExportActionDescription;

  /// Settings tile that opens the data export page.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get settingsDataExportTitle;

  /// Header above the export purposes.
  ///
  /// In en, this message translates to:
  /// **'For whom'**
  String get dataExportPurposeHeader;

  /// Export purpose: the user's own AI.
  ///
  /// In en, this message translates to:
  /// **'My AI'**
  String get dataExportPurposeAi;

  /// Line under the AI export purpose.
  ///
  /// In en, this message translates to:
  /// **'Text with a question and explained fields · .txt'**
  String get dataExportPurposeAiDescription;

  /// Export purpose: a nutrition advisor.
  ///
  /// In en, this message translates to:
  /// **'Nutrition advisor'**
  String get dataExportPurposeAdvisor;

  /// Line under the advisor export purpose.
  ///
  /// In en, this message translates to:
  /// **'Report and table · .pdf + .xlsx'**
  String get dataExportPurposeAdvisorDescription;

  /// Export purpose: the user.
  ///
  /// In en, this message translates to:
  /// **'For me'**
  String get dataExportPurposeSelf;

  /// Line under the self export purpose.
  ///
  /// In en, this message translates to:
  /// **'Report with charts · .pdf'**
  String get dataExportPurposeSelfDescription;

  /// Header above the export period chips.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get dataExportRangeHeader;

  /// Export period chip: the last 7 days.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get dataExportRangeSevenDays;

  /// Export period chip: the last 4 weeks.
  ///
  /// In en, this message translates to:
  /// **'4 weeks'**
  String get dataExportRangeFourWeeks;

  /// Export period chip: the last 3 months.
  ///
  /// In en, this message translates to:
  /// **'3 months'**
  String get dataExportRangeThreeMonths;

  /// Export period chip that opens a date range picker.
  ///
  /// In en, this message translates to:
  /// **'Custom …'**
  String get dataExportRangeCustom;

  /// What the export holds.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to} · days: {days} · entries: {entries} · weighings: {weighings}'**
  String dataExportSummary(
    String from,
    String to,
    int days,
    int entries,
    int weighings,
  );

  /// Privacy note above the share button.
  ///
  /// In en, this message translates to:
  /// **'The file is not encrypted. Whoever gets it sees your health data.'**
  String get dataExportPrivacyNote;

  /// Button that creates the export and opens the share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get dataExportShare;

  /// Error when the export files could not be written or shared.
  ///
  /// In en, this message translates to:
  /// **'Could not create the export.'**
  String get dataExportShareFailed;

  /// Error when the export data could not be read.
  ///
  /// In en, this message translates to:
  /// **'Could not load the data.'**
  String get dataExportLoadFailed;

  /// Title of the exported report.
  ///
  /// In en, this message translates to:
  /// **'Nutrition report'**
  String get dataExportReportTitle;

  /// Period line of the exported report.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to} · {days, plural, =1{1 day} other{{days} days}}'**
  String dataExportReportPeriod(String from, String to, int days);

  /// Question for the AI at the top of the text export.
  ///
  /// In en, this message translates to:
  /// **'I track my food with the app yamt. Below is my data for this period. Please rate my eating: what do I do well, what do I do wrong, and what should I change to reach my goal? Take training and pause days into account.'**
  String get dataExportAiPrompt;

  /// Header of the field explanations in the text export.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get dataExportFieldsHeader;

  /// Field explanations in the text export, one Markdown list item per line.
  ///
  /// In en, this message translates to:
  /// **'- kcal: kilocalories. P, C, F: protein, carbohydrates, fat in grams.\n- Goal: kcal and macro goal of the day. Training days have a higher kcal goal, rest days a lower one, so the week stays on target.\n- Pause day: a day without a goal, for example when ill or on holiday.\n- TDEE: estimated daily energy use, learned from weight and food.\n- Weight: weighing of the day; trend: smoothed weight.\n- Parts of the day: how the day\'s kcal goal splits over the meals.'**
  String get dataExportFieldsText;

  /// Header of the goals in the export.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get dataExportGoalsHeader;

  /// One goal in the export.
  ///
  /// In en, this message translates to:
  /// **'Goal {number}: {mode}, {start} – {end}, start weight {startWeight} kg, target weight {targetWeight} kg, {speed} kg per week, {kcal} kcal per day before training and rest day cycling'**
  String dataExportGoalLine(
    int number,
    String mode,
    String start,
    String end,
    String startWeight,
    String targetWeight,
    String speed,
    String kcal,
  );

  /// End of a goal that still runs.
  ///
  /// In en, this message translates to:
  /// **'running'**
  String get dataExportGoalRunning;

  /// Shown when no goal overlaps the export period.
  ///
  /// In en, this message translates to:
  /// **'No goal in this period.'**
  String get dataExportNoGoal;

  /// How the kcal goal splits over the meals; shares is a list like 'Breakfast 25 %, Lunch 35 %'.
  ///
  /// In en, this message translates to:
  /// **'Parts of the day: {shares}'**
  String dataExportMealShares(String shares);

  /// One meal share in the parts of the day list.
  ///
  /// In en, this message translates to:
  /// **'{meal} {percent} %'**
  String dataExportMealShare(String meal, int percent);

  /// Header of the overview in the export.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get dataExportOverviewHeader;

  /// Averages in the export overview.
  ///
  /// In en, this message translates to:
  /// **'Average per logged day: {kcal} kcal, protein {protein} g, carbohydrates {carbs} g, fat {fat} g. Average TDEE: {tdee} kcal.'**
  String dataExportOverviewLine(
    String kcal,
    String protein,
    String carbs,
    String fat,
    String tdee,
  );

  /// Weight change in the export overview.
  ///
  /// In en, this message translates to:
  /// **'Weight: {first} kg → {last} kg ({change} kg)'**
  String dataExportWeightLine(String first, String last, String change);

  /// Day type counts in the export overview.
  ///
  /// In en, this message translates to:
  /// **'Days: {training} training, {normal} normal, {pause} pause'**
  String dataExportDayTypesLine(int training, int normal, int pause);

  /// Header of the day list in the export.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get dataExportDaysHeader;

  /// Head line of one day in the text export: eaten against goal.
  ///
  /// In en, this message translates to:
  /// **'{date} · {type} · {kcal} / {goal} kcal · P {protein}/{proteinGoal} g · C {carbs}/{carbsGoal} g · F {fat}/{fatGoal} g'**
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
  );

  /// Weight of a day in the text export.
  ///
  /// In en, this message translates to:
  /// **'Weight {weight} kg, trend {trend} kg'**
  String dataExportDayWeight(String weight, String trend);

  /// TDEE of a day in the text export.
  ///
  /// In en, this message translates to:
  /// **'TDEE {tdee} kcal'**
  String dataExportDayTdee(String tdee);

  /// A day without entries in the export.
  ///
  /// In en, this message translates to:
  /// **'No entries'**
  String get dataExportNoEntries;

  /// Head of one meal in the text export.
  ///
  /// In en, this message translates to:
  /// **'{meal} · {kcal} kcal'**
  String dataExportMealLine(String meal, String kcal);

  /// One eaten food in the text export.
  ///
  /// In en, this message translates to:
  /// **'{name} · {amount} · {kcal} kcal · P {protein} g · C {carbs} g · F {fat} g'**
  String dataExportFoodLine(
    String name,
    String amount,
    String kcal,
    String protein,
    String carbs,
    String fat,
  );

  /// Report tile: average kcal eaten.
  ///
  /// In en, this message translates to:
  /// **'Average eaten'**
  String get dataExportKpiEaten;

  /// Report tile: average TDEE.
  ///
  /// In en, this message translates to:
  /// **'Average TDEE'**
  String get dataExportKpiTdee;

  /// Report tile: weight change.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get dataExportKpiWeight;

  /// Report tile: number of training and pause days.
  ///
  /// In en, this message translates to:
  /// **'Training / pause'**
  String get dataExportKpiDays;

  /// Report tile line under the average eaten kcal.
  ///
  /// In en, this message translates to:
  /// **'kcal · goal {kcal}'**
  String dataExportKpiGoal(String kcal);

  /// Report chart title.
  ///
  /// In en, this message translates to:
  /// **'Food, weight, and TDEE together'**
  String get dataExportChartCombined;

  /// Report chart title.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get dataExportChartWeight;

  /// Report chart title.
  ///
  /// In en, this message translates to:
  /// **'TDEE'**
  String get dataExportChartTdee;

  /// Report chart title.
  ///
  /// In en, this message translates to:
  /// **'kcal eaten vs. goal'**
  String get dataExportChartKcal;

  /// Report chart title.
  ///
  /// In en, this message translates to:
  /// **'Macros on average vs. goal'**
  String get dataExportChartMacros;

  /// Report chart legend: kcal eaten.
  ///
  /// In en, this message translates to:
  /// **'eaten'**
  String get dataExportLegendEaten;

  /// Report chart legend: kcal goal.
  ///
  /// In en, this message translates to:
  /// **'goal'**
  String get dataExportLegendGoal;

  /// Report chart legend: weight.
  ///
  /// In en, this message translates to:
  /// **'weight'**
  String get dataExportLegendWeight;

  /// Report chart legend: TDEE.
  ///
  /// In en, this message translates to:
  /// **'TDEE'**
  String get dataExportLegendTdee;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dataExportColumnDate;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Day type'**
  String get dataExportColumnDayType;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Goal kcal'**
  String get dataExportColumnGoal;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get dataExportColumnKcal;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Protein g'**
  String get dataExportColumnProtein;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Protein goal g'**
  String get dataExportColumnProteinGoal;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Carbs g'**
  String get dataExportColumnCarbs;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Carbs goal g'**
  String get dataExportColumnCarbsGoal;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Fat g'**
  String get dataExportColumnFat;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Fat goal g'**
  String get dataExportColumnFatGoal;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Weight kg'**
  String get dataExportColumnWeight;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Trend kg'**
  String get dataExportColumnTrend;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'TDEE kcal'**
  String get dataExportColumnTdee;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get dataExportColumnMeal;

  /// Table column: the meal's share of the day's kcal goal.
  ///
  /// In en, this message translates to:
  /// **'Part of the day kcal'**
  String get dataExportColumnMealGoal;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get dataExportColumnFood;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get dataExportColumnBrand;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get dataExportColumnAmount;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get dataExportColumnUnit;

  /// Table column: goal number.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get dataExportColumnNumber;

  /// Table column: goal mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get dataExportColumnMode;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get dataExportColumnStart;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get dataExportColumnEnd;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Start weight kg'**
  String get dataExportColumnStartWeight;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Target weight kg'**
  String get dataExportColumnTargetWeight;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'kg per week'**
  String get dataExportColumnSpeed;

  /// Table column: daily kcal goal before cycling.
  ///
  /// In en, this message translates to:
  /// **'Base kcal'**
  String get dataExportColumnBaseKcal;

  /// Table column: meal share in percent.
  ///
  /// In en, this message translates to:
  /// **'Share %'**
  String get dataExportColumnShare;

  /// Spreadsheet sheet name.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get dataExportSheetDays;

  /// Spreadsheet sheet name.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get dataExportSheetMeals;

  /// Spreadsheet sheet name.
  ///
  /// In en, this message translates to:
  /// **'Foods'**
  String get dataExportSheetFoods;

  /// Spreadsheet sheet name.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get dataExportSheetGoals;

  /// Footer of the exported report.
  ///
  /// In en, this message translates to:
  /// **'Made with yamt'**
  String get dataExportFooter;

  /// A macro in the report: eaten average against goal in grams.
  ///
  /// In en, this message translates to:
  /// **'{name} {value} / {goal} g'**
  String dataExportMacroBar(String name, String value, String goal);

  /// Report tile line under the weight change.
  ///
  /// In en, this message translates to:
  /// **'{first} → {last} kg'**
  String dataExportKpiWeightRange(String first, String last);

  /// Button that copies the AI export text to the clipboard, for AI apps that take no files.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get dataExportCopy;

  /// Snack bar after the AI export text was copied.
  ///
  /// In en, this message translates to:
  /// **'Copied. Paste it into your AI chat.'**
  String get dataExportCopied;

  /// Button that creates the report and saves it on the device, for the purpose For me.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dataExportSave;

  /// Snack bar after the report was saved on the device.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get dataExportSaved;

  /// Export period chip: every day from the start of the first goal to today.
  ///
  /// In en, this message translates to:
  /// **'All data'**
  String get dataExportRangeAll;

  /// Export period chip that opens a menu to pick one or more goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get dataExportRangeGoals;

  /// Export period chip label when goals first to last are picked.
  ///
  /// In en, this message translates to:
  /// **'Goals {first}–{last}'**
  String dataExportRangeGoalSpan(int first, int last);

  /// Food name in the export whose nutrition is not known yet, so its 0 kcal are not eaten food.
  ///
  /// In en, this message translates to:
  /// **'{name} · nutrition still open'**
  String dataExportFoodPending(String name);

  /// Separator between items of a list in the export, for example the parts of the day.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get dataExportListSeparator;

  /// Separator between the facts of a day in the PDF day table: day type, weight, TDEE.
  ///
  /// In en, this message translates to:
  /// **' · '**
  String get dataExportPartsSeparator;

  /// A weight in the export.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg'**
  String dataExportWeightValue(String weight);

  /// An eaten value and its goal in the PDF day table.
  ///
  /// In en, this message translates to:
  /// **'{value} / {goal}'**
  String dataExportValueOfGoal(String value, String goal);

  /// Number of training days and pause days in the PDF key numbers.
  ///
  /// In en, this message translates to:
  /// **'{training} / {pause}'**
  String dataExportTrainingPauseCount(int training, int pause);

  /// Unit under the average TDEE in the PDF key numbers.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get dataExportKcalUnit;

  /// First step of cooking a recipe in the new cooking flow.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get cookStepRecipe;

  /// Second step of cooking: assign each ingredient line from the stock.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get cookStepShopping;

  /// Third step of cooking: the pot question.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get cookStepCooking;

  /// Last step of cooking: weight, portions and putting the meal into the stock.
  ///
  /// In en, this message translates to:
  /// **'Portioning'**
  String get cookStepPortion;

  /// Portion count of the recipe being cooked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 portion} other{{count} portions}}'**
  String cookPortionsLabel(int count);

  /// Tooltip of the minus button of a counter.
  ///
  /// In en, this message translates to:
  /// **'Fewer'**
  String get cookFewer;

  /// Tooltip of the plus button of a counter.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get cookMore;

  /// Section title of the ingredient lines of a recipe.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get cookIngredients;

  /// Button on the recipe step that starts assigning stock to each line.
  ///
  /// In en, this message translates to:
  /// **'Assign ingredients'**
  String get cookAssignAction;

  /// Kicker of the found page: how many lines the stock suggestions cover.
  ///
  /// In en, this message translates to:
  /// **'{done} of {count} ingredients'**
  String cookFoundKicker(int done, int count);

  /// Title of the page with the stock suggestions to confirm.
  ///
  /// In en, this message translates to:
  /// **'Found in the stock'**
  String get cookFoundTitle;

  /// Hint on the found page.
  ///
  /// In en, this message translates to:
  /// **'Does the suggestion fit? Tap the item for another one.'**
  String get cookFoundHint;

  /// Tooltip of the check button that accepts a stock suggestion.
  ///
  /// In en, this message translates to:
  /// **'Fits'**
  String get cookFits;

  /// Tooltip of the cross button that turns a stock suggestion down.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t fit'**
  String get cookFitsNot;

  /// Warning under a line whose stock items hold less than it needs.
  ///
  /// In en, this message translates to:
  /// **'{amount} missing'**
  String cookMissingAmount(String amount);

  /// Disabled main button while suggestions are neither accepted nor turned down.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Check 1 more} other{Check {count} more}}'**
  String cookCheckRest(int count);

  /// Main button that goes to the next step of cooking.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get cookNext;

  /// Kicker of the page with the lines still to settle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ingredient} other{{count} ingredients}}'**
  String cookOpenKicker(int count);

  /// Title of the page with lines that have no accepted stock suggestion.
  ///
  /// In en, this message translates to:
  /// **'Still to settle'**
  String get cookOpenTitle;

  /// Hint on the page with the lines still to settle.
  ///
  /// In en, this message translates to:
  /// **'Assign from the stock or leave out.'**
  String get cookOpenHint;

  /// State of a line that the stock has no fitting item for.
  ///
  /// In en, this message translates to:
  /// **'No item in the stock'**
  String get cookOpenNoItem;

  /// State of a line whose stock suggestion the cook turned down.
  ///
  /// In en, this message translates to:
  /// **'Suggestion turned down'**
  String get cookOpenRejected;

  /// State of a line the cook leaves out of this cooking.
  ///
  /// In en, this message translates to:
  /// **'Left out'**
  String get cookOpenOmitted;

  /// Button that picks stock items for a line.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get cookAssign;

  /// Button that leaves a line out of this cooking.
  ///
  /// In en, this message translates to:
  /// **'Leave out'**
  String get cookOmit;

  /// How much of an item the stock holds.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String cookStockLeft(String amount);

  /// Title of the pot question before cooking.
  ///
  /// In en, this message translates to:
  /// **'What do you cook in?'**
  String get cookPotTitle;

  /// Hint of the pot question.
  ///
  /// In en, this message translates to:
  /// **'Weigh the full pot at the end; its empty weight is known.'**
  String get cookPotHint;

  /// Empty weight of a saved pot.
  ///
  /// In en, this message translates to:
  /// **'empty {grams} g'**
  String cookPotEmptyWeight(int grams);

  /// Name of a saved utensil without a name.
  ///
  /// In en, this message translates to:
  /// **'Pot'**
  String get cookPotUnnamed;

  /// Choice of cooking without weighing a pot: the meal is counted in portions or pieces.
  ///
  /// In en, this message translates to:
  /// **'Without pot · by count'**
  String get cookPotNone;

  /// Button after the pot question that goes to portioning.
  ///
  /// In en, this message translates to:
  /// **'Done cooking'**
  String get cookDoneCooking;

  /// Title of the portioning step.
  ///
  /// In en, this message translates to:
  /// **'Into the stock'**
  String get cookPortionTitle;

  /// Label of the field with the name of the cooked meal.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get cookMealName;

  /// Label of the field for the weight of the full pot on the scale.
  ///
  /// In en, this message translates to:
  /// **'Pot with food (g)'**
  String get cookGrossWeight;

  /// The food weight: full pot minus the empty pot.
  ///
  /// In en, this message translates to:
  /// **'Food: {grams} g'**
  String cookNetWeight(int grams);

  /// Error when the full pot weighs no more than the empty one.
  ///
  /// In en, this message translates to:
  /// **'Heavier than the empty pot ({grams} g)'**
  String cookWeightTooLow(int grams);

  /// Toggle: the meal is counted in portions.
  ///
  /// In en, this message translates to:
  /// **'Portions'**
  String get cookCountPortions;

  /// Toggle: the meal is counted in pieces, such as wraps.
  ///
  /// In en, this message translates to:
  /// **'Pieces'**
  String get cookCountPieces;

  /// Main button that puts the cooked meal into the stock and takes its ingredients.
  ///
  /// In en, this message translates to:
  /// **'Into the stock'**
  String get cookToStock;

  /// Snack bar after the cooked meal went into the stock.
  ///
  /// In en, this message translates to:
  /// **'{name} is in the stock'**
  String cookSaved(String name);

  /// Error when putting the cooked meal into the stock failed.
  ///
  /// In en, this message translates to:
  /// **'Could not put the meal into the stock.'**
  String get cookFinishFailed;

  /// Error: an assigned stock item has no nutrition values.
  ///
  /// In en, this message translates to:
  /// **'An ingredient lacks nutrition values.'**
  String get cookFinishMissingNutrition;

  /// Error: an assigned item holds less than assigned.
  ///
  /// In en, this message translates to:
  /// **'The stock changed: an item holds too little now.'**
  String get cookFinishTooLittle;

  /// Error: an assigned item was removed from the stock.
  ///
  /// In en, this message translates to:
  /// **'An item is no longer in the stock.'**
  String get cookFinishItemGone;

  /// Kicker of the sheet that picks stock items for one line.
  ///
  /// In en, this message translates to:
  /// **'Fill line'**
  String get cookPickerKicker;

  /// Hint of the item picker: each tapped item gives what it has, the last fills the rest.
  ///
  /// In en, this message translates to:
  /// **'Fitting in the stock · tap in order'**
  String get cookPickerHint;

  /// Sum of the picked items against what the line needs.
  ///
  /// In en, this message translates to:
  /// **'Together: {have} of {need}'**
  String cookPickerSum(String have, String need);

  /// Item picker without fitting items.
  ///
  /// In en, this message translates to:
  /// **'Nothing fitting in the stock.'**
  String get cookPickerEmpty;

  /// Button that assigns the picked items to the line.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get cookPickerApply;

  /// Shown when the recipe being cooked was removed.
  ///
  /// In en, this message translates to:
  /// **'This recipe is no longer in the cookbook.'**
  String get cookRecipeGone;

  /// Error when the recipe or the stock could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Could not load the recipe.'**
  String get cookLoadFailed;

  /// Button in the item picker that also lists the stock items whose name does not fit the line.
  ///
  /// In en, this message translates to:
  /// **'Show all stock items'**
  String get cookPickerShowAll;

  /// An amount in grams in the cooking flow, such as "150 g".
  ///
  /// In en, this message translates to:
  /// **'{amount} g'**
  String cookAmountGrams(String amount);

  /// An amount in milliliters in the cooking flow.
  ///
  /// In en, this message translates to:
  /// **'{amount} ml'**
  String cookAmountMilliliters(String amount);

  /// A count of pieces in the cooking flow, such as "2 pc".
  ///
  /// In en, this message translates to:
  /// **'{amount} pc'**
  String cookAmountPieces(String amount);

  /// An amount followed by its food in the cooking flow, such as "150 g Barilla" or "1 mittlere Zwiebel".
  ///
  /// In en, this message translates to:
  /// **'{amount} {food}'**
  String cookAmountOf(String amount, String food);

  /// What a Vorrat item still holds, shown after the amount a recipe line takes of it.
  ///
  /// In en, this message translates to:
  /// **'· {amount} left'**
  String cookStockAfterTake(String amount);

  /// Shown on the portion step of cooking when no recipe line takes anything from the Vorrat, so there is no meal to put in.
  ///
  /// In en, this message translates to:
  /// **'Nothing from the Vorrat goes into this meal yet.'**
  String get cookFinishNothingTaken;

  /// Shown on the pot step of cooking when the saved pots fail to load, above a retry button.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your pots.'**
  String get cookPotLoadFailed;
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
