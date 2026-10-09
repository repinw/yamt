import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/application/'
    'household_scoped_list_feed.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_template_copy.dart';

part 'prepared_meal_templates_controller.g.dart';

const _preparedMealTemplatesControllerLogName =
    'PreparedMealTemplatesController';

/// Defines prepared meal template save failure reason.
enum PreparedMealTemplateSaveFailureReason {
  /// Documented member.
  invalidInput,

  /// Documented member.
  recipeLoadFailed,

  /// Documented member.
  saveFailed,
}

/// Defines prepared meal template save result.
class PreparedMealTemplateSaveResult {
  const new _({required this.isSuccess, this.templateId, this.failureReason});

  /// Creates a [PreparedMealTemplateSaveResult] for success.
  const new success(String templateId)
    : this._(isSuccess: true, templateId: templateId);

  /// Creates a [PreparedMealTemplateSaveResult] for failure.
  const new failure(PreparedMealTemplateSaveFailureReason reason)
    : this._(isSuccess: false, failureReason: reason);

  /// Whether success.
  final bool isSuccess;

  /// The template id.
  final String? templateId;

  /// The failure reason.
  final PreparedMealTemplateSaveFailureReason? failureReason;
}

/// Defines prepared meal templates controller.
@riverpod
class PreparedMealTemplatesController
    extends _$PreparedMealTemplatesController {
  static const _uuid = Uuid();

  final _mutationQueue = SerializedMutationQueue();
  final Set<(String, String)> _recipeInstructionBackfillsInProgress =
      <(String, String)>{};
  final Set<(String, String)> _recipeInstructionBackfillsAttempted =
      <(String, String)>{};
  late final _feed = HouseholdScopedListFeed<PreparedMeal>(
    ref: () => ref,
    watch: () => ref
        .read(preparedMealTemplateRepositoryProvider)
        .watchAll()
        .map(_sortTemplates),
    setState: (next) => state = next,
    logName: _preparedMealTemplatesControllerLogName,
    recoveryMessage:
        'Rebuilding prepared meal template stream after household access '
        'changed.',
    onList: _scheduleRecipeInstructionBackfill,
  );

  @override
  FutureOr<List<PreparedMeal>> build() {
    ref
      ..watch(householdDataOwnerUserIdProvider)
      ..watch(preparedMealTemplateRepositoryProvider)
      ..onDispose(() {
        unawaited(_feed.close());
      })
      ..watch(activeHouseholdIdProvider);
    return _feed.start();
  }

  /// Refresh.
  Future<void> refresh() => _feed.refresh();

  /// Save template from meal.
  Future<PreparedMealTemplateSaveResult> saveTemplateFromMeal(
    PreparedMeal meal,
  ) {
    if (meal.name.trim().isEmpty ||
        meal.components.isEmpty ||
        meal.totalPortions < 1) {
      return Future<PreparedMealTemplateSaveResult>.value(
        const PreparedMealTemplateSaveResult.failure(
          PreparedMealTemplateSaveFailureReason.invalidInput,
        ),
      );
    }

    final keepAliveLink = ref.keepAlive();
    return _mutationQueue
        .run<PreparedMealTemplateSaveResult>(
          operation: () async {
            final currentTemplates = await _currentTemplates();
            final template = meal.asTemplate(
              id: _uuid.v4(),
              now: ref.read(clockProvider)(),
            );
            final nextTemplates = List<PreparedMeal>.from(currentTemplates)
              ..add(template);
            final saved = await _saveTemplates(
              previousTemplates: currentTemplates,
              nextTemplates: nextTemplates,
            );
            if (!saved) {
              return const PreparedMealTemplateSaveResult.failure(
                PreparedMealTemplateSaveFailureReason.saveFailed,
              );
            }
            return PreparedMealTemplateSaveResult.success(template.id);
          },
          fallbackValue: const PreparedMealTemplateSaveResult.failure(
            PreparedMealTemplateSaveFailureReason.saveFailed,
          ),
          onError: (error, stackTrace) {
            log(
              'Unexpected prepared meal template save error.',
              name: _preparedMealTemplatesControllerLogName,
              error: error,
              stackTrace: stackTrace,
            );
          },
        )
        .whenComplete(keepAliveLink.close);
  }

  /// Save recipe template.
  Future<PreparedMealTemplateSaveResult> saveRecipeTemplate(
    PreparedMeal template,
  ) {
    if (template.name.trim().isEmpty || template.totalPortions < 1) {
      return Future<PreparedMealTemplateSaveResult>.value(
        const PreparedMealTemplateSaveResult.failure(
          PreparedMealTemplateSaveFailureReason.invalidInput,
        ),
      );
    }

    final keepAliveLink = ref.keepAlive();
    return _mutationQueue
        .run<PreparedMealTemplateSaveResult>(
          operation: () async {
            final currentTemplates = await _currentTemplates();
            final now = DateTime.now();
            final newTemplate = template.copyWith(
              id: _uuid.v4(),
              createdAt: now,
              updatedAt: now,
            );
            final nextTemplates = List<PreparedMeal>.from(currentTemplates)
              ..add(newTemplate);
            final saved = await _saveTemplates(
              previousTemplates: currentTemplates,
              nextTemplates: nextTemplates,
            );
            if (!saved) {
              return const PreparedMealTemplateSaveResult.failure(
                PreparedMealTemplateSaveFailureReason.saveFailed,
              );
            }
            return PreparedMealTemplateSaveResult.success(newTemplate.id);
          },
          fallbackValue: const PreparedMealTemplateSaveResult.failure(
            PreparedMealTemplateSaveFailureReason.saveFailed,
          ),
          onError: (error, stackTrace) {
            log(
              'Unexpected recipe template save error.',
              name: _preparedMealTemplatesControllerLogName,
              error: error,
              stackTrace: stackTrace,
            );
          },
        )
        .whenComplete(keepAliveLink.close);
  }

  /// Save imported recipe template.
  Future<PreparedMealTemplateSaveResult> saveImportedRecipeTemplate({
    required PreparedMealRecipeImport importedRecipe,
    String name = '',
    int? totalPortions,
  }) {
    final keepAliveLink = ref.keepAlive();
    return _mutationQueue
        .run<PreparedMealTemplateSaveResult>(
          operation: () async {
            final currentTemplates = await _currentTemplates();
            return await _saveImportedRecipeTemplate(
              currentTemplates: currentTemplates,
              importedRecipe: importedRecipe,
              name: name,
              totalPortions: totalPortions,
            );
          },
          fallbackValue: const PreparedMealTemplateSaveResult.failure(
            PreparedMealTemplateSaveFailureReason.saveFailed,
          ),
          onError: (error, stackTrace) {
            log(
              'Unexpected imported recipe template save error.',
              name: _preparedMealTemplatesControllerLogName,
              error: error,
              stackTrace: stackTrace,
            );
          },
        )
        .whenComplete(keepAliveLink.close);
  }

  /// Delete template.
  Future<bool> deleteTemplate(String templateId) {
    if (templateId.trim().isEmpty) {
      return Future<bool>.value(false);
    }

    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(() async {
      final currentTemplates = await _currentTemplates();
      final nextTemplates = currentTemplates
          .where((template) => template.id != templateId)
          .toList(growable: false);
      if (nextTemplates.length == currentTemplates.length) {
        return false;
      }
      return await _saveTemplates(
        previousTemplates: currentTemplates,
        nextTemplates: nextTemplates,
      );
    }).whenComplete(keepAliveLink.close);
  }

  void _scheduleRecipeInstructionBackfill(List<PreparedMeal> templates) {
    final candidates = templates
        .where(_needsRecipeInstructionBackfill)
        .where((template) {
          final backfillKey = _recipeInstructionBackfillKey(template);
          if (backfillKey == null) {
            return false;
          }
          return !_recipeInstructionBackfillsInProgress.contains(backfillKey) &&
              !_recipeInstructionBackfillsAttempted.contains(backfillKey);
        })
        .toList(growable: false);
    if (candidates.isEmpty) {
      return;
    }

    for (final candidate in candidates) {
      final backfillKey = _recipeInstructionBackfillKey(candidate);
      if (backfillKey == null) {
        continue;
      }
      _recipeInstructionBackfillsInProgress.add(backfillKey);
      _recipeInstructionBackfillsAttempted.add(backfillKey);
    }
    unawaited(_backfillMissingRecipeInstructions(candidates));
  }

  Future<void> _backfillMissingRecipeInstructions(
    List<PreparedMeal> templates,
  ) async {
    final backfillKeys = templates
        .map(_recipeInstructionBackfillKey)
        .whereType<(String, String)>()
        .toList(growable: false);
    try {
      final importer = ref.read(preparedMealRecipeImporterProvider);
      final fetchedInstructions =
          <
            ({String templateId, String recipeUrl, List<String> instructions})
          >[];

      for (final template in templates) {
        final recipeUrl = template.recipeUrl;
        if (recipeUrl == null || recipeUrl.isEmpty) {
          continue;
        }

        try {
          final importedRecipe = await importer.importRecipe(recipeUrl);
          if (!ref.mounted) {
            return;
          }
          final normalizedInstructions =
              (importedRecipe?.instructions ?? const <String>[])
                  .map((line) => line.trim())
                  .where((line) => line.isNotEmpty)
                  .toList(growable: false);
          if (normalizedInstructions.isEmpty) {
            continue;
          }
          fetchedInstructions.add((
            templateId: template.id,
            recipeUrl: recipeUrl,
            instructions: normalizedInstructions,
          ));
        } on Object catch (error, stackTrace) {
          log(
            'Failed to backfill recipe instructions for template '
            '${template.id}.',
            name: _preparedMealTemplatesControllerLogName,
            error: error,
            stackTrace: stackTrace,
          );
        }
      }

      if (fetchedInstructions.isEmpty || !ref.mounted) {
        return;
      }

      await _mutationQueue.run<bool>(
        operation: () async {
          final currentTemplates = await _currentTemplates();
          if (!ref.mounted) {
            return false;
          }

          final fetchedByTemplateId =
              <
                String,
                ({
                  String templateId,
                  String recipeUrl,
                  List<String> instructions,
                })
              >{
                for (final entry in fetchedInstructions)
                  entry.templateId: entry,
              };
          final nextTemplates = List<PreparedMeal>.from(currentTemplates);
          var hasChanges = false;

          for (var index = 0; index < currentTemplates.length; index++) {
            final template = currentTemplates[index];
            final fetchedTemplate = fetchedByTemplateId[template.id];
            if (fetchedTemplate == null ||
                !_needsRecipeInstructionBackfill(template) ||
                template.recipeUrl != fetchedTemplate.recipeUrl) {
              continue;
            }
            nextTemplates[index] = template.copyWith(
              recipeInstructions: fetchedTemplate.instructions,
            );
            hasChanges = true;
          }

          if (!hasChanges) {
            return true;
          }
          return await _saveTemplates(
            previousTemplates: currentTemplates,
            nextTemplates: nextTemplates,
          );
        },
        fallbackValue: false,
        onError: (error, stackTrace) {
          log(
            'Unexpected recipe instruction backfill error.',
            name: _preparedMealTemplatesControllerLogName,
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
    } finally {
      backfillKeys.forEach(_recipeInstructionBackfillsInProgress.remove);
    }
  }

  Future<List<PreparedMeal>> _currentTemplates() async {
    final currentData = state.asData?.value;
    if (currentData != null) {
      return currentData;
    }
    final templates = await ref
        .read(preparedMealTemplateRepositoryProvider)
        .readAll();
    return _sortTemplates(templates);
  }

  Future<bool> _saveTemplates({
    required List<PreparedMeal> previousTemplates,
    required List<PreparedMeal> nextTemplates,
  }) async {
    final sortedTemplates = _sortTemplates(nextTemplates);
    if (ref.mounted) {
      state = AsyncData(sortedTemplates);
    }

    try {
      final saved = await ref
          .read(preparedMealTemplateRepositoryProvider)
          .saveAll(sortedTemplates);
      if (!saved && ref.mounted) {
        state = AsyncData(_sortTemplates(previousTemplates));
      }
      return saved;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to persist prepared meal template mutation.',
        name: _preparedMealTemplatesControllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
      if (ref.mounted) {
        state = AsyncData(_sortTemplates(previousTemplates));
      }
      return false;
    }
  }

  Future<bool> _runSerializedMutation(Future<bool> Function() mutation) {
    return _mutationQueue.run<bool>(
      operation: mutation,
      fallbackValue: false,
      onError: (error, stackTrace) {
        log(
          'Unexpected prepared meal template mutation error.',
          name: _preparedMealTemplatesControllerLogName,
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  Future<PreparedMealTemplateSaveResult> _saveImportedRecipeTemplate({
    required List<PreparedMeal> currentTemplates,
    required PreparedMealRecipeImport importedRecipe,
    required String name,
    required int? totalPortions,
  }) async {
    final resolvedName = _resolveRecipeTemplateName(
      name: name,
      importedTitle: importedRecipe.title,
      normalizedRecipeUrl: importedRecipe.recipeUrl,
    );
    final resolvedPortions = _resolveRecipeTemplatePortions(
      requestedPortions: totalPortions,
      importedServings: importedRecipe.servings,
    );
    if (resolvedName == null) {
      return const PreparedMealTemplateSaveResult.failure(
        PreparedMealTemplateSaveFailureReason.invalidInput,
      );
    }

    final template = _buildTemplateFromRecipe(
      recipeUrl: importedRecipe.recipeUrl,
      imageUrl: importedRecipe.imageUrl,
      name: resolvedName,
      recipeIngredients: importedRecipe.ingredients,
      recipeInstructions: importedRecipe.instructions,
      totalPortions: resolvedPortions,
    );
    final nextTemplates = List<PreparedMeal>.from(currentTemplates)
      ..add(template);
    final saved = await _saveTemplates(
      previousTemplates: currentTemplates,
      nextTemplates: nextTemplates,
    );
    if (!saved) {
      return const PreparedMealTemplateSaveResult.failure(
        PreparedMealTemplateSaveFailureReason.saveFailed,
      );
    }
    return PreparedMealTemplateSaveResult.success(template.id);
  }
}

PreparedMeal _buildTemplateFromRecipe({
  required String recipeUrl,
  required String? imageUrl,
  required String name,
  required List<String> recipeIngredients,
  required List<String> recipeInstructions,
  required int totalPortions,
}) {
  final now = DateTime.now();
  return PreparedMeal(
    id: PreparedMealTemplatesController._uuid.v4(),
    name: name,
    imageUrl: imageUrl,
    recipeUrl: recipeUrl,
    recipeIngredients: recipeIngredients,
    recipeInstructions: recipeInstructions,
    totalPortions: totalPortions,
    remainingPortions: totalPortions,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    createdAt: now,
    updatedAt: now,
    components: const <PreparedMealComponent>[],
  );
}

String? _resolveRecipeTemplateName({
  required String name,
  required String importedTitle,
  required String? normalizedRecipeUrl,
}) {
  final trimmedName = name.trim();
  if (trimmedName.isNotEmpty) {
    return trimmedName;
  }
  final trimmedImportedTitle = importedTitle.trim();
  if (trimmedImportedTitle.isNotEmpty) {
    return trimmedImportedTitle;
  }
  if (normalizedRecipeUrl == null) {
    return null;
  }

  final uri = Uri.tryParse(normalizedRecipeUrl);
  if (uri == null) {
    return null;
  }

  for (final segment in uri.pathSegments.reversed) {
    final normalizedSegment = _humanizeRecipePathSegment(segment);
    if (normalizedSegment != null) {
      return normalizedSegment;
    }
  }
  return uri.host;
}

int _resolveRecipeTemplatePortions({
  required int? requestedPortions,
  required int importedServings,
}) {
  if (requestedPortions != null && requestedPortions > 0) {
    return requestedPortions;
  }
  if (importedServings > 0) {
    return importedServings;
  }
  return 1;
}

String? _humanizeRecipePathSegment(String segment) {
  final trimmedSegment = Uri.decodeComponent(segment).trim();
  if (trimmedSegment.isEmpty) {
    return null;
  }

  final withoutExtension = trimmedSegment.replaceFirst(
    RegExp(r'\.[A-Za-z0-9]+$'),
    '',
  );
  final withoutSeparators = withoutExtension
      .replaceAll(RegExp('[-_]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (withoutSeparators.isEmpty ||
      RegExp(r'^\d+$').hasMatch(withoutSeparators)) {
    return null;
  }
  if (withoutSeparators.length < 2) {
    return null;
  }

  return withoutSeparators.split(' ').map(_capitalizeWord).join(' ');
}

String _capitalizeWord(String word) {
  if (word.isEmpty) {
    return word;
  }
  return '${word[0].toUpperCase()}${word.substring(1)}';
}

List<PreparedMeal> _sortTemplates(List<PreparedMeal> templates) {
  final sortedTemplates = List<PreparedMeal>.from(templates)
    ..sort((left, right) {
      final byUpdate = right.updatedAt.compareTo(left.updatedAt);
      if (byUpdate != 0) {
        return byUpdate;
      }
      return right.createdAt.compareTo(left.createdAt);
    });
  return List<PreparedMeal>.unmodifiable(sortedTemplates);
}

bool _needsRecipeInstructionBackfill(PreparedMeal template) {
  return (template.recipeUrl?.isNotEmpty ?? false) &&
      template.recipeInstructions.isEmpty;
}

(String, String)? _recipeInstructionBackfillKey(PreparedMeal template) {
  final recipeUrl = template.recipeUrl;
  if (recipeUrl == null || recipeUrl.isEmpty) {
    return null;
  }
  return (template.id, recipeUrl);
}
