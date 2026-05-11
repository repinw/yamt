import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/widgets/app_dropdown_button.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/app_selection_list_tiles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> platformCalls;

  setUp(() {
    platformCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('background taps do not send haptic feedback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ColoredBox(
            key: _surfaceKey,
            color: Colors.white,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(_surfaceKey));
    await tester.pump();

    expect(_hapticCalls(platformCalls), isEmpty);
  });

  testWidgets('AppInkWell sends feedback only for enabled taps', (
    tester,
  ) async {
    var tapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Material(
            child: Column(
              children: [
                AppInkWell(
                  key: _enabledKey,
                  onTap: () => tapCount++,
                  child: const SizedBox(width: 80, height: 48),
                ),
                const AppInkWell(
                  key: _disabledKey,
                  child: SizedBox(width: 80, height: 48),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(_enabledKey));
    await tester.tap(find.byKey(_disabledKey));
    await tester.pump();

    expect(tapCount, 1);
    expect(_hapticCalls(platformCalls), hasLength(1));
  });

  testWidgets('AppDropdownButton sends feedback when opened and changed', (
    tester,
  ) async {
    String? selected = 'a';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppDropdownButton<String>(
              value: selected,
              items: const [
                DropdownMenuItem(value: 'a', child: Text('A')),
                DropdownMenuItem(value: 'b', child: Text('B')),
              ],
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AppDropdownButton<String>));
    await tester.pumpAndSettle();
    expect(_hapticCalls(platformCalls), hasLength(1));

    await tester.tap(find.text('B').last);
    await tester.pumpAndSettle();

    expect(selected, 'b');
    expect(_hapticCalls(platformCalls), hasLength(2));
  });

  testWidgets('AppCheckboxListTile sends feedback when changed', (
    tester,
  ) async {
    bool? selected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCheckboxListTile(
            value: selected,
            title: const Text('Pick me'),
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick me'));
    await tester.pump();

    expect(selected, isTrue);
    expect(_hapticCalls(platformCalls), hasLength(1));
  });

  testWidgets('Material buttons keep their built-in feedback', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(seedColor: Colors.green),
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Save'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(_hapticCalls(platformCalls), isEmpty);
      expect(_systemSoundCalls(platformCalls), hasLength(1));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

const _surfaceKey = Key('app-haptic-feedback-surface');
const _enabledKey = Key('enabled-app-ink-well');
const _disabledKey = Key('disabled-app-ink-well');

Iterable<MethodCall> _hapticCalls(List<MethodCall> calls) {
  return calls.where(
    (call) =>
        call.method == 'HapticFeedback.vibrate' &&
        call.arguments == 'HapticFeedbackType.lightImpact',
  );
}

Iterable<MethodCall> _systemSoundCalls(List<MethodCall> calls) {
  return calls.where((call) => call.method == 'SystemSound.play');
}
