import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_import/shopping_import_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Asks for a new name of the product called [name]. Returns the trimmed
/// name, or null when the user cancels or leaves it empty.
Future<String?> showShoppingImportRenameDialog(
  BuildContext context,
  String name,
) => showDialog<String>(
  context: context,
  builder: (_) => _RenameDialog(name: name),
);

class _RenameDialog extends StatefulWidget {
  const new({required this.name});

  final String name;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _field = TextEditingController(text: widget.name);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _save() {
    final name = _field.text.trim();
    Navigator.of(context).pop(name.isEmpty ? null : name);
  }

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.shoppingImportRenameTitle),
      content: TextField(
        key: ShoppingImportKeys.renameField,
        controller: _field,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        TextButton(
          key: ShoppingImportKeys.renameSave,
          onPressed: _save,
          child: Text(material.saveButtonLabel),
        ),
      ],
    );
  }
}
