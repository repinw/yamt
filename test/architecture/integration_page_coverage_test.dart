import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pages without an integration test, from before this rule was enforced.
///
/// NEVER add an entry: write the integration test instead. When a page gets
/// a test or is deleted, remove its entry in the same change.
const _legacyPagesWithoutIntegrationTest = <String>{
  'lib/features/auth/presentation/data_key_page.dart',
  'lib/features/auth/presentation/recovery_key_page.dart',
  'lib/features/auth/presentation/welcome_page.dart',
  'lib/features/calories/presentation/calorie_goal_archive_page.dart',
  'lib/features/calories/presentation/tdee_analytics_page.dart',
  'lib/features/cooking_flow/presentation/cooking_flow_cooking_page.dart',
  'lib/features/cooking_flow/presentation/cooking_flow_finalize_page.dart',
  'lib/features/cooking_flow/presentation/cooking_flow_intro_page.dart',
  'lib/features/cooking_flow/presentation/cooking_flow_preparation_page.dart',
  'lib/features/cooking_flow/presentation/cooking_flow_success_page.dart',
  'lib/features/cooking_flow/presentation/cooking_flow_summary_page.dart',
  'lib/features/inventory/presentation/inventory_shopping_list_page.dart',
  'lib/features/kitchen_utensils/presentation/kitchen_utensils_page.dart',
  'lib/features/onboarding/presentation/calorie_goal_onboarding_page.dart',
  'lib/features/product_search_hub/presentation/food_estimate_result_page.dart',
  'lib/features/product_search_hub/presentation/product_ai_search_page.dart',
  'lib/features/product_search_hub/presentation/product_search_hub_item_edit_page.dart',
  'lib/features/product_search_hub/presentation/widgets/manual_product_search_editor_page/manual_product_search_editor_page.dart',
  'lib/features/product_search_hub/presentation/widgets/product_search_barcode_scanner_page/product_search_barcode_scanner_page.dart',
  'lib/features/settings/presentation/profile_page.dart',
  'lib/features/shoppinglist/presentation/shopping_list_page.dart',
};

final _import = RegExp(
  r'''^\s*(?:import|export)\s+((?:'[^']*'\s*)+)''',
  multiLine: true,
);
final _literal = RegExp("'([^']*)'");

void main() {
  test('every page has an integration test that imports it', () {
    final pages = _pages();
    final covered = _pagesImportedByIntegrationTests();

    final missing =
        pages
            .difference(covered)
            .difference(_legacyPagesWithoutIntegrationTest)
            .toList()
          ..sort();
    expect(
      missing,
      isEmpty,
      reason:
          'architecture.md §11: a page needs an integration test in '
          'integration_test/<feature>/ that drives it. Import the page in '
          'the test or in a test helper that the test imports.',
    );

    final stale =
        _legacyPagesWithoutIntegrationTest
            .where((page) => covered.contains(page) || !pages.contains(page))
            .toList()
          ..sort();
    expect(
      stale,
      isEmpty,
      reason:
          'These pages have an integration test now or no longer exist. '
          'Remove them from _legacyPagesWithoutIntegrationTest.',
    );
  });
}

/// Every page file: each `*_page.dart` under `lib/features/`, in any
/// folder.
///
/// Two kinds of files carry the suffix but are no routed pages, so the check
/// skips them on purpose:
/// - `presentation/models/`: route arguments and UI models, such as the
///   onboarding intro page model;
/// - `onboarding/presentation/widgets/intro/pages/`: the steps inside the
///   onboarding intro, which `calorie_goal_onboarding_page.dart` shows.
Set<String> _pages() {
  return {
    for (final file in Directory('lib/features').listSync(recursive: true))
      if (file is File && file.path.endsWith('_page.dart'))
        if (_normalize(file.path) case final path
            when !_notRoutedPage.any(path.contains))
          path,
  };
}

const _notRoutedPage = <String>[
  '/presentation/models/',
  '/onboarding/presentation/widgets/intro/pages/',
];

/// Pages that an integration test imports, directly or through the test
/// helpers under `test/` and `integration_test/` that it imports.
///
/// Imports inside `lib/` do not count: the router reaches every page, so a
/// test that starts the router would cover all of them.
Set<String> _pagesImportedByIntegrationTests() {
  final covered = <String>{};
  final seen = <String>{};
  final queue = [
    for (final file in Directory('integration_test').listSync(recursive: true))
      if (file is File && file.path.endsWith('_test.dart'))
        _normalize(file.path),
  ];
  while (queue.isNotEmpty) {
    final path = queue.removeLast();
    if (!seen.add(path)) continue;
    final file = File(path);
    if (!file.existsSync()) continue;
    for (final target in _imports(path, file.readAsStringSync())) {
      if (target.startsWith('lib/')) {
        if (target.endsWith('_page.dart')) covered.add(target);
      } else if (target.startsWith('test/') ||
          target.startsWith('integration_test/')) {
        queue.add(target);
      }
    }
  }
  return covered;
}

/// Repository-relative paths that the Dart source [content] of [path]
/// imports or exports. Adjacent string literals are joined.
Iterable<String> _imports(String path, String content) sync* {
  for (final match in _import.allMatches(content)) {
    final uri = _literal
        .allMatches(match.group(1)!)
        .map((literal) => literal.group(1))
        .join();
    if (uri.startsWith('package:yamt/')) {
      yield 'lib/${uri.substring('package:yamt/'.length)}';
    } else if (!uri.contains(':')) {
      yield _normalize('${File(path).parent.path}/$uri');
    }
  }
}

String _normalize(String path) {
  final parts = <String>[];
  for (final part in path.replaceAll(r'\', '/').split('/')) {
    if (part == '..') {
      parts.removeLast();
    } else if (part.isNotEmpty && part != '.') {
      parts.add(part);
    }
  }
  return parts.join('/');
}
