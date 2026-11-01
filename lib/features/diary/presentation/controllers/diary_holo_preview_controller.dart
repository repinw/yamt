import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diary_holo_preview_controller.g.dart';

/// Debug switch that puts the budget card in holo foil without hitting the
/// target. Off on every start. Kept alive so the switch holds after the
/// menu that set it closes, also before a budget card watches it.
@Riverpod(keepAlive: true)
class DiaryHoloPreviewController extends _$DiaryHoloPreviewController {
  @override
  bool build() => false;

  /// Switches the preview on or off.
  void toggle() => state = !state;
}
