import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_logic.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';

/// Storage container drafts of a restored session. A session without
/// containers restores one primary container from its weight fields.
List<CookingFlowStorageContainerSessionDraft> cookingFlowStorageContainerDrafts(
  CookingFlowSession storedSession,
) {
  if (storedSession.storageContainers.isNotEmpty) {
    return storedSession.storageContainers;
  }
  return <CookingFlowStorageContainerSessionDraft>[
    CookingFlowStorageContainerSessionDraft(
      id: 'container-1',
      label: '',
      taraText: storedSession.taraText,
      taraUtensilId: storedSession.taraUtensilId,
      grossWeightText: storedSession.grossWeightText,
      portionCount: resolveCookingFlowFinalPortions(
        splitIntoPortions: storedSession.splitIntoPortions,
        portionCount: storedSession.portionCount,
      ).toDouble(),
    ),
  ];
}

/// Next free container number after the ids `container-<n>`, at least 2.
int cookingFlowNextStorageContainerIndex(Iterable<String> containerIds) {
  var nextIndex = 1;
  for (final id in containerIds) {
    final suffix = int.tryParse(id.replaceFirst('container-', ''));
    if (suffix != null && suffix >= nextIndex) {
      nextIndex = suffix + 1;
    }
  }
  return nextIndex < 2 ? 2 : nextIndex;
}

/// Portion count text, rounded and at least 1.
String cookingFlowPortionText(num value) {
  final rounded = value.round();
  return (rounded < 1 ? 1 : rounded).toString();
}
