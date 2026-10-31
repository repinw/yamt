import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile_body.dart';

/// The copy of a dragged tile that follows the finger in the overlay, above
/// the page. It scrolls the page while it touches the page's top edge or
/// what floats over its bottom.
class DiaryDashboardLift {
  OverlayEntry? _entry;
  EdgeDraggingAutoScroller? _scroller;
  double _bottomInset = 0;
  String? _tileId;
  Rect _rect = Rect.zero;
  Offset _grab = Offset.zero;
  Offset _pointer = Offset.zero;

  /// Id of the dragged tile, or null without a drag.
  String? get tileId => _tileId;

  /// Size of the dragged tile when the drag started.
  Size get size => _rect.size;

  /// Where the copy is now, in global coordinates.
  Rect get rect => (_pointer - _grab) & _rect.size;

  /// Where the finger holds the copy, in global coordinates.
  Offset get pointer => _pointer;

  /// Lifts [tile] from [rect], held at [pointer], both in global
  /// coordinates.
  ///
  /// The copy scrolls [scrollable] at its edges, also over the
  /// [bottomInset] that floats over the page's bottom, and reports each
  /// scroll to [onScrolled].
  void show({
    required BuildContext context,
    required DiaryDashboardTile tile,
    required DiaryTilePlacement placement,
    required DateTime day,
    required Rect rect,
    required Offset pointer,
    ScrollableState? scrollable,
    double bottomInset = 0,
    VoidCallback? onScrolled,
  }) {
    remove();
    _tileId = tile.id;
    _rect = rect;
    _grab = pointer - rect.topLeft;
    _pointer = pointer;
    _bottomInset = bottomInset;
    _scroller = scrollable == null
        ? null
        : EdgeDraggingAutoScroller(
            scrollable,
            velocityScalar: AppDashboard.autoScrollVelocity,
            onScrollViewScrolled: () {
              // The scroller only goes on with a target it gets again.
              _autoScroll();
              onScrolled?.call();
            },
          );
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (context) {
        final box = overlay.context.findRenderObject() as RenderBox?;
        final origin = box?.globalToLocal(_pointer - _grab) ?? Offset.zero;
        return Positioned(
          left: origin.dx,
          top: origin.dy,
          width: _rect.width,
          height: _rect.height,
          child: IgnorePointer(
            child: Transform.scale(
              scale: AppDashboard.dragLiftScale,
              child: Opacity(
                opacity: AppDashboard.dragLiftOpacity,
                child: Material(
                  type: MaterialType.transparency,
                  child: DiaryDashboardTileBody(
                    tile: tile,
                    placement: placement,
                    day: day,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    _entry = entry;
    overlay.insert(entry);
  }

  /// Moves the copy with the finger at [pointer].
  void follow(Offset pointer) {
    _pointer = pointer;
    _entry?.markNeedsBuild();
    _autoScroll();
  }

  void _autoScroll() {
    final scroller = _scroller;
    if (scroller == null) return;
    final lifted = rect;
    final height = math.min(
      lifted.height + _bottomInset,
      scroller.scrollable.position.viewportDimension,
    );
    scroller.startAutoScrollIfNecessary(
      lifted.topLeft & Size(lifted.width, height),
    );
  }

  /// Drops the copy and stops the scrolling.
  void remove() {
    _scroller?.stopAutoScroll();
    _scroller = null;
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _tileId = null;
  }
}
