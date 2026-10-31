import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_packing.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_dashboard_edit_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_dashboard_layout_controller.dart';
import 'package:yamt/features/diary/presentation/diary_dashboard_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_catalog.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_edit_bar.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_edit_button.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_grid_block.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_lift.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_slot.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile_sheet.dart';

/// The diary day as a grid of tiles the user arranges: a long press enters
/// edit mode, where tiles move, resize, switch modes and hide.
class DiaryDashboard extends ConsumerStatefulWidget {
  /// Creates the dashboard of [day].
  const new({required this.day, this.tiles = diaryDashboardCatalog, super.key});

  /// Normalized diary day.
  final DateTime day;

  /// The tiles the dashboard offers, one for each spec of the layout.
  final List<DiaryDashboardTile> tiles;

  @override
  ConsumerState<DiaryDashboard> createState() => _DiaryDashboardState();
}

class _DiaryDashboardState extends ConsumerState<DiaryDashboard> {
  final _slotKeys = <String, GlobalKey>{};
  final _lift = DiaryDashboardLift();
  DiaryDashboardMetrics? _metrics;
  ScrollableState? _scrollable;
  ({String id, Rect origin})? _resize;
  DiaryDashboardLayout? _before;
  String? _dragTarget;
  bool _settling = false;
  bool _barDeferred = false;
  Timer? _settleTimer;
  List<DiaryTilePlacement>? _packedTiles;
  List<DiaryDashboardBlock> _blocks = const [];

  GlobalKey _keyOf(String id) => _slotKeys.putIfAbsent(id, GlobalKey.new);

  Rect? _rectOf(String id) {
    final box = _keyOf(id).currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollable = Scrollable.maybeOf(context, axis: Axis.vertical);
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    _lift.remove();
    super.dispose();
  }

  void _save(Future<bool> Function(DiaryDashboardLayoutController) change) =>
      unawaited(changeDiaryDashboardFlow(context, ref, change));

  /// Saves the layout when the drag or resize that just ended changed it.
  void _saveChange() {
    final before = _before;
    _before = null;
    if (before == null ||
        before == ref.read(diaryDashboardLayoutControllerProvider)) {
      return;
    }
    _save((layout) => layout.save());
  }

  /// Whether a drag or a resize runs; one at a time.
  bool get _busy => _lift.tileId != null || _resize != null;

  /// Ends the drag or resize whose recognizer went away without reporting
  /// an end; [save] keeps what it changed.
  void _endGesture({required bool save}) {
    if (!save) _before = null;
    final dragged = _lift.tileId;
    if (dragged != null) _onDragEnd(dragged);
    final resized = _resize?.id;
    if (resized != null) _onResizeEnd(resized);
  }

  void _onDragStart(DiaryTilePlacement placement, Offset global) {
    if (_busy) return;
    final rect = _rectOf(placement.id);
    final tile = widget.tiles.byId(placement.id);
    if (!ref.read(diaryDashboardEditControllerProvider)) {
      // The bar would push the tiles down under the finger; it shows when
      // the finger lets go.
      _barDeferred = rect != null && tile != null;
      ref.read(diaryDashboardEditControllerProvider.notifier).start();
    }
    if (rect == null || tile == null) return;
    AppHapticFeedback.mediumImpact();
    _dragTarget = null;
    _before = ref.read(diaryDashboardLayoutControllerProvider);
    _lift.show(
      context: context,
      tile: tile,
      placement: placement,
      day: widget.day,
      rect: rect,
      pointer: global,
      scrollable: _scrollable,
      // The home bar floats over the page's bottom.
      bottomInset: homeShellPageBottomPadding(context),
      // The page moved under the resting finger.
      onScrolled: () => _reorderAt(_lift.pointer),
    );
    setState(() {});
  }

  void _onDragUpdate(String id, Offset global) {
    if (_lift.tileId != id) return;
    _lift.follow(global);
    _reorderAt(global);
  }

