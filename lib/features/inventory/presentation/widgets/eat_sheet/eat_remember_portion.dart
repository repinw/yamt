import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_text_link.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "+ Remember this amount as a portion": a link that turns into a name
/// field. Saving hands the name to [onSave].
class EatRememberPortion extends StatefulWidget {
  /// Creates the portion memo.
  const new({
    required this.amountLabel,
    required this.onSave,
    this.linkLabel,
    this.nameHint,
    super.key,
  });

  /// Key of the link.
  static const linkKey = Key('eat_page_remember_portion');

  /// Key of the name field.
  static const nameFieldKey = Key('eat_page_portion_name_field');

  /// Key of the save button.
  static const saveKey = Key('eat_page_portion_save');

  /// Entered amount, such as "60 g".
  final String amountLabel;

  /// Called with the typed name.
  final ValueChanged<String> onSave;

  /// Text of the link. Defaults to remembering the amount as a portion.
  final String? linkLabel;

  /// Example name in the empty field. Defaults to a portion name.
  final String? nameHint;

  @override
  State<EatRememberPortion> createState() => _EatRememberPortionState();
}

class _EatRememberPortionState extends State<EatRememberPortion> {
  final _name = TextEditingController();
  var _isOpen = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final mono = textTheme.bodyMedium?.copyWith(fontFamily: AppFonts.mono);

    if (!_isOpen) {
      return EatTextLink(
        buttonKey: EatRememberPortion.linkKey,
        label: widget.linkLabel ?? l10n.eatPageRememberPortion,
        onPressed: () => setState(() => _isOpen = true),
      );
    }

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: colors.ink, width: AppFoodLabel.outline),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: AppSpacing.sm,
      children: [
        Expanded(
          child: TextField(
            key: EatRememberPortion.nameFieldKey,
            controller: _name,
            autofocus: true,
            textInputAction: TextInputAction.done,
            style: mono?.copyWith(color: colors.ink),
            decoration: InputDecoration(
              labelText: l10n.eatPagePortionNameLabel(widget.amountLabel),
              hintText: widget.nameHint ?? l10n.eatPagePortionNameHint,
              filled: true,
              fillColor: colors.card,
              enabledBorder: border,
              focusedBorder: border,
            ),
            onSubmitted: (_) => _save(),
          ),
        ),
        FilledButton(
          key: EatRememberPortion.saveKey,
          onPressed: _save,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, AppSizes.minTapTarget),
            backgroundColor: colors.accent,
            foregroundColor: colors.onAccent,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: colors.ink, width: AppFoodLabel.outline),
            ),
          ),
          child: Text(
            l10n.eatPageSavePortion,
            style: mono?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onAccent,
            ),
          ),
        ),
      ],
    );
  }

  void _save() {
    widget.onSave(_name.text);
    _name.clear();
    setState(() => _isOpen = false);
  }
}
