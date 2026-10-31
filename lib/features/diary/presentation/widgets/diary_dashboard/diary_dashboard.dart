import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_packing.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_dashboard_edit_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_dashboard_layout_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_catalog.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_edit_bar.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_edit_button.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_grid_block.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_lift.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_slot.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile_sheet.dart';

/// The diary day as a grid of tiles the user arranges: a long press enters
/// edit mode, where tiles move, resize, switch modes and hide.
class DiaryDashboard extends ConsumerStatefulWidget {
  /// Creates the dashboard of [day].
  const new({required this.day, super.key});

  /// Normalized diary day.
  final DateTime day;

  @override
  ConsumerState<DiaryDashboard> createState() => _DiaryDashboardState();
}

class _DiaryDashboardState extends ConsumerState<DiaryDashboard> {
  final _slotKeys = <String, GlobalKey>{};
  final _lift = DiaryDashboardLift();
  DiaryDashboardMetrics? _metrics;
  String? _dragTarget;
  bool _settling = false;
  Timer? _settleTimer;

  GlobalKey _keyOf(String id) => _slotKeys.putIfAbsent(id, GlobalKey.new);

  DiaryDashboardLayoutController get _layout =>
      ref.read(diaryDashboardLayoutControllerProvider.notifier);

  Rect? _rectOf(String id) {
    final box = _keyOf(id).currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    _lift.remove();
    super.dispose();
  }

  void _onDragStart(DiaryTilePlacement placement, Offset global) {
    final edit = ref.read(diaryDashboardEditControllerProvider.notifier);
    if (!ref.read(diaryDashboardEditControllerProvider)) edit.start();
    final rect = _rectOf(placement.id);
    final tile = ref.read(diaryDashboardTilesProvider).byId(placement.id);
    if (rect == null || tile == null) return;
    AppHapticFeedback.mediumImpact();
    _dragTarget = null;
    _lift.show(
      context: context,
      tile: tile,
      placement: placement,
      day: widget.day,
      rect: rect,
      pointer: global,
    );
    setState(() {});
  }

  void _onDragUpdate(Offset global) {
    final dragId = _lift.tileId;
    if (dragId == null) return;
    _lift.follow(global);
    if (_settling) return;
    final tiles = ref.read(diaryDashboardLayoutControllerProvider).tiles;
    final target = tiles
        .where(
          (t) => t.id != dragId && (_rectOf(t.id)?.contains(global) ?? false),
        )
        .firstOrNull;
    if (target == null || target.id == _dragTarget) {
      _dragTarget = target?.id;
      return;
    }
    _dragTarget = target.id;
    _layout.move(dragId, tiles.indexOf(target));
    AppHapticFeedback.selectionClick();
    // Lets the tiles slide before the next swap, so two tiles of different
    // size do not trade places back and forth under the finger.
    _settling = true;
    _settleTimer?.cancel();
    _settleTimer = Timer(AppDashboard.reflow, () => _settling = false);
  }

  void _onDragEnd() {
    if (_lift.tileId == null) return;
    _lift.remove();
    setState(() {});
    unawaited(_layout.save());
  }

  void _onResizeUpdate(DiaryTilePlacement placement, Offset global) {
    final rect = _rectOf(placement.id);
    final metrics = _metrics;
    final tile = ref.read(diaryDashboardTilesProvider).byId(placement.id);
    if (rect == null || metrics == null || tile == null) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final span = Offset(
      rtl ? rect.right - global.dx : global.dx - rect.left,
      global.dy - rect.top,
    );
    final cells = metrics.cellsOf(span);
    final size = snapDiaryTileSize(tile.sizes, cells.columns, cells.rows);
    if (size == placement.size) return;
    AppHapticFeedback.selectionClick();
    _layout.resize(placement.id, size);
  }

  Widget _slot(DiaryTilePlacement placement, {required bool editing}) {
    final tile = ref.read(diaryDashboardTilesProvider).byId(placement.id)!;
    return DiaryDashboardSlot(
      key: _keyOf(placement.id),
      tile: tile,
      placement: placement,
      day: widget.day,
      editing: editing,
      lifted: _lift.tileId == placement.id,
      liftedHeight: _lift.size.height,
      onDragStart: (global) => _onDragStart(placement, global),
      onDragUpdate: _onDragUpdate,
      onDragEnd: _onDragEnd,
      onResizeUpdate: (global) => _onResizeUpdate(placement, global),
      onResizeEnd: () => unawaited(_layout.save()),
      onMenu: () => unawaited(showDiaryDashboardTileSheet(context, tile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = ref.watch(diaryDashboardLayoutControllerProvider);
    final editing = ref.watch(diaryDashboardEditControllerProvider);
    final blocks = packDiaryDashboard(layout.tiles);

    return LayoutBuilder(
      key: DiaryDashboardKeys.dashboard,
      builder: (context, constraints) {
        final metrics = DiaryDashboardMetrics.of(
          constraints.maxWidth,
          MediaQuery.textScalerOf(context),
        );
        _metrics = metrics;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppDashboard.gap,
          children: [
            if (editing)
              const DiaryDashboardEditBar()
            else if (layout.tiles.isEmpty)
              const DiaryDashboardEditButton(),
            for (final block in blocks)
              switch (block) {
                DiaryGridBlock() => DiaryDashboardGridBlock(
                  block: block,
                  metrics: metrics,
                  slotBuilder: (p) => _slot(p, editing: editing),
                ),
                DiaryWideBlock(:final placement) => _slot(
                  placement,
                  editing: editing,
                ),
              },
          ],
        );
      },
    );
  }
}
