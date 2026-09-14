import 'package:flutter/widgets.dart';

/// Manages scroll-driven visibility state for home shell chrome.
class HomeShellChromeVisibilityController extends ValueNotifier<double> {
  /// Creates home shell chrome visibility controller initialized to visible.
  HomeShellChromeVisibilityController() : super(1);

  static const _hideScrollDistance = 320;
  static const _revealScrollDistance = 140;
  static const _snapVisibilityThreshold = 0.5;
  static const _topRevealThreshold = 8;

  /// Current visibility progress between 0 (hidden) and 1 (fully visible).
  double get visibility => value;

  /// Handles scroll notifications to update chrome visibility.
  bool handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical ||
        notification.metrics.maxScrollExtent <=
            notification.metrics.minScrollExtent) {
      return false;
    }

    if (_hasShortScrollRange(notification.metrics)) {
      reveal();
      return false;
    }

    if (notification is ScrollUpdateNotification &&
        notification.scrollDelta != null) {
      _updateFromScrollDelta(notification.scrollDelta!);
    } else if (notification is ScrollEndNotification) {
      _settleAfterScrollEnd(notification.metrics);
    } else if (notification.metrics.pixels <=
        notification.metrics.minScrollExtent + _topRevealThreshold) {
      reveal();
    }

    return false;
  }

  /// Forces shell chrome to be fully revealed.
  void reveal() {
    _setVisibility(1);
  }

  bool _hasShortScrollRange(ScrollMetrics metrics) {
    return metrics.maxScrollExtent - metrics.minScrollExtent <
        _hideScrollDistance;
  }

  void _settleAfterScrollEnd(ScrollMetrics metrics) {
    if (metrics.pixels <= metrics.minScrollExtent + _topRevealThreshold) {
      reveal();
      return;
    }

    _setVisibility(visibility >= _snapVisibilityThreshold ? 1 : 0);
  }

  void _updateFromScrollDelta(double scrollDelta) {
    if (scrollDelta == 0) {
      return;
    }

    final scrollDistance = scrollDelta > 0
        ? _hideScrollDistance
        : _revealScrollDistance;
    final nextVisibility = (visibility - (scrollDelta / scrollDistance)).clamp(
      0.0,
      1.0,
    );
    _setVisibility(nextVisibility);
  }

  void _setVisibility(double value) {
    final targetVisibility = value.clamp(0.0, 1.0);
    if ((visibility - targetVisibility).abs() < 0.001) {
      return;
    }

    this.value = targetVisibility;
  }
}
