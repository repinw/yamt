// Test harness overrides scoped provider without full app scope.
// ignore_for_file: scoped_providers_should_specify_dependencies

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_image_picker_field.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../support/fake_prepared_meal_image_picker.dart';

@Dependencies([preparedMealImagePicker])
void main() {
  testWidgets('sets loading while picking and forwards picked bytes', (
    tester,
  ) async {
    final picker = _ControlledPreparedMealImagePicker();
    final pickedBytes = <Uint8List>[];
    final imageBytes = tinyPreparedMealPngBytes();

    await tester.pumpWidget(
      _TestApp(
        imagePicker: picker,
        child: _ImagePickerMixinHarness(onPicked: pickedBytes.add),
      ),
    );

    await tester.tap(find.text('Pick file'));
    await tester.pump();

    expect(find.text('loading:true'), findsOneWidget);
    expect(pickedBytes, isEmpty);

    picker.completeFilePick(imageBytes);
    await tester.pumpAndSettle();

    expect(find.text('loading:false'), findsOneWidget);
    expect(find.text('picked:true'), findsOneWidget);
    expect(pickedBytes.single, orderedEquals(imageBytes));
  });

  testWidgets('resets loading when picker returns null', (tester) async {
    final picker = _ControlledPreparedMealImagePicker();
    final pickedBytes = <Uint8List>[];

    await tester.pumpWidget(
      _TestApp(
        imagePicker: picker,
        child: _ImagePickerMixinHarness(onPicked: pickedBytes.add),
      ),
    );

    await tester.tap(find.text('Pick file'));
    await tester.pump();

    expect(find.text('loading:true'), findsOneWidget);

    picker.completeFilePick(null);
    await tester.pumpAndSettle();

    expect(find.text('loading:false'), findsOneWidget);
    expect(find.text('picked:false'), findsOneWidget);
    expect(pickedBytes, isEmpty);
  });

  testWidgets('shows localized snackbar for picker exception', (tester) async {
    final picker = _ControlledPreparedMealImagePicker();
    final pickedBytes = <Uint8List>[];

    await tester.pumpWidget(
      _TestApp(
        imagePicker: picker,
        child: _ImagePickerMixinHarness(onPicked: pickedBytes.add),
      ),
    );

    await tester.tap(find.text('Pick file'));
    await tester.pump();

    picker.failFilePick(
      const PreparedMealImagePickerException(
        PreparedMealImagePickerErrorCodes.imageTooLarge,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('loading:false'), findsOneWidget);
    expect(find.text('picked:false'), findsOneWidget);
    expect(find.text('The selected image is too large.'), findsOneWidget);
    expect(pickedBytes, isEmpty);
  });
}

@Dependencies([preparedMealImagePicker])
class _ImagePickerMixinHarness extends ConsumerStatefulWidget {
  const _ImagePickerMixinHarness({required this.onPicked});

  final ValueChanged<Uint8List> onPicked;

  @override
  ConsumerState<_ImagePickerMixinHarness> createState() =>
      _ImagePickerMixinHarnessState();
}

class _ImagePickerMixinHarnessState
    extends ConsumerState<_ImagePickerMixinHarness>
    with PreparedMealImagePickerStateMixin<_ImagePickerMixinHarness> {
  Uint8List? _pickedBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('loading:$isPickingPreparedMealImage'),
          Text('picked:${_pickedBytes != null}'),
          TextButton(
            onPressed: () {
              unawaited(
                pickPreparedMealImage(
                  source: PreparedMealImageSource.file,
                  onPicked: (imageBytes) {
                    _pickedBytes = imageBytes;
                    widget.onPicked(imageBytes);
                  },
                ),
              );
            },
            child: const Text('Pick file'),
          ),
        ],
      ),
    );
  }
}

class _ControlledPreparedMealImagePicker implements PreparedMealImagePicker {
  late Completer<Uint8List?> _fileCompleter;

  @override
  bool get supportsCamera => false;

  @override
  Future<Uint8List?> pickFromCamera() async => null;

  @override
  Future<Uint8List?> pickFromFile() {
    final completer = Completer<Uint8List?>();
    _fileCompleter = completer;
    return completer.future;
  }

  void completeFilePick(Uint8List? bytes) {
    _fileCompleter.complete(bytes);
  }

  void failFilePick(Object error) {
    _fileCompleter.completeError(error);
  }
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.imagePicker, required this.child});

  final PreparedMealImagePicker imagePicker;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        preparedMealImagePickerProvider.overrideWithValue(imagePicker),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }
}
