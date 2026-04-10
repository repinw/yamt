import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Filters inventory content with tolerant text matching.
class InventorySearchService {
  const InventorySearchService();

  List<InventoryItem> filterItems({
    required List<InventoryItem> items,
    required String query,
  }) {
    final queryTokens = _buildSearchTokens(query);
    if (queryTokens.isEmpty) {
      return items;
    }

    return items
        .where((item) {
          return _matchesSearchTokens(
            haystack: _buildInventoryItemSearchText(item),
            queryTokens: queryTokens,
          );
        })
        .toList(growable: false);
  }

  List<PreparedMeal> filterPreparedMeals({
    required List<PreparedMeal> meals,
    required String query,
  }) {
    final queryTokens = _buildSearchTokens(query);
    if (queryTokens.isEmpty) {
      return meals;
    }

    return meals
        .where((meal) {
          return _matchesSearchTokens(
            haystack: _buildPreparedMealSearchText(meal),
            queryTokens: queryTokens,
          );
        })
        .toList(growable: false);
  }

  @visibleForTesting
  bool matchesQuery({required String haystack, required String query}) {
    final queryTokens = _buildSearchTokens(query);
    if (queryTokens.isEmpty) {
      return true;
    }

    return _matchesSearchTokens(haystack: haystack, queryTokens: queryTokens);
  }

  @visibleForTesting
  bool hasApproximateCompactMatch({
    required String haystack,
    required String queryToken,
  }) {
    final normalizedHaystack = _normalizeSearchText(haystack);
    final haystackTokens = normalizedHaystack
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toList(growable: false);

    return _hasApproximateCompactMatch(
      compactQueryToken: _compactSearchText(queryToken),
      haystackTokens: haystackTokens,
    );
  }

  @visibleForTesting
  bool isWithinEditDistanceOne(String left, String right) {
    return _isWithinEditDistanceOne(
      _compactSearchText(left),
      _compactSearchText(right),
    );
  }
}

List<String> _buildSearchTokens(String query) {
  final normalizedQuery = _normalizeSearchText(query);
  if (normalizedQuery.isEmpty) {
    return const <String>[];
  }

  return normalizedQuery
      .split(' ')
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
}

bool _matchesSearchTokens({
  required String haystack,
  required List<String> queryTokens,
}) {
  final normalizedHaystack = _normalizeSearchText(haystack);
  final haystackTokens = normalizedHaystack
      .split(' ')
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
  final compactHaystack = _compactSearchText(normalizedHaystack);

  return queryTokens.every((queryToken) {
    if (normalizedHaystack.contains(queryToken)) {
      return true;
    }

    final compactQueryToken = _compactSearchText(queryToken);
    if (compactQueryToken.isEmpty) {
      return true;
    }
    if (compactHaystack.contains(compactQueryToken)) {
      return true;
    }

    return _hasApproximateCompactMatch(
      compactQueryToken: compactQueryToken,
      haystackTokens: haystackTokens,
    );
  });
}

String _buildInventoryItemSearchText(InventoryItem item) {
  return <String>[
    item.name,
    item.brand ?? '',
    item.category ?? '',
    item.storeName,
    item.weight ?? '',
    item.ocrName ?? '',
    item.normalizedBarcode ?? '',
  ].join(' ');
}

String _buildPreparedMealSearchText(PreparedMeal meal) {
  return <String>[meal.name, ...meal.recipeIngredients].join(' ');
}

String _normalizeSearchText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ß', 'ss')
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll(RegExp(r'\s+'), ' ');
}

String _compactSearchText(String value) {
  return _normalizeSearchText(value).replaceAll(RegExp(r'[\s\-_/,.;:()]+'), '');
}

bool _hasApproximateCompactMatch({
  required String compactQueryToken,
  required List<String> haystackTokens,
}) {
  if (compactQueryToken.length < 4) {
    return false;
  }

  for (var start = 0; start < haystackTokens.length; start++) {
    var candidate = '';
    for (var end = start; end < haystackTokens.length; end++) {
      candidate += _compactSearchText(haystackTokens[end]);
      final lengthDifference = candidate.length - compactQueryToken.length;
      if (lengthDifference > 1) {
        break;
      }
      if (lengthDifference.abs() > 1) {
        continue;
      }
      if (_isWithinEditDistanceOne(candidate, compactQueryToken)) {
        return true;
      }
      if (end - start >= 2) {
        break;
      }
    }
  }

  return false;
}

bool _isWithinEditDistanceOne(String left, String right) {
  if (left == right) {
    return true;
  }

  final lengthDifference = left.length - right.length;
  if (lengthDifference.abs() > 1) {
    return false;
  }

  if (left.length == right.length) {
    return _isSingleReplacementOrSwap(left, right);
  }

  final longer = lengthDifference > 0 ? left : right;
  final shorter = lengthDifference > 0 ? right : left;
  return _isSingleInsertionOrDeletion(longer, shorter);
}

bool _isSingleReplacementOrSwap(String left, String right) {
  final mismatches = <int>[];

  for (var index = 0; index < left.length; index++) {
    if (left[index] == right[index]) {
      continue;
    }
    mismatches.add(index);
    if (mismatches.length > 2) {
      return false;
    }
  }

  if (mismatches.isEmpty || mismatches.length == 1) {
    return true;
  }

  final firstMismatch = mismatches[0];
  final secondMismatch = mismatches[1];
  return secondMismatch == firstMismatch + 1 &&
      left[firstMismatch] == right[secondMismatch] &&
      left[secondMismatch] == right[firstMismatch];
}

bool _isSingleInsertionOrDeletion(String longer, String shorter) {
  var longerIndex = 0;
  var shorterIndex = 0;
  var skippedCharacter = false;

  while (longerIndex < longer.length && shorterIndex < shorter.length) {
    if (longer[longerIndex] == shorter[shorterIndex]) {
      longerIndex++;
      shorterIndex++;
      continue;
    }
    if (skippedCharacter) {
      return false;
    }

    skippedCharacter = true;
    longerIndex++;
  }

  return true;
}
