import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_more_sheet.dart';

/// Opens the Mehr sheet of the home shell with a tab's own entries.
typedef HomeShellOpenMore = void Function(
  String title,
  List<HomeMoreEntry> entries,
);

/// Gives home tab pages access to the shell's Mehr sheet.
class HomeShellMoreScope extends InheritedWidget {
  /// Creates the Mehr sheet scope.
  const new({required this.openMore, required super.child, super.key});

  /// Opens the Mehr sheet. The shell adds the app entries, such as the
  /// settings, below the tab's entries.
  final HomeShellOpenMore openMore;

  /// The nearest scope, or `null` outside the home shell.
  static HomeShellMoreScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HomeShellMoreScope>();
  }

  @override
  bool updateShouldNotify(HomeShellMoreScope oldWidget) {
    return openMore != oldWidget.openMore;
  }
}
