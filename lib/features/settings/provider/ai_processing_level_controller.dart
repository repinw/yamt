import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/config/ai_processing_level.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'ai_processing_level_controller.g.dart';

@Riverpod(keepAlive: true)
class AiProcessingLevelController extends _$AiProcessingLevelController {
  @override
  AiProcessingLevel build() {
    final preferences = ref.read(appPreferencesProvider);
    final stored = preferences.getStringSync(aiProcessingLevelStorageKey);
    return aiProcessingLevelFromName(stored);
  }

  Future<void> setLevel(AiProcessingLevel level) async {
    if (state == level) {
      return;
    }
    state = level;
    await ref
        .read(appPreferencesProvider)
        .setString(aiProcessingLevelStorageKey, level.name);
  }
}
