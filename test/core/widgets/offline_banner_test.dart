import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/network_connectivity.dart';
import 'package:yamt/core/widgets/offline_banner.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../helpers/fake_connectivity.dart';

const _pageKey = Key('offline_banner_test_page');
final Finder _strip = find.byKey(OfflineBanner.stripKey);
final Finder _backOnline = find.byKey(OfflineBanner.backOnlineKey);

Future<FakeConnectivity> _pumpApp(
  WidgetTester tester, {
  bool offline = false,
}) async {
  final connectivity = FakeConnectivity(offline: offline);
  addTearDown(connectivity.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [connectivityProvider.overrideWithValue(connectivity)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => OfflineBanner(child: child!),
        home: Scaffold(
          appBar: AppBar(title: const Text('Page')),
          body: const _CounterPage(key: _pageKey),
        ),
      ),
    ),
  );
  await _pumpConnectionChange(tester);
  return connectivity;
}

/// The change reaches the provider in a microtask, the frame comes after it.
Future<void> _pumpConnectionChange(WidgetTester tester) async {
  await tester.pump(connectivitySettleDelay);
  await tester.pump();
}

void main() {
  testWidgets('an online start shows no strip and no snack bar', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.pumpAndSettle();

    expect(_strip, findsNothing);
    expect(_backOnline, findsNothing);
  });

  testWidgets('offline shows the strip, also to screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpApp(tester, offline: true);

    expect(_strip, findsOneWidget);
    // Painted after the app, so the barrier of the page route below does
    // not hide it.
    expect(find.bySemanticsLabel('Offline – no connection'), findsOneWidget);
    expect(_backOnline, findsNothing);
    semantics.dispose();
  });

  testWidgets('the connection coming back hides the strip with "Back online"', (
    tester,
  ) async {
    final connectivity = await _pumpApp(tester, offline: true);

    connectivity.goOnline();
    await _pumpConnectionChange(tester);

    expect(_strip, findsNothing);
    expect(_backOnline, findsOneWidget);
    expect(find.text('Back online'), findsOneWidget);

    // The snack bar goes away by itself.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(_backOnline, findsNothing);
  });

  testWidgets('losing the connection later shows the strip, no snack bar', (
    tester,
  ) async {
    final connectivity = await _pumpApp(tester);

    connectivity.goOffline();
    await _pumpConnectionChange(tester);

    expect(_strip, findsOneWidget);
    expect(_backOnline, findsNothing);

    connectivity.goOnline();
    await _pumpConnectionChange(tester);

    expect(_strip, findsNothing);
    expect(_backOnline, findsOneWidget);
  });

  testWidgets('the strip takes the status bar and the page keeps its state', (
    tester,
  ) async {
    // A status bar of 24 logical pixels.
    tester.view.padding = FakeViewPadding(
      top: 24 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetPadding);
    final connectivity = await _pumpApp(tester);
    await tester.tap(find.byKey(_pageKey));
    await tester.pump();
    final page = tester.state<_CounterPageState>(find.byKey(_pageKey));

    connectivity.goOffline();
    await _pumpConnectionChange(tester);

    final stripRect = tester.getRect(_strip);
    expect(stripRect.top, 0);
    expect(stripRect.bottom, greaterThan(24));
    expect(tester.getRect(find.byType(AppBar)).top, stripRect.bottom);
    expect(tester.state(find.byKey(_pageKey)), same(page));
    expect(find.text('1'), findsOneWidget);

    connectivity.goOnline();
    await _pumpConnectionChange(tester);

    expect(tester.getRect(find.byType(AppBar)).top, 0);
    expect(tester.state(find.byKey(_pageKey)), same(page));
  });
}

/// A page with state of its own: a tap counter.
class _CounterPage extends StatefulWidget {
  const new({super.key});

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  var _count = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _count++),
      child: Center(child: Text('$_count')),
    );
  }
}
