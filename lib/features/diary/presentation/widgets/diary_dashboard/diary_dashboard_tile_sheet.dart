import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';
import 'package:yamt/core/widgets/app_dashboard_sheet.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_dashboard_layout_controller.dart';
import 'package:yamt/features/diary/presentation/diary_dashboard_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the menu of [tile]: its display modes, its sizes, and hide.
Future<void> showDiaryDashboardTileSheet(
  BuildContext context,
  DiaryDashboardTile tile,
) => showAppDashboardSheet(context, (_) => DiaryDashboardTileSheet(tile: tile));

/// Content of the menu of one tile.
class DiaryDashboardTileSheet extends ConsumerWidget {
  /// Creates the menu of [tile].
  const new({required this.tile, super.key});

  /// The tile.
  final DiaryDashboardTile tile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final placement = ref.watch(
      diaryDashboardLayoutControllerProvider.select(
        (l) => l.tiles.where((t) => t.id == tile.id).firstOrNull,
      ),
    );
    if (placement == null) return const SizedBox.shrink();
    void change(Future<bool> Function(DiaryDashboardLayoutController) run) =>
        unawaited(changeDiaryDashboardFlow(context, ref, run));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        AppDashboardSheetHeading(icon: tile.icon, label: tile.label(l10n)),
        if (tile.modes.length > 1) ...[
          Text(
            l10n.diaryDashboardModesLabel.toUpperCase(),
            style: context.graphitKickerStyle,
          ),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final mode in tile.modes)
                ChoiceChip(
                  key: DiaryDashboardKeys.mode(mode.id),
                  avatar: Icon(mode.icon),
                  // In the label's color: the Material default would paint
                  // the icon of a selected chip in its fill, others in the
                  // accent.
                  iconTheme: IconThemeData(
                    color: placement.mode == mode.id
                        ? colors.surface
                        : colors.onSurface,
                  ),
                  showCheckmark: false,
                  label: Text(mode.label(l10n)),
                  selected: placement.mode == mode.id,
                  onSelected: (_) =>
                      change((layout) => layout.setMode(tile.id, mode.id)),
                ),
            ],
          ),
        ],
        if (tile.sizes.length > 1) ...[
          Text(
            l10n.diaryDashboardSizesLabel.toUpperCase(),
            style: context.graphitKickerStyle,
          ),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final size in tile.sizes)
                ChoiceChip(
                  key: DiaryDashboardKeys.size(size.name),
                  showCheckmark: false,
                  label: Text(_sizeLabel(l10n, size)),
                  selected: placement.size == size,
                  onSelected: (_) =>
                      change((layout) => layout.setSize(tile.id, size)),
                ),
            ],
          ),
        ],
        OutlinedButton.icon(
          key: DiaryDashboardKeys.hide,
          onPressed: () {
            change((layout) => layout.hide(tile.id));
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.visibility_off_outlined),
          label: Text(l10n.diaryDashboardHideTile),
        ),
      ],
    );
  }
}

String _sizeLabel(AppLocalizations l10n, DiaryTileSize size) =>
    switch (size.rows) {
      final rows? => l10n.diaryDashboardSizeLabel(size.columns, rows),
      null => l10n.diaryDashboardSizeWide,
    };
