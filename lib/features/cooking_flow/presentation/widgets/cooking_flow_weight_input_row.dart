import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';

/// Shared weight input row for cookflow measurement fields: a large number
/// on a soft tile with the unit after it.
class CookingFlowWeightInputRow extends StatelessWidget {
  /// Creates weight input row.
  const new({
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
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide.none,
    );

    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            cursorColor: colors.ink,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: context.graphitDisplayStyle(
                textTheme.headlineSmall,
                color: colors.muted,
              ),
              filled: true,
              fillColor: colors.tile,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border,
            ),
            style: context.graphitDisplayStyle(textTheme.headlineSmall),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          unitLabel,
          style: textTheme.titleMedium?.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
