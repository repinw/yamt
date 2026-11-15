import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_editor_draft.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_step_list.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The field of the line in edit: `key` keeps the field, its keyboard, and
/// its focus when the edit moves to another line; `onDone` ends the edit;
/// `onRemove` removes the line.
typedef RecipeEditorLineEdit = ({
  GlobalKey key,
  TextEditingController controller,
  FocusNode focusNode,
  VoidCallback onDone,
  VoidCallback onRemove,
});

/// One line of a list in the recipe editor: its text, which a tap turns into
/// a field in the same place, or that field with the button that removes
/// the line.
class RecipeEditorLineRow extends StatelessWidget {
  /// Creates the row of the line [text] at [index] of [section]; [edit] is
  /// the field while the line is in edit.
  const new({
    required this.section,
    required this.index,
    required this.text,
    required this.edit,
    required this.onTap,
    super.key,
  });

  /// Key of the field of the line in edit.
  static const fieldKey = ValueKey<String>('recipe-editor-line-field');

  /// Key of the button that removes the line in edit.
  static const removeKey = ValueKey<String>('recipe-editor-line-remove');

  /// The list the line belongs to.
  final RecipeEditorSection section;

  /// The line's place in its list.
  final int index;

  /// The line as it reads.
  final String text;

  /// The field while the line is in edit; `null` shows the text.
  final RecipeEditorLineEdit? edit;

  /// Puts the line in edit.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final style = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(color: colors.ink);
    final edit = this.edit;
    final content = edit == null
        ? Text(text, style: style)
        : Row(
            key: edit.key,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: fieldKey,
                  controller: edit.controller,
                  focusNode: edit.focusNode,
                  // A long step grows line by line; "done" ends the edit.
                  minLines: 1,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  onEditingComplete: edit.onDone,
                  // The remove button below the caret stays in view too.
                  scrollPadding: const EdgeInsets.all(AppSizes.minTapTarget),
                  style: style,
                  decoration: const InputDecoration.collapsed(hintText: null),
                ),
              ),
              IconButton(
                key: removeKey,
                tooltip: switch (section) {
                  .ingredients => l10n.recipeEditorRemoveLine,
                  .steps => l10n.recipeEditorRemoveStep,
                },
                onPressed: edit.onRemove,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          );
    final row = switch (section) {
      .ingredients => Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.rule)),
        ),
        child: content,
      ),
      .steps => RecipeStepRow(number: index + 1, child: content),
    };
    if (edit != null) {
      return row;
    }
    return Semantics(
      button: true,
      label: switch (section) {
        .ingredients => l10n.recipeEditorEditLine(text),
        .steps => l10n.recipeEditorEditStep(text),
      },
      excludeSemantics: true,
      onTap: onTap,
      child: AppInkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          child: row,
        ),
      ),
    );
  }
}
