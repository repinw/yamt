import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile_body.dart';

/// The copy of a dragged tile that follows the finger in the overlay, above
/// the page.
class DiaryDashboardLift {
  OverlayEntry? _entry;
  String? _tileId;
  Rect _rect = Rect.zero;
  Offset _grab = Offset.zero;
  Offset _pointer = Offset.zero;

  /// Id of the dragged tile, or null without a drag.
  String? get tileId => _tileId;

  /// Size of the dragged tile when the drag started.
  Size get size => _rect.size;

  /// Lifts [tile] from [rect], held at [pointer], both in global
  /// coordinates.
  void show({
    required BuildContext context,
    required DiaryDashboardTile tile,
    required DiaryTilePlacement placement,
    required DateTime day,
    required Rect rect,
    required Offset pointer,
  }) {
    remove();
    _tileId = tile.id;
    _rect = rect;
    _grab = pointer - rect.topLeft;
    _pointer = pointer;
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
  }

  /// Drops the copy.
  void remove() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _tileId = null;
  }
}
