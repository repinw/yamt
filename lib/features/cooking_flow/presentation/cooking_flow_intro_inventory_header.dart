import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Header displaying the inventory check title and optional reset action.
class CookingFlowInventoryCheckHeader extends StatelessWidget {
  /// Creates an inventory check header.
  const new({
    required this.hasSelections,
    required this.onRestartPressed,
    super.key,
  });

  /// Whether any items or actions are currently selected.
  final bool hasSelections;

  /// Callback when the reset button is pressed.
  final Future<void> Function() onRestartPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: <Widget>[
        Icon(Icons.shopping_cart_outlined, color: colors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Text(
          l10n.cookflowInventoryCheckTitle,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        if (hasSelections)
          TextButton.icon(
            onPressed: () {
              unawaited(onRestartPressed());
            },
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(l10n.cookflowResetButton),
          ),
      ],
    );
  }
}
