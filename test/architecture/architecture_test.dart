import 'package:flutter_test/flutter_test.dart';

import 'architecture_baseline.dart';
import 'architecture_rules.dart';

void main() {
  late List<String> featureOrder;
  late Project project;

  setUpAll(() {
    featureOrder = readFeatureOrder('.');
    project = Project.load('.', featureOrder);
  });

  test('the Feature Order lists every feature folder once', () {
    expect(
      featureOrder.toSet().length,
      featureOrder.length,
      reason: 'The Feature Order in architecture.md lists a feature twice.',
    );
    expect(
      featureOrder.toSet(),
      project.features,
      reason:
          'The Feature Order in architecture.md must list exactly the '
          'folders in lib/features/. Add a new feature after every feature '
          'that it imports.',
    );
  });

  test('the baseline names only known rules', () {
    final ruleIds = architectureRules.map((rule) => rule.id).toSet();
    expect(architectureBaseline.keys.toSet().difference(ruleIds), isEmpty);
  });

  group('architecture rule', () {
    for (final rule in architectureRules) {
      test(rule.id, () {
        final problems = _compareWithBaseline(
          rule.check(project),
          architectureBaseline[rule.id] ?? const {},
        );
        if (problems.isEmpty) return;
        fail(
          '${rule.rule}\n\n${problems.join('\n')}\n\n'
          'NEW: fix the code. NEVER add it to '
          'test/architecture/architecture_baseline.dart.\n'
          'FIXED: lower or remove the entry in the baseline.',
        );
      });
    }
  });
}

List<String> _compareWithBaseline(
  Iterable<Finding> findings,
  Map<String, int> baseline,
) {
  final byPath = <String, List<Finding>>{};
  for (final finding in findings) {
    byPath.putIfAbsent(finding.path, () => []).add(finding);
  }
  return [
    for (final MapEntry(key: path, value: found) in byPath.entries)
      if (found.length > (baseline[path] ?? 0)) ...[
        'NEW   $path: ${found.length} found, baseline ${baseline[path] ?? 0}',
        for (final finding in found)
          '        line ${finding.line}: ${finding.text}',
      ],
    for (final MapEntry(key: path, value: allowed) in baseline.entries)
      if ((byPath[path]?.length ?? 0) < allowed)
        'FIXED $path: baseline $allowed, found ${byPath[path]?.length ?? 0}',
  ];
}
