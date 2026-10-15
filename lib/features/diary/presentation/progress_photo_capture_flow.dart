import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_capture_sheet.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the sheet that adds a progress photo, preset to [pose], or that
/// replaces the image of [replacing], and confirms a saved photo unless
/// [confirmSaved] is off. Returns whether a photo was saved.
///
/// A caller inside a modal turns [confirmSaved] off: the snack bar would show
/// behind the modal.
Future<bool> showProgressPhotoCapture(
  BuildContext context, {
  ProgressPhotoPose pose = ProgressPhotoPose.front,
  ProgressPhoto? replacing,
  bool confirmSaved = true,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final today = normalizeLocalDay(container.read(clockProvider)());
  final saved = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => ProgressPhotoCaptureSheet(
      today: today,
      pose: pose,
      replacing: replacing,
    ),
  );
  if (saved != true) {
    return false;
  }
  if (confirmSaved && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.progressPhotoSaved)),
    );
  }
  return true;
}
