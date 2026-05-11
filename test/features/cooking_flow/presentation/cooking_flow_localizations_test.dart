import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/presentation/cooking_flow_localizations.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  test('delegates cookflow helper labels to localizations', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('de'));

    expect(
      l10n.cookflowInventoryConflictText(
        availableAmount: '100 g',
        missingAmount: '50 g',
      ),
      l10n.cookflowInventoryConflictMessage('100 g', '50 g'),
    );
  });
}
