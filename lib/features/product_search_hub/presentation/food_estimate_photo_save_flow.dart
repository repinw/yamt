import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/product_search_hub/domain/food_estimate_item.dart';
import 'package:yamt/features/product_search_hub/domain/product_photo.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'food_estimate_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_ai_search_result.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'photo_upload_queued_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// [result] with the first photo as the item's image and every photo on
/// its AI estimate (#763). The uploads run on after the page closes; a
/// failed upload waits on the device for a later try. The user hears of a
/// failure on the app's messenger.
Future<ManualProductAiSearchResult> withSavedFoodPhotos(
  BuildContext context,
  WidgetRef ref,
  ManualProductAiSearchResult result,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  final List<ProductPhotoUpload> uploads;
  try {
    uploads = await ref
        .read(foodEstimateControllerProvider.notifier)
        .savePhotos();
  } on Object catch (error, stackTrace) {
    log(
      'Storing the food photo failed.',
      name: 'FoodEstimatePhotoSaveFlow',
      error: error,
      stackTrace: stackTrace,
    );
    messenger.showAppSnackBar(
      l10n.foodEstimatePhotoNotSaved,
      tone: AppSnackBarTone.error,
    );
    return result;
  }
  whenPhotoUploadQueued(
    Future.wait([for (final upload in uploads) upload.done]),
    () => messenger.showAppSnackBar(
      l10n.photoUploadQueued,
      tone: AppSnackBarTone.info,
    ),
  );
  return result.withItem(
    result.item.withFoodPhotos([
      for (final upload in uploads) ?upload.frontAddress,
    ]),
  );
}
