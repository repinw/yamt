import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_import_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_catalog.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_import_reading.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_import_review.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_scope_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_shelf_choices_controller.dart';

part 'shopping_import_controller.g.dart';

/// Steps through a list import: null while the user gives the list, then
/// the read, then the review of what was read.
@riverpod
class ShoppingImportController extends _$ShoppingImportController {
  Future<ShoppingImportReading> Function()? _lastRead;
  // Counts the reads, so a read the user went back from is dropped.
  var _reads = 0;

  @override
  AsyncValue<ShoppingImportReview>? build() {
    // The review compares with the list and the import adds to it, so the
    // list stays loaded while the import is open.
    ref.listen(shoppingListControllerProvider, (_, _) {});
    return null;
  }

  /// Reads the products out of the pasted [text].
  Future<void> readText(String text) => _read(
    () => ref.read(shoppingListImportRepositoryProvider).loadFromText(text),
  );

  /// Reads the products out of the scanned pages at [filePaths].
  Future<void> readFiles(List<String> filePaths) => _read(
    () =>
        ref.read(shoppingListImportRepositoryProvider).loadFromFiles(filePaths),
  );

  /// Runs the last read again after it failed or found nothing.
  Future<void> retry() async {
    final read = _lastRead;
    if (read != null) await _read(read);
  }

  /// Goes back to giving the list.
  void restart() {
    _reads++;
    state = null;
  }

  /// Selects or unselects the product at [index].
  void toggle(int index) => _updateReview((review) => review.toggled(index));

  /// Calls the product at [index] [name].
  void rename(int index, String name) {
    if (name.trim().isEmpty) return;
    _updateReview((review) => review.renamed(index, name, _listItems()));
  }

  /// Puts the selected products on the list shown. Returns false when the
  /// list could not be saved. On the household list, the shelf the reader
  /// guessed for a product the catalog does not know is remembered, unless
  /// the household chose one already.
  Future<bool> addSelected() async {
    final review = state?.value;
    if (review == null) return false;
    // The page may close while this saves; the shelves are still remembered.
    final link = ref.keepAlive();
    try {
      final isPrivate = ref
          .read(shoppingListScopeControllerProvider)
          .addsPrivate;
      final revert = await ref
          .read(shoppingListControllerProvider.notifier)
          .addItemsWithRevert([
            for (final line in review.selectedLines)
              (
                name: line.name,
                brand: null,
                note: line.note,
                quantity: line.quantity,
              ),
          ], isPrivate: isPrivate);
      if (revert == null) return false;
      final guessed = {
        for (final line in review.selectedLines)
          if (line.shelf != ShoppingShelf.other &&
              lookUpShoppingCatalog(line.name) == null)
            line.name: line.shelf,
      };
      // A private product's shelf would show in the household's choices.
      if (!isPrivate && guessed.isNotEmpty) {
        await ref
            .read(shoppingShelfChoicesControllerProvider.notifier)
            .chooseAll(guessed, keepStored: true);
      }
      return true;
    } finally {
      link.close();
    }
  }

  Future<void> _read(Future<ShoppingImportReading> Function() read) async {
    _lastRead = read;
    final id = ++_reads;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(read);
    if (!ref.mounted || id != _reads) return;
    state = result.whenData(
      (reading) => ShoppingImportReview.of(reading, _listItems()),
    );
  }

  void _updateReview(
    ShoppingImportReview Function(ShoppingImportReview) update,
  ) {
    final review = state?.value;
    if (review != null) state = AsyncData(update(review));
  }

  /// The entries of the list the import adds to. In "both" that is the
  /// household list alone, since adding merges only within one list.
  List<ShoppingListItem> _listItems() {
    final addsPrivate = ref
        .read(shoppingListScopeControllerProvider)
        .addsPrivate;
    final items =
        ref.read(shoppingListControllerProvider).value ??
        const <ShoppingListItem>[];
    return [
      for (final item in items)
        if (item.isPrivate == addsPrivate) item,
    ];
  }
}
