import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_meal_picture.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'portion_stepper.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Where the recipe photo comes from.
enum RecipePhotoSource {
  /// Taken with the camera.
  camera,

  /// Picked from the files.
  files,
}

/// Top of the recipe editor: the photo button and the name beside it, and
/// the portions under them.
class RecipeEditorHeader extends StatelessWidget {
  /// Creates the header.
  const new({
    required this.nameController,
    required this.onNameChanged,
    required this.portions,
    required this.onPortionsChanged,
    required this.photo,
    required this.original,
    required this.onPhoto,
    super.key,
  });

  /// Key of the photo button.
  static const photoKey = ValueKey<String>('recipe-editor-photo');

  /// Key of the name field.
  static const nameKey = ValueKey<String>('recipe-editor-name');

  /// Key of the portion count.
  static const portionsKey = ValueKey<String>('recipe-editor-portions');

  /// Key of the button that adds a portion.
  static const morePortionsKey = ValueKey<String>('recipe-editor-more');

  /// Holds the typed name.
  final TextEditingController nameController;

  /// Called when the cook edits the name.
  final ValueChanged<String> onNameChanged;

  /// The portion count.
  final int portions;

  /// Called with the new portion count.
  final ValueChanged<int> onPortionsChanged;

  /// The photo picked in the editor.
  final Uint8List? photo;

  /// The saved recipe, whose photo shows until another is picked.
  final PreparedMeal? original;

  /// Asks for a photo.
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final original = this.original;
    final photo = this.photo;
    final picture = switch ((photo, original)) {
      (final Uint8List bytes, _) => Image.memory(bytes, fit: BoxFit.cover),
      (null, final PreparedMeal recipe)
          when recipe.imageAssetId != null || recipe.imageUrl != null =>
        CookbookMealPicture(meal: recipe, size: AppGraphit.editorPhoto),
      _ => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: AppSpacing.xxs,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: AppGraphit.toolIcon,
            color: colors.ink,
          ),
          Text(
            l10n.recipeEditorPhoto.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(color: colors.ink),
          ),
        ],
      ),
    };

    // The portions stand under the photo and the name: beside a long name
    // they would not fit a narrow phone with large text.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            Semantics(
              button: true,
              label: l10n.recipeEditorPhoto,
              excludeSemantics: true,
              child: Material(
                color: colors.card,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: AppInkWell(
                  key: photoKey,
                  onTap: onPhoto,
                  child: SizedBox.square(
                    dimension: AppGraphit.editorPhoto,
                    child: picture,
                  ),
                ),
              ),
            ),
            Expanded(
              // A long name wraps to three lines, then scrolls.
              child: TextField(
                key: nameKey,
                controller: nameController,
                onChanged: onNameChanged,
                minLines: 1,
                maxLines: 3,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                style: textTheme.headlineSmall?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  hintText: l10n.recipeFromListName,
                  hintMaxLines: 3,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.recipeFromListPortions,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            PortionStepper(
              count: portions,
              onChanged: onPortionsChanged,
              lessTooltip: l10n.cookedPortionsLess,
              moreTooltip: l10n.cookedPortionsMore,
              countKey: portionsKey,
              moreKey: morePortionsKey,
            ),
          ],
        ),
      ],
    );
  }
}

/// Asks where the recipe photo comes from; the camera only when
/// [canUseCamera]. Returns `null` when the cook closes the sheet.
Future<RecipePhotoSource?> chooseRecipePhotoSource(
  BuildContext context, {
  required bool canUseCamera,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<RecipePhotoSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canUseCamera)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.preparedMealImageCameraAction),
              onTap: () => Navigator.of(context).pop(RecipePhotoSource.camera),
            ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.preparedMealAddImageAction),
            onTap: () => Navigator.of(context).pop(RecipePhotoSource.files),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
}
