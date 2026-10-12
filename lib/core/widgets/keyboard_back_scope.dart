import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Lets the system back close an open keyboard before it leaves a page.
///
/// Android hands the back gesture to the app even while the keyboard is open,
/// so the page closed and lost the typed text. While a text field has focus
/// and the keyboard shows, the first back only takes the focus away, which
/// closes the keyboard; the next back leaves the page, sheet, or dialog as
/// usual. Close buttons and the `PopScope`s of pages stay untouched, and so
/// does the iOS swipe back, because nothing holds a route between gestures.
///
/// It must sit above the router, in `MaterialApp.router(builder:)`: the
/// binding asks its observers in the order they were added, so this scope
/// hears the back before the router pops a route and before the predictive
/// back of a page starts to slide it away.
class KeyboardBackScope extends StatefulWidget {
  /// Creates a keyboard back scope around [child].
  const new({required this.child, super.key});

  /// App content below the scope.
  final Widget child;

  @override
  State<KeyboardBackScope> createState() => _KeyboardBackScopeState();
}

class _KeyboardBackScopeState extends State<KeyboardBackScope>
    with WidgetsBindingObserver {
  final _noPop = _NoPopEntry();
  ModalRoute<Object?>? _heldRoute;
  bool _gestureTaken = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _release();
    _noPop.canPopNotifier.dispose();
    super.dispose();
  }

  /// The focused text field while the keyboard is open, otherwise null.
  BuildContext? _typingField() {
    if (MediaQuery.viewInsetsOf(context).bottom <= 0) return null;
    final field = FocusManager.instance.primaryFocus?.context;
    if (field?.findAncestorWidgetOfExactType<EditableText>() == null) {
      return null;
    }
    // A field below a route that took no focus, such as a popup, leaves the
    // back to that route.
    if (!(ModalRoute.of(field!)?.isCurrent ?? false)) return null;
    return field;
  }

  void _closeKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  void _release() {
    final route = _heldRoute;
    if (route != null && route.isActive) route.unregisterPopEntry(_noPop);
    _heldRoute = null;
  }

  // A back button, or a back gesture that no page took.
  @override
  Future<bool> didPopRoute() async {
    if (_typingField() == null) return false;
    _closeKeyboard();
    return true;
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    _release();
    _gestureTaken = false;
    final field = _typingField();
    if (field == null) return false;
    _gestureTaken = true;
    // A held route cannot pop, so the predictive back of the page, which
    // the binding asks after this scope, leaves it in place.
    _heldRoute = ModalRoute.of(field)?..registerPopEntry(_noPop);
    return true;
  }

  @override
  void handleCommitBackGesture() {
    final taken = _gestureTaken;
    _gestureTaken = false;
    _release();
    if (taken || _typingField() != null) {
      _closeKeyboard();
      return;
    }
    // The binding keeps the observers of the last gesture until the next
    // one starts, so a back that commits without a start of its own, such
    // as the 3-button back, lands here too. Hand it to the router below as
    // the plain back it is.
    BackButtonDispatcher? dispatcher;
    void findRouter(Element element) {
      if (dispatcher != null) return;
      if (element.widget case Router(:final backButtonDispatcher?)) {
        dispatcher = backButtonDispatcher;
        return;
      }
      element.visitChildElements(findRouter);
    }

    context.visitChildElements(findRouter);
    unawaited(dispatcher?.invokeCallback(Future<bool>.value(false)));
  }

  @override
  void handleCancelBackGesture() {
    _gestureTaken = false;
    _release();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Keeps the route it is registered with from popping.
class _NoPopEntry extends PopEntry<Object?> {
  @override
  final ValueNotifier<bool> canPopNotifier = ValueNotifier(false);
}
