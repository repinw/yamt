import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/features/progress/presentation/controllers/progress_photo_edit_controller.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_photo_move_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Key of the confirm button of the delete and replace dialogs.
const progressPhotoConfirmKey = ValueKey<String>('progress-photo-confirm');

/// Asks before it deletes [photo]. Returns whether it was deleted.
Future<bool> deleteProgressPhoto(
  BuildContext context,
  WidgetRef ref,
  ProgressPhoto photo,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await _confirm(
    context,
    title: l10n.progressPhotoDeleteTitle,
    body: l10n.progressPhotoDeleteBody,
    action: l10n.progressPhotoDelete,
  );
  if (!confirmed || !context.mounted) {
    return false;
  }
  final deleted = await ref
      .read(progressPhotoEditControllerProvider.notifier)
      .delete(photo.id);
  if (!deleted && context.mounted) {
    _showFailed(context, l10n.progressPhotoDeleteFailed);
  }
  return deleted;
}

/// Lets the user pick another day and pose for [photo] and moves it there,
/// after asking before it replaces a photo of that day and pose.
Future<void> moveProgressPhoto(
  BuildContext context,
  WidgetRef ref,
  ProgressPhoto photo,
) async {
  final l10n = AppLocalizations.of(context)!;
  final today = normalizeLocalDay(ref.read(clockProvider)());
  final target = await showModalBottomSheet<ProgressPhotoMoveTarget>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => ProgressPhotoMoveSheet(photo: photo, today: today),
  );
  if (target == null || !context.mounted) {
    return;
  }
  final (:day, :pose) = target;
  final photos = ref.read(progressPhotosProvider).value ?? const [];
  final taken = photos.any(
    (other) => other.id != photo.id && other.day == day && other.pose == pose,
  );
  if (taken &&
      !await _confirm(
        context,
        title: l10n.progressPhotoMoveReplaceTitle,
        body: l10n.progressPhotoMoveReplaceBody,
        action: l10n.progressPhotoReplace,
      )) {
    return;
  }
  if (!context.mounted) {
    return;
  }
  final moved = await ref
      .read(progressPhotoEditControllerProvider.notifier)
      .move(photo.id, day: day, pose: pose);
  if (!moved && context.mounted) {
    _showFailed(context, l10n.progressPhotoMoveFailed);
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          key: progressPhotoConfirmKey,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

void _showFailed(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
