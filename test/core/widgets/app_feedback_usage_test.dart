import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature code uses app feedback-safe interaction wrappers', () {
    final violations = <String>[];

    for (final file in _dartFilesUnder([
      'lib/core/widgets',
      'lib/features',
    ])) {
      final path = _normalizeDartPath(file.path);
      final source = file.readAsStringSync();

      if (!_directInteractionAllowedPaths.contains(path)) {
        for (final rule in _directInteractionRules.entries) {
          if (rule.value.hasMatch(source)) {
            violations.add('$path uses ${rule.key}; use the App* wrapper.');
          }
        }
      }

      if (!_feedbackConfigurationAllowedPaths.contains(path) &&
          source.contains('enableFeedback: false')) {
        violations.add('$path configures enableFeedback outside core.');
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('normalizes Windows path separators before allow-list checks', () {
    expect(
      _normalizeDartPath(r'lib\core\widgets\app_dropdown_button.dart'),
      'lib/core/widgets/app_dropdown_button.dart',
    );
  });
}

const Set<String> _directInteractionAllowedPaths = <String>{
  'lib/core/widgets/app_dropdown_button.dart',
  'lib/core/widgets/app_ink_well.dart',
  'lib/core/widgets/app_selection_list_tiles.dart',
};

const Set<String> _feedbackConfigurationAllowedPaths = <String>{
  'lib/core/theme/app_theme.dart',
  ..._directInteractionAllowedPaths,
};

final Map<String, RegExp> _directInteractionRules = <String, RegExp>{
  'InkWell': RegExp(r'\bInkWell\s*\('),
  'InkResponse': RegExp(r'\bInkResponse\s*\('),
  'DropdownButton': RegExp(r'\bDropdownButton(?:<[^>]+>)?\s*\('),
  'DropdownButtonFormField': RegExp(
    r'\bDropdownButtonFormField(?:<[^>]+>)?\s*\(',
  ),
  'CheckboxListTile': RegExp(
    r'\bCheckboxListTile(?:\.adaptive)?(?:<[^>]+>)?\s*\(',
  ),
  'RadioListTile': RegExp(
    r'\bRadioListTile(?:\.adaptive)?(?:<[^>]+>)?\s*\(',
  ),
  'SwitchListTile': RegExp(
    r'\bSwitchListTile(?:\.adaptive)?(?:<[^>]+>)?\s*\(',
  ),
};

String _normalizeDartPath(String path) {
  return path.replaceAll(r'\', '/');
}

Iterable<File> _dartFilesUnder(List<String> roots) sync* {
  for (final root in roots) {
    yield* Directory(root)
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) => file.path.endsWith('.dart'),
        );
  }
}
