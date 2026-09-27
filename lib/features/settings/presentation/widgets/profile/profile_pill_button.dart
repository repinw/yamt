import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// A round button that is dark when selected.
class ProfilePillButton extends StatelessWidget {
  /// Creates the button.
  const new({
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.icon,
    super.key,
  });

  /// Text on the button.
  final String label;

  /// Called on tap.
  final VoidCallback onTap;

  /// Whether the button shows the current choice.
  final bool isSelected;

  /// Icon before [label], or `null`.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = FoodLabelColors.of(context);
    final foreground = isSelected ? colors.paper : colors.ink;
    final radius = BorderRadius.circular(AppRadius.pill);
    final icon = this.icon;
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? colors.ink : colors.tile,
        borderRadius: radius,
        child: AppInkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: AppSpacing.xs,
              children: [
                if (icon != null) Icon(icon, color: foreground),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
