import 'package:flutter/material.dart';

/// Extended floating action button used in the expanded inventory menu.
class InventoryFabMenuAction extends StatelessWidget {
  /// Creates expanded-menu action.
  const InventoryFabMenuAction({
    required this.heroTag,
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
    String? tooltip,
  }) : tooltip = tooltip ?? label;

  /// Hero tag for the floating action button.
  final Object heroTag;

  /// Action icon.
  final IconData icon;

  /// Visible label.
  final String label;

  /// Tooltip text.
  final String tooltip;

  /// Called when user presses the action.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final labelMaxWidth = (screenWidth - 128).clamp(120.0, 240.0);

    return Tooltip(
      message: tooltip,
      child: FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed,
        icon: Icon(icon),
        label: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: labelMaxWidth),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
