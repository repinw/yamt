import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'receipt_item_editor_draft.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_item_editor/receipt_item_editor_form_field_metadata.dart';

void main() {
  test('quantity revalidates unitPrice and weight fields', () {
    expect(
      ReceiptItemEditorDraftField.quantity.linkedValidationFields,
      const <ReceiptItemEditorDraftField>[
        ReceiptItemEditorDraftField.unitPrice,
        ReceiptItemEditorDraftField.weight,
      ],
    );
  });

  test('unitPrice revalidates quantity field', () {
    expect(
      ReceiptItemEditorDraftField.unitPrice.linkedValidationFields,
      const <ReceiptItemEditorDraftField>[ReceiptItemEditorDraftField.quantity],
    );
  });
}
