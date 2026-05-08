import 'package:flutter/material.dart';

class InventoryFabMenuAction extends StatelessWidget {
  const InventoryFabMenuAction({
    required this.heroTag,
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
    String? tooltip,
  }) : tooltip = tooltip ?? label;

  final Object heroTag;
  final IconData icon;
  final String label;
  final String tooltip;
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
