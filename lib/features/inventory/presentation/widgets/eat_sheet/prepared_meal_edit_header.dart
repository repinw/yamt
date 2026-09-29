import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_image_tile.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/prepared_meal_image_picker_field.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Head of the meal editor: the picture, which opens the picture choices on
/// tap, and the name as a borderless input.
class PreparedMealEditHeader extends StatelessWidget {
  /// Creates the head.
  const new({
    required this.nameController,
    required this.imageUrl,
    required this.imageBytes,
    required this.collageImageUrls,
    required this.fallbackLetter,
    required this.hasPicture,
    required this.supportsCamera,
    required this.onPickImage,
    required this.onClearImage,
    super.key,
  });

  /// Key of the name input.
  static const nameKey = Key('prepared_meal_edit_name');

  /// Key of the picture button.
  static const pictureKey = Key('prepared_meal_edit_picture');

  /// Text of the name input.
  final TextEditingController nameController;

  /// Stored picture address.
  final String? imageUrl;

  /// Picture bytes, shown in place of [imageUrl].
  final Uint8List? imageBytes;

  /// Ingredient pictures, shown as a collage without a meal picture.
  final List<String?> collageImageUrls;

  /// Letter shown without any picture.
  final String? fallbackLetter;

  /// Whether the meal has its own picture that can be removed.
  final bool hasPicture;

  /// Whether the device can take a photo.
  final bool supportsCamera;

  /// Called with the source of a new picture.
  final ValueChanged<PreparedMealImageSource> onPickImage;

  /// Removes the picture.
  final VoidCallback onClearImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final style = Theme.of(context).textTheme.headlineMedium
        ?.copyWith(fontWeight: FontWeight.w800, color: colors.ink);

    return Row(
      spacing: AppSpacing.xl,
      children: [
        Semantics(
          button: true,
          label: l10n.preparedMealImageLabel,
          child: AppInkWell(
            key: pictureKey,
            onTap: () => _showChoices(context),
            child: EatImageTile(
              imageUrl: imageUrl,
              imageBytes: imageBytes,
              collageImageUrls: collageImageUrls,
              fallbackLetter: fallbackLetter,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            key: nameKey,
            controller: nameController,
            cursorColor: colors.ink,
            style: style,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.preparedMealNameLabel,
              hintStyle: style?.copyWith(color: colors.muted),
              contentPadding: const EdgeInsets.only(bottom: AppSpacing.xs),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.rule),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.ink),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showChoices(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<_PictureChoice>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (supportsCamera)
              _choiceTile(
                context,
                _PictureChoice.camera,
                Icons.photo_camera_outlined,
                l10n.preparedMealImageCameraAction,
              ),
            _choiceTile(
              context,
              _PictureChoice.file,
              Icons.photo_library_outlined,
              hasPicture
                  ? l10n.preparedMealChangeImageAction
                  : l10n.preparedMealAddImageAction,
            ),
            if (hasPicture)
              _choiceTile(
                context,
                _PictureChoice.remove,
                Icons.delete_outline_rounded,
                l10n.preparedMealRemoveImageAction,
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    switch (choice) {
      case _PictureChoice.camera:
        onPickImage(PreparedMealImageSource.camera);
      case _PictureChoice.file:
        onPickImage(PreparedMealImageSource.file);
      case _PictureChoice.remove:
        onClearImage();
      case null:
        break;
    }
  }

  static Widget _choiceTile(
    BuildContext context,
    _PictureChoice choice,
    IconData icon,
    String label,
  ) {
    return ListTile(
      key: Key('prepared_meal_edit_picture_${choice.name}'),
      leading: Icon(icon),
      title: Text(label),
      onTap: () => Navigator.of(context).pop(choice),
    );
  }
}

enum _PictureChoice { camera, file, remove }
