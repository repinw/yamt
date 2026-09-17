import 'package:material_ui/material_ui.dart';

/// Floating sliver that hosts the shared home top chrome.
class HomeShellTopSliverChrome extends StatelessWidget {
  /// The shell top chrome sliver.
  const new({required this.child, super.key});

  /// The visible app bar.
  final PreferredSizeWidget child;
  @override
  Widget build(BuildContext context) {
    final statusBarInset = MediaQuery.paddingOf(context).top;
    final toolbarHeight = child.preferredSize.height;
    return SliverPersistentHeader(
      floating: true,
      delegate: _HomeShellTopChromeDelegate(
        child: child,
        statusBarInset: statusBarInset,
        toolbarHeight: toolbarHeight,
      ),
    );
  }
}

class _HomeShellTopChromeDelegate extends SliverPersistentHeaderDelegate {
  const new({
    required this.child,
    required this.statusBarInset,
    required this.toolbarHeight,
  });
  final PreferredSizeWidget child;
  final double statusBarInset;
  final double toolbarHeight;
  @override
  double get minExtent => 0;
  @override
  double get maxExtent => statusBarInset + toolbarHeight;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    if (maxExtent <= 0) return const SizedBox.shrink();
    final visibility = ((maxExtent - shrinkOffset) / maxExtent).clamp(0.0, 1.0);
    if (visibility <= 0) return const SizedBox.shrink();
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: maxExtent,
        maxHeight: maxExtent,
        child: Transform.translate(
          offset: Offset(0, -toolbarHeight * (1 - visibility)),
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeShellTopChromeDelegate oldDelegate) =>
      child != oldDelegate.child ||
      statusBarInset != oldDelegate.statusBarInset ||
      toolbarHeight != oldDelegate.toolbarHeight;
}
