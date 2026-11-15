import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/kitchen_utensils/application/kitchen_utensil_image_url_provider.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/kitchen_utensil_cover.dart';

/// A tile of "Töpfe": the utensil's picture with a circle that shows it can
/// be picked along with others, its name and a line under it; or, with
/// [isAdd], the tile that adds a utensil.
class KochmodusPotTile extends ConsumerWidget {
  /// Creates the tile of a utensil named [name].
  const new({
    required this.name,
    required this.selected,
    required this.onTap,
    this.sub,
    this.imagePath,
    this.isAdd = false,
    super.key,
  });

  /// The utensil's name, or what the tile does.
  final String name;

  /// The line under the name, such as the empty weight.
  final String? sub;

  /// The Storage path of the utensil's photo.
  final String? imagePath;

  /// Whether the utensil is picked; the tile turns ink.
  final bool selected;

  /// Whether this tile adds a utensil: a plus instead of picture and circle.
  final bool isAdd;

  /// Picks or unpicks the utensil, or adds one.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final path = imagePath;
    final imageUrl = path == null
        ? null
        : ref.watch(kitchenUtensilImageUrlProvider(path)).asData?.value;
    final foreground = selected ? colors.paper : colors.ink;
    final subText = sub;
    return Semantics(
      button: true,
      selected: isAdd ? null : selected,
      child: Material(
        color: selected
            ? colors.ink
            : (isAdd ? Colors.transparent : colors.card),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: selected ? colors.ink : colors.rule),
        ),
        child: AppInkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: AppSpacing.md,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAdd)
                      Icon(Icons.add_rounded, color: colors.muted)
                    else
                      KitchenUtensilCover(
                        label: name,
                        imageBytes: null,
                        imageUrl: imageUrl,
                        size: AppGraphit.stockRowPicture,
                      ),
                    const Spacer(),
                    if (!isAdd)
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: AppGraphit.toolIcon,
                        color: selected ? colors.paper : colors.muted,
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The add tile says what it does in full; a name stays
                    // on one line.
                    Text(
                      name,
                      maxLines: isAdd ? null : 1,
                      overflow: isAdd ? null : TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subText != null)
                      Text(
                        subText,
                        style: textTheme.bodySmall?.copyWith(
                          color: selected ? colors.paper : colors.muted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
