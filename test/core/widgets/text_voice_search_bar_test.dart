import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _FakeVoiceSearchService implements VoiceSearchService {
  bool _isListening = false;
  int cancelCallCount = 0;
  int stopCallCount = 0;
  Completer<VoiceSearchFailure?>? startCompleter;
  ValueChanged<VoiceSearchRecognition>? _onResult;
  ValueChanged<bool>? _onListeningStateChanged;
  ValueChanged<VoiceSearchFailure>? _onError;

  @override
  bool get isListening => _isListening;

  @override
  Future<VoiceSearchFailure?> startListening({
    required ValueChanged<VoiceSearchRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<VoiceSearchFailure> onError,
  }) async {
    _onResult = onResult;
    _onListeningStateChanged = onListeningStateChanged;
    _onError = onError;

    final pendingStart = startCompleter;
    if (pendingStart != null) {
      return pendingStart.future;
    }

    _isListening = true;
    onListeningStateChanged(true);
    return null;
  }

  @override
  Future<void> stopListening() async {
    stopCallCount++;
    _isListening = false;
    _onListeningStateChanged?.call(false);
  }

  @override
  Future<void> cancelListening() async {
    cancelCallCount++;
    _isListening = false;
    _onListeningStateChanged?.call(false);
  }

  void emitTranscript(String transcript) {
    _onResult?.call(
      VoiceSearchRecognition(transcript: transcript, isFinal: true),
    );
  }

  void emitError(VoiceSearchFailure failure) {
    _onError?.call(failure);
  }
}

Widget _buildTestApp({
  required TextEditingController textController,
  required VoiceSearchService voiceSearchService,
  TextVoiceSearchController? voiceSearchController,
  List<Widget> trailingActions = const <Widget>[],
  double? searchBarWidth,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: searchBarWidth,
          child: TextVoiceSearchBar(
            controller: textController,
            label: 'Search',
            fieldKey: const Key('shared_search_field'),
            voiceButtonKey: const Key('shared_voice_button'),
            clearButtonKey: const Key('shared_clear_button'),
            voiceSearchService: voiceSearchService,
            voiceSearchController: voiceSearchController,
            trailingActions: trailingActions,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('cancelListening is called when widget is disposed', (
    tester,
  ) async {
    final textController = TextEditingController(text: 'milk');
    final voiceSearchService = _FakeVoiceSearchService();

    await tester.pumpWidget(
      _buildTestApp(
        textController: textController,
        voiceSearchService: voiceSearchService,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    expect(voiceSearchService.cancelCallCount, 1);
    textController.dispose();
  });

  testWidgets('search field grows downward for long search text', (
    tester,
  ) async {
    final textController = TextEditingController();
    final voiceSearchService = _FakeVoiceSearchService();

    addTearDown(textController.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        textController: textController,
        voiceSearchService: voiceSearchService,
        searchBarWidth: 260,
      ),
    );

    final fieldFinder = find.byKey(const Key('shared_search_field'));
    final initialTop = tester.getTopLeft(fieldFinder).dy;
    final initialHeight = tester.getSize(fieldFinder).height;

    await tester.enterText(
      fieldFinder,
      'organic whole grain oat milk with vanilla and extra calcium for '
      'breakfast smoothies',
    );
    await tester.pump();

    expect(tester.getTopLeft(fieldFinder).dy, initialTop);
    expect(tester.getSize(fieldFinder).height, greaterThan(initialHeight));
  });

  testWidgets('search field height stops growing after three lines', (
    tester,
  ) async {
    final textController = TextEditingController();
    final voiceSearchService = _FakeVoiceSearchService();

    addTearDown(textController.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        textController: textController,
        voiceSearchService: voiceSearchService,
        searchBarWidth: 260,
      ),
    );

    final fieldFinder = find.byKey(const Key('shared_search_field'));

    await tester.enterText(fieldFinder, 'milk\noats\nbananas');
    await tester.pump();
    final threeLineHeight = tester.getSize(fieldFinder).height;

    await tester.enterText(
      fieldFinder,
      'milk\noats\nbananas\napples\nyogurt\ncinnamon',
    );
    await tester.pump();

    expect(tester.getSize(fieldFinder).height, threeLineHeight);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unmount during pending startListening does not throw', (
    tester,
  ) async {
    final textController = TextEditingController();
    final voiceSearchService = _FakeVoiceSearchService()
      ..startCompleter = Completer<VoiceSearchFailure?>();

    await tester.pumpWidget(
      _buildTestApp(
        textController: textController,
        voiceSearchService: voiceSearchService,
      ),
    );

    await tester.tap(find.byKey(const Key('shared_voice_button')));
    await tester.pump();

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    voiceSearchService.startCompleter!.complete(null);
    await tester.pump();

    expect(tester.takeException(), isNull);
    textController.dispose();
  });

  testWidgets('controller dispose cancels an active voice search', (
    tester,
  ) async {
    final textController = TextEditingController();
    final voiceSearchService = _FakeVoiceSearchService();
    final voiceSearchController = TextVoiceSearchController();

    await tester.pumpWidget(
      _buildTestApp(
        textController: textController,
        voiceSearchService: voiceSearchService,
        voiceSearchController: voiceSearchController,
      ),
    );

    await tester.tap(find.byKey(const Key('shared_voice_button')));
    await tester.pump();

    voiceSearchController.dispose();
    await tester.pump();

    expect(voiceSearchService.cancelCallCount, 1);
    textController.dispose();
  });

  testWidgets('trailing actions stay top-aligned with search field', (
    tester,
  ) async {
    final textController = TextEditingController();
    final voiceSearchService = _FakeVoiceSearchService();

    addTearDown(textController.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        textController: textController,
        voiceSearchService: voiceSearchService,
        trailingActions: const <Widget>[
          SizedBox(
            key: Key('extra_action'),
            height: 72,
            width: 56,
            child: ColoredBox(color: Colors.red),
          ),
        ],
      ),
    );

    final fieldTop = tester.getTopLeft(
      find.byKey(const Key('shared_search_field')),
    );
    final actionTop = tester.getTopLeft(find.byKey(const Key('extra_action')));

    expect(actionTop.dy, fieldTop.dy);
  });
}
