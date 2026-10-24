import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/prepared_meal_reminder_plan_service.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'recipe_reminder_plan_controller.g.dart';

/// Gives the reminders of Kochbuch recipes their values once the recipes
/// let them count. It lives as long as `RecipeReminderPlanListener` around
/// the app watches it.
@riverpod
class RecipeReminderPlanController extends _$RecipeReminderPlanController {
  @override
  void build() {
    // At app start the recipes may come before the plans can be read.
    ref.listen(plannedEntryRepositoryProvider, (_, _) {
      if (_latest case final templates?) {
        unawaited(refresh(templates));
      }
    });
  }

  /// Counts the reminders that [templates] can count now, with the Vorrat as
  /// it is. One refresh runs at a time; changes that come in meanwhile run
  /// once after it with the latest recipes. A failure is logged and the
  /// next change tries again.
  ///
  /// shortcut: only a change of the recipes counts the reminders, not a
  /// Vorrat item that is new; accepting the reminder counts it then.
  Future<void> refresh(List<PreparedMeal> templates) async {
    _latest = _next = templates;
    if (_running) {
      return;
    }
    _running = true;
    try {
      for (var next = _next; next != null; next = _next) {
        _next = null;
        await _refresh(next);
        if (!ref.mounted) {
          return;
        }
      }
    } finally {
      _running = false;
    }
  }

  List<PreparedMeal>? _latest;
  List<PreparedMeal>? _next;
  var _running = false;

  Future<void> _refresh(List<PreparedMeal> templates) async {
    try {
      // Listened, so neither auto-dispose provider goes away while it runs.
      final items = ref.listen(
        inventoryQuickEatItemsProvider.future,
        (_, _) {},
      );
      final service = ref.listen(
        preparedMealReminderPlanServiceProvider,
        (_, _) {},
      );
      try {
        await service.read().refreshRecipes(templates, await items.read());
      } finally {
        items.close();
        service.close();
      }
    } on Object catch (error, stackTrace) {
      log(
        'Recipe reminders kept their kind.',
        name: 'RecipeReminderPlanController',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
