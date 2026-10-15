import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/presentation/progress_photo_capture_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_capture_sheet.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_progress_photo_repository.dart';

Future<void> _saveWithCamera(
  WidgetTester tester, {
  required bool confirmSaved,
}) async {
  final repository = FakeProgressPhotoRepository(
    pickedImage: Uint8List.fromList(<int>[1, 2, 3]),
  );
  addTearDown(repository.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        progressPhotoRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 15)),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  showProgressPhotoCapture(context, confirmSaved: confirmSaved),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ProgressPhotoCaptureSheet.cameraKey));
  await tester.pumpAndSettle();
  expect(repository.pickedSources, [ImageSource.camera]);
}

void main() {
  testWidgets('confirms a saved photo with a snack bar', (tester) async {
    await _saveWithCamera(tester, confirmSaved: true);

    expect(find.text('Photo saved'), findsOneWidget);
  });

  testWidgets('shows no snack bar when the caller confirms itself', (
    tester,
  ) async {
    await _saveWithCamera(tester, confirmSaved: false);

    expect(find.byType(SnackBar), findsNothing);
  });
}
