import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Tile of one package photo: a camera prompt before the photo, then the
/// photo with a tag that says whether it was read. Tapping it takes the
/// photo again.
class ManualProductPhotoTile extends StatelessWidget {
  /// Creates the tile.
  const new({
    required this.title,
    required this.hint,
    required this.photo,
    required this.isReading,
    required this.hasRead,
    required this.onPressed,
    this.readLabel,
    super.key,
  });

  /// Side of the package, such as "Front".
  final String title;

  /// What the photo fills in.
  final String hint;

  /// The photo, or null before the user takes one.
  final Uint8List? photo;

  /// Whether the AI reads the photo.
  final bool isReading;

  /// Whether the photo filled in the product.
  final bool hasRead;

  /// Takes the photo. The tile is disabled when null.
  final VoidCallback? onPressed;

  /// What the photo filled in, such as "Name · 500 g", shown once read.
  final String? readLabel;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final image = photo;
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: colors.card,
        shape: Border.all(
          color: image == null ? colors.muted : colors.ink,
          width: AppFoodLabel.outline,
        ),
        clipBehavior: Clip.antiAlias,
        child: AppInkWell(
          onTap: onPressed,
          child: SizedBox(
            height: AppFoodLabel.photoTile,
            child: image == null
                ? _Prompt(title: title, hint: hint)
                : _Photo(
                    title: title,
                    image: image,
                    isReading: isReading,
                    hasRead: hasRead,
                    readLabel: readLabel,
                  ),
          ),
        ),
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  const new({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    // Large text shrinks instead of overflowing the fixed tile.
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xxs,
          children: [
            Icon(Icons.photo_camera_outlined, color: colors.muted),
            Text(
              title,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            Text(
              hint,
              style: textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const new({
    required this.title,
    required this.image,
    required this.isReading,
    required this.hasRead,
    required this.readLabel,
  });

  final String title;
  final Uint8List image;
  final bool isReading;
  final bool hasRead;
  final String? readLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(image, fit: BoxFit.cover),
        Positioned(
          top: AppSpacing.xs,
          left: AppSpacing.xs,
          child: _Tag(
            text: title,
            background: colors.paper,
            foreground: colors.ink,
          ),
        ),
        Positioned(
          left: AppSpacing.xs,
          bottom: AppSpacing.xs,
          child: isReading
              ? _Tag(
                  text: l10n.productEditorPhotoReading,
                  background: colors.paper,
                  foreground: colors.ink,
                  isBusy: true,
                )
              : hasRead
              ? _Tag(
                  text: readLabel ?? l10n.productEditorPhotoRead,
                  background: colors.accent,
                  foreground: colors.onAccent,
                  icon: Icons.check_rounded,
                )
              : _Tag(
                  text: l10n.productEditorPhotoRetake,
                  background: colors.paper,
                  foreground: colors.ink,
                  icon: Icons.refresh_rounded,
                ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const new({
    required this.text,
    required this.background,
    required this.foreground,
    this.icon,
    this.isBusy = false,
  });

  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final tagIcon = icon;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xxs,
          children: [
            if (isBusy)
              SizedBox.square(
                dimension: AppSizes.inlineProgressIndicator / 2,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.progressStrokeWidth,
                  color: foreground,
                ),
              )
            else if (tagIcon != null)
              Icon(
                tagIcon,
                size: AppSizes.inlineProgressIndicator / 2,
                color: foreground,
              ),
            Text(
              text,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w700, color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
