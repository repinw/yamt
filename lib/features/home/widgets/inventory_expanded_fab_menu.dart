import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Animated expanded inventory FAB menu.
class InventoryExpandedFabMenu extends StatelessWidget {
  /// Creates expanded inventory FAB menu.
  const InventoryExpandedFabMenu({
    required this.actions,
    required this.closeButton,
    super.key,
  });

  /// Action buttons shown above the close button.
  final List<Widget> actions;

  /// Button used to close the expanded menu.
  final Widget closeButton;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, progress, child) {
          return Opacity(
            opacity: progress,
            child: Transform.scale(
              alignment: Alignment.bottomRight,
              scale: 0.94 + (progress * 0.06),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final action in actions) ...[
              action,
              const SizedBox(height: AppSpacing.sm),
            ],
            closeButton,
          ],
        ),
      ),
    );
  }
}
