// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_today_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Today's diary day from [clockProvider]. It moves on when
/// [DiaryToday.refresh] reads the clock again, at midnight and when the app
/// resumes.

@ProviderFor(DiaryToday)
final diaryTodayProvider = DiaryTodayProvider._();

/// Today's diary day from [clockProvider]. It moves on when
/// [DiaryToday.refresh] reads the clock again, at midnight and when the app
/// resumes.
final class DiaryTodayProvider extends $NotifierProvider<DiaryToday, DateTime> {
  /// Today's diary day from [clockProvider]. It moves on when
  /// [DiaryToday.refresh] reads the clock again, at midnight and when the app
  /// resumes.
  DiaryTodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryTodayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryTodayHash();

  @$internal
  @override
  DiaryToday create() => DiaryToday();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$diaryTodayHash() => r'be4539c23a5cf997e2170844167f3d51fd04771b';

/// Today's diary day from [clockProvider]. It moves on when
/// [DiaryToday.refresh] reads the clock again, at midnight and when the app
/// resumes.

abstract class _$DiaryToday extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
