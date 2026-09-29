import 'package:material_ui/material_ui.dart';

/// Sliver that hosts the shared home top chrome. A [pinned] header stays put
/// while the tab scrolls below it; otherwise it scrolls away with the
/// content, and the tab puts a [HomeShellStatusBarSliver] first so the
/// content never slides under the status bar.
class HomeShellTopSliverChrome extends StatelessWidget {
  /// The shell top chrome sliver.
  const new({required this.child, this.pinned = true, super.key});

  /// The visible app bar.
  final PreferredSizeWidget child;

  /// Whether the header stays at the top while scrolling.
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    if (!pinned) {
      return SliverToBoxAdapter(
        child: ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: SizedBox(height: child.preferredSize.height, child: child),
          ),
        ),
      );
    }
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

/// Pinned strip behind the status bar, for a tab whose header scrolls away.
class HomeShellStatusBarSliver extends StatelessWidget {
  /// Creates the strip.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeShellPinnedSliver(
      height: MediaQuery.paddingOf(context).top,
      child: const SizedBox.expand(),
    );
  }
}

/// Pinned sliver of a fixed [height] on the page background, such as a
/// search row that stays under the status bar while the list scrolls.
class HomeShellPinnedSliver extends StatelessWidget {
  /// Creates the sliver.
  const new({required this.height, required this.child, super.key});

  /// Height of the sliver.
  final double height;

  /// Content of the sliver.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HomeShellFixedDelegate(
        extent: height,
        background: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      ),
    );
  }
}

class _HomeShellFixedDelegate extends SliverPersistentHeaderDelegate {
  const new({
    required this.child,
    required this.extent,
    required this.background,
  });
  final Widget child;
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
    // The header takes the height of its child, so the box fills it.
    return SizedBox(
      height: extent,
      child: ColoredBox(color: background, child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeShellFixedDelegate oldDelegate) =>
      child != oldDelegate.child ||
      extent != oldDelegate.extent ||
      background != oldDelegate.background;
}
