import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

const _shellChromeMotionDuration = Duration(milliseconds: 220);

/// Collapses and fades the shared home bottom chrome.
class HomeShellBottomChrome extends StatelessWidget {
  /// The shell bottom chrome transition.
  const new({required this.child, required this.visibility, super.key});

  /// The visible bottom chrome.
  final Widget child;

  /// How much chrome is visible, from 0 to 1.
  final double visibility;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(end: visibility.clamp(0.0, 1.0)),
    duration: _shellChromeMotionDuration,
    curve: Curves.easeOutCubic,
    child: child,
    builder: (context, effectiveVisibility, chromeChild) => IgnorePointer(
      ignoring: effectiveVisibility < 0.05,
      child: Opacity(
        opacity: effectiveVisibility,
        child: Transform.translate(
          offset: Offset(
            0,
            AppSizes.homeShellBottomBarClearance * (1 - effectiveVisibility),
          ),
          child: chromeChild,
        ),
      ),
    ),
  );
}
