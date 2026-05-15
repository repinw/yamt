// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_meal_sections_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides real meal sections for one diary day.

@ProviderFor(diaryMealSections)
final diaryMealSectionsProvider = DiaryMealSectionsFamily._();

/// Provides real meal sections for one diary day.

final class DiaryMealSectionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DiaryMealSection>>,
          List<DiaryMealSection>,
          FutureOr<List<DiaryMealSection>>
        >
    with
        $FutureModifier<List<DiaryMealSection>>,
        $FutureProvider<List<DiaryMealSection>> {
  /// Provides real meal sections for one diary day.
  DiaryMealSectionsProvider._({
    required DiaryMealSectionsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryMealSectionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryMealSectionsHash();

  @override
  String toString() {
    return r'diaryMealSectionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<DiaryMealSection>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DiaryMealSection>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryMealSections(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryMealSectionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryMealSectionsHash() => r'bd334850f504e2f92134cc2213af3413b942d85a';

/// Provides real meal sections for one diary day.

final class DiaryMealSectionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<DiaryMealSection>>, DateTime> {
  DiaryMealSectionsFamily._()
    : super(
        retry: null,
        name: r'diaryMealSectionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides real meal sections for one diary day.

  DiaryMealSectionsProvider call(DateTime day) =>
      DiaryMealSectionsProvider._(argument: day, from: this);

  @override
  String toString() => r'diaryMealSectionsProvider';
}
