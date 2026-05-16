// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_ingredient_parser.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the template ingredient parser.

@ProviderFor(templateIngredientParser)
final templateIngredientParserProvider = TemplateIngredientParserProvider._();

/// Provides the template ingredient parser.

final class TemplateIngredientParserProvider
    extends
        $FunctionalProvider<
          TemplateIngredientParser,
          TemplateIngredientParser,
          TemplateIngredientParser
        >
    with $Provider<TemplateIngredientParser> {
  /// Provides the template ingredient parser.
  TemplateIngredientParserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'templateIngredientParserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$templateIngredientParserHash();

  @$internal
  @override
  $ProviderElement<TemplateIngredientParser> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TemplateIngredientParser create(Ref ref) {
    return templateIngredientParser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TemplateIngredientParser value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TemplateIngredientParser>(value),
    );
  }
}

String _$templateIngredientParserHash() =>
    r'5d0600ddaeaba650b461d8c37eddf83727cd0e86';
