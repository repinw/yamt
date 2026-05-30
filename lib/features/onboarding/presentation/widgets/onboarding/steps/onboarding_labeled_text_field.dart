import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Shared labeled input for calorie-goal onboarding numeric fields.
class OnboardingLabeledTextField extends StatelessWidget {
  /// Creates a labeled onboarding text field.
  const OnboardingLabeledTextField({
    required this.label,
    required this.hintText,
    required this.initialValue,
    required this.keyboardType,
    required this.errorText,
    required this.onChanged,
    super.key,
  });

  /// Field label.
  final String label;

  /// Field hint text.
  final String hintText;

  /// Initial text value.
  final String initialValue;

  /// Keyboard type.
  final TextInputType keyboardType;

  /// Validation error text.
  final String? errorText;

  /// Called when text changes.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          onFieldSubmitted: (_) => _dismissKeyboard(context),
          onTapOutside: (_) => _dismissKeyboard(context),
          keyboardType: keyboardType,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            filled: true,
            fillColor: Theme.of(context).canvasColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.surfaceContainerHigh,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.surfaceContainer,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}
