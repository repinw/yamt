import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Was kommt dazu?": one field to type what goes into the pot while
/// cooking. It pops with the text, or `null` when it is closed.
class KochmodusTypeSheet extends StatefulWidget {
  /// Creates the sheet.
  const new({super.key});

  /// Key of the field.
  static const fieldKey = ValueKey<String>('kochmodus-type-field');

  /// Key of "Hinzufügen".
  static const addKey = ValueKey<String>('kochmodus-type-add');

  /// Shows the sheet and returns the typed text.
  static Future<String?> show(BuildContext context) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        showDragHandle: true,
        builder: (_) => const KochmodusTypeSheet(),
      );

  @override
  State<KochmodusTypeSheet> createState() => _KochmodusTypeSheetState();
}

class _KochmodusTypeSheetState extends State<KochmodusTypeSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Text(
            l10n.kochmodusTypeTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: FoodLabelColors.of(context).ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          Row(
            spacing: AppSpacing.xs,
            children: [
              Expanded(
                child: TextField(
                  key: KochmodusTypeSheet.fieldKey,
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(hintText: l10n.cookingTypeHint),
                  onSubmitted: (_) => _submit(),
                  onTapUpOutside: (_) => FocusScope.of(context).unfocus(),
                ),
              ),
              FilledButton(
                key: KochmodusTypeSheet.addKey,
                onPressed: _submit,
                child: Text(l10n.cookingAddAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
