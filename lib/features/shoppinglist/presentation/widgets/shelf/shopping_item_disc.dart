import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shelf/shopping_shelf_labels.dart';

/// The picture of an entry on a small rounded square, or a tick once it is
/// in the cart.
class ShoppingItemDisc extends StatelessWidget {
  /// Creates the disc.
  const new({
    required this.icon,
    required this.size,
    this.ticked = false,
    super.key,
  });

  /// The picture of the entry.
  final ShoppingItemIcon icon;

  /// Edge length at text scale one.
  final double size;

  /// Whether the disc shows a tick instead of the picture.
  final bool ticked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scaled = MediaQuery.textScalerOf(context).scale(size);
    return ExcludeSemantics(
      child: Container(
        width: scaled,
        height: scaled,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          color: ticked ? colors.primary : colors.surfaceContainerHighest,
        ),
        child: Icon(
          ticked ? Icons.check_rounded : shoppingItemIconData(icon),
          size: scaled * AppShopping.itemDiscIconRatio,
          color: ticked ? colors.onPrimary : colors.onSurface,
        ),
      ),
    );
  }
}
