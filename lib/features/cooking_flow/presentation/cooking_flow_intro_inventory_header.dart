import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_action_button.dart';
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
    final colors = FoodLabelColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            l10n.cookflowInventoryCheckTitle,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: colors.ink, fontWeight: FontWeight.w800),
          ),
        ),
        if (hasSelections)
          CookingFlowQuietButton(
            label: l10n.cookflowResetButton,
            onPressed: () {
              unawaited(onRestartPressed());
            },
          ),
      ],
    );
  }
}
