import 'dart:async';
import 'dart:developer' show log;

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cookbook_new/application/recipe_estimate_service.dart';
import 'package:yamt/features/cookbook_new/data/ingredient_list_scan_repository.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_editor_draft.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
import 'package:yamt/features/cookbook_new/domain/scanned_ingredient_list.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_editor_state.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_template_writer.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';

part 'recipe_editor_controller.g.dart';

/// What became of a pasted or shared text.
enum RecipePasteResult {
  /// What the text holds is in the draft.
  read,

  /// The text holds no line.
  empty,

  /// The text is longer than [recipeTextCharacterLimit].
  tooLong,
}

/// Holds the state of the open editor [editorId]: a new recipe when
/// [recipeId] is `null`, else the saved recipe [recipeId]. The state is
/// `null` when that recipe is gone.
///
/// Every editor of a new recipe has its own [editorId], so two of them never
/// share a draft; the editor of a saved recipe uses the recipe's id.
@riverpod
class RecipeEditorController extends _$RecipeEditorController {
  static const _uuid = Uuid();

  @override
  FutureOr<RecipeEditorState?> build(String editorId, String? recipeId) {
    // A new recipe starts at once, so the page can scan or paste right away.
    if (recipeId == null) {
      return const RecipeEditorState(draft: RecipeEditorDraft());
    }
    // Read once: a later change of the saved recipe must not reset the
    // cook's edits.
    final templates = ref.watch(preparedMealTemplateRepositoryProvider);
    return templates.readAll().then((all) {
      final recipe = all.firstWhereOrNull((t) => t.id == recipeId);
      return recipe == null
          ? null
          : RecipeEditorState(draft: RecipeEditorDraft.fromRecipe(recipe));
    });
  }

  /// Whether the device can take the photo with its camera.
  bool canUseCamera() =>
      ref.read(preparedMealImagePickerProvider).supportsCamera;

  /// Sets the typed name.
  void setName(String name) => _change((draft) => draft.copyWith(name: name));

  /// Keeps [recipeUrl] as the source of the new recipe.
  void setRecipeUrl(String recipeUrl) =>
      _change((draft) => draft.copyWith(recipeUrl: recipeUrl));

  /// Sets the portion count.
  void setPortions(int portions) =>
      _change((draft) => draft.copyWith(portions: portions));

  /// Adds [text] as a new line after the lines of [section].
  void addLine(RecipeEditorSection section, String text) =>
      _change((draft) => draft.withAddedLines(section, [text]));

  /// Sets the line at [index] of [section] to [text].
  void setLine(RecipeEditorSection section, int index, String text) =>
      _change((draft) => draft.withLine(section, index, text));

  /// Removes the line at [index] of [section].
  void removeLine(RecipeEditorSection section, int index) =>
      _change((draft) => draft.withoutLine(section, index));

  /// Puts the removed [line] back at [index] of [section], with its weight.
  void restoreLine(
    RecipeEditorSection section,
    int index,
    RecipeEditorLine line,
  ) => _change((draft) => draft.withRestoredLine(section, index, line));

