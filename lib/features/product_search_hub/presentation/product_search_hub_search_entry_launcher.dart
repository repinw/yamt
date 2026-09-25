import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_entry_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens edited entries from the hub search view.
typedef ProductSearchHubSearchEditedEntryOpener =
    Future<ProductSearchHubEditedResult?> Function(AppLocalizations l10n);

/// Coordinates keyboard and view state while opening an edited search entry.
Future<void> openProductSearchHubSearchEditedEntry({
  required BuildContext context,
  required bool isOpeningEntry,
  required ValueChanged<bool> setOpeningEntry,
  required VoidCallback hideKeyboard,
  required VoidCallback onCancelled,
  required ValueChanged<ProductSearchHubEditedResult> onResult,
  required ProductSearchHubSearchEditedEntryOpener openEntry,
}) async {
  if (isOpeningEntry) {
    return;
  }
  setOpeningEntry(true);
  hideKeyboard();

  final result = await openEntry(AppLocalizations.of(context)!);
  if (!context.mounted) {
    return;
  }
  setOpeningEntry(false);
  if (result == null) {
    onCancelled();
    return;
  }
  onResult(result);
}
