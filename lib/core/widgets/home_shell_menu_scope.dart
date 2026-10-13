import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_action_entry.dart';

/// Actions of a header tool: the panel's sections and the key of the entry
/// that gets the lime tile.
typedef HomeHeaderActions = ({
  List<HomeActionSection> sections,
  Key? highlightedKey,
});

/// Builds a header tool's actions. The shell calls it on every rebuild of the
/// open panel, so the actions follow the providers it watches through [ref].
typedef HomeHeaderActionsBuilder = HomeHeaderActions Function(WidgetRef ref);

/// Opens the shell's action panel at the top right, under the header tool
/// that asked for it, with the actions that [build] returns.
typedef HomeShellOpenActions = void Function(HomeHeaderActionsBuilder build);

/// Gives home tab pages access to the shell's side menu and action panel.
class HomeShellMenuScope extends InheritedWidget {
  /// Creates the menu scope.
  const new({
    required this.openMenu,
    required this.openActions,
    required super.child,
    super.key,
  });

  /// Opens the side menu.
  final VoidCallback openMenu;

  /// Opens the action panel for a header tool on the right, the way the
  /// action button of the bottom bar opens it.
  final HomeShellOpenActions openActions;

  /// The nearest scope, or `null` outside the home shell.
  static HomeShellMenuScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HomeShellMenuScope>();
  }

  @override
  bool updateShouldNotify(HomeShellMenuScope oldWidget) {
    return openMenu != oldWidget.openMenu ||
        openActions != oldWidget.openActions;
  }
}
