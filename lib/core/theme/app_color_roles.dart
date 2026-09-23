import 'package:material_ui/material_ui.dart';

/// App color roles that Material's [ColorScheme] does not name.
extension AppColorRoles on ColorScheme {
  /// Empty part of a progress bar inside a `surfaceContainerLow` card.
  ///
  /// Dark mode insets the track with the darker [surface]. In light mode
  /// [surface] is lighter than the card and the track disappears, so the
  /// track uses the recessed [surfaceContainerHighest] instead.
  Color get progressTrack =>
      brightness == Brightness.dark ? surface : surfaceContainerHighest;
}
