import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';

part 'shopping_private_list_status.g.dart';

/// Whether the private list failed to load. The household list still shows;
/// the page offers a retry for the private one. Checked again whenever the
/// list changes.
@riverpod
bool shoppingPrivateListFailed(Ref ref) {
  ref.watch(shoppingListControllerProvider);
  return ref.watch(shoppingListRepositoryProvider).privateUnreadable;
}
