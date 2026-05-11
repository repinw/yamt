import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Shared weight input row for cookflow measurement fields.
class CookingFlowWeightInputRow extends StatelessWidget {
  /// Creates weight input row.
  const CookingFlowWeightInputRow({
    required this.controller,
    required this.unitLabel,
    super.key,
    this.hintText,
    this.onChanged,
  });

  /// Input controller.
  final TextEditingController controller;

  /// Unit shown on the right side.
  final String unitLabel;

  /// Optional hint text.
  final String? hintText;

  /// Optional change callback.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: colors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xxl,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          unitLabel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