  /// Reads the pasted or shared [text] with the AI and adds what it holds
  /// to the draft like a scan (see [RecipeEditorDraft.withScan]). Without
  /// an answer, such as offline, the text is read by rules instead (see
  /// [RecipeEditorDraft.withPastedText]). A text that holds no line or is
  /// longer than [recipeTextCharacterLimit] goes to neither and leaves the
  /// draft as it is.
  Future<RecipePasteResult> paste(String text) async {
    if (text.trim().isEmpty) {
      return RecipePasteResult.empty;
    }
    if (text.length > recipeTextCharacterLimit) {
      return RecipePasteResult.tooLong;
    }
    _setProgress(isScanning: true);
    ScannedIngredientList? read;
    try {
      final answer = await ref
          .read(ingredientListScanRepositoryProvider)
          .loadRecipeText(text);
      if (answer.ingredients.isNotEmpty || answer.steps.isNotEmpty) {
        read = answer;
      }
    } on Object catch (error, stackTrace) {
      log(
        'Reading the pasted recipe failed; the rules read it.',
        name: 'RecipeEditorController',
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (ref.mounted) {
      _change(
        (draft) => switch (read) {
          final read? => draft.withScan(read),
          null => draft.withPastedText(text),
        },
      );
      _setProgress(isScanning: false);
    }
    return RecipePasteResult.read;
  }

  /// Takes up to three pages and adds what they show to the draft (see
  /// [RecipeEditorDraft.withScan]). Returns `false` when taking or reading
  /// the pages failed or they show no line; a canceled scan changes nothing.
  Future<bool> scan() async {
    final repository = ref.read(ingredientListScanRepositoryProvider);
    _setProgress(isScanning: true);
    try {
      final pages = await repository.loadPagePhotos();
      if (pages == null || !ref.mounted) {
        return true;
      }
      final scanned = await repository.loadIngredientList(pages);
      if (scanned.ingredients.isEmpty && scanned.steps.isEmpty) {
        return false;
      }
      if (ref.mounted) {
        _change((draft) => draft.withScan(scanned));
      }
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Reading the scanned ingredient list failed.',
        name: 'RecipeEditorController',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      if (ref.mounted) {
        _setProgress(isScanning: false);
      }
    }
  }

  /// Takes the photo with the camera, or picks it from the files without
  /// [camera]. Returns `false` when that failed; a canceled pick changes
  /// nothing.
  Future<bool> pickPhoto({required bool camera}) async {
    final picker = ref.read(preparedMealImagePickerProvider);
    try {
      final bytes = await (camera
          ? picker.pickFromCamera()
          : picker.pickFromFile());
      if (bytes != null && ref.mounted) {
        _change((draft) => draft.copyWith(photo: bytes));
      }
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Picking the recipe photo failed.',
        name: 'RecipeEditorController',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Saves the draft: a new recipe, or the changes onto the saved one as it
  /// is now, with everything the editor does not show, then estimates the
  /// saved recipe in the background. Returns the recipe's id, or `null`
  /// when the draft cannot be saved or saving failed.
  Future<String?> save() async {
    final editor = state.value;
    if (editor == null || !editor.canSave) {
      return null;
    }
    final draft = editor.draft;
    final link = ref.keepAlive();
    _setProgress(isSaving: true);
    try {
      final now = ref.read(clockProvider)();
      final writer = ref.read(preparedMealTemplateWriterProvider);
      final templates = ref.read(preparedMealTemplateRepositoryProvider);
      final estimates = ref.read(recipeEstimateServiceProvider);
      final imageAssetId = await _savePhoto(draft);
      final original = draft.original;
      if (original == null) {
        final template = await writer.addFromMeal(
          draft.newRecipe(now: now, imageAssetId: imageAssetId),
        );
        estimates.estimateInBackground(template.id);
        // Stays saving: the page leaves for the recipe.
        return template.id;
      }
      // The latest recipe: an estimate or a cook's choices may have arrived
      // since the editor opened.
      final latest = (await templates.readAll()).firstWhereOrNull(
        (t) => t.id == original.id,
      );
      if (latest == null) {
        throw StateError('The recipe is gone.');
      }
      final saved = await templates.save(
        draft.editedRecipe(latest, now: now, imageAssetId: imageAssetId),
      );
      if (!saved) {
        throw StateError('The recipe was not saved.');
      }
      // The estimate skips a recipe whose lines and portions it still fits.
      estimates.estimateInBackground(original.id);
      return original.id;
    } on Object catch (error, stackTrace) {
      log(
        'Saving the recipe failed.',
        name: 'RecipeEditorController',
        error: error,
        stackTrace: stackTrace,
      );
      if (ref.mounted) {
        _setProgress(isSaving: false);
      }
      return null;
    } finally {
      link.close();
    }
  }

  /// Stores the picked photo and returns its asset id, or `null` without
  /// one.
  Future<String?> _savePhoto(RecipeEditorDraft draft) async {
    final photo = draft.photo;
    if (photo == null) {
      return null;
    }
    final imageAssetId = _uuid.v4();
    final imageRef = localImageAssetRef(imageAssetId);
    await ref
        .read(localImageStoreProvider)
        .saveBytes(imageRef: imageRef, bytes: photo);
    if (ref.mounted) {
      ref.invalidate(localImageBytesProvider(imageRef));
    }
    return imageAssetId;
  }

  void _change(RecipeEditorDraft Function(RecipeEditorDraft draft) change) {
    final editor = state.value;
    if (editor != null) {
      state = AsyncData(editor.copyWith(draft: change(editor.draft)));
    }
  }

  void _setProgress({bool? isScanning, bool? isSaving}) {
    final editor = state.value;
    if (editor != null) {
      state = AsyncData(
        editor.copyWith(isScanning: isScanning, isSaving: isSaving),
      );
    }
  }
}
