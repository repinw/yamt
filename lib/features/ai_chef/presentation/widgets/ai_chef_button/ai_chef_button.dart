import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/ai_chef/presentation/controllers/'
    'ai_chef_controller.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_dialog.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// App Bar action button for launching the AI Chef generator.
@Dependencies([AiChefController, InventoryItemsController])
class AiChefButton extends StatelessWidget {
  /// Creates an AI Chef button.
  const AiChefButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: l10n.aiChefTooltip,
      onPressed: () {
        unawaited(HapticFeedback.lightImpact());
        unawaited(showAiChefDialog(context));
      },
      icon: Icon(
        Icons.auto_awesome_rounded,
        color: colors.primary,
      ),
    );
  }
}
