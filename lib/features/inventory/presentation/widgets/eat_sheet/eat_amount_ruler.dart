import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_ruler.dart';

/// Amount input of the eat page: a typeable number with its unit and a
/// ruler slider with marks for saved portions.
class EatAmountRuler extends StatelessWidget {
  /// Creates the amount input.
  const new({
    required this.controller,
    required this.focusNode,
    required this.unitLabel,
    required this.value,
    required this.max,
    required this.step,
    required this.marks,
    required this.allowFractionalInput,
    required this.onTextChanged,
    required this.onSliderChanged,
    this.hint,
    this.errorText,
    this.onUnitPressed,
    super.key,
  });

  /// Key of the amount field.
  static const fieldKey = Key('eat_page_amount_field');

  /// Key of the unit button.
  static const unitKey = Key('eat_page_amount_unit');

  /// Text controller of the amount field.
  final TextEditingController controller;

  /// Focus node of the amount field.
  final FocusNode focusNode;

  /// Unit after the number.
  final String unitLabel;

  /// Slider position.
  final double value;

  /// Slider maximum.
  final double max;

  /// Step the slider snaps to.
  final double step;

  /// Marks under the ruler.
  final List<EatRulerMark> marks;

  /// Whether the keyboard offers a decimal separator.
  final bool allowFractionalInput;

  /// Called when the number is typed.
  final ValueChanged<String> onTextChanged;

  /// Called when the slider moves.
  final ValueChanged<double> onSliderChanged;

  /// Short note at the end of the number row, such as "= 2 × slice".
  final String? hint;

  /// Error under the number.
  final String? errorText;

  /// Makes the unit tappable, for example to switch between units.
  final VoidCallback? onUnitPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final hintText = hint;
    final error = errorText;
    final unitStyle = textTheme.bodyMedium?.copyWith(
      fontFamily: AppFonts.mono,
      color: colors.ink,
    );
    final onUnit = onUnitPressed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Row(
          children: [
            SizedBox(
              width: AppFoodLabel.amountField,
              child: TextField(
                key: fieldKey,
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: allowFractionalInput,
                ),
                textInputAction: TextInputAction.done,
                cursorColor: colors.ink,
                style: textTheme.displaySmall?.copyWith(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: colors.muted,
                      width: AppFoodLabel.outline,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: colors.ink,
                      width: AppFoodLabel.outline,
                    ),
                  ),
                ),
                onChanged: onTextChanged,
                onSubmitted: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (onUnit == null)
              Text(unitLabel, style: unitStyle)
            else
              TextButton(
                key: unitKey,
                onPressed: onUnit,
                style: TextButton.styleFrom(foregroundColor: colors.ink),
                child: Text(
                  unitLabel,
                  style: unitStyle?.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            const Spacer(),
            if (hintText != null)
              Flexible(
                child: Text(
                  hintText,
                  textAlign: TextAlign.end,
                  style: textTheme.labelMedium?.copyWith(
                    fontFamily: AppFonts.mono,
                    fontWeight: FontWeight.w700,
                    color: colors.accentText,
                  ),
                ),
              ),
          ],
        ),
        if (error != null)
          Text(
            error,
            style: textTheme.bodySmall?.copyWith(
              fontFamily: AppFonts.mono,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        EatRuler(
          value: value,
          max: max,
          step: step,
          marks: marks,
          onChanged: onSliderChanged,
        ),
      ],
    );
  }
}
