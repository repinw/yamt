import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile_body.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What a slot reports while the user drags it or its resize handle, in
/// global coordinates.
typedef DiaryDashboardPointerCallback = void Function(Offset global);

/// One tile in the dashboard with its gestures: a long press enters edit
/// mode and drags; in edit mode a short hold drags, a tap opens the menu and
/// the corner handle resizes.
class DiaryDashboardSlot extends StatelessWidget {
  /// Creates the slot of [tile].
  const new({
    required this.tile,
    required this.placement,
    required this.day,
    required this.editing,
    required this.lifted,
    required this.liftedHeight,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onResizeUpdate,
    required this.onResizeEnd,
    required this.onMenu,
    super.key,
  });

  /// The tile.
  final DiaryDashboardTile tile;

  /// Its size and mode.
  final DiaryTilePlacement placement;

  /// Normalized diary day.
  final DateTime day;

  /// Whether the dashboard is in edit mode.
  final bool editing;

  /// Whether the tile follows the finger, so its cell shows a gap.
  final bool lifted;

  /// Height of the gap a lifted wide tile leaves.
  final double liftedHeight;

  /// A drag of the tile started.
  final DiaryDashboardPointerCallback onDragStart;

  /// The finger moved during a drag of the tile.
  final DiaryDashboardPointerCallback onDragUpdate;

  /// The drag of the tile ended.
  final VoidCallback onDragEnd;

  /// The finger moved on the resize handle.
  final DiaryDashboardPointerCallback onResizeUpdate;

  /// The finger left the resize handle.
  final VoidCallback onResizeEnd;

  /// The tile menu should open.
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final body = IgnorePointer(
      ignoring: editing,
      child: DiaryDashboardTileBody(tile: tile, placement: placement, day: day),
    );

    // The detector stays while the tile is lifted: it carries the drag.
    return RawGestureDetector(
      key: DiaryDashboardKeys.tile(tile.id),
      gestures: {
        LongPressGestureRecognizer: _dragGesture<LongPressGestureRecognizer>(
          LongPressGestureRecognizer.new,
        ),
        if (editing) ...{
          _QuickHoldRecognizer: _dragGesture<_QuickHoldRecognizer>(
            _QuickHoldRecognizer.new,
          ),
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                TapGestureRecognizer.new,
                (r) => r.onTap = onMenu,
              ),
        },
      },
      child: switch ((lifted, editing)) {
        (true, _) => _Gap(height: placement.size.isWide ? liftedHeight : null),
        (false, false) => body,
        (false, true) => _EditChrome(
          tile: tile,
          wide: placement.size.isWide,
          onMenu: onMenu,
          onResizeUpdate: onResizeUpdate,
          onResizeEnd: onResizeEnd,
          child: body,
        ),
      },
    );
  }

  GestureRecognizerFactoryWithHandlers<T>
  _dragGesture<T extends LongPressGestureRecognizer>(T Function() create) =>
      GestureRecognizerFactoryWithHandlers<T>(
        create,
        (r) => r
          ..onLongPressStart = ((d) => onDragStart(d.globalPosition))
          ..onLongPressMoveUpdate = ((d) => onDragUpdate(d.globalPosition))
          ..onLongPressEnd = ((_) => onDragEnd()),
      );
}

/// The short hold that drags a tile in edit mode.
class _QuickHoldRecognizer extends LongPressGestureRecognizer {
  new() : super(duration: AppDashboard.editDragDelay);
}

/// Grabs the resize handle as soon as the finger lands, before the page
/// can claim the drag as a scroll.
class _GrabRecognizer extends LongPressGestureRecognizer {
  new() : super(duration: AppDashboard.resizeDelay);
}

/// The cell a lifted tile leaves, at [height] for a wide tile.
class _Gap extends StatelessWidget {
  const new({required this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FoodLabelColors.of(context).track,
        borderRadius: BorderRadius.circular(AppDashboard.tileRadius),
      ),
      child: height == null
          ? const SizedBox.expand()
          : SizedBox(width: double.infinity, height: height),
    );
  }
}

/// The outline, the menu button and the resize handle of a tile in edit
/// mode, over the tile.
class _EditChrome extends StatelessWidget {
  const new({
    required this.tile,
    required this.wide,
    required this.onMenu,
    required this.onResizeUpdate,
    required this.onResizeEnd,
    required this.child,
  });

  final DiaryDashboardTile tile;
  final bool wide;
  final VoidCallback onMenu;
  final DiaryDashboardPointerCallback onResizeUpdate;
  final VoidCallback onResizeEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    return Stack(
      fit: wide ? StackFit.loose : StackFit.expand,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDashboard.tileRadius),
                border: Border.all(
                  color: colors.ink,
                  width: AppDashboard.editOutline,
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: 0,
          end: 0,
          child: _EditButton(
            key: DiaryDashboardKeys.menu(tile.id),
            icon: Icons.more_horiz,
            tooltip: l10n.diaryDashboardTileMenu,
            onTap: onMenu,
          ),
        ),
        if (tile.sizes.length > 1)
          PositionedDirectional(
            bottom: 0,
            end: 0,
            child: RawGestureDetector(
              gestures: {
                _GrabRecognizer:
                    GestureRecognizerFactoryWithHandlers<_GrabRecognizer>(
                      _GrabRecognizer.new,
                      (r) => r
                        ..onLongPressMoveUpdate = ((d) =>
                            onResizeUpdate(d.globalPosition))
                        ..onLongPressEnd = ((_) => onResizeEnd()),
                    ),
              },
              child: _EditButton(
                key: DiaryDashboardKeys.resize(tile.id),
                icon: Icons.open_in_full,
                tooltip: l10n.diaryDashboardResizeTile,
                alignment: AlignmentDirectional.bottomEnd,
              ),
            ),
          ),
      ],
    );
  }
}

/// A round button in a corner of a tile in edit mode.
class _EditButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    this.alignment = AlignmentDirectional.topEnd,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final AlignmentDirectional alignment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: AppSizes.minTapTarget,
          child: Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.all(AppDashboard.editButtonInset),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.ink,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: AppDashboard.editButtonSize,
                  child: Icon(
                    icon,
                    size: AppDashboard.editButtonIcon,
                    color: colors.paper,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
