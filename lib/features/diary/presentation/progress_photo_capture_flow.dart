import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_capture_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the sheet that adds a progress photo and confirms a saved photo.
Future<void> showProgressPhotoCapture(BuildContext context) async {
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
    builder: (_) => ProgressPhotoCaptureSheet(today: today),
  );
  if (saved != true || !context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context)!.progressPhotoSaved)),
  );
}
