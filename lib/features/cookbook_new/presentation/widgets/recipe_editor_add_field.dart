import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// The field under a list of the recipe editor that adds a line, which stays
/// in view above the editor's bottom bar as the list grows.
class RecipeEditorAddField extends StatefulWidget {
  /// Creates the field that adds the text of [controller] with [onAdd].
  const new({
    required this.controller,
    required this.hint,
    required this.onAdd,
    required this.fieldKey,
    super.key,
  });

  /// The typed text, which "Rezept speichern" also adds while it is not
  /// submitted.
  final TextEditingController controller;

  /// The hint of the empty field, such as "+ Zutat".
  final String hint;

  /// Adds a typed line.
  final ValueChanged<String> onAdd;

  /// Key of the text field.
  final Key fieldKey;

  @override
  State<RecipeEditorAddField> createState() => _RecipeEditorAddFieldState();
}

class _RecipeEditorAddFieldState extends State<RecipeEditorAddField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  // Line after line: the field keeps the keyboard for the next one, and an
  // empty line closes it.
  void _submit() {
    final add = widget.controller;
    final text = add.text;
    if (text.trim().isEmpty) {
      _focus.unfocus();
      return;
    }
    widget.onAdd(text);
    add.clear();
    // The new line pushes the field down; once it is laid out, scroll just
    // enough to show the whole field again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: TextField(
        key: widget.fieldKey,
        controller: widget.controller,
        focusNode: _focus,
        onEditingComplete: _submit,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.sentences,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: FoodLabelColors.of(context).ink),
        decoration: InputDecoration(hintText: widget.hint),
      ),
    );
  }
}
