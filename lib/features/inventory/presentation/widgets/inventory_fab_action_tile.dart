import 'package:flutter/material.dart';

/// List tile for one inventory FAB action.
class InventoryFabActionTile extends StatelessWidget {
  /// Creates inventory FAB action tile.
  const InventoryFabActionTile({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
    this.subtitle,
  });

  /// Leading icon.
  final IconData icon;

  /// Main label.
  final String label;

  /// Optional supporting text.
  final String? subtitle;

  /// Called when user taps the tile.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle!),
      enabled: onPressed != null,
      onTap: onPressed,
    );
  }
}
