import 'package:material_ui/material_ui.dart';

/// Pinned sliver that hosts the shared home top chrome. The header stays
/// put while the tab scrolls below it.
class HomeShellTopSliverChrome extends StatelessWidget {
  /// The shell top chrome sliver.
  const new({required this.child, super.key});

  /// The visible app bar.
  final PreferredSizeWidget child;
  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HomeShellTopChromeDelegate(
        child: child,
        extent: MediaQuery.paddingOf(context).top + child.preferredSize.height,
        background: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }
}

class _HomeShellTopChromeDelegate extends SliverPersistentHeaderDelegate {
  const new({
    required this.child,
    required this.extent,
    required this.background,
  });
  final PreferredSizeWidget child;
  final double extent;
  final Color background;
  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    if (extent <= 0) return const SizedBox.shrink();
    return ColoredBox(color: background, child: child);
  }

  @override
  bool shouldRebuild(covariant _HomeShellTopChromeDelegate oldDelegate) =>
      child != oldDelegate.child ||
      extent != oldDelegate.extent ||
      background != oldDelegate.background;
}
