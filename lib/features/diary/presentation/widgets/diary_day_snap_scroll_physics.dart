import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Snaps diary calendar flings to exact day boundaries.
class DiaryDaySnapScrollPhysics extends ClampingScrollPhysics {
  /// Creates day snap scroll physics.
  const DiaryDaySnapScrollPhysics({
    required this.itemExtent,
    super.parent,
  });

  /// Width of one day item.
  final double itemExtent;

  @override
  DiaryDaySnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return DiaryDaySnapScrollPhysics(
      itemExtent: itemExtent,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (itemExtent <= 0 || position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    if (velocity.abs() > tolerance.velocity) {
      return DiaryDayCoastThenSnapSimulation(
        start: position.pixels,
        velocity: velocity,
        itemExtent: itemExtent,
        minScrollExtent: position.minScrollExtent,
        maxScrollExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
    }

    final target = _nearestSnapPixels(position.pixels, position);
    final distance = (target - position.pixels).abs();
    if (distance < tolerance.distance) {
      return null;
    }

    return DiaryDaySnapSimulation(
      start: position.pixels,
      end: target,
      itemExtent: itemExtent,
    );
  }

  double _nearestSnapPixels(double pixels, ScrollMetrics position) {
    final targetIndex = (pixels / itemExtent).round();
    return (targetIndex * itemExtent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }
}

/// Animates from the current offset to the nearest day boundary.
class DiaryDaySnapSimulation extends Simulation {
  /// Creates a day snap simulation.
  DiaryDaySnapSimulation({
    required this.start,
    required this.end,
    required double itemExtent,
  }) : duration = _resolveDuration(
         distance: (end - start).abs(),
         itemExtent: itemExtent,
       );

  /// Start offset.
  final double start;

  /// End offset.
  final double end;

  /// Animation duration in seconds.
  final double duration;

  @override
  double x(double time) {
    if (time >= duration) {
      return end;
    }

    final t = (time / duration).clamp(0.0, 1.0);
    final eased = 1 - math.pow(1 - t, 3);
    return start + ((end - start) * eased);
  }

  @override
  double dx(double time) {
    if (time >= duration) {
      return 0;
    }

    final t = (time / duration).clamp(0.0, 1.0);
    return (end - start) * 3 * math.pow(1 - t, 2) / duration;
  }

  @override
  bool isDone(double time) => time >= duration;

  static double _resolveDuration({
    required double distance,
    required double itemExtent,
  }) {
    if (distance == 0) {
      return 0.001;
    }

    final pages = itemExtent <= 0 ? 1.0 : distance / itemExtent;
    final pageDuration = 0.18 + (math.min(pages, 12) * 0.024);
    return pageDuration.clamp(0.16, 0.46);
  }
}

/// Lets a fling coast, then snaps the final offset to a day boundary.
class DiaryDayCoastThenSnapSimulation extends Simulation {
  /// Creates a coast-then-snap day simulation.
  DiaryDayCoastThenSnapSimulation({
    required double start,
    required double velocity,
    required this.itemExtent,
    required this.minScrollExtent,
    required this.maxScrollExtent,
    required Tolerance tolerance,
  }) : _coast = ClampingScrollSimulation(
         position: start,
         velocity: velocity,
         tolerance: tolerance,
       ) {
    _coastDuration = _resolveCoastDuration(_coast);
    _snapStart = _clampPixels(_coast.x(_coastDuration));
    _snapEnd = _nearestSnapPixels(_snapStart);
    _snapDuration = DiaryDaySnapSimulation._resolveDuration(
      distance: (_snapEnd - _snapStart).abs(),
      itemExtent: itemExtent,
    );
  }

  /// Width of one day item.
  final double itemExtent;

  /// Minimum scroll offset.
  final double minScrollExtent;

  /// Maximum scroll offset.
  final double maxScrollExtent;
  final ClampingScrollSimulation _coast;

  late final double _coastDuration;
  late final double _snapStart;
  late final double _snapEnd;
  late final double _snapDuration;

  double get _duration => _coastDuration + _snapDuration;

  @override
  double x(double time) {
    if (time < _coastDuration) {
      return _clampPixels(_coast.x(time));
    }
    if (time >= _duration) {
      return _snapEnd;
    }

    final t = ((time - _coastDuration) / _snapDuration).clamp(0.0, 1.0);
    final eased = 1 - math.pow(1 - t, 3);
    return _snapStart + ((_snapEnd - _snapStart) * eased);
  }

  @override
  double dx(double time) {
    if (time < _coastDuration) {
      return _coast.dx(time);
    }
    if (time >= _duration) {
      return 0;
    }

    final t = ((time - _coastDuration) / _snapDuration).clamp(0.0, 1.0);
    return (_snapEnd - _snapStart) * 3 * math.pow(1 - t, 2) / _snapDuration;
  }

  @override
  bool isDone(double time) => time >= _duration;

  double _clampPixels(double pixels) {
    return pixels.clamp(minScrollExtent, maxScrollExtent);
  }

  double _nearestSnapPixels(double pixels) {
    final targetIndex = (pixels / itemExtent).round();
    return (targetIndex * itemExtent).clamp(minScrollExtent, maxScrollExtent);
  }

  static double _resolveCoastDuration(Simulation simulation) {
    var time = 0.0;
    while (time < 4 && !simulation.isDone(time)) {
      time += 1 / 60;
    }
    return time;
  }
}
