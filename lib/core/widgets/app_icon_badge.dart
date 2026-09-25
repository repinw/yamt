import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';

/// Small primary icon on a tinted rounded background.
class AppIconBadge extends StatelessWidget {
  /// Creates an icon badge.
  const new({required this.icon, super.key});

  /// Icon to show.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(
          alpha: AppOpacities.iconBadgeBackground,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(icon, color: colors.primary, size: AppSizes.iconBadgeIcon),
      ),
    );
  }
}
