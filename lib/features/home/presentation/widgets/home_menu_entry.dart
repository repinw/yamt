import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// One destination in the home side menu: an icon tile and a label.
class HomeMenuEntry extends StatelessWidget {
  /// Creates a menu entry.
  const new({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  /// Icon in the tile.
  final IconData icon;

  /// Name of the destination.
  final String label;

  /// Opens the destination.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AppInkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
        child: Row(
          children: [
            Container(
              width: AppSizes.homeMenuIconTile,
              height: AppSizes.homeMenuIconTile,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: AppSizes.homeMenuIcon),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
