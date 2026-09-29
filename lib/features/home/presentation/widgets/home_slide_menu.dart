import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows [menu] behind the home shell: opening slides [child] aside, shrinks
/// it to a rounded card, and leaves a faded card behind it.
///
/// The page moves to the right, or to the left when [fromEnd] is set, so the
/// menu shows on the side it belongs to.
///
/// Tapping the card, the system back gesture, or [onClose] closes the menu.
class HomeSlideMenu extends StatefulWidget {
  /// Creates the slide menu.
  const new({
    required this.isOpen,
    required this.onClose,
    required this.menu,
    required this.child,
    this.fromEnd = false,
    super.key,
  });

  /// Whether the menu opens on the right side.
  final bool fromEnd;

  /// Whether the menu is open.
  final bool isOpen;

  /// Called when the user closes the menu.
  final VoidCallback onClose;

  /// The menu behind the page.
  final Widget menu;

  /// The home shell.
  final Widget child;

  @override
  State<HomeSlideMenu> createState() => _HomeSlideMenuState();
}

class _HomeSlideMenuState extends State<HomeSlideMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.homeSlideMenu,
    value: widget.isOpen ? 1 : 0,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void didUpdateWidget(HomeSlideMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen == oldWidget.isOpen) {
      return;
    }
    if (widget.isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !widget.isOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          widget.onClose();
        }
      },
      child: Material(
        color: colors.surfaceContainer,
        child: AnimatedBuilder(
          animation: _progress,
          child: widget.child,
          builder: (context, child) {
            final progress = _progress.value;
            final isClosed = progress == 0;
            final size = MediaQuery.sizeOf(context);
            // Share of the width left of the card; the end side mirrors it.
            double left(double share, double scale) => widget.fromEnd
                ? size.width * (1 - share - scale)
                : size.width * share;
            return Stack(
              children: [
                // The menu leaves the tree while closed, so it neither builds
                // nor shows up for assistive technology.
                Positioned.fill(
                  child: isClosed
                      ? const SizedBox.shrink()
                      : Opacity(opacity: progress, child: widget.menu),
                ),
                _SlidCard(
                  progress: progress,
                  left: left(
                    AppSizes.homeSlideMenuGhostLeft,
                    AppSizes.homeSlideMenuGhostScale,
                  ),
                  top: size.height * AppSizes.homeSlideMenuGhostTop,
                  scale: AppSizes.homeSlideMenuGhostScale,
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: colors.surfaceContainerHighest.withValues(
                        alpha: AppOpacities.homeSlideMenuGhost * progress,
                      ),
                    ),
                  ),
                ),
                _SlidCard(
                  progress: progress,
                  left: left(
                    AppSizes.homeSlideMenuPageLeft,
                    AppSizes.homeSlideMenuPageScale,
                  ),
                  top: size.height * AppSizes.homeSlideMenuPageTop,
                  scale: AppSizes.homeSlideMenuPageScale,
                  shadowColor: colors.shadow.withValues(
                    alpha: AppOpacities.homeSlideMenuPageShadow * progress,
                  ),
                  child: Stack(
                    children: [
                      child!,
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: isClosed,
                          child: Semantics(
                            button: true,
                            label: l10n.homeMenuClose,
                            excludeSemantics: true,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: widget.onClose,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Moves [child] towards [left] and [top] and shrinks it to [scale] as
/// [progress] runs from 0 to 1.
class _SlidCard extends StatelessWidget {
  const new({
    required this.progress,
    required this.left,
    required this.top,
    required this.scale,
    required this.child,
    this.shadowColor,
  });

  final double progress;
  final double left;
  final double top;
  final double scale;
  final Color? shadowColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      AppSizes.homeSlideMenuPageRadius * progress,
    );
    final shadowColor = this.shadowColor;
    final currentScale = 1 - (1 - scale) * progress;
    return Positioned.fill(
      child: Transform(
        transform: Matrix4.translationValues(left * progress, top * progress, 0)
          ..scaleByDouble(currentScale, currentScale, 1, 1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: shadowColor == null
                ? null
                : [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: AppSizes.homeSlideMenuPageShadowBlur,
                      offset: const Offset(
                        0,
                        AppSizes.homeSlideMenuPageShadowOffset,
                      ),
                    ),
                  ],
          ),
          child: ClipRRect(borderRadius: radius, child: child),
        ),
      ),
    );
  }
}
