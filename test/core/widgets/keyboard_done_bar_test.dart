import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/keyboard_done_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _doneKey = Key('keyboard_done_bar_button');
const _numberFieldKey = Key('number-field');
const _textFieldKey = Key('text-field');

void main() {
  testWidgets('iOS number field shows the bar and Done closes the keyboard', (
    tester,
  ) async {
    await _pumpHarness(tester);

    await tester.tap(find.byKey(_numberFieldKey));
    await tester.pump();

    expect(find.byKey(_doneKey), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.byKey(_doneKey));
    await tester.pump();

    expect(_hasFocus(tester, _numberFieldKey), isFalse);
    expect(find.byKey(_doneKey), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('iOS number field lifts the page above the bar', (tester) async {
    await _pumpHarness(tester);
    final keyboardHeight = MediaQuery.viewInsetsOf(
      tester.element(find.byType(KeyboardDoneBar)),
    ).bottom;

    await tester.tap(find.byKey(_numberFieldKey));
    await tester.pump();

    final pageInset = MediaQuery.viewInsetsOf(
      tester.element(find.byType(Scaffold)),
    ).bottom;
    expect(pageInset, keyboardHeight + AppSizes.minTapTarget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('large text keeps the label inside the bar and the page above', (
    tester,
  ) async {
    await _pumpHarness(tester, textScaler: const TextScaler.linear(3));
    final keyboardHeight = MediaQuery.viewInsetsOf(
      tester.element(find.byType(KeyboardDoneBar)),
    ).bottom;

    await tester.tap(find.byKey(_numberFieldKey));
    await tester.pump();

    expect(tester.takeException(), isNull);
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final pageInset = MediaQuery.viewInsetsOf(
      tester.element(find.byType(Scaffold)),
    ).bottom;
    final button = tester.getRect(find.byKey(_doneKey));
    // The button sits between the page bottom and the keyboard top.
    expect(button.top, greaterThanOrEqualTo(screenHeight - pageInset));
    expect(button.bottom, lessThanOrEqualTo(screenHeight - keyboardHeight));
    expect(pageInset, greaterThan(keyboardHeight + AppSizes.minTapTarget));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('iOS text field shows no bar', (tester) async {
    await _pumpHarness(tester);

    await tester.tap(find.byKey(_textFieldKey));
    await tester.pump();

    expect(find.byKey(_doneKey), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('Android number field shows no bar', (tester) async {
    await _pumpHarness(tester);

    await tester.tap(find.byKey(_numberFieldKey));
    await tester.pump();

    expect(find.byKey(_doneKey), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('iOS number field without an open keyboard shows no bar', (
    tester,
  ) async {
    await _pumpHarness(tester, keyboardOpen: false);

    await tester.tap(find.byKey(_numberFieldKey));
    await tester.pump();

    expect(find.byKey(_doneKey), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  bool keyboardOpen = true,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  if (keyboardOpen) {
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
  }

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: KeyboardDoneBar(child: child!),
      ),
      home: Scaffold(
        body: ListView(
          children: const [
            TextField(key: _numberFieldKey, keyboardType: TextInputType.number),
            TextField(key: _textFieldKey),
          ],
        ),
      ),
    ),
  );
}

bool _hasFocus(WidgetTester tester, Key key) {
  final editable = tester.widget<EditableText>(
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText)),
  );
  return editable.focusNode.hasFocus;
}
