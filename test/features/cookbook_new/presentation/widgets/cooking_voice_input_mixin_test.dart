import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/voice_input_state_mixin.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooking_voice_input_mixin.dart';

void main() {
  testWidgets('a stop shows what was heard until it takes the final result '
      'once (#832)', (tester) async {
    final voice = _FakeVoice(finalText: '200 ml Sahne');
    final page = await _pump(tester, voice);

    await page.toggleListening();
    await tester.pump();
    expect(page.pendingSpeech.value, '200 ml');
    // Cooking ends a recognition after a short pause.
    expect(voice.pauseFor, const Duration(seconds: 2));

    await page.stopListening();
    expect(page.pendingSpeech.value, '200 ml');
    await tester.pump();
    expect(page.heard, ['200 ml Sahne']);
    expect(page.pendingSpeech.value, isNull);
  });

  testWidgets('a stop without a final result leaves no half-heard text', (
    tester,
  ) async {
    final page = await _pump(tester, _FakeVoice());

    await page.toggleListening();
    await tester.pump();
    await page.stopListening();
    await tester.pump();
    expect(page.pendingSpeech.value, '200 ml');
    await tester.pump(const Duration(seconds: 3));

    expect(page.heard, isEmpty);
    expect(page.pendingSpeech.value, isNull);
    expect(page.isListening, isFalse);
  });

  testWidgets('finishing takes what is still heard at once, and no late '
      'final result follows', (tester) async {
    final page = await _pump(tester, _FakeVoice(finalText: '200 ml Sahne'));

    await page.toggleListening();
    await tester.pump();
    await page.finishListening();
    await tester.pump();

    expect(page.heard, ['200 ml']);
    expect(page.pendingSpeech.value, isNull);
  });

  testWidgets('a final result later than the wait still counts, and '
      'finishing after a stop takes what it showed (#832)', (tester) async {
    final voice = _FakeVoice();
    final page = await _pump(tester, voice);

    await page.toggleListening();
    await tester.pump();
    await page.stopListening();
    await tester.pump(const Duration(seconds: 3));
    expect(page.pendingSpeech.value, isNull);
    voice.sendFinal('200 ml Sahne');
    expect(page.heard, ['200 ml Sahne']);

    // "Kochen" right after a stop: no final comes, so it takes what the
    // stop showed.
    await page.toggleListening();
    await tester.pump();
    await page.stopListening();
    final finishing = page.finishListening();
    await tester.pump(const Duration(seconds: 3));
    await finishing;
    expect(page.heard, ['200 ml Sahne', '200 ml']);
    expect(page.pendingSpeech.value, isNull);
  });

  testWidgets('finishing right after a stop waits for its final result', (
    tester,
  ) async {
    final page = await _pump(tester, _FakeVoice(finalText: '200 ml Sahne'));

    await page.toggleListening();
    await tester.pump();
    // The stop's final result is still on its way when "Kochen" is tapped,
    // which pauses voice input before it finishes.
    final stopping = page.stopListening();
    page.pauses = true;
    final finishing = page.finishListening();
    await stopping;
    await tester.pump();
    await finishing;

    expect(page.heard, ['200 ml Sahne']);
    expect(page.pendingSpeech.value, isNull);
  });

  testWidgets('starting again clears what the last stop still showed', (
    tester,
  ) async {
    final page = await _pump(tester, _FakeVoice());

    await page.toggleListening();
    await tester.pump();
    await page.stopListening();
    expect(page.pendingSpeech.value, '200 ml');
    // Before the new session hears anything.
    final starting = page.toggleListening();

    expect(page.pendingSpeech.value, isNull);
    await starting;
  });

  testWidgets('a "not listening" report while starting starts no second '
      'session', (tester) async {
    final voice = _FakeVoice(reportsStartAs: false);
    final page = await _pump(tester, voice);

    await page.toggleListening();
    await tester.pump();

    expect(voice.starts, 1);
    expect(page.isListening, isTrue);
  });
}

Future<_PageState> _pump(WidgetTester tester, _FakeVoice voice) async {
  await tester.pumpWidget(MaterialApp(home: _Page(voice: voice)));
  return tester.state<_PageState>(find.byType(_Page));
}

class _Page extends StatefulWidget {
  const new({required this.voice});

  final VoiceSearchService voice;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page>
    with VoiceInputStateMixin<_Page>, CookingVoiceInputMixin<_Page> {
  final heard = <String>[];

  @override
  VoiceSearchService get voiceService => widget.voice;

  /// Set while the page saves, as "Kochen" does before it finishes.
  bool pauses = false;

  @override
  bool get pausesVoiceInput => pauses;

  @override
  void onSpokenText(String text) => heard.add(text);

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Hears "200 ml" while listening. Stopping sends [finalText] as the final
/// result, like the plugin, or nothing when it is `null`; cancelling sends
/// nothing.
class _FakeVoice implements VoiceSearchService {
  new({this.finalText, this.reportsStartAs = true});

  final String? finalText;

  /// What the service reports while it starts, before it returns.
  final bool reportsStartAs;

  /// How often listening started.
  int starts = 0;

  /// The pause the last start asked for.
  Duration? pauseFor;
  ValueChanged<VoiceSearchRecognition>? _onResult;
  ValueChanged<bool>? _onListening;

  @override
  bool isListening = false;

  @override
  Future<VoiceSearchFailure?> startListening({
    required ValueChanged<VoiceSearchRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<VoiceSearchFailure> onError,
    Duration? pauseFor,
  }) async {
    starts++;
    this.pauseFor = pauseFor;
    isListening = true;
    _onResult = onResult;
    _onListening = onListeningStateChanged;
    onListeningStateChanged(reportsStartAs);
    scheduleMicrotask(
      () => onResult(
        const VoiceSearchRecognition(transcript: '200 ml', isFinal: false),
      ),
    );
    return null;
  }

  @override
  Future<void> stopListening() async {
    await cancelListening();
    // The final result comes after the stop returns, as on Android.
    if (finalText case final text?) {
      scheduleMicrotask(
        () => _onResult?.call(
          VoiceSearchRecognition(transcript: text, isFinal: true),
        ),
      );
    }
  }

  @override
  Future<void> cancelListening() async {
    isListening = false;
    _onListening?.call(false);
  }

  /// Sends [text] as a late final result.
  void sendFinal(String text) =>
      _onResult?.call(VoiceSearchRecognition(transcript: text, isFinal: true));
}
