import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/ai_template_file_input.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_import_reading.dart';

part 'shopping_list_import_repository.g.dart';

/// Firebase AI server prompt template that reads a shopping list from text
/// or photos. The prompt, model and output schema live on the server.
const shoppingListImportTemplateId = 'shopping-list-import-template';

const _requestTimeout = Duration(seconds: 60);

/// Runs [shoppingListImportTemplateId] with template [inputs] and returns
/// the response text.
typedef ShoppingListImportTemplateClient = Future<String?> Function(
  Map<String, Object?> inputs,
);

/// Shopping list import repository.
@riverpod
ShoppingListImportRepository shoppingListImportRepository(Ref ref) {
  final model = FirebaseAI.googleAI().templateGenerativeModel();
  return ShoppingListImportRepository(
    templateClient: (inputs) async {
      final response = await model
          .generateContent(shoppingListImportTemplateId, inputs: inputs)
          .timeout(_requestTimeout);
      return response.text;
    },
  );
}

/// Reads products, quantities and shelves out of a shopping list with
/// Firebase AI.
class ShoppingListImportRepository {
  /// Creates a shopping list import repository.
  new({required this._templateClient});

  final ShoppingListImportTemplateClient _templateClient;

  /// Reads a list pasted as [text].
  Future<ShoppingImportReading> loadFromText(String text) =>
      _load({'text': text});

  /// Reads a list from the photos or PDFs at [filePaths], in page order.
  Future<ShoppingImportReading> loadFromFiles(List<String> filePaths) async {
    final files = [
      // One after another, so full-size scans do not fill the memory.
      for (final path in filePaths) await aiTemplateFileInput(path),
    ];
    return await _load({'files': files});
  }

  Future<ShoppingImportReading> _load(Map<String, Object?> inputs) async {
    final text = await _templateClient(inputs);
    if (text == null || text.trim().isEmpty) {
      throw const FormatException('Empty shopping list import response');
    }
    return ShoppingImportReading.fromJson(jsonDecode(text));
  }
}
