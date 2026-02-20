// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeInventory => 'Inventory';

  @override
  String get homeShopping => 'Shopping';

  @override
  String get homeCalories => 'Calories';

  @override
  String get homeSettings => 'Settings';

  @override
  String get homeQuickActionTooltip => 'Quick action';

  @override
  String get homeQuickActionTapped => 'Quick action tapped';

  @override
  String get inventoryFabTooltip => 'Receipt actions';

  @override
  String get inventoryActionScanCamera => 'Scan receipt (camera)';

  @override
  String get inventoryActionUploadFile => 'Upload receipt (image/PDF)';

  @override
  String get inventoryActionCameraUnsupported => 'Camera is not supported on this platform.';

  @override
  String get inventoryReceiptSelectedCamera => 'Receipt image captured.';

  @override
  String get inventoryReceiptSelectedFile => 'Receipt file selected.';

  @override
  String get inventoryReceiptSelectionFailed => 'Could not select a receipt. Please try again.';

  @override
  String get inventoryReceiptAnalysisSucceeded => 'Receipt analyzed successfully.';

  @override
  String get inventoryReceiptAnalysisFailed => 'Receipt analysis failed. Please try again.';

  @override
  String get inventoryReceiptReviewTitle => 'Review receipt items';

  @override
  String get inventoryReceiptReviewPriceTitle => 'Price overview';

  @override
  String get inventoryReceiptReviewPriceTotal => 'Total receipt';

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
  String get inventoryReceiptReviewFieldId => 'ID';

  @override
  String get inventoryReceiptReviewFieldName => 'Name';

  @override
  String get inventoryReceiptReviewFieldEntryDate => 'Entry date';

  @override
  String get inventoryReceiptReviewFieldStoreName => 'Store name';

  @override
  String get inventoryReceiptReviewFieldQuantity => 'Quantity';

  @override
  String get inventoryReceiptReviewFieldInitialQuantity => 'Initial quantity';

  @override
  String get inventoryReceiptReviewFieldUnitPrice => 'Unit price';

  @override
  String get inventoryReceiptReviewFieldWeight => 'Weight';

  @override
  String get inventoryReceiptReviewFieldBrand => 'Brand';

  @override
  String get inventoryReceiptReviewFieldCategory => 'Category';

  @override
  String get inventoryReceiptReviewFieldDiscounts => 'Discounts (JSON)';

  @override
  String get inventoryReceiptReviewDiscountsHint => 'JSON or pairs: coupon=-1.50';

  @override
  String get inventoryReceiptReviewFieldReceiptId => 'Receipt ID';

  @override
  String get inventoryReceiptReviewFieldReceiptDate => 'Receipt date';

  @override
  String get inventoryReceiptReviewFieldLanguage => 'Language';

  @override
  String get inventoryReceiptReviewFieldIsDeposit => 'Is deposit item';

  @override
  String get inventoryReceiptReviewFieldIsDiscount => 'Is discount item';

  @override
  String get inventoryReceiptReviewSelectDateAction => 'Select date';

  @override
  String get inventoryReceiptReviewClearDateAction => 'Clear date';

  @override
  String get inventoryReceiptReviewNoDate => 'No date';

  @override
  String get inventoryReceiptReviewInvalidNumber => 'Please enter valid numbers.';

  @override
  String get inventoryReceiptReviewInvalidDiscounts => 'Use JSON or key=value pairs.';

  @override
  String get inventoryReceiptReviewCancelAction => 'Cancel';

  @override
  String get inventoryReceiptReviewSaveAction => 'Save to inventory';

  @override
  String get inventoryReceiptSaveSucceeded => 'Items added to inventory.';

  @override
  String get inventoryReceiptSaveFailed => 'Could not save receipt items. Please try again.';

  @override
  String get inventorySummaryTitle => 'Overview';

  @override
  String get inventorySummaryEntries => 'Entries';

  @override
  String get inventorySummaryQuantity => 'Total quantity';

  @override
  String get inventorySummaryEstimatedValue => 'Estimated value';

  @override
  String get inventoryListSectionTitle => 'Items';

  @override
  String get inventoryReceiptGroupTitle => 'Receipt';

  @override
  String get inventoryReceiptGroupNoReceipt => 'No receipt';

  @override
  String get inventoryReceiptGroupItems => 'items';

  @override
  String get inventoryItemNoPrice => 'No price';

  @override
  String get inventoryItemDeleteAction => 'Delete';

  @override
  String get inventoryItemEatAction => 'Eat';

  @override
  String get inventoryItemThrowAwayAction => 'Throw away';

  @override
  String get inventoryItemActionFailed => 'Action failed. Please try again.';

  @override
  String get inventoryEmptyState => 'No items in your fridge yet. Scan a receipt to get started.';

  @override
  String get inventoryLoadFailed => 'Could not load inventory items.';

  @override
  String get inventoryRetryAction => 'Retry';

  @override
  String get homeShoppingActionContextPlaceholder => 'Shopping action coming soon.';

  @override
  String get homeCaloriesActionContextPlaceholder => 'Calories action coming soon.';

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
  String get accountPageLinkSuccess => 'Account linked successfully.';

  @override
  String get accountPageLinkNotCompleted => 'Account linking was not completed. Please try again.';

  @override
  String get accountPageLinkConflictTitle => 'Google account already in use';

  @override
  String get accountPageLinkConflictDescription => 'This Google account is already linked to another profile. Choose how to continue.';

  @override
  String get accountPageLinkConflictOverwriteAction => 'Overwrite with this guest';

  @override
  String get accountPageLinkConflictOverwriteSubtitle => 'Keep this guest account and replace the old Google-linked account.';

  @override
  String get accountPageLinkConflictDeleteGuestAction => 'Delete guest and sign in';

  @override
  String get accountPageLinkConflictDeleteGuestSubtitle => 'Delete this guest account and continue with the existing Google account.';

  @override
  String get accountPageLinkConflictOverwriteDone => 'Google account moved to this guest account.';

  @override
  String get accountPageLinkConflictDeleteGuestDone => 'Guest account deleted. Signed in with Google.';

  @override
  String get accountPageGuestSessionRequired => 'This action is only available for guest accounts.';

  @override
  String get accountPageSignOut => 'Sign out';

  @override
  String get accountPageDisplayName => 'Display name';

  @override
  String get accountPageEmail => 'Email';

  @override
  String get accountPageUserId => 'User ID';

  @override
  String get accountPageNotSet => 'Not set';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsAboutSubtitle => 'App version and information';

  @override
  String get appSubtitle => 'Yet Another Meal Tracker';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get loginAsGuest => 'Login as guest';

  @override
  String get loginWithGoogle => 'Login with Google';

  @override
  String get registerWithGoogle => 'Register with Google';

  @override
  String get createAccount => 'Create account';

  @override
  String get authSwitchToRegister => 'Don\'t have an account? Register';

  @override
  String get authSwitchToLogin => 'Already have an account? Login';

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
  String get commonNotImplementedYet => 'Not implemented yet';
}
