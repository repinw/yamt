import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingNavigatorObserver extends NavigatorObserver {
  final pushedRoutes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }

  void clear() {
    pushedRoutes.clear();
  }
}

Widget nestedNavigatorHarness({
  required Widget child,
  required RecordingNavigatorObserver rootObserver,
  required RecordingNavigatorObserver nestedObserver,
  Locale? locale,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale> supportedLocales = const <Locale>[Locale('en')],
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: localizationsDelegates,
    supportedLocales: supportedLocales,
    navigatorObservers: <NavigatorObserver>[rootObserver],
    home: Navigator(
      observers: <NavigatorObserver>[nestedObserver],
      onGenerateRoute: (_) {
        return MaterialPageRoute<void>(builder: (_) => child);
      },
    ),
  );
}

void expectRootPopupRoutePushed({
  required RecordingNavigatorObserver rootObserver,
  required RecordingNavigatorObserver nestedObserver,
}) {
  expect(
    rootObserver.pushedRoutes.whereType<PopupRoute<dynamic>>(),
    isNotEmpty,
  );
  expect(nestedObserver.pushedRoutes.whereType<PopupRoute<dynamic>>(), isEmpty);
}
