import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sheet_constants.dart';

/// Page that shows its child as a bottom sheet on a transparent page route.
///
/// Unlike a modal bottom sheet route, this is a [PageRoute], so [Hero]
/// widgets fly between the page below and the sheet. The sheet fades and
/// slides in while the hero lands, and a downward drag closes it.
class HeroSheetPage<T> extends Page<T> {
  /// Creates a hero sheet page.
  const new({required this.child, super.key});

  /// Sheet content. It positions itself, usually at the bottom.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _HeroSheetRoute<T>(page: this);
}

class _HeroSheetRoute<T> extends PageRoute<T> {
  new({required HeroSheetPage<T> page}) : super(settings: page);

  HeroSheetPage<T> get _page => settings as HeroSheetPage<T>;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor {
    final context = navigator?.context;
    if (context == null) {
      return null;
    }
    return Theme.of(context).colorScheme.scrim
        .withValues(alpha: AppOpacities.modalBarrier);
  }

  @override
  String? get barrierLabel {
    final context = navigator?.context;
    if (context == null) {
      return null;
    }
    return MaterialLocalizations.of(context).modalBarrierDismissLabel;
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => AppSheetTokens.heroSheetTransition;

  @override
  Duration get reverseTransitionDuration =>
      AppSheetTokens.heroSheetReverseTransition;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _DragToDismiss(child: _page.child);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, AppSheetTokens.heroSheetEntranceOffset),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Moves the sheet with a downward drag and pops the route on release when
/// the drag went far or fast enough.
class _DragToDismiss extends StatefulWidget {
  const new({required this.child});

  final Widget child;

  @override
  State<_DragToDismiss> createState() => _DragToDismissState();
}

class _DragToDismissState extends State<_DragToDismiss>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: AppSheetTokens.dragSettle,
  )..addListener(_onSettleTick);
  double _dragOffset = 0;
  double _settleFrom = 0;

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _onSettleTick() {
    setState(() {
      _dragOffset =
          _settleFrom * (1 - Curves.easeOutCubic.transform(_settle.value));
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _settle.stop();
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0, double.infinity);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final height = context.size?.height ?? 0;
    final velocity = details.primaryVelocity ?? 0;
    final shouldDismiss =
        velocity > AppSheetTokens.dismissFlingVelocity ||
        _dragOffset > height * AppSheetTokens.dismissDragFraction;
    if (!shouldDismiss) {
      _settleBack();
      return;
    }
    unawaited(_dismiss());
  }

  Future<void> _dismiss() async {
    final route = ModalRoute.of(context);
    await Navigator.of(context).maybePop();
    // PopScope may keep the route open; then return the sheet to its place.
    if (mounted && (route?.isCurrent ?? false)) {
      _settleBack();
    }
  }

  void _settleBack() {
    _settleFrom = _dragOffset;
    _settle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: widget.child,
      ),
    );
  }
}
