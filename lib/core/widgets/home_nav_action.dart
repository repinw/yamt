import 'package:material_ui/material_ui.dart';

/// The round action in the middle of the home bar: it opens the actions of
/// the current tab.
@immutable
class HomeNavAction {
  /// Creates the action with its [label] under the button.
  const new({required this.label, required this.onPressed});

  /// Word under the button, such as "Hinzufügen".
  final String label;

  /// Opens the actions of the current tab.
  final VoidCallback onPressed;
}
