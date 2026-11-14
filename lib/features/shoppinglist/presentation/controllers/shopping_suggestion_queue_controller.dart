import 'dart:convert';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion_queue.dart';

part 'shopping_suggestion_queue_controller.g.dart';

const _pushedBackKey = 'shopping_suggestions_pushed_back_v1';

/// The suggestions the user pushed back, as keys in the order of pushing,
/// saved on the device.
@riverpod
class ShoppingSuggestionQueueController
    extends _$ShoppingSuggestionQueueController {
  @override
  List<String> build() {
    final stored = ref
        .watch(appPreferencesProvider)
        .getStringSync(_pushedBackKey);
    if (stored == null || stored.isEmpty) {
      return const [];
    }
    // Only this controller writes the value; one that cannot be read is
    // worth less than the strip, so the order starts over.
    try {
      final decoded = jsonDecode(stored);
      return decoded is List ? decoded.whereType<String>().toList() : const [];
    } on FormatException catch (error, stackTrace) {
      log(
        'Stored suggestion order is unreadable; starting over.',
        name: 'ShoppingSuggestionQueueController',
        error: error,
        stackTrace: stackTrace,
      );
      return const [];
    }
  }

  /// Puts [suggestion] behind all [current] suggestions. Stays alive until
  /// the order is saved, even when the page closes meanwhile.
  Future<void> pushBack(
    ShoppingSuggestion suggestion, {
    required List<ShoppingSuggestion> current,
  }) async {
    final link = ref.keepAlive();
    try {
      final pushedBack = pushShoppingSuggestionBack(
        state,
        suggestion,
        current: current,
      );
      state = pushedBack;
      await ref
          .read(appPreferencesProvider)
          .setString(_pushedBackKey, jsonEncode(pushedBack));
    } finally {
      link.close();
    }
  }
}
