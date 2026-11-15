import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_editor_draft.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_editor_state.dart';

void main() {
  final ready = const RecipeEditorDraft(name: 'Suppe')
      .withAddedLines(.ingredients, ['Salz']);

  test('starts with nothing running', () {
    final editor = RecipeEditorState(draft: ready);

    expect(editor.isScanning, isFalse);
    expect(editor.isSaving, isFalse);
    expect(editor.isBusy, isFalse);
    expect(editor.canSave, isTrue);
  });

  test('a scan or a save makes it busy and stops saving', () {
    final editor = RecipeEditorState(draft: ready);

    final scanning = editor.copyWith(isScanning: true);
    expect(scanning.isBusy, isTrue);
    expect(scanning.canSave, isFalse);

    final saving = editor.copyWith(isSaving: true);
    expect(saving.isBusy, isTrue);
    expect(saving.canSave, isFalse);
  });

  test('canSave follows the rule of the draft', () {
    const editor = RecipeEditorState(draft: RecipeEditorDraft(name: 'Suppe'));

    expect(editor.canSave, isFalse);
    expect(editor.copyWith(draft: ready).canSave, isTrue);
  });

  test('copyWith keeps what it does not change', () {
    final saving = RecipeEditorState(draft: ready, isSaving: true);

    final copy = saving.copyWith(isScanning: true);

    expect(copy.draft, ready);
    expect(copy.isSaving, isTrue);
    expect(copy.isScanning, isTrue);
  });
}
