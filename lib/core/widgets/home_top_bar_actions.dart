import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';

/// Circular icon-button styled actions shown at the end of a home top bar.
class HomeTopBarActions extends StatelessWidget {
  /// Creates home top bar actions.
  const new({required this.actions, super.key});

  /// The action widgets, usually icon buttons.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: colors.surfaceContainerHigh,
          disabledBackgroundColor: colors.surfaceContainerHigh.withValues(
            alpha: AppOpacities.homeTopBarDisabledBackground,
          ),
          disabledForegroundColor: colors.onSurfaceVariant.withValues(
            alpha: AppOpacities.homeTopBarDisabledForeground,
          ),
          fixedSize: const Size.square(AppSizes.homeTopBarIconButton),
          foregroundColor: colors.onSurfaceVariant,
          minimumSize: const Size.square(AppSizes.homeTopBarIconButton),
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < actions.length; index += 1) ...[
            if (index > 0) const SizedBox(width: AppSpacing.xs),
            actions[index],
          ],
        ],
      ),
    );
  }
}
