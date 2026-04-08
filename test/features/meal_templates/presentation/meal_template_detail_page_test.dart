import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/meal_templates/presentation/'
    'meal_template_detail_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _FakePreparedMealTemplateRepository
    implements PreparedMealTemplateRepository {
  _FakePreparedMealTemplateRepository({
    required List<PreparedMeal> initialTemplates,
  }) : _templates = List<PreparedMeal>.from(initialTemplates);

  final _controller = StreamController<List<PreparedMeal>>.broadcast();
  List<PreparedMeal> _templates;

  @override
  Stream<List<PreparedMeal>> watchAll() {
    return Stream<List<PreparedMeal>>.multi((controller) {
      controller.add(List<PreparedMeal>.from(_templates));
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  @override
  Future<List<PreparedMeal>> readAll() async {
    return List<PreparedMeal>.from(_templates);
  }

  @override
  Future<bool> saveAll(List<PreparedMeal> templates) async {
    _templates = List<PreparedMeal>.from(templates);
    _controller.add(List<PreparedMeal>.from(_templates));
    return true;
  }

  Future<void> dispose() => _controller.close();
}

class _FakeInventoryItemRepository implements InventoryItemRepository {
  @override
  Stream<List<InventoryItem>> watchAll() {
    return Stream<List<InventoryItem>>.value(const <InventoryItem>[]);
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return const <InventoryItem>[];
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }
}

PreparedMeal _recipeTemplate() {
  return PreparedMeal(
    id: 'template-1',
    name: 'Potato soup',
    recipeUrl: 'https://www.chefkoch.de/rezepte/1234/potato-soup.html',
    recipeIngredients: const <String>['1 kg Potatoes', '500 ml Broth'],
    totalPortions: 4,
    remainingPortions: 4,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
    updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
    components: const <PreparedMealComponent>[],
  );
}

Widget _buildHarness({
  required PreparedMealTemplateRepository templateRepository,
}) {
  return ProviderScope(
    overrides: [
      preparedMealTemplateRepositoryProvider.overrideWithValue(
        templateRepository,
      ),
      inventoryItemRepositoryProvider.overrideWithValue(
        _FakeInventoryItemRepository(),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MealTemplateDetailPage(templateId: 'template-1'),
    ),
  );
}

void main() {
  testWidgets('renders localized meal template detail content', (tester) async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: <PreparedMeal>[_recipeTemplate()],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildHarness(templateRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Ingredient Matching: Potato soup'), findsOneWidget);
    expect(find.text('Base: 4 portions'), findsOneWidget);
    expect(find.text('4 portions'), findsOneWidget);
    expect(find.text('1 kg Potatoes'), findsOneWidget);
  });

  testWidgets('shows localized not-found state', (tester) async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: const <PreparedMeal>[],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildHarness(templateRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Template not found.'), findsOneWidget);
  });
}
