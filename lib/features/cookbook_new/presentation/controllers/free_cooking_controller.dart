import 'dart:developer' show log;

import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cookbook_new/application/ingredient_stock_match.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_row.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_transcript.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/prepared_meal_cooking_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

part 'free_cooking_controller.g.dart';

/// The ingredient rows of the meal on the "Frei kochen" page.
@immutable
class FreeCookingDraft {
  /// Creates a draft with [rows].
  const new({
    this.rows = const <String>[],
    this.isCooking = false,
    this.addedLast = 0,
  });

  /// The rows as spoken or typed.
  final List<String> rows;

  /// Whether "Kochen" is saving the meal.
  final bool isCooking;

  /// How many of the last [rows] the last text added, which an undo word
  /// takes out again.
  final int addedLast;

  /// Copy with.
  FreeCookingDraft copyWith({
    List<String>? rows,
    bool? isCooking,
    int? addedLast,
  }) {
    return FreeCookingDraft(
      rows: rows ?? this.rows,
      isCooking: isCooking ?? this.isCooking,
      addedLast: addedLast ?? this.addedLast,
    );
  }
}

/// Holds the rows of a meal cooked without a recipe and saves it as a Vorrat
/// meal.
@riverpod
class FreeCookingController extends _$FreeCookingController {
  @override
  FreeCookingDraft build() => const FreeCookingDraft();

  /// Adds the rows found in spoken or typed [text]. An undo word such as
  /// "nein" at its start takes the rows added last out again first, so
  /// "nein, 200 g Sahne" swaps them for the correction.
  void addText(String text) {
    final correction = afterUndoWords(text);
    final rows = splitFreeCookingTranscript(correction ?? text);
    if (rows.isEmpty && (correction == null || state.addedLast == 0)) {
      return;
    }
    final kept = correction == null
        ? state.rows
        : state.rows.sublist(0, state.rows.length - state.addedLast);
    state = state.copyWith(rows: [...kept, ...rows], addedLast: rows.length);
  }

  /// Loads the Vorrat again after it failed.
  void retryStock() => ref.invalidate(inventoryQuickEatItemsProvider);

  /// Removes the row at [index].
  void removeRow(int index) {
    final firstAddedLast = state.rows.length - state.addedLast;
    state = state.copyWith(
      rows: [...state.rows]..removeAt(index),
      addedLast: index >= firstAddedLast
          ? state.addedLast - 1
          : state.addedLast,
    );
  }

  /// Saves the meal [name] with [rows] in the Vorrat. Rows in stock take their
  /// amount from the matched item; the others stay open on the meal.
  /// Returns the id of the saved meal, or `null` when saving failed.
  Future<String?> cook({
    required String name,
    required List<FreeCookingRow> rows,
  }) async {
    if (state.isCooking || rows.isEmpty) {
      return null;
    }
    final link = ref.keepAlive();
    state = state.copyWith(isCooking: true);
    try {
      final result = await ref
          .read(preparedMealCookingServiceProvider)
          .cook(
            name: name,
            ingredients: [for (final row in rows) row.text],
            assignments: {
              for (final row in rows)
                if (row.stockItem case final item?) row.text: [item.id],
            },
          );
      if (ref.mounted) {
        state = result.isSuccess
            ? const FreeCookingDraft()
            : state.copyWith(isCooking: false);
      }
      return result.isSuccess ? result.preparedMealId : null;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to cook the free meal.',
        name: 'FreeCookingController',
        error: error,
        stackTrace: stackTrace,
      );
      if (ref.mounted) {
        state = state.copyWith(isCooking: false);
      }
      return null;
    } finally {
      link.close();
    }
  }
}

/// The draft rows with their amount and the Vorrat item that supplies each.
/// It loads and fails with the Vorrat.
///
/// It is synchronous, so a removed row is gone in the same frame. A row gets
/// a Vorrat item only when it has an amount in a unit that the item can
/// supply, because only then does "Kochen" take the row from the Vorrat.
@riverpod
AsyncValue<List<FreeCookingRow>> freeCookingRows(Ref ref, String localeCode) {
  final texts = ref.watch(
    freeCookingControllerProvider.select((draft) => draft.rows),
  );
  final parser = ref.watch(templateIngredientParserProvider);
  return ref
      .watch(inventoryQuickEatItemsProvider)
      .whenData(
        (items) => [
          for (final text in texts)
            _row(
              text: text,
              requirement: parser.parseRequirement(
                ingredient: text,
                selectedPortions: 1,
                basePortions: 1,
              ),
              items: items,
              localeCode: localeCode,
            ),
        ],
      );
}

FreeCookingRow _row({
  required String text,
  required TemplateIngredientRequirement? requirement,
  required List<InventoryItem> items,
  required String localeCode,
}) => FreeCookingRow(
  text: text,
  requirement: requirement,
  stockItem: bestIngredientStockMatch(
    text: text,
    requirement: requirement,
    items: items,
    localeCode: localeCode,
  ),
);
