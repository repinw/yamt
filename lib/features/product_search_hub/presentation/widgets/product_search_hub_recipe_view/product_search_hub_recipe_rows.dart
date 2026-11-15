import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The large accent button that scans a pack, with its line under the label.
class RecipeScanButton extends StatelessWidget {
  /// Creates the button.
  const new({required this.onPressed, super.key});

  /// Opens the scanner.
  final VoidCallback onPressed;

  /// Key of the button.
  static const buttonKey = Key('product_search_hub_recipe_scan_button');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return FilledButton(
      key: buttonKey,
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        minimumSize: const Size.fromHeight(AppGraphit.leadButtonMinHeight),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.qr_code_scanner_rounded,
            size: AppGraphit.leadButtonIcon,
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.recipeFoodScanTitle,
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.onAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.recipeFoodScanLine,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One row that picks a food: picture, name, a grey line, an optional
/// chevron.
class RecipeFoodRow extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.imageUrl,
    this.icon,
    this.showsChevron = false,
    super.key,
  });

  /// The food's name, or the row's action.
  final String title;

  /// Brand, pack size, or what the Vorrat holds.
  final String? subtitle;

  /// The food's picture; without it the first letter of [title].
  final String? imageUrl;

  /// An icon instead of a picture, for a row that is an action.
  final IconData? icon;

  /// Whether the row leads to another list.
  final bool showsChevron;

  /// Picks the food.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final subtitle = this.subtitle;
    return AppInkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppGraphit.foodRowMinHeight,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.rule)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                _FoodPicture(title: title, imageUrl: imageUrl, icon: icon),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (showsChevron)
                  Icon(Icons.chevron_right_rounded, color: colors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The quiet last row that opens the own entry of a food.
class RecipeOwnEntryRow extends StatelessWidget {
  /// Creates the row.
  const new({required this.onPressed, super.key});

  /// Opens the editor.
  final VoidCallback onPressed;

  /// Key of the row.
  static const rowKey = Key('product_search_hub_recipe_own_entry');

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: rowKey,
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: colors.muted),
        icon: const Icon(Icons.edit_note_rounded),
        label: Text(AppLocalizations.of(context)!.recipeFoodOwnEntry),
      ),
    );
  }
}

/// A grey line in the list, such as "Nichts gefunden", with an optional
/// action.
class RecipeListNote extends StatelessWidget {
  /// Creates the note.
  const new({required this.text, this.action, super.key});

  /// The note.
  final String text;

  /// A button under it, such as "Erneut versuchen".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final action = this.action;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: colors.muted),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _FoodPicture extends StatelessWidget {
  const new({required this.title, this.imageUrl, this.icon});

  final String title;
  final String? imageUrl;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final imageUrl = this.imageUrl;
    final icon = this.icon;
    final letter = Center(
      child: icon != null
          ? Icon(icon, color: colors.ink)
          : Text(
              title.isEmpty ? '' : title.characters.first.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: colors.muted, fontWeight: FontWeight.w800),
            ),
    );
    return Transform.rotate(
      angle: icon == null ? AppFoodLabel.imageTilt : 0,
      child: SizedBox.square(
        dimension: AppGraphit.rowTile,
        child: ColoredBox(
          color: colors.tile,
          child: imageUrl == null
              ? letter
              : AppCachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => letter,
                ),
        ),
      ),
    );
  }
}
