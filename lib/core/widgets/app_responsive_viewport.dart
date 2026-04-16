import 'package:flutter/widgets.dart';

/// Caps aggressive platform text scaling so dense mobile layouts stay usable.
class AppResponsiveViewport extends StatelessWidget {
  /// Creates the responsive viewport wrapper.
  const AppResponsiveViewport({required this.child, super.key});

  /// The wrapped subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: child,
    );
  }
}
