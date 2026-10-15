import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/diary/presentation/progress_photo_capture_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_capture_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_frame.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/features/progress/application/progress_photo_overview_provider.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_photo_overview.dart';
import 'package:yamt/features/progress/presentation/controllers/progress_photo_edit_controller.dart';
import 'package:yamt/features/progress/presentation/progress_photo_edit_flow.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_photo_section.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One progress photo in full size. Its actions replace the image, move the
/// photo to another day or pose, and delete it.
class ProgressPhotoViewerPage extends ConsumerWidget {
  /// Creates the viewer of the photo [photoId].
  const new({required this.photoId, super.key});

  /// Key of the replace button.
  static const replaceKey = ValueKey<String>('progress-photo-viewer-replace');

  /// Key of the move button.
  static const moveKey = ValueKey<String>('progress-photo-viewer-move');

  /// Key of the delete button.
  static const deleteKey = ValueKey<String>('progress-photo-viewer-delete');

  /// The id of the shown photo.
  final String photoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final overview = ref.watch(
      progressPhotoOverviewProvider(ProgressScope.all),
    );
    final photo = overview.value?.photos.firstWhereOrNull(
      (photo) => photo.id == photoId,
    );
    // Watching also keeps the edit controller alive while a write runs.
    final busy = ref.watch(progressPhotoEditControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (photo != null) ...[
            IconButton(
              key: replaceKey,
              tooltip: l10n.progressPhotoReplace,
              icon: const Icon(Icons.photo_camera_outlined),
              onPressed: busy
                  ? null
                  : () => unawaited(_replace(context, photo)),
            ),
            IconButton(
              key: moveKey,
              tooltip: l10n.progressPhotoMove,
              icon: const Icon(Icons.edit_calendar_outlined),
              onPressed: busy
                  ? null
                  : () => unawaited(moveProgressPhoto(context, ref, photo)),
            ),
            IconButton(
              key: deleteKey,
              tooltip: l10n.progressPhotoDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: busy
                  ? null
                  : () => unawaited(_delete(context, ref, photo)),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: responsivePagePadding(
          context,
          top: AppSpacing.md,
          bottom: AppSpacing.xl,
        ),
        children: overview.when(
          data: (overview) => photo == null
              ? [ProgressSectionNote(text: l10n.progressPhotoMissing)]
              : _photo(context, overview, photo),
          loading: () => const [ProgressSectionLoading()],
          error: (_, _) => [
            ProgressSectionNote(text: l10n.progressPhotosLoadFailed),
          ],
        ),
      ),
    );
  }

  List<Widget> _photo(
    BuildContext context,
    ProgressPhotoOverview overview,
    ProgressPhoto photo,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return [
      ProgressPhotoFrame(photoId: photo.id),
      const SizedBox(height: AppSpacing.sm),
      Text(
        l10n.progressPhotoViewerCaption(
          progressPhotoPoseLabel(l10n, photo.pose),
          progressPhotoCaption(context, photo, overview.weightKg(photo)),
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ];
  }

  // The new image is saved under a new id, so the viewer closes.
  Future<void> _replace(BuildContext context, ProgressPhoto photo) async {
    final saved = await showProgressPhotoCapture(context, replacing: photo);
    if (saved && context.mounted) {
      context.pop();
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ProgressPhoto photo,
  ) async {
    if (await deleteProgressPhoto(context, ref, photo) && context.mounted) {
      context.pop();
    }
  }
}
