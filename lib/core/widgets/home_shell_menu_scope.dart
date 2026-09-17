import 'package:material_ui/material_ui.dart';

/// Gives home tab pages access to the shell's side menu.
class HomeShellMenuScope extends InheritedWidget {
  /// Creates the menu scope.
  const new({required this.openMenu, required super.child, super.key});

  /// Opens the side menu.
  final VoidCallback openMenu;

  /// The nearest scope, or `null` outside the home shell.
  static HomeShellMenuScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HomeShellMenuScope>();
  }

  @override
  bool updateShouldNotify(HomeShellMenuScope oldWidget) {
    return openMenu != oldWidget.openMenu;
  }
}
