import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/voice_input_state_mixin.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooking_voice_input_mixin.dart';

void main() {
  testWidgets('a stop takes the final result once', (tester) async {
    final page = await _pump(tester, _FakeVoice(finalText: '200 ml Sahne'));

    await page.toggleListening();
    await tester.pump();
    expect(page.pendingSpeech, '200 ml');

    await page.stopListening();
    await tester.pump();
    expect(page.heard, ['200 ml Sahne']);
    expect(page.pendingSpeech, isNull);
  });

  testWidgets('a stop without a final result leaves no half-heard text', (
    tester,
  ) async {
    final page = await _pump(tester, _FakeVoice());

    await page.toggleListening();
    await tester.pump();
    await page.stopListening();
    await tester.pump();

    expect(page.heard, isEmpty);
    expect(page.pendingSpeech, isNull);
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
    expect(page.pendingSpeech, isNull);
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

  @override
  bool get pausesVoiceInput => false;

  @override
  void onSpokenText(String text) => heard.add(text);

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Hears "200 ml" while listening. Stopping sends [finalText] as the final
/// result, like the plugin, or nothing when it is `null`; cancelling sends
/// nothing.
class _FakeVoice implements VoiceSearchService {
  new({this.finalText});

  final String? finalText;
  ValueChanged<VoiceSearchRecognition>? _onResult;
  ValueChanged<bool>? _onListening;

  @override
  bool isListening = false;

  @override
  Future<VoiceSearchFailure?> startListening({
    required ValueChanged<VoiceSearchRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<VoiceSearchFailure> onError,
  }) async {
    isListening = true;
    _onResult = onResult;
    _onListening = onListeningStateChanged;
    onListeningStateChanged(true);
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
}
