import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_template_copy.dart';

part 'prepared_meal_template_writer.g.dart';

/// The writer that adds cookbook templates.
@riverpod
PreparedMealTemplateWriter preparedMealTemplateWriter(Ref ref) =>
    PreparedMealTemplateWriter(
      repository: ref.watch(preparedMealTemplateRepositoryProvider),
      clock: ref.watch(clockProvider),
    );

/// Adds cookbook templates.
class PreparedMealTemplateWriter {
  /// Creates the writer.
  const new({required this._repository, required this._clock});

  static const _uuid = Uuid();

  final PreparedMealTemplateRepository _repository;
  final DateTime Function() _clock;

  /// Saves [meal] as a new cookbook template with its ingredients and
  /// amounts, and returns the template. Throws when the save fails.
  Future<PreparedMeal> addFromMeal(PreparedMeal meal) async {
    final template = meal.asTemplate(id: _uuid.v4(), now: _clock());
    final templates = await _repository.readAll();
    if (!await _repository.saveAll([...templates, template])) {
      throw StateError('The cookbook template was not saved.');
    }
    return template;
  }
}
