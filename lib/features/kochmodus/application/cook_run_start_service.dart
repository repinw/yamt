import 'dart:math' show max;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/preferences/install_id.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/inventory/application/template_ingredient_unit_mapper.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';
import 'package:yamt/features/kochmodus/application/cook_line_parse.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_not_counted.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

part 'cook_run_start_service.g.dart';

/// The start of a cooking for the signed-in member on this device.
@riverpod
CookRunStartService cookRunStartService(Ref ref) => CookRunStartService(
  auth: ref.watch(firebaseAuthProvider),
  preferences: ref.watch(appPreferencesProvider),
  clock: ref.watch(clockProvider),
  parser: ref.watch(templateIngredientParserProvider),
);

/// The id of the run of the recipe [recipeId]: the household has one run
/// per recipe.
String cookRecipeRunId(String recipeId) => 'recipe-$recipeId';

/// [run] with the new [timer], unless a timer of its name still counts at
/// [now], as after a double tap on a step's time: then [run] stays as it is
/// and the timer bar shows the timer that runs. Once that one rang or was
/// stopped, a new one starts.
CookRun cookRunWithTimer(
  CookRun run,
  CookTimer timer, {
  required DateTime now,
}) =>
    run.timers.any(
      (other) => other.label == timer.label && other.endsAt.isAfter(now),
    )
    ? run
    : run.addTimer(timer);

/// Makes the draft of a cook run. The draft is not stored: a recipe's is
/// created with its first change while assigning, free cooking's once the
/// cook chose the pots.
class CookRunStartService {
  /// Creates the service.
  const new({
    required this._auth,
    required this._preferences,
    required this._clock,
    required this._parser,
  });

  final FirebaseAuth _auth;
  final AppPreferences _preferences;
  final DateTime Function() _clock;
  final TemplateIngredientParser _parser;

  /// The draft of cooking the Kochbuch recipe [template] for [portions]
  /// portions, the recipe's own when `null`, on "Zuweisen". Its id is
  /// `recipe-<templateId>`, so the household has one run per recipe. Every
  /// recipe line keeps its index as id (`line-<index>`); a line the recipe
  /// leaves out stays, ignored, and so does a line that does not count in the
  /// nutrition, such as a pinch of salt ([cookLineNotCounted]). The recipe's
  /// rough weight of a line ([PreparedMeal.recipeLineWeights]) becomes the
  /// need of a line whose text names no amount ([CookRunLine.roughWeight]), and
  /// the piece weight of a line in pieces without the recipe's own. Throws a
  /// [StateError] while signed out and an [ArgumentError] for [portions] below
  /// 1.
  CookRun recipeDraft(PreparedMeal template, {int? portions}) {
    final basePortions = max(1, template.totalPortions);
    final ignored = template.ignoredRecipeIngredients.toSet();
    TemplateIngredientRequirement? read(String text) => readCookLineText(
      _parser,
      text,
      selectedPortions: basePortions,
      basePortions: basePortions,
    );
    return _draft(
      id: cookRecipeRunId(template.id),
      kind: CookRunKind.recipe,
      step: CookRunStep.assign,
      recipeId: template.id,
      name: template.name,
      imageAssetId: template.imageAssetId,
      imageUrl: template.imageUrl,
      basePortions: basePortions,
      portions: portions ?? basePortions,
      steps: template.recipeInstructions,
      lines: [
        for (final (index, text) in template.recipeIngredients.indexed)
          CookRunLine(
            id: 'line-$index',
            text: text,
            origin: CookLineOrigin.recipe,
            conversion:
                _conversionOf(
                  template.recipeIngredientAmountConversions[text],
                ) ??
                _pieceWeightOf(read(text), template.recipeLineWeights[text]),
            amount: null,
            amountPortions: null,
            amountUnit: null,
            settlement: ignored.contains(text) || cookLineNotCounted(text)
                ? const LineIgnored()
                : const LineOpen(),
            weighed: null,
            potId: null,
            addedItemIds: const [],
            roughWeight: read(text) == null
                ? _roughWeightOf(template.recipeLineWeights[text])
                : null,
          ),
      ],
    );
  }

  /// The draft of free cooking with the id [runId], without lines, on
  /// "Töpfe". Throws a [StateError] while signed out.
  CookRun freeDraft(String runId) => _draft(
    id: runId,
    kind: CookRunKind.free,
    step: CookRunStep.pots,
    recipeId: null,
    name: '',
    imageAssetId: null,
    imageUrl: null,
    basePortions: 1,
    portions: 1,
    steps: const [],
    lines: const [],
  );

  /// The id of this device, which the timers it starts carry, so only this
  /// device rings them. Throws when a new id cannot be saved.
  Future<String> deviceId() => readInstallId(_preferences);

  /// A new timer [label] of this device that rings after [duration] from
  /// now. Throws when the device id cannot be saved.
  Future<CookTimer> timer(String label, Duration duration) async {
    final endsAt = _clock().add(duration);
    return CookTimer(
      id: const Uuid().v4(),
      label: label,
      endsAt: endsAt,
      deviceId: await deviceId(),
    );
  }

  CookRun _draft({
    required String id,
    required CookRunKind kind,
    required CookRunStep step,
    required String? recipeId,
    required String name,
    required String? imageAssetId,
    required String? imageUrl,
    required int basePortions,
    required int portions,
    required List<String> steps,
    required List<CookRunLine> lines,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Cooking needs a signed-in member.');
    }
    return CookRun(
      id: id,
      kind: kind,
      step: step,
      recipeId: recipeId,
      name: name,
      imageAssetId: imageAssetId,
      imageUrl: imageUrl,
      basePortions: basePortions,
      portions: portions,
      steps: steps,
      startedBy: user.uid,
      // The view words an empty name.
      startedByName: _nonBlank(user.displayName) ?? _nonBlank(user.email) ?? '',
      startedAt: _clock(),
      lines: lines,
      pots: null,
      withGuide: steps.isNotEmpty,
      guideStep: 0,
      timers: const [],
      meals: const [],
      toCookbook: false,
      droppedItemIds: const [],
    );
  }
}

CookLineConversion? _conversionOf(RecipeIngredientAmountConversion? source) =>
    source == null
    ? null
    : CookLineConversion(
        amountPerPiece: source.amountPerPiece,
        unit: source.unit.toTemplateIngredientUnit(),
      );

// One piece of a line in pieces ("3 Eier") from its rough [weight].
CookLineConversion? _pieceWeightOf(
  TemplateIngredientRequirement? read,
  RecipeLineWeight? weight,
) {
  final count = read?.exactQuantity;
  if (read?.unit != TemplateIngredientUnit.piece ||
      count == null ||
      count <= 0 ||
      weight == null) {
    return null;
  }
  return CookLineConversion(
    amountPerPiece: max(1, (weight.amount / count).round()),
    unit: _unitOf(weight),
  );
}

CookRoughWeight? _roughWeightOf(RecipeLineWeight? weight) => weight == null
    ? null
    : CookRoughWeight(amount: weight.amount, unit: _unitOf(weight));

TemplateIngredientUnit _unitOf(RecipeLineWeight weight) =>
    switch (weight.unit) {
      RecipeLineWeightUnit.gram => TemplateIngredientUnit.gram,
      RecipeLineWeightUnit.milliliter => TemplateIngredientUnit.milliliter,
    };

String? _nonBlank(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
