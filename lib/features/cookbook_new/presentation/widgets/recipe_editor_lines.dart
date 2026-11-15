import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_editor_draft.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_editor_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_section_title.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_add_field.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_line_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Where a line stands: its list and its place in it.
typedef _LinePlace = (RecipeEditorSection section, int index);

/// The ingredient lines and the steps of the recipe editor: each list with
/// its title, its lines, and the field that adds one.
///
/// A tap on a line edits it in its place, one line at a time. Leaving the
/// field keeps the text: "done", a tap on another line or into a field,
/// or any other loss of focus. An empty text removes the line, like its
/// remove button, and the snack bar can bring it back.
class RecipeEditorLines extends ConsumerStatefulWidget {
  /// Creates the lists of [draft] in the editor [editorId] of [recipeId].
  const new({
    required this.editorId,
    required this.recipeId,
    required this.draft,
    required this.addControllers,
    required this.onEditPendingChanged,
    super.key,
  });

  /// Key of the field that adds a line to [section].
  static ValueKey<String> addKey(RecipeEditorSection section) =>
      ValueKey<String>('recipe-editor-add-${section.name}');

  /// Key of the line at [index] of [section].
  static ValueKey<String> lineKey(RecipeEditorSection section, int index) =>
      ValueKey<String>('recipe-editor-line-${section.name}-$index');

  /// Key of the snack bar after a line was removed.
  static const removedKey = ValueKey<String>('recipe-editor-line-removed');

  /// The id of the open editor (see [RecipeEditorController]).
  final String editorId;

  /// The editor's recipe id; `null` for a new recipe.
  final String? recipeId;

  /// The draft whose lines show.
  final RecipeEditorDraft draft;

  /// The text of the field that adds a line, by list, which "Rezept
  /// speichern" also adds while it is not submitted.
  final Map<RecipeEditorSection, TextEditingController> addControllers;

  /// Called with whether the line in edit holds a text it does not have yet.
  final ValueChanged<bool> onEditPendingChanged;

  @override
  ConsumerState<RecipeEditorLines> createState() => _RecipeEditorLinesState();
}

class _RecipeEditorLinesState extends ConsumerState<RecipeEditorLines> {
  final _edit = TextEditingController();
  final _editFocus = FocusNode();

  /// Moves with the edit from line to line, so the keyboard stays up.
  final GlobalKey _editRow = GlobalKey();

  /// The line in edit.
  _LinePlace? _editing;
  bool _editPending = false;

  RecipeEditorController get _controller => ref.read(
    recipeEditorControllerProvider(widget.editorId, widget.recipeId).notifier,
  );

  @override
  void initState() {
    super.initState();
    _edit.addListener(_reportEdit);
    _editFocus.addListener(_leaveOnFocusLoss);
  }

  @override
  void dispose() {
    _editFocus
      ..removeListener(_leaveOnFocusLoss)
      ..dispose();
    _edit.dispose();
    super.dispose();
  }

  RecipeEditorLine? _lineAt(_LinePlace place) => ref
      .read(recipeEditorControllerProvider(widget.editorId, widget.recipeId))
      .value
      ?.draft
      .linesOf(place.$1)
      .elementAtOrNull(place.$2);

  void _leaveOnFocusLoss() {
    if (!_editFocus.hasFocus) _commit();
  }

  void _reportEdit() {
    final editing = _editing;
    final pending =
        editing != null && _edit.text.trim() != _lineAt(editing)?.text;
    if (pending != _editPending) {
      _editPending = pending;
      widget.onEditPendingChanged(pending);
    }
  }

  /// Ends the edit and returns where it was.
  _LinePlace? _end() {
    final editing = _editing;
    if (editing == null || !mounted) return null;
    setState(() => _editing = null);
    _reportEdit();
    return editing;
  }

  /// Ends the edit: a changed text goes to the line, an empty one removes
  /// it. Returns whether the line was removed.
  bool _commit() {
    final editing = _end();
    final line = editing == null ? null : _lineAt(editing);
    if (editing == null || line == null) return false;
    final text = _edit.text;
    if (text.trim() == line.text) return false;
    if (text.trim().isEmpty) {
      _remove(editing);
      return true;
    }
    _controller.setLine(editing.$1, editing.$2, text);
    return false;
  }

  void _start(RecipeEditorSection section, int index) {
    final before = _editing;
    // The line before in the same list may be gone, so this one moved up.
    final place = _commit() && before?.$1 == section && before!.$2 < index
        ? (section, index - 1)
        : (section, index);
    final text = _lineAt(place)?.text;
    if (text == null) return;
    setState(() => _editing = place);
    _edit.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final row = _editRow.currentContext;
      if (!mounted || _editing != place || row == null) return;
      _editFocus.requestFocus();
      Scrollable.ensureVisible(
        row,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  void _remove(_LinePlace place) {
    final line = _lineAt(place);
    if (line == null) return;
    final (section, index) = place;
    final l10n = AppLocalizations.of(context)!;
    _controller.removeLine(section, index);
    ScaffoldMessenger.of(context).showAppSnackBar(
      switch (section) {
        .ingredients => l10n.recipeEditorLineRemoved,
        .steps => l10n.recipeEditorStepRemoved,
      },
      key: RecipeEditorLines.removedKey,
      onUndo: () async {
        if (!mounted) return false;
        _controller.restoreLine(section, index, line);
        // The line in edit moves down with the lines after the restored one.
        final editing = _editing;
        if (editing != null && editing.$1 == section && editing.$2 >= index) {
          setState(() => _editing = (section, editing.$2 + 1));
        }
        return true;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in RecipeEditorSection.values) ...[
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xl),
            child: CookbookSectionTitle(
              title: switch (section) {
                .ingredients => l10n.recipeEditorIngredientsTitle(
                  widget.draft.ingredients.length,
                ),
                .steps => l10n.recipeEditorStepsTitle(
                  widget.draft.steps.length,
                ),
              },
            ),
          ),
          for (final (index, line) in widget.draft.linesOf(section).indexed)
            RecipeEditorLineRow(
              key: RecipeEditorLines.lineKey(section, index),
              section: section,
              index: index,
              text: line.text,
              edit: _editing == (section, index)
                  ? (
                      key: _editRow,
                      controller: _edit,
                      focusNode: _editFocus,
                      onDone: _editFocus.unfocus,
                      onRemove: () {
                        if (_end() case final place?) _remove(place);
                      },
                    )
                  : null,
              onTap: () => _start(section, index),
            ),
          RecipeEditorAddField(
            fieldKey: RecipeEditorLines.addKey(section),
            controller: widget.addControllers[section]!,
            hint: switch (section) {
              .ingredients => l10n.recipeEditorAddIngredient,
              .steps => l10n.recipeEditorAddStep,
            },
            onAdd: (text) => _controller.addLine(section, text),
          ),
        ],
      ],
    );
  }
}
