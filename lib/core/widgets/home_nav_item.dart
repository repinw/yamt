import 'package:material_ui/material_ui.dart';

/// Data needed to render one item in the home bottom navigation.
class HomeNavItem {
  /// The home nav item.
  const new({required this.icon, required this.label});

  /// The icon.
  final IconData icon;

  /// The label.
  final String label;
}
