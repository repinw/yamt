import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_holo_preview_controller.dart';

void main() {
  test('is off on start and toggles on and off', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final states = <bool>[];
    container.listen(
      diaryHoloPreviewControllerProvider,
      (_, next) => states.add(next),
    );

    expect(container.read(diaryHoloPreviewControllerProvider), isFalse);
    container.read(diaryHoloPreviewControllerProvider.notifier).toggle();
    container.read(diaryHoloPreviewControllerProvider.notifier).toggle();

    expect(states, [true, false]);
  });
}
