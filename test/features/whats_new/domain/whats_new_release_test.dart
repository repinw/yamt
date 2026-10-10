import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/core/domain/app_version.dart';
import 'package:yamt/features/whats_new/domain/whats_new_release.dart';

Map<String, dynamic> _notes({List<String> added = const ['A']}) => {
  'new': added,
  'improved': ['B'],
  'fixed': ['C'],
};

void main() {
  group('WhatsNewRelease', () {
    test('reads the bundled notes of 3.7.0', () {
      final json = File('assets/whats_new/3.7.0.json').readAsStringSync();
      final release = WhatsNewRelease.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(release.notesFor('de').added, isNotEmpty);
      expect(release.notesFor('en').improved, isNotEmpty);
      expect(release.notesFor('fr'), same(release.en));
    });

    test('needs both languages and all three lists', () {
      expect(
        () => WhatsNewRelease.fromJson({'de': _notes()}),
        throwsA(isA<MissingRequiredKeysException>()),
      );
      expect(
        () => WhatsNewRelease.fromJson({
          'de': _notes(),
          'en': const {'new': <String>[], 'improved': <String>[]},
        }),
        throwsA(isA<MissingRequiredKeysException>()),
      );
      expect(
        () => WhatsNewRelease.fromJson({
          'de': _notes(),
          'en': _notes(),
          'fr': _notes(),
        }),
        throwsA(isA<UnrecognizedKeysException>()),
      );
    });

    test('the headline is the first new point, else the next list', () {
      final release = WhatsNewRelease.fromJson({
        'de': _notes(),
        'en': _notes(added: []),
      });

      expect(release.de.headline, 'A');
      expect(release.en.headline, 'B');
    });
  });

  group('whatsNewStep', () {
    const running = AppVersion(3, 7, 0);

    test('shows the notes once per version to a device that used the app', () {
      expect(
        whatsNewStep(running: running, lastSeen: null, usedBefore: true),
        WhatsNewStep.show,
      );
      expect(
        whatsNewStep(
          running: running,
          lastSeen: const AppVersion(3, 6, 0),
          usedBefore: false,
        ),
        WhatsNewStep.show,
      );
      expect(
        whatsNewStep(running: running, lastSeen: running, usedBefore: true),
        WhatsNewStep.skip,
      );
      expect(
        whatsNewStep(
          running: running,
          lastSeen: const AppVersion(3, 8, 0),
          usedBefore: true,
        ),
        WhatsNewStep.skip,
      );
    });

    test('a fresh install only stores the version', () {
      expect(
        whatsNewStep(running: running, lastSeen: null, usedBefore: false),
        WhatsNewStep.markSeen,
      );
    });
  });
}
