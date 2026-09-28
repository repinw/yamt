import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// One line with a small number field, such as "1 piece = [50] g".
class EatInlineAmountField extends StatelessWidget {
  /// Creates the line.
  const new({
    required this.fieldKey,
    required this.label,
    required this.unitLabel,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.errorText,
    this.unitKey,
    this.onUnitPressed,
    this.isAmountMissing = false,
    this.isUnitMissing = false,
    super.key,
  });

  /// Key of the number field.
  final Key fieldKey;

  /// Text before the field.
  final String label;

  /// Unit after the field.
  final String unitLabel;

  /// Text controller of the field.
  final TextEditingController controller;

  /// Focus node of the field.
  final FocusNode focusNode;

  /// Called when the number is typed.
  final ValueChanged<String> onChanged;

  /// Error under the field.
  final String? errorText;

  /// Key of the unit button.
  final Key? unitKey;

  /// Makes the unit tappable, for example to switch between g and ml.
  final VoidCallback? onUnitPressed;

  /// Frames the number field in the accent color while a required amount is
  /// still empty.
  final bool isAmountMissing;

  /// Frames the unit button in the accent color while a required unit is
  /// still unset.
  final bool isUnitMissing;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: colors.ink);
    final onUnit = onUnitPressed;
    const textPadding = EdgeInsets.only(top: AppSpacing.sm);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Flexible(
          child: Padding(
            padding: textPadding,
            child: Text(label, style: style),
          ),
        ),
        SizedBox(
          width: AppFoodLabel.inlineAmountField,
          child: TextField(
            key: fieldKey,
            controller: controller,
            focusNode: focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            cursorColor: colors.ink,
            style: style?.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              isDense: true,
              errorText: errorText,
              errorMaxLines: 2,
              contentPadding: isAmountMissing
                  ? const EdgeInsets.all(AppSpacing.sm)
                  : null,
              enabledBorder: isAmountMissing
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                        color: colors.accent,
                        width: AppFoodLabel.outline,
                      ),
                    )
                  : UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: colors.muted,
                        width: AppFoodLabel.outline,
                      ),
                    ),
              focusedBorder: isAmountMissing
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                        color: colors.ink,
                        width: AppFoodLabel.outline,
                      ),
                    )
                  : UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: colors.ink,
                        width: AppFoodLabel.outline,
                      ),
                    ),
            ),
            onChanged: onChanged,
            onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
        ),
        if (onUnit == null)
          Padding(
            padding: textPadding,
            child: Text(unitLabel, style: style),
          )
        else
          TextButton(
            key: unitKey,
            onPressed: onUnit,
            style: TextButton.styleFrom(
              foregroundColor: colors.ink,
              shape: const RoundedRectangleBorder(),
              side: isUnitMissing
                  ? BorderSide(
                      color: colors.accent,
                      width: AppFoodLabel.outline,
                    )
                  : null,
            ),
            child: Text(
              unitLabel,
              style: style?.copyWith(decoration: TextDecoration.underline),
            ),
          ),
      ],
    );
  }
}
