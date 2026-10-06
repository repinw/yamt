import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/native_theme_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('de.yamt.app/theme_mode');
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('tells Android the picked mode', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await applyNativeThemeMode(ThemeMode.dark);

    expect(calls.single.method, 'set');
    expect(calls.single.arguments, 'dark');
  });

  test('leaves iOS alone', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await applyNativeThemeMode(ThemeMode.light);

    expect(calls, isEmpty);
  });

  test('without the channel the app keeps running', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);

    await expectLater(applyNativeThemeMode(ThemeMode.system), completes);
  });
}
