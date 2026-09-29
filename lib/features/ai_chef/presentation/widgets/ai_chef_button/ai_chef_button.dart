import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_dialog.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';

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
