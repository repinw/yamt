import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_shutdown_controller.g.dart';

@Riverpod(keepAlive: true)
class SessionShutdownController extends _$SessionShutdownController {
  @override
  bool build() {
    return false;
  }

  void begin() {
    state = true;
  }

  void finish() {
    state = false;
  }
}
