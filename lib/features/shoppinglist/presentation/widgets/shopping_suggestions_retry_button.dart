import 'package:material_ui/material_ui.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Offers to load the suggestions again after they failed. The feature that
/// owns the suggestions puts it in the error slot of the list page.
class ShoppingSuggestionsRetryButton extends StatelessWidget {
  /// Creates the button.
  const new({required this.onRetry, super.key});

  /// Loads the suggestions again.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: Text(AppLocalizations.of(context)!.shoppingListSuggestionsRetry),
    ),
  );
}
