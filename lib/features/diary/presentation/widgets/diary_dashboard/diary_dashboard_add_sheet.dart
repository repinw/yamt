import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_dashboard_sheet.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_dashboard_layout_controller.dart';
import 'package:yamt/features/diary/presentation/diary_dashboard_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_catalog.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Lists the hidden tiles of [tiles]; a tap shows one at the end of the
/// dashboard.
Future<void> showDiaryDashboardAddSheet(
  BuildContext context,
  List<DiaryDashboardTile> tiles,
) =>
    showAppDashboardSheet(context, (_) => DiaryDashboardAddSheet(tiles: tiles));

/// Content of the sheet that adds a hidden tile back.
class DiaryDashboardAddSheet extends ConsumerWidget {
  /// Creates the sheet for a dashboard with [tiles].
  const new({required this.tiles, super.key});

  /// The tiles the dashboard offers.
  final List<DiaryDashboardTile> tiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hidden = ref.watch(
      diaryDashboardLayoutControllerProvider.select((l) => l.hidden),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDashboardSheetHeading(
          icon: Icons.add,
          label: l10n.diaryDashboardAddTile,
        ),
        for (final id in hidden)
          if (tiles.byId(id) case final tile?)
            ListTile(
              key: DiaryDashboardKeys.addTile(id),
              leading: Icon(tile.icon),
              title: Text(tile.label(l10n)),
              onTap: () {
                unawaited(
                  changeDiaryDashboardFlow(
                    context,
                    ref,
                    (layout) => layout.show(id),
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
      ],
    );
  }
}
