import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// Lays out the diary header: the leading tools, the trailing tools and the
/// day with its arrows.
///
/// Both sides get the same width, so the day stays centered: the natural
/// width of the widest tool, with the reference widgets, which are laid out
/// but never shown. The day sits in one row between the sides when [dayWidth]
/// fits there, else in a second row of the full width below the tools.
/// The sides and [dayWidth] do not depend on the selected day, so the choice
/// never flips while the user swipes through the days.
class DiaryHeaderLayout extends MultiChildRenderObjectWidget {
  /// Creates the header layout.
  new({
    required Widget leading,
    required Widget trailing,
    required Widget day,
    required this.dayWidth,
    List<Widget> references = const <Widget>[],
    super.key,
  }) : super(
         children: [
           leading,
           trailing,
           day,
           for (final reference in references)
             _MeasureOnly(child: ExcludeFocus(child: reference)),
         ],
       );

  /// Least width that the day needs to stay in one row between the sides.
  final double dayWidth;

  @override
  RenderBox createRenderObject(BuildContext context) =>
      _RenderDiaryHeader(dayWidth);

  @override
  void updateRenderObject(BuildContext context, RenderBox renderObject) {
    (renderObject as _RenderDiaryHeader).dayWidth = dayWidth;
  }
}

/// A child that takes part in the layout but is never painted, hit-tested,
/// read by accessibility, or found by widget tests.
class _MeasureOnly extends SingleChildRenderObjectWidget {
  const new({required super.child});

  @override
  SingleChildRenderObjectElement createElement() => _MeasureOnlyElement(this);

  @override
  RenderBox createRenderObject(BuildContext context) => _RenderMeasureOnly();
}

class _MeasureOnlyElement extends SingleChildRenderObjectElement {
  new(_MeasureOnly super.widget);

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {}
}

class _RenderMeasureOnly extends RenderProxyBox {
  @override
  void paint(PaintingContext context, Offset offset) {}

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {}
}

typedef _Measure = Size Function(RenderBox child, BoxConstraints constraints);

class _Arrangement {
  const new({
    required this.size,
    required this.leading,
    required this.trailing,
    required this.day,
  });

  final Size size;
  final Offset leading;
  final Offset trailing;
  final Offset day;
}

class _RenderDiaryHeader extends RenderBox
    with
        ContainerRenderObjectMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        >,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        > {
  new(this._dayWidth);

  double _dayWidth;

  double get dayWidth => _dayWidth;

  set dayWidth(double value) {
    if (value != _dayWidth) {
      _dayWidth = value;
      markNeedsLayout();
    }
  }

  RenderBox get _leading => firstChild!;
  RenderBox get _trailing => childAfter(_leading)!;
  RenderBox get _day => childAfter(_trailing)!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ContainerBoxParentData<RenderBox>) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _arrange(constraints, ChildLayoutHelper.dryLayoutChild).size;

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => null;

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => null;

  @override
  double computeMinIntrinsicWidth(double height) {
    final sides = _sides(_intrinsicSize);
    return sides.leading.width + sides.trailing.width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) =>
      2 * _sides(_intrinsicSize).width + _dayWidth;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _arrange(BoxConstraints(maxWidth: width), _intrinsicSize).size.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  Size _intrinsicSize(RenderBox child, BoxConstraints constraints) {
    final width = constraints.hasTightWidth
        ? constraints.maxWidth
        : child.getMaxIntrinsicWidth(double.infinity);
    return Size(width, child.getMaxIntrinsicHeight(width));
  }

  @override
  void performLayout() {
    final arrangement = _arrange(constraints, ChildLayoutHelper.layoutChild);
    _offsetOf(_leading).offset = arrangement.leading;
    _offsetOf(_trailing).offset = arrangement.trailing;
    _offsetOf(_day).offset = arrangement.day;
    size = arrangement.size;
  }

  ContainerBoxParentData<RenderBox> _offsetOf(RenderBox child) =>
      child.parentData! as ContainerBoxParentData<RenderBox>;

  /// The sizes of the two tool groups and the widest side and tallest tool
  /// row over them and the reference children.
  ({Size leading, Size trailing, double width, double height}) _sides(
    _Measure measure,
  ) {
    const natural = BoxConstraints();
    final leading = measure(_leading, natural);
    final trailing = measure(_trailing, natural);
    var width = math.max(leading.width, trailing.width);
    var height = math.max(leading.height, trailing.height);
    for (
      var child = childAfter(_day);
      child != null;
      child = childAfter(child)
    ) {
      final reference = measure(child, natural);
      width = math.max(width, reference.width);
      height = math.max(height, reference.height);
    }
    return (leading: leading, trailing: trailing, width: width, height: height);
  }

  _Arrangement _arrange(BoxConstraints constraints, _Measure measure) {
    final sides = _sides(measure);
    final side = sides.width;
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : 2 * side + _dayWidth;
    final oneRow = width >= 2 * side + _dayWidth;
    final dayArea = oneRow ? width - 2 * side : width;
    final day = measure(_day, BoxConstraints.tightFor(width: dayArea));
    final height = oneRow
        ? math.max(sides.height, day.height)
        : sides.height + day.height;
    final toolsCenter = (oneRow ? height : sides.height) / 2;
    return _Arrangement(
      size: constraints.constrain(Size(width, height)),
      leading: Offset(0, toolsCenter - sides.leading.height / 2),
      trailing: Offset(
        width - sides.trailing.width,
        toolsCenter - sides.trailing.height / 2,
      ),
      day: oneRow
          ? Offset(side, (height - day.height) / 2)
          : Offset(0, sides.height),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
