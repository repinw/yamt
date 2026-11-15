import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// The button at the bottom of the recipe page, with an optional [header]
/// above it.
class RecipeBottomBar extends StatelessWidget {
  /// Creates the bar.
  const new({
    required this.label,
    required this.onPressed,
    this.buttonKey,
    this.header,
    super.key,
  });

  /// The button text.
  final String label;

  /// Called by the button; `null` turns it off.
  final VoidCallback? onPressed;

  /// Key of the button.
  final Key? buttonKey;

  /// Shown above the button, such as a note about it.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final header = this.header;
    final button = FilledButton(
      key: buttonKey,
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
      ),
      child: Text(label),
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: header == null
            ? button
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.sm,
                children: [header, button],
              ),
      ),
    );
  }
}
