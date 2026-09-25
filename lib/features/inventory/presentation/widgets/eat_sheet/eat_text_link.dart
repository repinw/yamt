import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Underlined text button of the eat page, such as "+ remember as portion".
class EatTextLink extends StatelessWidget {
  /// Creates the link.
  const new({
    required this.label,
    required this.onPressed,
    this.buttonKey,
    this.isMuted = false,
    super.key,
  });

  /// Key of the button itself. The link spans the whole row, so taps in
  /// tests must target the button.
  final Key? buttonKey;

  /// Text of the link.
  final String label;

  /// Called when the link is tapped.
  final VoidCallback onPressed;

  /// Uses the muted text color instead of the accent.
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final color = isMuted ? colors.muted : colors.accentText;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        key: buttonKey,
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: color,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontFamily: AppFonts.mono,
            color: color,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
