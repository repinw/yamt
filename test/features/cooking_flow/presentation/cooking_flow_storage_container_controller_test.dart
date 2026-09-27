import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_storage_container_controller.dart';

void main() {
  test('finalizeInputs splits the total portions over containers', () {
    final controller = CookingFlowStorageContainerController(
      initialFinalPortions: 4,
    );
    addTearDown(controller.dispose);
    controller.add(finalPortions: 4);
    controller.containers[0].taraController.text = '350';
    controller.containers[0].grossWeightController.text = '750';
    controller.containers[1].taraController.text = '300';
    controller.containers[1].grossWeightController.text = '650';

    final inputs = controller.finalizeInputs(
      totalPortions: 4,
      fallbackLabelForIndex: (index) => 'Behälter ${index + 1}',
    );

    expect(inputs.map((input) => input.finalNetWeight), <int>[400, 350]);
    expect(inputs.map((input) => input.totalPortions), <int>[2, 2]);
  });

  test('finalizeInputs keeps all portions for a single container', () {
    final controller = CookingFlowStorageContainerController(
      initialFinalPortions: 4,
    );
    addTearDown(controller.dispose);
    controller.grossWeightController.text = '1600';

    final inputs = controller.finalizeInputs(
      totalPortions: 4,
      fallbackLabelForIndex: (index) => 'Behälter ${index + 1}',
    );

    expect(inputs.single.totalPortions, 4);
  });
}