  /// Moves the lifted tile to the place of the tile under [global].
  void _reorderAt(Offset global) {
    final dragId = _lift.tileId;
    if (dragId == null || _settling) return;
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
    ref
        .read(diaryDashboardLayoutControllerProvider.notifier)
        .move(dragId, tiles.indexOf(target));
    AppHapticFeedback.selectionClick();
    // Lets the tiles slide before the next swap, so two tiles of different
    // size do not trade places back and forth under the finger.
    _settling = true;
    _settleTimer?.cancel();
    _settleTimer = Timer(AppDashboard.reflow, () => _settling = false);
  }

  void _onDragEnd(String id) {
    if (_lift.tileId != id) return;
    _lift.remove();
    setState(() => _barDeferred = false);
    _saveChange();
  }

  void _onResizeStart(String id) {
    final origin = _rectOf(id);
    if (_busy || origin == null) return;
    _resize = (id: id, origin: origin);
    _before = ref.read(diaryDashboardLayoutControllerProvider);
  }

  /// Snaps tile [placement] to the size closest to the span from where the
  /// tile started to [global]; the start stays put while the tile moves.
  void _onResizeUpdate(DiaryTilePlacement placement, Offset global) {
    final origin = _resize?.origin;
    final metrics = _metrics;
    final tile = widget.tiles.byId(placement.id);
    if (_resize?.id != placement.id ||
        origin == null ||
        metrics == null ||
        tile == null) {
      return;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final span = Offset(
      rtl ? origin.right - global.dx : global.dx - origin.left,
      global.dy - origin.top,
    );
    final cells = metrics.cellsOf(span);
    final size = snapDiaryTileSize(tile.sizes, cells.columns, cells.rows);
    if (size == placement.size) return;
    AppHapticFeedback.selectionClick();
    ref
        .read(diaryDashboardLayoutControllerProvider.notifier)
        .resize(placement.id, size);
  }

  void _onResizeEnd(String id) {
    if (_resize?.id != id) return;
    _resize = null;
    _saveChange();
  }

  /// The blocks of [tiles], packed again only when the tiles changed.
  List<DiaryDashboardBlock> _blocksOf(List<DiaryTilePlacement> tiles) {
    if (!identical(tiles, _packedTiles)) {
      _packedTiles = tiles;
      _blocks = packDiaryDashboard(tiles);
    }
    return _blocks;
  }

  Widget _slot(DiaryTilePlacement placement, {required bool editing}) {
    final tile = widget.tiles.byId(placement.id)!;
    return DiaryDashboardSlot(
      key: _keyOf(placement.id),
      tile: tile,
      placement: placement,
      day: widget.day,
      editing: editing,
      lifted: _lift.tileId == placement.id,
      liftedHeight: _lift.size.height,
      onDragStart: (global) => _onDragStart(placement, global),
      onDragUpdate: (global) => _onDragUpdate(placement.id, global),
      onDragEnd: () => _onDragEnd(placement.id),
      onResizeStart: () => _onResizeStart(placement.id),
      onResizeUpdate: (global) => _onResizeUpdate(placement, global),
      onResizeEnd: () => _onResizeEnd(placement.id),
      onMenu: () => unawaited(showDiaryDashboardTileSheet(context, tile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = ref.watch(diaryDashboardLayoutControllerProvider);
    final editing = ref.watch(diaryDashboardEditControllerProvider);
    final blocks = _blocksOf(layout.tiles);
    // A recognizer that goes away with edit mode or with its tile reports
    // no end, so the drag or resize ends here.
    ref.listen(diaryDashboardEditControllerProvider, (_, stillEditing) {
      if (!stillEditing) _endGesture(save: true);
    });
    ref.listen(diaryDashboardLayoutControllerProvider, (_, next) {
      final id = _lift.tileId ?? _resize?.id;
      if (id != null && next.tiles.every((t) => t.id != id)) {
        _endGesture(save: false);
      }
    });

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
            if (editing) ...[
              if (!_barDeferred) DiaryDashboardEditBar(tiles: widget.tiles),
            ] else if (layout.tiles.isEmpty)
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
