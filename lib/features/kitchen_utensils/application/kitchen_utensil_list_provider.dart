import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil_rules.dart';

part 'kitchen_utensil_list_provider.g.dart';

/// Watches the saved kitchen utensils, newest first.
@riverpod
Stream<List<KitchenUtensil>> kitchenUtensilList(Ref ref) {
  return ref
      .watch(kitchenUtensilRepositoryProvider)
      .watchAll()
      .map(sortKitchenUtensils);
}
