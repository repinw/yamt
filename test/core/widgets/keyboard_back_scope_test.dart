import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/keyboard_back_scope.dart';

import '../../helpers/system_back_test_utils.dart';

const _fieldKey = Key('keyboard_back_scope_test_field');
const _closeKey = Key('keyboard_back_scope_test_close');
const _sheetKey = Key('keyboard_back_scope_test_sheet');
const _formPath = '/form';
const _plainPath = '/plain';
const _guardedPath = '/guarded';

void main() {
  testWidgets('the first back closes the keyboard, the second leaves', (
    tester,
  ) async {
    await _pumpApp(tester, push: _formPath);
    await _type(tester, 'Kantine');

    await pressSystemBack(tester);

    expect(find.byType(_FormPage), findsOneWidget);
    expect(_fieldHasFocus(tester), isFalse);
    expect(_fieldText(tester), 'Kantine');

    await closeTestKeyboard(tester);
    await pressSystemBack(tester);

    expect(find.byType(_FormPage), findsNothing);
  });

  testWidgets('the first back gesture closes the keyboard and keeps the '
      'page in place', (tester) async {
    await _pumpApp(tester, push: _formPath);
    await _type(tester, 'Kantine');
    final route = ModalRoute.of(tester.element(find.byKey(_fieldKey)))!;

    await startSystemBackGesture(tester);
    await updateSystemBackGesture(tester, 0.5);

    // The page does not follow the finger.
    expect(route.animation!.value, 1);

    await endSystemBackGesture(tester);

    expect(find.byType(_FormPage), findsOneWidget);
    expect(_fieldHasFocus(tester), isFalse);
    expect(_fieldText(tester), 'Kantine');

    await closeTestKeyboard(tester);
    await startSystemBackGesture(tester);
    await updateSystemBackGesture(tester, 0.5);

    // The predictive back of the page runs again.
    expect(route.animation!.value, lessThan(1));

    await endSystemBackGesture(tester);

    expect(find.byType(_FormPage), findsNothing);
  });

  testWidgets('a cancelled back gesture keeps the keyboard and lets the page '
      'close later', (tester) async {
    await _pumpApp(tester, push: _formPath);
    await _type(tester, 'Kantine');

    await startSystemBackGesture(tester);
    await endSystemBackGesture(tester, cancel: true);

    expect(find.byType(_FormPage), findsOneWidget);
    expect(_fieldHasFocus(tester), isTrue);

    await tester.tap(find.byKey(_closeKey));
    await tester.pumpAndSettle();

    expect(find.byType(_FormPage), findsNothing);
  });

  testWidgets('a back without a gesture start after a closed keyboard '
      'leaves the page', (tester) async {
    await _pumpApp(tester, push: _formPath);
    await _type(tester, 'Kantine');
    await swipeSystemBack(tester);
    expect(find.byType(_FormPage), findsOneWidget);
    await closeTestKeyboard(tester);

    // The 3-button back commits without starting a gesture.
    await endSystemBackGesture(tester);

    expect(find.byType(_FormPage), findsNothing);
  });

  testWidgets('back closes a popup above the field, not the keyboard', (
    tester,
  ) async {
    await _pumpApp(tester, push: _formPath);
    await _type(tester, 'Kantine');
    showDialog<void>(
      context: tester.element(find.byKey(_fieldKey)),
      requestFocus: false,
      builder: (_) => const AlertDialog(content: Text('popup')),
    );
    await tester.pumpAndSettle();

    await pressSystemBack(tester);

    expect(find.text('popup'), findsNothing);
    expect(_fieldHasFocus(tester), isTrue);
  });

  testWidgets('back leaves a page at once when no field has focus', (
    tester,
  ) async {
    await _pumpApp(tester, push: _formPath);

    await pressSystemBack(tester);

    expect(find.byType(_FormPage), findsNothing);
  });

  testWidgets('back leaves a page at once when the keyboard is already '
      'closed', (tester) async {
    await _pumpApp(tester, push: _formPath);
    await _type(tester, 'Kantine');
    await closeTestKeyboard(tester);

    await swipeSystemBack(tester);

    expect(find.byType(_FormPage), findsNothing);
  });

  testWidgets('the close button still closes the page while typing', (
    tester,
  ) async {
    await _pumpApp(tester, push: _formPath);
    await _type(tester, 'Kantine');

    await tester.tap(find.byKey(_closeKey));
    await tester.pumpAndSettle();

    expect(find.byType(_FormPage), findsNothing);
  });

  testWidgets('a PopScope of the page only hears the second back', (
    tester,
  ) async {
    final pops = await _pumpApp(tester, push: _guardedPath);
    await _type(tester, 'Kantine');

    await pressSystemBack(tester);

    expect(pops, isEmpty);
    expect(_fieldHasFocus(tester), isFalse);

    await closeTestKeyboard(tester);
    await pressSystemBack(tester);

    expect(pops, [false]);
    expect(find.byType(_FormPage), findsOneWidget);
  });

  testWidgets('a page without transition closes the keyboard on the first '
      'back gesture', (tester) async {
    await _pumpApp(tester, push: _plainPath);
    await _type(tester, 'Kantine');

    await swipeSystemBack(tester);

    expect(find.byType(_FormPage), findsOneWidget);
    expect(_fieldHasFocus(tester), isFalse);

    await closeTestKeyboard(tester);
    await swipeSystemBack(tester);

    expect(find.byType(_FormPage), findsNothing);
  });

  testWidgets('a bottom sheet closes its keyboard before it closes', (
    tester,
  ) async {
    await _pumpApp(tester);
    showModalBottomSheet<void>(
      context: tester.element(find.byType(Scaffold)),
      builder: (context) => const Padding(
        key: _sheetKey,
        padding: EdgeInsets.all(16),
        child: TextField(key: _fieldKey),
      ),
    ).ignore();
    await tester.pumpAndSettle();
    await _type(tester, 'Kantine');

    await swipeSystemBack(tester);

    expect(find.byKey(_sheetKey), findsOneWidget);
    expect(_fieldHasFocus(tester), isFalse);

    await closeTestKeyboard(tester);
    await pressSystemBack(tester);

    expect(find.byKey(_sheetKey), findsNothing);
  });

  testWidgets('the iOS swipe back still leaves the page while typing', (
    tester,
  ) async {
    await _pumpApp(tester, push: _formPath);
    await _type(tester, 'Kantine');

    await tester.dragFrom(const Offset(5, 300), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(find.byType(_FormPage), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}

/// Pumps a router app with the scope in the builder above the router, as
/// the app has it, and opens [push] when given. Returns the `didPop` values
/// that the `PopScope` of the guarded page heard.
Future<List<bool>> _pumpApp(WidgetTester tester, {String? push}) async {
  final guardedPops = <bool>[];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(path: _formPath, builder: (context, state) => const _FormPage()),
      // Like the product editor, which opens without transition.
      GoRoute(
        path: _plainPath,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const _FormPage(),
        ),
      ),
      GoRoute(
        path: _guardedPath,
        builder: (context, state) => PopScope<Object?>(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) => guardedPops.add(didPop),
          child: const _FormPage(),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => KeyboardBackScope(child: child!),
    ),
  );
  await tester.pumpAndSettle();
  if (push != null) {
    router.push<void>(push).ignore();
    await tester.pumpAndSettle();
  }
  return guardedPops;
}

/// Types [text] into the field, which opens the keyboard.
Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(_fieldKey), text);
  await openTestKeyboard(tester);
}

EditableText _editable(WidgetTester tester) => tester.widget<EditableText>(
  find.descendant(
    of: find.byKey(_fieldKey),
    matching: find.byType(EditableText),
  ),
);

bool _fieldHasFocus(WidgetTester tester) =>
    _editable(tester).focusNode.hasFocus;

String _fieldText(WidgetTester tester) => _editable(tester).controller.text;

class _FormPage extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          IconButton(
            key: _closeKey,
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
          ),
          const TextField(key: _fieldKey),
        ],
      ),
    );
  }
}
