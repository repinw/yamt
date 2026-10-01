import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';

/// Bare vertical scroll wheel used by the onboarding pickers.
///
/// It reports a selection only once the user moves the wheel, so a picker that
/// the user never touched still counts as unset. A new [selectedIndex] from the
/// parent moves the wheel without a report: the parent already knows the value,
/// and a report during that build would change its state mid-build.
class IntroWheel extends StatefulWidget {
  /// Creates a scroll wheel.
  const new({
    required this.itemCount,
    required this.selectedIndex,
    required this.labelBuilder,
    required this.onSelected,
    super.key,
  });

  /// Number of selectable items.
  final int itemCount;

  /// Index the wheel shows.
  final int selectedIndex;

  /// Builds the label of one item.
  final String Function(int index) labelBuilder;

  /// Called with the index the wheel settles on.
  final ValueChanged<int> onSelected;

  @override
  State<IntroWheel> createState() => _IntroWheelState();
}

class _IntroWheelState extends State<IntroWheel> {
  late FixedExtentScrollController _controller;

  /// Whether the wheel is jumping to a [IntroWheel.selectedIndex] from the
  /// parent, which must not be reported back.
  bool _isSyncing = false;

  int get _safeIndex => widget.selectedIndex.clamp(0, widget.itemCount - 1);

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: _safeIndex);
  }

  @override
  void didUpdateWidget(IntroWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.hasClients && _controller.selectedItem != _safeIndex) {
      _isSyncing = true;
      try {
        _controller.jumpToItem(_safeIndex);
      } finally {
        _isSyncing = false;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSelected(int index) {
    if (_isSyncing) {
      return;
    }
    AppHapticFeedback.selectionClick();
    widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: constraints.hasBoundedHeight
            ? constraints.maxHeight
            : AppIntroLayout.wheelHeight,
        child: ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: AppIntroLayout.wheelItemExtent,
          physics: const FixedExtentScrollPhysics(),
          diameterRatio: AppIntroLayout.wheelDiameterRatio,
          overAndUnderCenterOpacity: AppIntroLayout.wheelOffCenterOpacity,
          onSelectedItemChanged: _handleSelected,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: widget.itemCount,
            builder: (context, index) => Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.labelBuilder(index),
                  maxLines: 1,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
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
