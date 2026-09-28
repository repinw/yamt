import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// A row of an editable food label: the nutrient name and its number input
/// with the unit. A required input that is still empty gets an accent frame.
class EatLabelInputRow extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.fieldKey,
    required this.label,
    required this.unit,
    required this.controller,
    required this.focusNode,
    required this.bottom,
    required this.onChanged,
    required this.onSubmitted,
    this.accent,
    this.isPart = false,
    this.isRequired = false,
    super.key,
  });

  /// Key of the input.
  final Key fieldKey;

  /// Nutrient name.
  final String label;

  /// Unit shown in the input, such as "g".
  final String unit;

  /// Text of the input.
  final TextEditingController controller;

  /// Focus of the input.
  final FocusNode focusNode;

  /// Rule under the row.
  final BorderSide bottom;

  /// Called when the input changes.
  final ValueChanged<String> onChanged;

  /// Called when the input is confirmed on the keyboard.
  final VoidCallback onSubmitted;

  /// Diary macro color of the row, or null for a plain row.
  final Color? accent;

  /// Whether the row is a muted, indented line such as "of which sugars".
  final bool isPart;

  /// Whether the value must be filled in.
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final color = accent ?? (isPart ? colors.muted : colors.ink);
    // Names in the app font, values in mono.
    final base = (isPart ? textTheme.bodySmall : textTheme.bodyMedium)
        ?.copyWith(color: color);
    final isMissing = isRequired && controller.text.trim().isEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: bottom)),
      child: Padding(
        padding: EdgeInsets.only(
          left: isPart ? AppSpacing.md : 0,
          top: AppSpacing.xxs,
          bottom: AppSpacing.xxs,
        ),
        child: Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(
              child: Text(
                label,
                style: base?.copyWith(
                  fontWeight: isPart
                      ? FontWeight.w400
                      : accent == null
                      ? FontWeight.w500
                      : FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: AppFoodLabel.labelValueField,
              child: TextField(
                key: fieldKey,
                controller: controller,
                focusNode: focusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_decimalInputFormatter],
                textAlign: TextAlign.end,
                textInputAction: isRequired
                    ? TextInputAction.next
                    : TextInputAction.done,
                cursorColor: colors.ink,
                style: textTheme.bodySmall?.copyWith(
                  fontFamily: AppFonts.mono,
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                ),
                onChanged: onChanged,
                onSubmitted: (_) => onSubmitted(),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: AppLocalizations.of(context)!.eatPageAmountUnknown,
                  suffixText: unit,
                  suffixStyle: textTheme.labelSmall?.copyWith(
                    fontFamily: AppFonts.mono,
                    color: colors.muted,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: isMissing
                        ? BorderSide(
                            color: colors.accent,
                            width: AppFoodLabel.outline,
                          )
                        : BorderSide(color: colors.rule),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: colors.ink,
                      width: AppFoodLabel.outline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps digits and one decimal separator, so a value like "12,5" stays
/// parseable.
final TextInputFormatter _decimalInputFormatter =
    TextInputFormatter.withFunction((oldValue, newValue) {
      final sanitizedText = _sanitizeDecimalInput(newValue.text);
      if (sanitizedText == newValue.text) {
        return newValue;
      }
      return TextEditingValue(
        text: sanitizedText,
        selection: TextSelection.collapsed(offset: sanitizedText.length),
      );
    });

String _sanitizeDecimalInput(String rawText) {
  final buffer = StringBuffer();
  var hasSeparator = false;
  for (final char in rawText.split('')) {
    if ('0123456789'.contains(char)) {
      buffer.write(char);
    } else if (!hasSeparator && (char == ',' || char == '.')) {
      hasSeparator = true;
      buffer.write(char);
    }
  }
  return buffer.toString();
}
