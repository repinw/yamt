import 'package:flutter/material.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_entry_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens edited entries from the focused hub search page.
typedef ProductSearchHubSearchEditedEntryOpener =
    Future<ProductSearchHubEditedResult?> Function(AppLocalizations l10n);

/// Coordinates keyboard and page state while opening an edited search entry.
Future<void> openProductSearchHubSearchEditedEntry({
  required BuildContext context,
  required bool isOpeningEntry,
  required bool isClosing,
  required ValueChanged<bool> setOpeningEntry,
  required VoidCallback hideKeyboard,
  required VoidCallback requestKeyboard,
  required ValueChanged<Object?> closeSearchPage,
  required ProductSearchHubSearchEditedEntryOpener openEntry,
}) async {
  if (isOpeningEntry || isClosing) {
    return;
  }
  setOpeningEntry(true);
  hideKeyboard();

  final result = await openEntry(AppLocalizations.of(context)!);
  if (!context.mounted) {
    return;
  }
  if (result == null) {
    setOpeningEntry(false);
    requestKeyboard();
    return;
  }
  closeSearchPage(result);
}
