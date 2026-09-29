import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_action_entry.dart';
import 'package:yamt/features/home/presentation/widgets/home_action_panel.dart';

/// Button that shows a tab's actions in the action panel inside a sheet,
/// standing in for the home bar's round action button in tests.
class SheetLauncher extends ConsumerWidget {
  /// Creates the launcher for [actions].
  const new({required this.actions, super.key});

  /// Key of the button.
  static const buttonKey = ValueKey<String>('sheet-launcher');

  /// Builds the actions to show.
  final List<HomeActionSection> Function(BuildContext context, WidgetRef ref)
  actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton(
      key: buttonKey,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => HomeActionPanel(
          sections: actions(context, ref),
          onClose: () => Navigator.of(sheetContext).pop(),
        ),
      ),
      child: const Text('Open'),
    );
  }
}
