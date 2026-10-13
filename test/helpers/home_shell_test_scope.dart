import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_shell_menu_scope.dart';
import 'package:yamt/features/home/presentation/widgets/home_action_panel.dart';

/// Stands in for the home shell in tests: a header tool below it opens its
/// actions in the action panel inside a sheet. The side menu does nothing.
class HomeShellTestScope extends StatelessWidget {
  /// Creates the scope around [child].
  const new({required this.child, super.key});

  /// The tab content with its header tools.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HomeShellMenuScope(
      openMenu: () {},
      openActions: (build) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => Consumer(
          builder: (_, ref, _) {
            final actions = build(ref);
            return HomeActionPanel(
              sections: actions.sections,
              highlightedKey: actions.highlightedKey,
              fromTop: true,
              onClose: () => Navigator.of(sheetContext).pop(),
            );
          },
        ),
      ),
      child: child,
    );
  }
}
