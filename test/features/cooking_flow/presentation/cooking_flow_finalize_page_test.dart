import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_models.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_finalize_page.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_storage_container_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _buildHarness({
  required TextEditingController grossWeightController,
  required bool isWeightValid,
  required CookingFlowNutritionPreview nutritionPreview,
  required String taraWeightText,
  required bool splitIntoPortions,
  required String? validationMessage,
  required double portionCount,
  String labelText = '',
}) {
  final labelController = TextEditingController(text: labelText);
  final taraController = TextEditingController(text: taraWeightText);
  final portionController = TextEditingController(
    text: portionCount.round().toString(),
  );
  addTearDown(labelController.dispose);
  addTearDown(taraController.dispose);
  addTearDown(portionController.dispose);

  return MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CookingFlowFinalizePage(
        storageContainers: <CookingFlowStorageContainerView>[
          CookingFlowStorageContainerView(
            id: 'container-1',
            labelController: labelController,
            taraController: taraController,
            grossWeightController: grossWeightController,
            portionController: portionController,
            selectedTaraUtensilId: null,
            canRemove: false,
          ),
        ],
        isWeightValid: isWeightValid,
        nutritionPreview: nutritionPreview,
        splitIntoPortions: splitIntoPortions,
        validationMessage: validationMessage,
        portionCount: portionCount,
        onContainerChanged: (_) {},
        onSplitIntoPortionsChanged: (_) {},
        onPortionCountChanged: (_) {},
      ),
    ),
  );
}

void main() {
  testWidgets('shows inline validation and zero net weight when invalid', (
    tester,
  ) async {
    final controller = TextEditingController(text: '900');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(
        grossWeightController: controller,
        isWeightValid: false,
        nutritionPreview: const CookingFlowNutritionPreview.zero(),
        taraWeightText: '1000',
        splitIntoPortions: true,
        validationMessage: 'Bruttogewicht muss größer als Tara sein.',
        portionCount: 3,
      ),
    );

    expect(
      find.text('Bruttogewicht muss größer als Tara sein.'),
      findsOneWidget,
    );
    expect(find.text('0 g'), findsOneWidget);
  });

  testWidgets('renders nutrition preview values for current portions', (
    tester,
  ) async {
    final controller = TextEditingController(text: '2500');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(
        grossWeightController: controller,
        isWeightValid: true,
        nutritionPreview: const CookingFlowNutritionPreview(
          kcal: 524,
          carbs: 86,
          protein: 28,
          fat: 2,
        ),
        taraWeightText: '1000',
        splitIntoPortions: true,
        validationMessage: null,
        portionCount: 3,
      ),
    );

    expect(find.text('Portionen nachjustieren?'), findsOneWidget);
    expect(find.text('1500 g'), findsOneWidget);
    expect(find.text('524 kcal'), findsOneWidget);
    expect(find.text('86g'), findsOneWidget);
    expect(find.text('28g'), findsOneWidget);
    expect(find.text('2g'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
  });

  testWidgets('shows selected container label and tare in finalize step', (
    tester,
  ) async {
    final controller = TextEditingController(text: '2500');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(
        grossWeightController: controller,
        isWeightValid: true,
        nutritionPreview: const CookingFlowNutritionPreview.zero(),
        taraWeightText: '420',
        splitIntoPortions: true,
        validationMessage: null,
        portionCount: 3,
        labelText: 'Suppentopf',
      ),
    );

    expect(find.text('Suppentopf'), findsOneWidget);
    expect(find.byIcon(Icons.kitchen_rounded), findsOneWidget);
    expect(find.text('420 g'), findsWidgets);
  });
}
