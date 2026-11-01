import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/utils/exclusive_runner.dart';
import 'package:yamt/core/widgets/home_action_entry.dart';
import 'package:yamt/features/diary/presentation/progress_photo_capture_flow.dart';
import 'package:yamt/features/progress/presentation/progress_weight_entry_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Keys of the Fortschritt actions.
abstract final class ProgressActionKeys {
  /// Entry that enters today's weight.
  static const weigh = ValueKey<String>('progress-action-weigh');

  /// Entry that adds a progress photo.
  static const photo = ValueKey<String>('progress-action-photo');

  /// Entry that opens the data export.
  static const export = ValueKey<String>('progress-action-export');
}

/// The Fortschritt actions: enter today's weight, add a progress photo, and
/// export the data.
///
/// [weightEntry] opens one weight entry at a time: the entry waits for the
/// chart weights before its dialog opens (#703).
List<HomeActionSection> progressActions(
  BuildContext context, {
  required ExclusiveRunner weightEntry,
}) {
  final l10n = AppLocalizations.of(context)!;
  return [
    HomeActionSection(
      title: l10n.homeProgress,
      entries: [
        HomeActionEntry(
          key: ProgressActionKeys.weigh,
          icon: Icons.monitor_weight_outlined,
          title: l10n.homeActionWeigh,
          description: l10n.progressActionWeighDescription,
          onSelected: () => unawaited(
            weightEntry.run(() => showProgressWeightEntry(context)),
          ),
        ),
        HomeActionEntry(
          key: ProgressActionKeys.photo,
          icon: Icons.photo_camera_outlined,
          title: l10n.progressActionPhoto,
          description: l10n.progressActionPhotoDescription,
          onSelected: () => unawaited(showProgressPhotoCapture(context)),
        ),
        HomeActionEntry(
          key: ProgressActionKeys.export,
          icon: Icons.ios_share_rounded,
          title: l10n.dataExportTitle,
          description: l10n.dataExportActionDescription,
          onSelected: () =>
              unawaited(context.push(AppRoutes.homeProgressExport)),
        ),
      ],
    ),
  ];
}
