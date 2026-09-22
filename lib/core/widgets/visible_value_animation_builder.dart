import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/content_visibility.dart';
import 'package:yamt/core/widgets/value_animation_handoff.dart';

/// Animates from zero to [value] and from each old value to the next one,
/// like a [TweenAnimationBuilder], but only while the user can see it.
///
/// A change that arrives while another route covers this one, while its tab
/// is hidden, or while [ContentVisibility] is false waits and plays once the
/// widget is visible again. Without this, a value that changes behind a sheet
/// or page, for example after an entry is deleted there, would finish
/// animating unseen.
class VisibleValueAnimationBuilder extends StatefulWidget {
  /// Creates the builder.
  const new({
    required this.value,
    required this.duration,
    required this.curve,
    required this.builder,
    this.handoffTag,
    this.child,
    super.key,
  });

  /// Value to animate to.
  final double value;

  /// Duration of each animation.
  final Duration duration;

  /// Curve of each animation.
  final Curve curve;

  /// Builds the widget for the current animated value.
  final ValueWidgetBuilder<double> builder;

  /// Tag under which this builder hands the value it shows to the next
  /// visible builder with the same tag in the same
  /// [ValueAnimationHandoffScope]. A hidden builder shows the handed value
  /// and animates from it once visible.
  final Object? handoffTag;

  /// Passed to [builder] unchanged.
  final Widget? child;

  @override
  State<VisibleValueAnimationBuilder> createState() =>
      _VisibleValueAnimationBuilderState();
}

class _VisibleValueAnimationBuilderState
    extends State<VisibleValueAnimationBuilder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addListener(_recordShownValue);
  final Tween<double> _tween = Tween<double>(begin: 0, end: 0);
  late final Animation<double> _animation = _tween.animate(
    CurvedAnimation(parent: _controller, curve: widget.curve),
  );
  ValueAnimationHandoff? _handoff;
  var _isHandoffUpdateScheduled = false;

  /// Null until the first dependencies are known.
  bool? _isVisible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listenToHandoff(ValueAnimationHandoffScope.maybeOf(context));
    final isVisible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true) &&
        ContentVisibility.of(context);
    if (isVisible == _isVisible) {
      return;
    }
    _isVisible = isVisible;
    final start = _handedOffValue ?? _animation.value;
    if (isVisible) {
      _animateFrom(start);
    } else {
      _holdAt(start);
    }
  }

  @override
  void didUpdateWidget(VisibleValueAnimationBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    // A hidden builder catches up once it is visible again.
    if (widget.value != oldWidget.value && (_isVisible ?? false)) {
      _animateFrom(_animation.value);
    }
  }

  @override
  void dispose() {
    _listenToHandoff(null);
    _controller.dispose();
    super.dispose();
  }

  double? get _handedOffValue {
    final tag = widget.handoffTag;
    return tag == null ? null : _handoff?.valueOf(tag);
  }

  void _listenToHandoff(ValueAnimationHandoff? handoff) {
    final tag = widget.handoffTag;
    if (handoff == _handoff || tag == null) {
      _handoff = handoff;
      return;
    }
    _handoff?.removeListener(tag, _followHandoff);
    _handoff = handoff?..addListener(tag, _followHandoff);
  }

  /// Keeps a hidden builder at the value the visible one shows. The update
  /// waits for the next frame, since the visible builder may record while
  /// widgets build.
  void _followHandoff() {
    if ((_isVisible ?? true) || _isHandoffUpdateScheduled) {
      return;
    }
    _isHandoffUpdateScheduled = true;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        _isHandoffUpdateScheduled = false;
        final value = _handedOffValue;
        if (mounted && !(_isVisible ?? true) && value != null) {
          setState(() => _holdAt(value));
        }
      })
      ..ensureVisualUpdate();
  }

  void _recordShownValue() {
    final tag = widget.handoffTag;
    if ((_isVisible ?? false) && tag != null) {
      _handoff?.record(tag, _animation.value);
    }
  }

  void _animateFrom(double from) {
    _tween
      ..begin = from
      ..end = widget.value;
    _controller.forward(from: 0);
  }

  void _holdAt(double value) {
    _controller.stop();
    _tween
      ..begin = value
      ..end = value;
    _controller.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) =>
          widget.builder(context, _animation.value, child),
      child: widget.child,
    );
  }
}
