import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines prepared meal image source.
enum PreparedMealImageSource {
  /// Camera source.
  camera,

  /// File picker source.
  file,
}

/// Defines prepared meal image picker field.
class PreparedMealImagePickerField extends StatelessWidget {
  /// The prepared meal image picker field.
  const PreparedMealImagePickerField({
    required this.label,
    required this.imageBytes,
    required this.supportsCamera,
    required this.isPickingImage,
    required this.onPickImage,
    required this.onClearImage,
    super.key,
  });

  /// The label used for the cover fallback initial.
  final String label;

  /// The image bytes currently shown in the preview.
  final Uint8List? imageBytes;

  /// Whether camera picking is available.
  final bool supportsCamera;

  /// Whether an image picker action is running.
  final bool isPickingImage;

  /// Called when the user chooses an image source.
  final ValueChanged<PreparedMealImageSource> onPickImage;

  /// Called when the user removes the image.
  final VoidCallback onClearImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.preparedMealImageLabel,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PreparedMealCover(
              label: label,
              imageBytes: imageBytes,
              size: 88,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (supportsCamera)
                        FilledButton.tonalIcon(
                          onPressed: isPickingImage
                              ? null
                              : () => onPickImage(
                                  PreparedMealImageSource.camera,
                                ),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: Text(l10n.preparedMealImageCameraAction),
                        ),
                      FilledButton.tonalIcon(
                        onPressed: isPickingImage
                            ? null
                            : () => onPickImage(PreparedMealImageSource.file),
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          imageBytes == null
                              ? l10n.preparedMealAddImageAction
                              : l10n.preparedMealChangeImageAction,
                        ),
                      ),
                      if (imageBytes != null)
                        TextButton.icon(
                          onPressed: isPickingImage ? null : onClearImage,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(l10n.preparedMealRemoveImageAction),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.preparedMealImageHint,
                    style:
                        Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shares prepared meal image picking behavior between sheets.
mixin PreparedMealImagePickerStateMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Whether image picking is in progress.
  bool isPickingPreparedMealImage = false;

  /// Whether the current platform supports camera picking.
  bool get supportsPreparedMealCamera {
    return ref.read(preparedMealImagePickerProvider).supportsCamera;
  }

  /// Picks a prepared meal image and passes selected bytes to [onPicked].
  Future<void> pickPreparedMealImage({
    required PreparedMealImageSource source,
    required ValueChanged<Uint8List> onPicked,
  }) async {
    setState(() {
      isPickingPreparedMealImage = true;
    });

    final picker = ref.read(preparedMealImagePickerProvider);
    try {
      final imageBytes = await switch (source) {
        PreparedMealImageSource.camera => picker.pickFromCamera(),
        PreparedMealImageSource.file => picker.pickFromFile(),
      };
      if (!mounted || imageBytes == null) {
        return;
      }
      setState(() {
        onPicked(imageBytes);
      });
    } on PreparedMealImagePickerException catch (error) {
      if (!mounted) {
        return;
      }
      showPreparedMealImageError(error.code);
    } on Object catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      log(
        'Failed to pick prepared meal image.',
        name: 'PreparedMealImagePickerField',
        error: error,
        stackTrace: stackTrace,
      );
      showPreparedMealImageError(_fallbackErrorCode(source));
    } finally {
      if (mounted) {
        setState(() {
          isPickingPreparedMealImage = false;
        });
      }
    }
  }

  /// Shows the localized prepared meal image error message.
  void showPreparedMealImageError(String errorCode) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (errorCode) {
      PreparedMealImagePickerErrorCodes.imageTooLarge =>
        l10n.preparedMealImageTooLarge,
      _ => l10n.preparedMealImagePickFailed,
    };

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  String _fallbackErrorCode(PreparedMealImageSource source) {
    return switch (source) {
      PreparedMealImageSource.camera =>
        PreparedMealImagePickerErrorCodes.cameraPickFailed,
      PreparedMealImageSource.file =>
        PreparedMealImagePickerErrorCodes.filePickFailed,
    };
  }
}
