import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Bottom sheet with one text field to type ingredient rows. It pops with the
/// typed text, or with `null` when the user closes it.
class FreeCookingTextSheet extends StatefulWidget {
  /// Creates the sheet.
  const new({super.key});

  /// Key of the text field.
  static const fieldKey = ValueKey<String>('free-cooking-text-field');

  /// Key of the add button.
  static const addKey = ValueKey<String>('free-cooking-text-add');

  /// Shows the sheet and returns the typed text.
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const FreeCookingTextSheet(),
    );
  }

  @override
  State<FreeCookingTextSheet> createState() => _FreeCookingTextSheetState();
}

class _FreeCookingTextSheetState extends State<FreeCookingTextSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    Navigator.of(context).pop(text);
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
              key: FreeCookingTextSheet.fieldKey,
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(hintText: l10n.freeCookingTypeHint),
              onSubmitted: (_) => _submit(),
            ),
          ),
          FilledButton(
            key: FreeCookingTextSheet.addKey,
            onPressed: _submit,
            child: Text(l10n.freeCookingAddAction),
          ),
        ],
      ),
    );
  }
}
