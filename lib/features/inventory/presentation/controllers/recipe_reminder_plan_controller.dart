import 'dart:async';
import 'dart:developer' show log;

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/prepared_meal_reminder_plan_service.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'recipe_reminder_plan_controller.g.dart';

/// Gives the plans of Kochbuch recipes their values whenever a change of
/// the household's recipes lets a reminder count or gives a recipe other
/// saved Vorrat items. It lives as long as
/// `RecipeReminderPlanListener` around the app watches it.
@riverpod
class RecipeReminderPlanController extends _$RecipeReminderPlanController {
  @override
  void build() {
    ref.listen(planTemplatesProvider, (previous, next) {
      // A failed read changes nothing; the next change counts.
      if (next case AsyncData(value: final templates)) {
        // Several changes before a run keep the oldest version.
        for (final before in _repickedBefore(previous?.value, templates)) {
          _repicked.putIfAbsent(before.id, () => before);
        }
        unawaited(_count(templates));
      }
    });
    // At app start the recipes may come before the plans can be read.
    ref.listen(plannedEntryRepositoryProvider, (_, _) {
      if (ref.read(planTemplatesProvider) case AsyncData(
        value: final templates,
      )) {
        unawaited(_count(templates));
      }
    });
  }

  /// Counts the reminders that [templates] can count now, with the Vorrat as
  /// it is. One run at a time; changes that come in meanwhile run once
  /// after it with the latest recipes. A failure is logged and the next
  /// change tries again.
  ///
  /// shortcut: only a change of the recipes counts the reminders, not a
  /// Vorrat item that is new; accepting the reminder counts it then.
  Future<void> _count(List<PreparedMeal> templates) async {
    _next = templates;
    if (_running) {
      return;
    }
    _running = true;
    try {
      for (var next = _next; next != null; next = _next) {
        _next = null;
        final repicked = {..._repicked};
        _repicked.clear();
        if (!await _refresh(next, repicked)) {
          // The next change counts these recipes again, from these older
          // versions.
          _repicked.addAll(repicked);
        }
        if (!ref.mounted) {
          return;
        }
      }
    } finally {
      _running = false;
    }
  }

  List<PreparedMeal>? _next;
  final _repicked = <String, PreparedMeal>{};
  var _running = false;

  Future<bool> _refresh(
    List<PreparedMeal> templates,
    Map<String, PreparedMeal> repicked,
  ) async {
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
        await service.read().refreshRecipes(
          templates,
          await items.read(),
          repicked: repicked,
        );
      } finally {
        items.close();
        service.close();
      }
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Recipe reminders kept their kind.',
        name: 'RecipeReminderPlanController',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}

/// The recipes of [before] whose saved Vorrat items differ in [after], as
/// they were before.
Iterable<PreparedMeal> _repickedBefore(
  List<PreparedMeal>? before,
  List<PreparedMeal> after,
) {
  final saved = {
    for (final template in after)
      template.id: template.recipeIngredientAssignments,
  };
  return [
    for (final template in before ?? const <PreparedMeal>[])
      if (saved[template.id] case final items?
          when !const DeepCollectionEquality().equals(
            items,
            template.recipeIngredientAssignments,
          ))
        template,
  ];
}
