import 'dart:ui' show Locale;

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cooking/application/cook_recipe_source.dart';
import 'package:yamt/features/cooking/application/stock_suggestion.dart';
import 'package:yamt/features/cooking/domain/cook_line_food.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/cooking/presentation/controllers/cook_session_controller.dart';
import 'package:yamt/features/cooking/presentation/models/cook_view.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'cook_view_builder.g.dart';

/// The cooking page of the recipe [recipeId]: the recipe, the cook's
/// choices, and each line with its Vorrat suggestion; `null` when the
/// recipe is gone. It loads and fails with the recipe and the Vorrat.
@riverpod
AsyncValue<CookView?> cookView(Ref ref, String recipeId, String localeCode) {
  // Watched first, so the cook's choices outlive a loading or failing
  // Vorrat.
  final session = ref.watch(cookSessionControllerProvider(recipeId));
  final template = ref.watch(cookRecipeTemplateProvider(recipeId));
  final items = ref.watch(inventoryQuickEatItemsProvider);
  for (final async in [template, items]) {
    if (async case AsyncError(:final error, :final stackTrace)) {
      return AsyncError(error, stackTrace);
    }
  }
  // The previous values carry the page through a reload.
  if (!template.hasValue || !items.hasValue) {
    return const AsyncLoading();
  }
  final stored = template.value;
  if (stored == null) {
    return const AsyncData(null);
  }
  return AsyncData(
    buildCookView(
      template: stored,
      items: items.requireValue,
      session: session,
      parser: ref.watch(templateIngredientParserProvider),
      localeCode: localeCode,
      l10n: lookupAppLocalizations(Locale(localeCode)),
    ),
  );
}

/// The view of [session] cooking [template] from [items]. Lines are
/// suggested in recipe order, and an item one line is offered is not
/// offered again to a later one.
CookView buildCookView({
  required PreparedMeal template,
  required List<InventoryItem> items,
  required CookSession session,
  required TemplateIngredientParser parser,
  required String localeCode,
  required AppLocalizations l10n,
}) {
  final recipe = cookRecipeOfTemplate(template);
  final portions = session.portions ?? recipe.portions;
  final byId = {for (final item in items) item.id: item};
  List<CookTakeView> show(List<ItemTake> takes) => [
    for (final take in takes)
      if (byId[take.itemId] case final item?) (item: item, amount: take.amount),
  ];
  var reserving = session;
  final lines = <CookLineView>[];
  for (final line in recipe.lines) {
    final requirement = parser.parseRequirement(
      ingredient: line.text,
      selectedPortions: portions,
      basePortions: recipe.portions,
    );
    final clarification = session.lineOf(line.id);
    final (:candidates, :more, :suggestion) = suggest(
      lineId: line.id,
      text: line.text,
      requirement: requirement,
      recipe: template,
      items: items,
      session: reserving,
      localeCode: localeCode,
    );
    final conversion = template.recipeIngredientAmountConversions[line.text];
    CookOffer offer(InventoryItem item) => (
      item: item,
      available:
          item.availableAmount -
          session.takenFrom(item.id, exceptLineId: line.id),
      needed: neededFrom(requirement, item, conversion)?.amount,
    );
    if (clarification is LineOpen && suggestion.isNotEmpty) {
      reserving = reserving.withLine(line.id, LineAssigned(suggestion));
    }
    final takes = switch (clarification) {
      LineAssigned(:final takes) => show(takes),
      _ => show(suggestion),
    };
    final first = takes.firstOrNull?.item ?? candidates.firstOrNull;
    final needed = first == null
        ? null
        : neededFrom(requirement, first, conversion);
    lines.add(
      CookLineView(
        line: line,
        label: _label(l10n, parser, line.text, requirement),
        food: cookLineFood(requirement?.name ?? line.text),
        clarification: clarification,
        offers: [for (final item in candidates) offer(item)],
        moreOffers: [for (final item in more) offer(item)],
        suggestion: show(suggestion),
        takes: takes,
        needed: needed?.amount,
        unit: needed?.unit ?? first?.amountUnit,
        scale: first == null ? 1 : cookAmountScale(first),
      ),
    );
  }
  return CookView(
    recipe: recipe,
    session: session,
    portions: portions,
    lines: lines,
  );
}

// The line sized for the portions cooked. Pieces show no unit ("1 mittlere
// Zwiebel"), unless the recipe counts them in a measure ("2 EL").
String _label(
  AppLocalizations l10n,
  TemplateIngredientParser parser,
  String text,
  TemplateIngredientRequirement? requirement,
) => switch (requirement) {
  null => text,
  TemplateIngredientRequirement(
    unit: TemplateIngredientUnit.piece,
    :final amount,
    :final name,
    countMeasureLabel: null || '',
  ) =>
    l10n.cookAmountOf('$amount', name),
  _ => parser.pendingIngredientLabel(
    originalIngredient: text,
    requirement: requirement,
  ),
};
