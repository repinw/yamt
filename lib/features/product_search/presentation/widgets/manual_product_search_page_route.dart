import 'package:flutter/material.dart';

/// Material route without transition animations for nested manual product
/// flows.
class ManualProductNoAnimationMaterialPageRoute<T>
    extends MaterialPageRoute<T> {
  /// Creates a route that skips transition animations.
  ManualProductNoAnimationMaterialPageRoute({
    required super.builder,
    super.fullscreenDialog,
  });

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
