import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_nav_item.dart';

/// UI state and action for a single home navigation entry.
class HomeNavEntry {
  /// The home nav entry.
  const new({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  /// The item.
  final HomeNavItem item;

  /// Whether selected.
  final bool isSelected;

  /// The on tap.
  final VoidCallback onTap;
}
