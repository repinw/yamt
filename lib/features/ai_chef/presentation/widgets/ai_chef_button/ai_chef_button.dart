import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_dialog.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the AI Chef generator.
void openAiChef(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  unawaited(HapticFeedback.lightImpact());
  unawaited(
    showAiChefDialog(
      context,
      inventoryItemsLoader: () {
        return container.read(inventoryItemRepositoryProvider).readAll();
      },
    ),
  );
}

/// Cookbook header tool that launches the AI Chef generator.
class AiChefButton extends StatelessWidget {
  /// Creates an AI Chef button.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeHeaderTool(
      symbol: const Icon(Icons.auto_awesome_rounded),
      label: AppLocalizations.of(context)!.aiChefIdeaToolLabel,
      onPressed: () => openAiChef(context),
    );
  }
}
