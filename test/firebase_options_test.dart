import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/firebase_options.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('currentPlatform returns android options on Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      DefaultFirebaseOptions.currentPlatform,
      same(DefaultFirebaseOptions.android),
    );
  });

  test('currentPlatform returns ios options on iOS', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(
      DefaultFirebaseOptions.currentPlatform,
      same(DefaultFirebaseOptions.ios),
    );
  });

  test('currentPlatform returns macos options on macOS', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(
      DefaultFirebaseOptions.currentPlatform,
      same(DefaultFirebaseOptions.macos),
    );
  });

  test('currentPlatform throws for Windows without generated options', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(
      () => DefaultFirebaseOptions.currentPlatform,
      throwsUnsupportedError,
    );
  });

  test('currentPlatform throws for Linux', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    expect(
      () => DefaultFirebaseOptions.currentPlatform,
      throwsUnsupportedError,
    );
  });

  test('currentPlatform throws for unsupported fallback platform', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    expect(
      () => DefaultFirebaseOptions.currentPlatform,
      throwsUnsupportedError,
    );
  });

  test('all generated options are accessible', () {
    expect(DefaultFirebaseOptions.web.projectId, isNotEmpty);
    expect(DefaultFirebaseOptions.android.projectId, isNotEmpty);
    expect(DefaultFirebaseOptions.ios.projectId, isNotEmpty);
    expect(DefaultFirebaseOptions.macos.projectId, isNotEmpty);
  });
}
