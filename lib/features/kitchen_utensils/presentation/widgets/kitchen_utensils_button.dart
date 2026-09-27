import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Cookbook header tool that opens the kitchen utensil library.
class KitchenUtensilsButton extends StatelessWidget {
  /// Creates button.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeHeaderTool(
      symbol: const Icon(Icons.kitchen_rounded),
      label: AppLocalizations.of(context)!.kitchenUtensilsToolLabel,
      onPressed: () {
        unawaited(context.push(AppRoutes.homeKitchenUtensils));
      },
    );
  }
}
