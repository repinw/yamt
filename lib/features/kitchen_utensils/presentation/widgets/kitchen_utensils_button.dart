import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Button that opens the kitchen utensil library.
class KitchenUtensilsButton extends StatelessWidget {
  /// Creates button.
  const KitchenUtensilsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: l10n.kitchenUtensilsOpenAction,
      onPressed: () {
        unawaited(context.push(AppRoutes.homeKitchenUtensils));
      },
      icon: const Icon(Icons.kitchen_rounded),
    );
  }
}
