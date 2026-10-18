import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Bottom sheet that asks for the name of a new cookbook template. It pops
/// with the name, or with `null` when the user closes it.
class PreparedMealTemplateNameSheet extends StatefulWidget {
  /// Creates the sheet, filled with [initialName].
  const new({required this.initialName, super.key});

  /// Key of the name field.
  static const fieldKey = ValueKey<String>('template-name-field');

  /// Key of the save button.
  static const saveKey = ValueKey<String>('template-name-save');

  /// The name the field starts with.
  final String initialName;

  /// Shows the sheet and returns the name.
  static Future<String?> show(
    BuildContext context, {
    required String initialName,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => PreparedMealTemplateNameSheet(initialName: initialName),
    );
  }

  @override
  State<PreparedMealTemplateNameSheet> createState() =>
      _PreparedMealTemplateNameSheetState();
}

class _PreparedMealTemplateNameSheetState
    extends State<PreparedMealTemplateNameSheet> {
  late final _controller = TextEditingController(text: widget.initialName)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialName.length,
    );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Row(
        spacing: AppSpacing.xs,
        children: [
          Expanded(
            child: TextField(
              key: PreparedMealTemplateNameSheet.fieldKey,
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.preparedMealTemplateNameLabel,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => FilledButton(
              key: PreparedMealTemplateNameSheet.saveKey,
              onPressed: _controller.text.trim().isEmpty ? null : _submit,
              child: Text(l10n.preparedMealTemplateNameSave),
            ),
          ),
        ],
      ),
    );
  }
}
