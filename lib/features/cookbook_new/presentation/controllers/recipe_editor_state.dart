import 'package:meta/meta.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_editor_draft.dart';

/// The open recipe editor: the draft and what is running on it.
@immutable
class RecipeEditorState {
  /// Creates the state of an editor that holds [draft].
  const new({
    required this.draft,
    this.isScanning = false,
    this.isSaving = false,
  });

  /// The new recipe, or the changes to a saved one.
  final RecipeEditorDraft draft;

  /// Whether a scan or paste is taking or reading its pages or text.
  final bool isScanning;

  /// Whether the recipe is being saved.
  final bool isSaving;

  /// Whether a scan or a save is running.
  bool get isBusy => isScanning || isSaving;

  /// Whether the draft can be saved and nothing is running.
  bool get canSave => !isBusy && draft.canSave;

  /// Copies the state.
  RecipeEditorState copyWith({
    RecipeEditorDraft? draft,
    bool? isScanning,
    bool? isSaving,
  }) => RecipeEditorState(
    draft: draft ?? this.draft,
    isScanning: isScanning ?? this.isScanning,
    isSaving: isSaving ?? this.isSaving,
  );
}
