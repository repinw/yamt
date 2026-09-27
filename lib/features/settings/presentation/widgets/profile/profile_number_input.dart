import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// A big number field with its unit, such as the height in cm.
class ProfileNumberInput extends StatelessWidget {
  /// Creates the number field.
  const new({
    required this.controller,
    required this.unit,
    required this.onChanged,
    this.allowDecimals = false,
    this.errorText,
    super.key,
  });

  /// Holds the typed text.
  final TextEditingController controller;

  /// Unit after the number.
  final String unit;

  /// Called with the text after every change.
  final ValueChanged<String> onChanged;

  /// Whether the number may have decimals.
  final bool allowDecimals;

  /// Tells why the number is not accepted, or `null`.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = FoodLabelColors.of(context);
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimals),
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: label.tile,
        suffixText: unit,
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
