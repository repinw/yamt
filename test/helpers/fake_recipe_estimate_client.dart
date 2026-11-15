import 'dart:async';
import 'dart:convert';
import 'dart:math';

/// Stands in for the AI's recipe estimate template: it answers [request]
/// after a real asynchronous gap with one weight per line, counts the calls,
/// and can hold its answers back like a slow AI call.
class FakeRecipeEstimateClient {
  /// Answers nothing when [noAnswer], which fails the estimate quietly and
  /// leaves the recipe as it is.
  new({this.noAnswer = false});

  /// Whether the answers are empty.
  final bool noAnswer;

  /// What the next requests throw instead of answering.
  Exception? failure;

  /// How many requests were made.
  int calls = 0;

  /// The most requests that were running at the same moment.
  int mostRunning = 0;

  int _running = 0;
  Completer<void>? _held;

  /// Holds back the answers until [release].
  void hold() => _held ??= Completer<void>();

  /// Lets the answers go.
  void release() {
    _held?.complete();
    _held = null;
  }

  /// Answers one request; goes to `recipeEstimateTemplateClientProvider`.
  Future<String?> request(Map<String, Object?> inputs) async {
    calls += 1;
    _running += 1;
    mostRunning = max(mostRunning, _running);
    await _held?.future;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    _running -= 1;
    if (failure case final failure?) {
      throw failure;
    }
    if (noAnswer) {
      return null;
    }
    final lines = inputs['lines']! as List<Object?>;
    return jsonEncode({
      'status': 'ok',
      'kcal': 420,
      'protein': 18,
      'carbs': 52,
      'fat': 14,
      'lines': [
        for (final _ in lines) {'amount': 100, 'unit': 'g'},
      ],
    });
  }
}
