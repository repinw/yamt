import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/household/provider/'
    'household_access_recovery_utils.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_url_parser.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

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
  const PreparedMealTemplateSaveResult._({
    required this.isSuccess,
    this.templateId,
    this.failureReason,
  });

  /// Creates a [PreparedMealTemplateSaveResult] for success.
  const PreparedMealTemplateSaveResult.success(String templateId)
    : this._(isSuccess: true, templateId: templateId);

  /// Creates a [PreparedMealTemplateSaveResult] for failure.
  const PreparedMealTemplateSaveResult.failure(
    PreparedMealTemplateSaveFailureReason reason,
  ) : this._(isSuccess: false, failureReason: reason);

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

  // Subscription is cancelled by `_disposeSubscription`.
  // ignore: cancel_subscriptions
  StreamSubscription<List<PreparedMeal>>? _templatesSubscription;
  int _subscriptionGeneration = 0;
  final _mutationQueue = SerializedMutationQueue();
  final Set<(String, String)> _recipeInstructionBackfillsInProgress =
      <(String, String)>{};
  final Set<(String, String)> _recipeInstructionBackfillsAttempted =
      <(String, String)>{};
  String? _currentDataOwnerUserId;
  bool _isRecoveringHouseholdAccess = false;

  @override
  FutureOr<List<PreparedMeal>> build() {
    ref
      ..watch(householdDataOwnerUserIdProvider)
      ..watch(preparedMealTemplateRepositoryProvider)
      ..onDispose(() {
        unawaited(_disposeSubscription());
      });
    _currentDataOwnerUserId = ref.watch(
      effectiveHouseholdDataOwnerUserIdProvider,
    );
    return _restartSubscription();
  }

  /// Refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(_restartSubscription);
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

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
            final template = _buildTemplateFromMeal(meal);
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

  /// Create template from recipe.
  Future<PreparedMealTemplateSaveResult> createTemplateFromRecipe({
    required String recipeUrl,
    String name = '',
    int? totalPortions,
    String? localeName,
  }) {
    final normalizedRecipeUrl = _normalizeRecipeUrl(recipeUrl);
    if (normalizedRecipeUrl == null) {
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
            final importedRecipe = await ref
                .read(preparedMealRecipeImporterProvider)
                .importRecipe(normalizedRecipeUrl, localeName: localeName);
            if (importedRecipe == null) {
              return const PreparedMealTemplateSaveResult.failure(
                PreparedMealTemplateSaveFailureReason.recipeLoadFailed,
              );
            }

            return _saveImportedRecipeTemplate(
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
            return _saveImportedRecipeTemplate(
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

  /// Update recipe template.
  Future<PreparedMealTemplateSaveResult> updateRecipeTemplate({
    required String templateId,
    required String recipeUrl,
    String name = '',
    int? totalPortions,
    String? localeName,
  }) {
    final normalizedRecipeUrl = _normalizeRecipeUrl(recipeUrl);
    if (templateId.trim().isEmpty || normalizedRecipeUrl == null) {
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
            final templateIndex = currentTemplates.indexWhere(
              (template) => template.id == templateId,
            );
            if (templateIndex < 0) {
              return const PreparedMealTemplateSaveResult.failure(
                PreparedMealTemplateSaveFailureReason.invalidInput,
              );
            }

            final currentTemplate = currentTemplates[templateIndex];
            final shouldReloadRecipe =
                currentTemplate.recipeUrl != normalizedRecipeUrl;
            var nextRecipeUrl = normalizedRecipeUrl;
            var nextImageUrl = currentTemplate.imageUrl;
            var nextRecipeIngredients = currentTemplate.recipeIngredients;
            var nextRecipeInstructions = currentTemplate.recipeInstructions;
            var nextIgnoredIngredients =
                currentTemplate.ignoredRecipeIngredients;
            var nextRecipeIngredientAssignments =
                currentTemplate.recipeIngredientAssignments;
            var importedTitle = currentTemplate.name;
            var importedServings = currentTemplate.totalPortions;

            if (shouldReloadRecipe) {
              final importedRecipe = await ref
                  .read(preparedMealRecipeImporterProvider)
                  .importRecipe(normalizedRecipeUrl, localeName: localeName);
              if (importedRecipe == null) {
                return const PreparedMealTemplateSaveResult.failure(
                  PreparedMealTemplateSaveFailureReason.recipeLoadFailed,
                );
              }
              nextRecipeUrl = importedRecipe.recipeUrl;
              nextImageUrl = importedRecipe.imageUrl;
              nextRecipeIngredients = importedRecipe.ingredients;
              nextRecipeInstructions = importedRecipe.instructions;
              nextIgnoredIngredients = const <String>[];
              nextRecipeIngredientAssignments = const <String, List<String>>{};
              importedTitle = importedRecipe.title;
              importedServings = importedRecipe.servings;
            }

            final resolvedName = _resolveRecipeTemplateName(
              name: name,
              importedTitle: importedTitle,
              normalizedRecipeUrl: nextRecipeUrl,
            );
            if (resolvedName == null) {
              return const PreparedMealTemplateSaveResult.failure(
                PreparedMealTemplateSaveFailureReason.invalidInput,
              );
            }

            final resolvedPortions = _resolveRecipeTemplatePortions(
              requestedPortions: totalPortions,
              importedServings: importedServings,
            );
            final nextTemplates = List<PreparedMeal>.from(currentTemplates);
            nextTemplates[templateIndex] = currentTemplate.copyWith(
              name: resolvedName,
              imageUrl: nextImageUrl,
              recipeUrl: nextRecipeUrl,
              recipeIngredients: nextRecipeIngredients,
              recipeInstructions: nextRecipeInstructions,
              ignoredRecipeIngredients: nextIgnoredIngredients,
              recipeIngredientAssignments: nextRecipeIngredientAssignments,
              totalPortions: resolvedPortions,
              remainingPortions: resolvedPortions,
              updatedAt: DateTime.now(),
            );
            final saved = await _saveTemplates(
              previousTemplates: currentTemplates,
              nextTemplates: nextTemplates,
            );
            if (!saved) {
              return const PreparedMealTemplateSaveResult.failure(
                PreparedMealTemplateSaveFailureReason.saveFailed,
              );
            }
            return PreparedMealTemplateSaveResult.success(templateId);
          },
          fallbackValue: const PreparedMealTemplateSaveResult.failure(
            PreparedMealTemplateSaveFailureReason.saveFailed,
          ),
          onError: (error, stackTrace) {
            log(
              'Unexpected recipe template update error.',
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
      return _saveTemplates(
        previousTemplates: currentTemplates,
        nextTemplates: nextTemplates,
      );
    }).whenComplete(keepAliveLink.close);
  }

  /// Set recipe ingredient ignored.
  Future<bool> setRecipeIngredientIgnored({
    required String templateId,
    required String ingredient,
    required bool isIgnored,
  }) {
    if (templateId.trim().isEmpty || ingredient.trim().isEmpty) {
      return Future<bool>.value(false);
    }

    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(() async {
      final currentTemplates = await _currentTemplates();
      final templateIndex = currentTemplates.indexWhere(
        (template) => template.id == templateId,
      );
      if (templateIndex < 0) {
        return false;
      }

      final currentTemplate = currentTemplates[templateIndex];
      final normalizedIngredient = ingredient.trim();
      final nextIgnoredIngredients = List<String>.from(
        currentTemplate.ignoredRecipeIngredients,
      );
      final alreadyIgnored = nextIgnoredIngredients.contains(
        normalizedIngredient,
      );
      if (isIgnored && !alreadyIgnored) {
        nextIgnoredIngredients.add(normalizedIngredient);
      } else if (!isIgnored && alreadyIgnored) {
        nextIgnoredIngredients.remove(normalizedIngredient);
      } else {
        return true;
      }

      final nextTemplates = List<PreparedMeal>.from(currentTemplates);
      nextTemplates[templateIndex] = currentTemplate.copyWith(
        ignoredRecipeIngredients: nextIgnoredIngredients,
        updatedAt: DateTime.now(),
      );
      return _saveTemplates(
        previousTemplates: currentTemplates,
        nextTemplates: nextTemplates,
      );
    }).whenComplete(keepAliveLink.close);
  }

  /// Update recipe ingredient assignments.
  Future<bool> updateRecipeIngredientAssignments({
    required String templateId,
    required Map<String, List<String>> recipeIngredientAssignments,
    required Map<String, RecipeIngredientAmountConversion>
    recipeIngredientAmountConversions,
  }) {
    if (templateId.trim().isEmpty) {
      return Future<bool>.value(false);
    }

    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(() async {
      final currentTemplates = await _currentTemplates();
      final templateIndex = currentTemplates.indexWhere(
        (template) => template.id == templateId,
      );
      if (templateIndex < 0) {
        return false;
      }

      final currentTemplate = currentTemplates[templateIndex];
      final nextAssignments = <String, List<String>>{};
      for (final entry in recipeIngredientAssignments.entries) {
        final ingredient = entry.key.trim();
        if (ingredient.isEmpty) {
          continue;
        }
        final itemIds = entry.value
            .map((itemId) => itemId.trim())
            .where((itemId) => itemId.isNotEmpty)
            .toSet()
            .toList(growable: false);
        if (itemIds.isEmpty) {
          continue;
        }
        nextAssignments[ingredient] = itemIds;
      }
      final nextConversions = <String, RecipeIngredientAmountConversion>{};
      for (final entry in recipeIngredientAmountConversions.entries) {
        final ingredient = entry.key.trim();
        final conversion = entry.value;
        if (ingredient.isEmpty ||
            conversion.amountPerPiece < 1 ||
            conversion.unit == InventoryAmountUnit.piece ||
            !nextAssignments.containsKey(ingredient)) {
          continue;
        }
        nextConversions[ingredient] = conversion;
      }

      final nextTemplates = List<PreparedMeal>.from(currentTemplates);
      nextTemplates[templateIndex] = currentTemplate.copyWith(
        recipeIngredientAssignments: nextAssignments,
        recipeIngredientAmountConversions: nextConversions,
        updatedAt: DateTime.now(),
      );
      return _saveTemplates(
        previousTemplates: currentTemplates,
        nextTemplates: nextTemplates,
      );
    }).whenComplete(keepAliveLink.close);
  }

  Future<List<PreparedMeal>> _restartSubscription() async {
    final initialTemplates = Completer<List<PreparedMeal>>();
    _currentDataOwnerUserId = ref.read(
      effectiveHouseholdDataOwnerUserIdProvider,
    );
    final repository = ref.read(preparedMealTemplateRepositoryProvider);
    final generation = ++_subscriptionGeneration;
    await _disposeSubscription();

    _templatesSubscription = repository.watchAll().listen(
      (templates) {
        if (generation != _subscriptionGeneration) {
          return;
        }
        final sortedTemplates = _sortTemplates(templates);
        _scheduleRecipeInstructionBackfill(sortedTemplates);
        if (!initialTemplates.isCompleted) {
          initialTemplates.complete(sortedTemplates);
          return;
        }
        _onRealtimeTemplates(sortedTemplates);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (generation != _subscriptionGeneration) {
          return;
        }
        if (!initialTemplates.isCompleted) {
          if (_shouldRecoverFromRevokedHouseholdAccess(error)) {
            initialTemplates.complete(const <PreparedMeal>[]);
            unawaited(_recoverFromRevokedHouseholdAccess(showLoading: false));
            return;
          }
          initialTemplates.completeError(error, stackTrace);
          return;
        }
        _onRealtimeError(error, stackTrace);
      },
    );

    return initialTemplates.future;
  }

  Future<void> _disposeSubscription() async {
    final currentSubscription = _templatesSubscription;
    _templatesSubscription = null;
    if (currentSubscription != null) {
      await currentSubscription.cancel();
    }
  }

  void _onRealtimeTemplates(List<PreparedMeal> templates) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(templates);
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
          return _saveTemplates(
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

  void _onRealtimeError(Object error, StackTrace stackTrace) {
    if (_shouldRecoverFromRevokedHouseholdAccess(error)) {
      unawaited(_recoverFromRevokedHouseholdAccess());
      return;
    }
    if (!ref.mounted) {
      return;
    }
    state = AsyncError(error, stackTrace);
  }

  bool _shouldRecoverFromRevokedHouseholdAccess(Object error) {
    return shouldRecoverControllerHouseholdAccess(
      ref: ref,
      error: error,
      isRecoveringHouseholdAccess: _isRecoveringHouseholdAccess,
      currentHouseholdDataOwnerUserId: _currentDataOwnerUserId,
    );
  }

  Future<void> _recoverFromRevokedHouseholdAccess({bool showLoading = true}) {
    return recoverControllerHouseholdAccess<PreparedMeal>(
      ref: ref,
      isRecoveringHouseholdAccess: _isRecoveringHouseholdAccess,
      setIsRecoveringHouseholdAccess: ({required value}) {
        _isRecoveringHouseholdAccess = value;
      },
      setState: (nextState) {
        state = nextState;
      },
      restartHouseholdScopedSubscription: _restartSubscription,
      currentHouseholdDataOwnerUserId: _currentDataOwnerUserId,
      householdAccessRecoveryLogName: _preparedMealTemplatesControllerLogName,
      householdAccessRecoveryMessage:
          'Rebuilding prepared meal template stream after household access '
          'changed.',
      showLoading: showLoading,
    );
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

PreparedMeal _buildTemplateFromMeal(PreparedMeal meal) {
  final now = DateTime.now();
  return meal.copyWith(
    id: PreparedMealTemplatesController._uuid.v4(),
    name: meal.name.trim(),
    remainingPortions: meal.totalPortions,
    createdAt: now,
    updatedAt: now,
  );
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

String? _normalizeRecipeUrl(String value) =>
    normalizePreparedMealRecipeUrl(value);

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
