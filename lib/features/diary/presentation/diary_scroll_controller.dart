import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const _scrollActionEdgeThreshold = 32.0;
const _jumpToMealsPrimaryDuration = Duration(milliseconds: 520);
const _jumpToMealsFallbackDuration = Duration(milliseconds: 460);
const _jumpToMealsSettleDuration = Duration(milliseconds: 260);
const _jumpToMealsRevealAlignment = 0.04;
const _scrollToTopDuration = Duration(milliseconds: 560);

/// Coordinates diary page scrolling and shortcut visibility.
class DiaryScrollController extends ChangeNotifier {
  /// Creates a diary scroll controller.
  DiaryScrollController() {
    scrollController.addListener(_updateScrollActions);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        _updateScrollActions();
      }
    });
  }

  /// Inner Flutter scroll controller used by the list.
  final ScrollController scrollController = ScrollController();

  /// Key for the meals section jump target.
  final GlobalKey mealsSectionKey = GlobalKey();

  var _disposed = false;
  var _showJumpToMeals = false;
  var _showScrollToTop = false;
  var _isManualScrolling = false;

  /// Whether the shortcut should show the jump-to-meals action.
  bool get showJumpToMeals => _showJumpToMeals;

  /// Whether the shortcut should show the scroll-to-top action.
  bool get showScrollToTop => _showScrollToTop;

  /// Whether the user is currently dragging the diary list.
  bool get isManualScrolling => _isManualScrolling;

  /// Handles vertical scroll notifications from the diary list.
  bool handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _setManualScrolling(true);
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      _setManualScrolling(true);
    } else if (notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle) {
      _setManualScrolling(false);
    } else if (notification is ScrollEndNotification) {
      _setManualScrolling(false);
    }

    return false;
  }

  /// Jumps to the diary meals section, falling back when it is not built yet.
  void scrollToMeals() {
    if (!scrollController.hasClients) {
      return;
    }

    unawaited(_scrollToMealsSection());
  }

  /// Scrolls to the top of the diary list.
  void scrollToTop() {
    if (!scrollController.hasClients) {
      return;
    }

    unawaited(
      scrollController.animateTo(
        0,
        duration: _scrollToTopDuration,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    scrollController
      ..removeListener(_updateScrollActions)
      ..dispose();
    super.dispose();
  }

  void _setManualScrolling(bool value) {
    if (_isManualScrolling == value) {
      return;
    }

    _isManualScrolling = value;
    notifyListeners();
  }

  void _updateScrollActions() {
    if (_disposed || !scrollController.hasClients) {
      return;
    }

    final position = scrollController.position;
    final showJumpToMeals =
        position.maxScrollExtent > 0 &&
        position.pixels <=
            position.minScrollExtent + _scrollActionEdgeThreshold;
    final showScrollToTop =
        position.maxScrollExtent > 0 &&
        position.pixels >=
            position.maxScrollExtent - _scrollActionEdgeThreshold;

    if (_showJumpToMeals == showJumpToMeals &&
        _showScrollToTop == showScrollToTop) {
      return;
    }

    _showJumpToMeals = showJumpToMeals;
    _showScrollToTop = showScrollToTop;
    notifyListeners();
  }

  Future<void> _scrollToMealsSection() async {
    if (!scrollController.hasClients) {
      return;
    }

    final scrolledToExactTarget = await _animateToMealsOffset(
      duration: _jumpToMealsPrimaryDuration,
    );
    if (scrolledToExactTarget || _disposed || !scrollController.hasClients) {
      _updateScrollActions();
      return;
    }

    await scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: _jumpToMealsFallbackDuration,
      curve: Curves.easeOutCubic,
    );
    if (_disposed) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(
        _animateToMealsOffset(duration: _jumpToMealsSettleDuration),
      ),
    );
  }

  Future<bool> _animateToMealsOffset({required Duration duration}) async {
    if (_disposed || !scrollController.hasClients) {
      return false;
    }

    final targetOffset = _offsetForKey(
      mealsSectionKey,
      alignment: _jumpToMealsRevealAlignment,
    );
    if (targetOffset == null) {
      return false;
    }

    final position = scrollController.position;
    await scrollController.animateTo(
      targetOffset.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: duration,
      curve: Curves.easeOutCubic,
    );
    _updateScrollActions();
    return true;
  }

  double? _offsetForKey(GlobalKey key, {double alignment = 0}) {
    final keyContext = key.currentContext;
    final renderObject = keyContext?.findRenderObject();
    if (renderObject == null) {
      return null;
    }

    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    if (viewport == null) {
      return null;
    }

    return viewport.getOffsetToReveal(renderObject, alignment).offset;
  }
}
