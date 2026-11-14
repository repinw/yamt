import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';

/// A disc with the first letter of an entry, or a tick once it is in the
/// cart. It stands in for the picture of the entry.
class ShoppingListLetterDisc extends StatelessWidget {
  /// Creates the disc.
  const new({
    required this.name,
    required this.size,
    this.ticked = false,
    super.key,
  });

  /// The entry name whose first letter shows.
  final String name;

  /// Diameter at text scale one.
  final double size;

  /// Whether the disc shows a tick instead of the letter.
  final bool ticked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final scaled = MediaQuery.textScalerOf(context).scale(size);
    final foreground = ticked ? colors.onPrimary : colors.onSurface;
    return ExcludeSemantics(
      child: Container(
        width: scaled,
        height: scaled,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ticked ? colors.primary : colors.surfaceContainerHighest,
        ),
        child: ticked
            ? Icon(
                Icons.check_rounded,
                size: scaled * AppShopping.letterDiscTickRatio,
                color: foreground,
              )
            : Text(
                name.isEmpty ? '' : name.characters.first.toUpperCase(),
                textScaler: TextScaler.noScaling,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: scaled * AppShopping.letterDiscLetterRatio,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
      ),
    );
  }
}
