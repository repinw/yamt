import 'package:flutter/material.dart';

class InventoryFabActionTile extends StatelessWidget {
  const InventoryFabActionTile({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
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
