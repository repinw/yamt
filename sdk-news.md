# What the current SDK can do

The app builds with **Flutter 3.50.0** and **Dart 3.14.0** (2026-11-11). This
file lists what is new since Flutter 3.47 / Dart 3.13 and matters for this
app. It exists because assistants and older habits do not know these APIs.
Renew it with every SDK upgrade. API names were checked against the SDK
sources; before using one, read its doc comment.

Sources: the Flutter 3.50 release notes and breaking-change pages on
docs.flutter.dev, the Dart SDK changelog, and the changelogs of the packages
in the pub cache.

## Dart 3.14

No new language features. The language is the one from 3.13 (see
`architecture.md`, Stack).

- **`Future.syncValue(value)`** makes a completed future from a plain value.
  New lint `future_sync_value` asks for it where `Future.sync` returns a
  non-future.
- **Typed data:** `rangeEquals` on integer lists and `ByteData` compares two
  ranges without a loop.
- **`dart analyze <directory>` now reports analyzer plugin lints**
  (`max_file_lines`, `riverpod_lint`). Before, only `dart analyze <file>` did.
- **Tools:** `dart pub upgrade <package>@latest` or `@resolvable` explains why
  a newer version is not selected. `dart run -e '<code>'` runs a snippet.
  `dart migrate` raises the SDK constraint one minor version at a time and
  applies the fixes for each step.
- **Removed:** `Isolate.runSync` and the other synchronous isolate APIs that
  3.13 exposed by accident. `dart:mirrors` is deprecated.

## Flutter 3.50: widgets and framework

Scrolling:

- **`SliverClipRect`, `SliverClipRRect`** clip or round a scrolling section;
  pinned headers stay unclipped (`clipOverlap`).
- **`ListView.separated(itemExtentBuilder:)`** gives rows a known height
  without building them.
- **`ScrollPhysics.shouldUpdate`** lets physics react to a configuration
  change.

Dialogs, navigation, focus:

- **`showGeneralDialog(barrierBuilder:)`** and `RawDialogRoute` build a
  custom backdrop, for example a blur. `showDialog` does not take it.
- **`Navigator.popUntilWithResult`** hands the result to the last popped
  route.
- **`FocusableActionDetector.skipTraversal`** takes a widget out of Tab order.
- Tooltips close on Escape.

Images and painting:

- **`DecorationImage.placeholder`** paints a fallback until the image loads.
- **`FadeInImage(transition: FadeInImageTransition.fadeInOver)`** fades the
  image in over an opaque placeholder.
- **`ResizeImage.useLogicalSize`, `Image.useLogicalCacheSize`** size the image
  cache in logical pixels, so no `devicePixelRatio` math is needed.
- **`RawImage.blendMode`**, and `HSVColor.lerp` / `HSLColor.lerp` take the
  short way around the hue circle.

Text input:

- **`TextInputType.numberWithOptions(password: true)`** opens a hidden-digit
  keypad on Android (PIN entry).
- **`AutofillHints.emailOTPCode`** fills one-time codes from email.
- **Soft hyphens** (U+00AD) now show a hyphen at a line break; `TextStyle`
  takes `hyphens` to control it. German compound words can carry soft
  hyphens to wrap well.

Accessibility:

- **`MediaQuery.of(context).reduceMotion`**: the user asked for less motion.
  Swap slides and parallax for fades.
- **`SemanticsRole.slider`** for custom sliders (the eat page ruler).

## material_ui 1.6 to 1.11

`package:flutter/material.dart` and `cupertino.dart` are now formally
deprecated; the app already imports `package:material_ui/material_ui.dart`.

- **Material 3 Expressive:** `StyleVariant`, `ElevatedButtonTheme.variantOf`,
  `IconButtonTheme.variantOf`, selectable `ElevatedButton` states, and
  `Springs` (spring tokens for the standard and expressive motion schemes).
- **Shapes:** `RoundedPolygon`, `CornerRounding`, the `MaterialShapes` catalog
  and `MaterialShapeBorder`, which morphs between shapes when lerped.
- **Forms:** `DropdownButtonFormField(enabled:)` (no more `onChanged: null` to
  disable), `InputDecoration.supportingTextPadding`,
  `TextFormField.enableInlinePrediction`, `Checkbox.markInsets`.
- **Date picker:** `dayBuilder` and `weekdayBuilder` on `showDatePicker` and
  `CalendarDatePicker` draw custom day cells (for example plan dots).
- **Search:** `SearchAnchor.bar(barFocusNode:)`, `SearchAnchor.enableTapHandling`.
- **Ink:** `InkWell.onTertiaryTapDown` and friends.
- **Changed look:** the default primary `TabBar` indicator is at least 24 dp
  wide. A full-screen dialog and a persistent bottom sheet now paint behind a
  translucent keyboard.

## Riverpod 3.5

- **`provider.exists`** is listenable: `ref.watch(p.exists)`,
  `container.read(p.exists)`. `ref.exists(p)` and `container.exists(p)` are
  deprecated. The getter is `exists`; the Riverpod changelog misnames it
  `exist`.
- **`ProviderDisposedException`** (from `package:riverpod/misc.dart`): a
  provider's `.future` completes with it when the provider is disposed before
  it emits. It was a `StateError` before.
- Observers no longer hear about a future that completes after its provider
  was disposed.

## Android and iOS

- **Release builds ignore `route`, `dart_entrypoint` and cached-engine intent
  extras** from other apps, and engine flags passed by intent. Deep links
  (`ACTION_VIEW` with a URI from the manifest) keep working; the app uses
  those.
- **Tested Android tools:** AGP up to 9.4, Gradle 9.5, Kotlin 2.4.20. Flutter's
  defaults stay compileSdk 36, targetSdk 36, minSdk 24.
- **Built-in Kotlin** is the goal for apps and plugins; the app can switch
  when every plugin has dropped the Kotlin Gradle plugin.
- **HCPP** (`flutter config --enable-hcpp`): faster platform views on
  Android 14+ with Vulkan. Not switched on here.
- **iOS:** Flutter warns on every command while Swift Package Manager is
  off; CocoaPods support will be removed. Firebase's iOS SDK 13 ships only
  through Swift Package Manager.
- **Native interop without channels:** `package:ffigen` (C, Objective-C) and
  `package:jnigen` (Java, Kotlin) are stable; Pigeon has a native interop
  mode in preview.
