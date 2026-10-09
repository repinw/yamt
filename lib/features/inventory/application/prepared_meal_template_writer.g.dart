// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_template_writer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The writer that adds cookbook templates.

@ProviderFor(preparedMealTemplateWriter)
final preparedMealTemplateWriterProvider =
    PreparedMealTemplateWriterProvider._();

/// The writer that adds cookbook templates.

final class PreparedMealTemplateWriterProvider
    extends
        $FunctionalProvider<
          PreparedMealTemplateWriter,
          PreparedMealTemplateWriter,
          PreparedMealTemplateWriter
        >
    with $Provider<PreparedMealTemplateWriter> {
  /// The writer that adds cookbook templates.
  PreparedMealTemplateWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preparedMealTemplateWriterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preparedMealTemplateWriterHash();

  @$internal
  @override
  $ProviderElement<PreparedMealTemplateWriter> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PreparedMealTemplateWriter create(Ref ref) {
    return preparedMealTemplateWriter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreparedMealTemplateWriter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreparedMealTemplateWriter>(value),
    );
  }
}

String _$preparedMealTemplateWriterHash() =>
    r'612c1982652a0b0b46707510018c4957eef1e071';
