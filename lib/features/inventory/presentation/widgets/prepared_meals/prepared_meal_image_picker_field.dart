import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines prepared meal image source.
enum PreparedMealImageSource {
  /// Camera source.
  camera,

  /// File picker source.
  file,
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

    ScaffoldMessenger.of(context)
        .showAppSnackBar(message, tone: AppSnackBarTone.error);
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
