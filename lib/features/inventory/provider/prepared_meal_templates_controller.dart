import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'prepared_meal_templates_controller.g.dart';

const _preparedMealTemplatesControllerLogName =
    'PreparedMealTemplatesController';

@riverpod
class PreparedMealTemplatesController
    extends _$PreparedMealTemplatesController {
  static const _uuid = Uuid();

  StreamSubscription<List<PreparedMeal>>? _templatesSubscription;
  final _mutationQueue = SerializedMutationQueue();

  @override
  FutureOr<List<PreparedMeal>> build() {
    ref.watch(preparedMealTemplateRepositoryProvider);
    ref.onDispose(_disposeSubscription);
    return _restartSubscription();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(_restartSubscription);
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  Future<bool> saveTemplateFromMeal(PreparedMeal meal) {
    if (meal.name.trim().isEmpty ||
        meal.components.isEmpty ||
        meal.totalPortions < 1) {
      return Future<bool>.value(false);
    }

    final keepAliveLink = ref.keepAlive();
    return _runSerializedMutation(() async {
      final currentTemplates = await _currentTemplates();
      final template = _buildTemplateFromMeal(meal);
      final nextTemplates = List<PreparedMeal>.from(currentTemplates)
        ..add(template);
      return _saveTemplates(
        previousTemplates: currentTemplates,
        nextTemplates: nextTemplates,
      );
    }).whenComplete(keepAliveLink.close);
  }

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

  Future<List<PreparedMeal>> _restartSubscription() {
    final initialTemplates = Completer<List<PreparedMeal>>();
    final repository = ref.read(preparedMealTemplateRepositoryProvider);
    _disposeSubscription();

    _templatesSubscription = repository.watchAll().listen(
      (templates) {
        final sortedTemplates = _sortTemplates(templates);
        if (!initialTemplates.isCompleted) {
          initialTemplates.complete(sortedTemplates);
          return;
        }
        _onRealtimeTemplates(sortedTemplates);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!initialTemplates.isCompleted) {
          initialTemplates.completeError(error, stackTrace);
          return;
        }
        _onRealtimeError(error, stackTrace);
      },
    );

    return initialTemplates.future;
  }

  void _disposeSubscription() {
    final currentSubscription = _templatesSubscription;
    _templatesSubscription = null;
    if (currentSubscription != null) {
      unawaited(currentSubscription.cancel());
    }
  }

  void _onRealtimeTemplates(List<PreparedMeal> templates) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(templates);
  }

  void _onRealtimeError(Object error, StackTrace stackTrace) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncError(error, stackTrace);
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
    } catch (error, stackTrace) {
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

List<PreparedMeal> _sortTemplates(List<PreparedMeal> templates) {
  final sortedTemplates = List<PreparedMeal>.from(templates);
  sortedTemplates.sort((left, right) {
    final byUpdate = right.updatedAt.compareTo(left.updatedAt);
    if (byUpdate != 0) {
      return byUpdate;
    }
    return right.createdAt.compareTo(left.createdAt);
  });
  return List<PreparedMeal>.unmodifiable(sortedTemplates);
}
