import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_import_page.dart';

/// Opens the full-screen import that reads a pasted or scanned list and puts
/// the products the user keeps on the shopping list.
Future<void> showShoppingListImport(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const ShoppingImportPage(),
      ),
    );
