import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';

part 'shopping_open_count.g.dart';

/// How many entries are still to buy on the household list and the private
/// list together. It is loading while the list loads and an error when the
/// list cannot be read, never 0 in their place.
@riverpod
AsyncValue<int> openShoppingListCount(Ref ref) => ref
    .watch(shoppingListControllerProvider)
    .whenData((items) => items.where((item) => item.isOpen).length);
