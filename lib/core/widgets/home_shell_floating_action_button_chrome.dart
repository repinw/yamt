import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_sizes.dart';

const _shellChromeMotionDuration = Duration(milliseconds: 220);

/// Moves the home floating action button with the shared bottom chrome.
class HomeShellFloatingActionButtonChrome extends StatelessWidget {
  /// The shell floating action button transition.
  const new({required this.child, required this.visibility, super.key});

  /// The visible floating action button.
  final Widget child;

  /// How much bottom chrome is visible, from 0 to 1.
  final double visibility;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(end: visibility.clamp(0.0, 1.0)),
    duration: _shellChromeMotionDuration,
    curve: Curves.easeOutCubic,
    child: child,
    builder: (context, effectiveVisibility, fabChild) => Padding(
      padding: EdgeInsets.only(
        bottom: AppSizes.homeShellBottomBarClearance * effectiveVisibility,
      ),
      child: fabChild,
    ),
  );
}
