import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/presentation/controllers/recipe_reminder_plan_controller.dart';

/// Counts the reminders of Kochbuch recipes as soon as a recipe change,
/// here or on another device of the household, lets them. Wraps the app.
class RecipeReminderPlanListener extends ConsumerWidget {
  /// Creates the listener around [child].
  const new({required this.child, super.key});

  /// The app.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(recipeReminderPlanControllerProvider);
    ref.listen(planTemplatesProvider, (_, next) {
      // A failed read changes nothing; the next change counts.
      if (next case AsyncData(value: final templates)) {
        unawaited(
          ref
              .read(recipeReminderPlanControllerProvider.notifier)
              .refresh(templates),
        );
      }
    });
    return child;
  }
}
