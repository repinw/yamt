// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt_capture_flow_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReceiptCaptureFlowResult {

 ReceiptInputSource get source;
/// Create a copy of ReceiptCaptureFlowResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptCaptureFlowResultCopyWith<ReceiptCaptureFlowResult> get copyWith => _$ReceiptCaptureFlowResultCopyWithImpl<ReceiptCaptureFlowResult>(this as ReceiptCaptureFlowResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptCaptureFlowResult&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,source);

@override
String toString() {
  return 'ReceiptCaptureFlowResult(source: $source)';
}


}

/// @nodoc
abstract mixin class $ReceiptCaptureFlowResultCopyWith<$Res>  {
  factory $ReceiptCaptureFlowResultCopyWith(ReceiptCaptureFlowResult value, $Res Function(ReceiptCaptureFlowResult) _then) = _$ReceiptCaptureFlowResultCopyWithImpl;
@useResult
$Res call({
 ReceiptInputSource source
});




}
/// @nodoc
class _$ReceiptCaptureFlowResultCopyWithImpl<$Res>
    implements $ReceiptCaptureFlowResultCopyWith<$Res> {
  _$ReceiptCaptureFlowResultCopyWithImpl(this._self, this._then);

  final ReceiptCaptureFlowResult _self;
  final $Res Function(ReceiptCaptureFlowResult) _then;

/// Create a copy of ReceiptCaptureFlowResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ReceiptInputSource,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceiptCaptureFlowResult].
extension ReceiptCaptureFlowResultPatterns on ReceiptCaptureFlowResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReceiptCaptureFlowCompleted value)?  completed,TResult Function( ReceiptCaptureFlowInputCanceled value)?  inputCanceled,TResult Function( ReceiptCaptureFlowInputUnsupported value)?  inputUnsupported,TResult Function( ReceiptCaptureFlowInputFailed value)?  inputFailed,TResult Function( ReceiptCaptureFlowAnalysisFailed value)?  analysisFailed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReceiptCaptureFlowCompleted() when completed != null:
return completed(_that);case ReceiptCaptureFlowInputCanceled() when inputCanceled != null:
return inputCanceled(_that);case ReceiptCaptureFlowInputUnsupported() when inputUnsupported != null:
return inputUnsupported(_that);case ReceiptCaptureFlowInputFailed() when inputFailed != null:
return inputFailed(_that);case ReceiptCaptureFlowAnalysisFailed() when analysisFailed != null:
return analysisFailed(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReceiptCaptureFlowCompleted value)  completed,required TResult Function( ReceiptCaptureFlowInputCanceled value)  inputCanceled,required TResult Function( ReceiptCaptureFlowInputUnsupported value)  inputUnsupported,required TResult Function( ReceiptCaptureFlowInputFailed value)  inputFailed,required TResult Function( ReceiptCaptureFlowAnalysisFailed value)  analysisFailed,}){
final _that = this;
switch (_that) {
case ReceiptCaptureFlowCompleted():
return completed(_that);case ReceiptCaptureFlowInputCanceled():
return inputCanceled(_that);case ReceiptCaptureFlowInputUnsupported():
return inputUnsupported(_that);case ReceiptCaptureFlowInputFailed():
return inputFailed(_that);case ReceiptCaptureFlowAnalysisFailed():
return analysisFailed(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReceiptCaptureFlowCompleted value)?  completed,TResult? Function( ReceiptCaptureFlowInputCanceled value)?  inputCanceled,TResult? Function( ReceiptCaptureFlowInputUnsupported value)?  inputUnsupported,TResult? Function( ReceiptCaptureFlowInputFailed value)?  inputFailed,TResult? Function( ReceiptCaptureFlowAnalysisFailed value)?  analysisFailed,}){
final _that = this;
switch (_that) {
case ReceiptCaptureFlowCompleted() when completed != null:
return completed(_that);case ReceiptCaptureFlowInputCanceled() when inputCanceled != null:
return inputCanceled(_that);case ReceiptCaptureFlowInputUnsupported() when inputUnsupported != null:
return inputUnsupported(_that);case ReceiptCaptureFlowInputFailed() when inputFailed != null:
return inputFailed(_that);case ReceiptCaptureFlowAnalysisFailed() when analysisFailed != null:
return analysisFailed(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ReceiptInputSource source,  ReceiptAnalysisExtraction extraction,  List<FridgeItem> mappedItems)?  completed,TResult Function( ReceiptInputSource source)?  inputCanceled,TResult Function( ReceiptInputSource source,  String errorCode)?  inputUnsupported,TResult Function( ReceiptInputSource source,  String errorCode)?  inputFailed,TResult Function( ReceiptInputSource source,  String errorCode)?  analysisFailed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReceiptCaptureFlowCompleted() when completed != null:
return completed(_that.source,_that.extraction,_that.mappedItems);case ReceiptCaptureFlowInputCanceled() when inputCanceled != null:
return inputCanceled(_that.source);case ReceiptCaptureFlowInputUnsupported() when inputUnsupported != null:
return inputUnsupported(_that.source,_that.errorCode);case ReceiptCaptureFlowInputFailed() when inputFailed != null:
return inputFailed(_that.source,_that.errorCode);case ReceiptCaptureFlowAnalysisFailed() when analysisFailed != null:
return analysisFailed(_that.source,_that.errorCode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ReceiptInputSource source,  ReceiptAnalysisExtraction extraction,  List<FridgeItem> mappedItems)  completed,required TResult Function( ReceiptInputSource source)  inputCanceled,required TResult Function( ReceiptInputSource source,  String errorCode)  inputUnsupported,required TResult Function( ReceiptInputSource source,  String errorCode)  inputFailed,required TResult Function( ReceiptInputSource source,  String errorCode)  analysisFailed,}) {final _that = this;
switch (_that) {
case ReceiptCaptureFlowCompleted():
return completed(_that.source,_that.extraction,_that.mappedItems);case ReceiptCaptureFlowInputCanceled():
return inputCanceled(_that.source);case ReceiptCaptureFlowInputUnsupported():
return inputUnsupported(_that.source,_that.errorCode);case ReceiptCaptureFlowInputFailed():
return inputFailed(_that.source,_that.errorCode);case ReceiptCaptureFlowAnalysisFailed():
return analysisFailed(_that.source,_that.errorCode);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ReceiptInputSource source,  ReceiptAnalysisExtraction extraction,  List<FridgeItem> mappedItems)?  completed,TResult? Function( ReceiptInputSource source)?  inputCanceled,TResult? Function( ReceiptInputSource source,  String errorCode)?  inputUnsupported,TResult? Function( ReceiptInputSource source,  String errorCode)?  inputFailed,TResult? Function( ReceiptInputSource source,  String errorCode)?  analysisFailed,}) {final _that = this;
switch (_that) {
case ReceiptCaptureFlowCompleted() when completed != null:
return completed(_that.source,_that.extraction,_that.mappedItems);case ReceiptCaptureFlowInputCanceled() when inputCanceled != null:
return inputCanceled(_that.source);case ReceiptCaptureFlowInputUnsupported() when inputUnsupported != null:
return inputUnsupported(_that.source,_that.errorCode);case ReceiptCaptureFlowInputFailed() when inputFailed != null:
return inputFailed(_that.source,_that.errorCode);case ReceiptCaptureFlowAnalysisFailed() when analysisFailed != null:
return analysisFailed(_that.source,_that.errorCode);case _:
  return null;

}
}

}

/// @nodoc


class ReceiptCaptureFlowCompleted extends ReceiptCaptureFlowResult {
  const ReceiptCaptureFlowCompleted({required this.source, required this.extraction, required final  List<FridgeItem> mappedItems}): _mappedItems = mappedItems,super._();
  

@override final  ReceiptInputSource source;
 final  ReceiptAnalysisExtraction extraction;
 final  List<FridgeItem> _mappedItems;
 List<FridgeItem> get mappedItems {
  if (_mappedItems is EqualUnmodifiableListView) return _mappedItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mappedItems);
}


/// Create a copy of ReceiptCaptureFlowResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptCaptureFlowCompletedCopyWith<ReceiptCaptureFlowCompleted> get copyWith => _$ReceiptCaptureFlowCompletedCopyWithImpl<ReceiptCaptureFlowCompleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptCaptureFlowCompleted&&(identical(other.source, source) || other.source == source)&&(identical(other.extraction, extraction) || other.extraction == extraction)&&const DeepCollectionEquality().equals(other._mappedItems, _mappedItems));
}


@override
int get hashCode => Object.hash(runtimeType,source,extraction,const DeepCollectionEquality().hash(_mappedItems));

@override
String toString() {
  return 'ReceiptCaptureFlowResult.completed(source: $source, extraction: $extraction, mappedItems: $mappedItems)';
}


}

/// @nodoc
abstract mixin class $ReceiptCaptureFlowCompletedCopyWith<$Res> implements $ReceiptCaptureFlowResultCopyWith<$Res> {
  factory $ReceiptCaptureFlowCompletedCopyWith(ReceiptCaptureFlowCompleted value, $Res Function(ReceiptCaptureFlowCompleted) _then) = _$ReceiptCaptureFlowCompletedCopyWithImpl;
@override @useResult
$Res call({
 ReceiptInputSource source, ReceiptAnalysisExtraction extraction, List<FridgeItem> mappedItems
});


$ReceiptAnalysisExtractionCopyWith<$Res> get extraction;

}
/// @nodoc
class _$ReceiptCaptureFlowCompletedCopyWithImpl<$Res>
    implements $ReceiptCaptureFlowCompletedCopyWith<$Res> {
  _$ReceiptCaptureFlowCompletedCopyWithImpl(this._self, this._then);

  final ReceiptCaptureFlowCompleted _self;
  final $Res Function(ReceiptCaptureFlowCompleted) _then;

/// Create a copy of ReceiptCaptureFlowResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? extraction = null,Object? mappedItems = null,}) {
  return _then(ReceiptCaptureFlowCompleted(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ReceiptInputSource,extraction: null == extraction ? _self.extraction : extraction // ignore: cast_nullable_to_non_nullable
as ReceiptAnalysisExtraction,mappedItems: null == mappedItems ? _self._mappedItems : mappedItems // ignore: cast_nullable_to_non_nullable
as List<FridgeItem>,
  ));
}

/// Create a copy of ReceiptCaptureFlowResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReceiptAnalysisExtractionCopyWith<$Res> get extraction {
  
  return $ReceiptAnalysisExtractionCopyWith<$Res>(_self.extraction, (value) {
    return _then(_self.copyWith(extraction: value));
  });
}
}

/// @nodoc


class ReceiptCaptureFlowInputCanceled extends ReceiptCaptureFlowResult {
  const ReceiptCaptureFlowInputCanceled({required this.source}): super._();
  

@override final  ReceiptInputSource source;

/// Create a copy of ReceiptCaptureFlowResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptCaptureFlowInputCanceledCopyWith<ReceiptCaptureFlowInputCanceled> get copyWith => _$ReceiptCaptureFlowInputCanceledCopyWithImpl<ReceiptCaptureFlowInputCanceled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptCaptureFlowInputCanceled&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,source);

@override
String toString() {
  return 'ReceiptCaptureFlowResult.inputCanceled(source: $source)';
}


}

/// @nodoc
abstract mixin class $ReceiptCaptureFlowInputCanceledCopyWith<$Res> implements $ReceiptCaptureFlowResultCopyWith<$Res> {
  factory $ReceiptCaptureFlowInputCanceledCopyWith(ReceiptCaptureFlowInputCanceled value, $Res Function(ReceiptCaptureFlowInputCanceled) _then) = _$ReceiptCaptureFlowInputCanceledCopyWithImpl;
@override @useResult
$Res call({
 ReceiptInputSource source
});




}
/// @nodoc
class _$ReceiptCaptureFlowInputCanceledCopyWithImpl<$Res>
    implements $ReceiptCaptureFlowInputCanceledCopyWith<$Res> {
  _$ReceiptCaptureFlowInputCanceledCopyWithImpl(this._self, this._then);

  final ReceiptCaptureFlowInputCanceled _self;
  final $Res Function(ReceiptCaptureFlowInputCanceled) _then;

/// Create a copy of ReceiptCaptureFlowResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,}) {
  return _then(ReceiptCaptureFlowInputCanceled(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ReceiptInputSource,
  ));
}


}

/// @nodoc


class ReceiptCaptureFlowInputUnsupported extends ReceiptCaptureFlowResult {
  const ReceiptCaptureFlowInputUnsupported({required this.source, required this.errorCode}): super._();
  

@override final  ReceiptInputSource source;
 final  String errorCode;

/// Create a copy of ReceiptCaptureFlowResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptCaptureFlowInputUnsupportedCopyWith<ReceiptCaptureFlowInputUnsupported> get copyWith => _$ReceiptCaptureFlowInputUnsupportedCopyWithImpl<ReceiptCaptureFlowInputUnsupported>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptCaptureFlowInputUnsupported&&(identical(other.source, source) || other.source == source)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode));
}


@override
int get hashCode => Object.hash(runtimeType,source,errorCode);

@override
String toString() {
  return 'ReceiptCaptureFlowResult.inputUnsupported(source: $source, errorCode: $errorCode)';
}


}

/// @nodoc
abstract mixin class $ReceiptCaptureFlowInputUnsupportedCopyWith<$Res> implements $ReceiptCaptureFlowResultCopyWith<$Res> {
  factory $ReceiptCaptureFlowInputUnsupportedCopyWith(ReceiptCaptureFlowInputUnsupported value, $Res Function(ReceiptCaptureFlowInputUnsupported) _then) = _$ReceiptCaptureFlowInputUnsupportedCopyWithImpl;
@override @useResult
$Res call({
 ReceiptInputSource source, String errorCode
});




}
/// @nodoc
class _$ReceiptCaptureFlowInputUnsupportedCopyWithImpl<$Res>
    implements $ReceiptCaptureFlowInputUnsupportedCopyWith<$Res> {
  _$ReceiptCaptureFlowInputUnsupportedCopyWithImpl(this._self, this._then);

  final ReceiptCaptureFlowInputUnsupported _self;
  final $Res Function(ReceiptCaptureFlowInputUnsupported) _then;

/// Create a copy of ReceiptCaptureFlowResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? errorCode = null,}) {
  return _then(ReceiptCaptureFlowInputUnsupported(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ReceiptInputSource,errorCode: null == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ReceiptCaptureFlowInputFailed extends ReceiptCaptureFlowResult {
  const ReceiptCaptureFlowInputFailed({required this.source, required this.errorCode}): super._();
  

@override final  ReceiptInputSource source;
 final  String errorCode;

/// Create a copy of ReceiptCaptureFlowResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptCaptureFlowInputFailedCopyWith<ReceiptCaptureFlowInputFailed> get copyWith => _$ReceiptCaptureFlowInputFailedCopyWithImpl<ReceiptCaptureFlowInputFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptCaptureFlowInputFailed&&(identical(other.source, source) || other.source == source)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode));
}


@override
int get hashCode => Object.hash(runtimeType,source,errorCode);

@override
String toString() {
  return 'ReceiptCaptureFlowResult.inputFailed(source: $source, errorCode: $errorCode)';
}


}

/// @nodoc
abstract mixin class $ReceiptCaptureFlowInputFailedCopyWith<$Res> implements $ReceiptCaptureFlowResultCopyWith<$Res> {
  factory $ReceiptCaptureFlowInputFailedCopyWith(ReceiptCaptureFlowInputFailed value, $Res Function(ReceiptCaptureFlowInputFailed) _then) = _$ReceiptCaptureFlowInputFailedCopyWithImpl;
@override @useResult
$Res call({
 ReceiptInputSource source, String errorCode
});




}
/// @nodoc
class _$ReceiptCaptureFlowInputFailedCopyWithImpl<$Res>
    implements $ReceiptCaptureFlowInputFailedCopyWith<$Res> {
  _$ReceiptCaptureFlowInputFailedCopyWithImpl(this._self, this._then);

  final ReceiptCaptureFlowInputFailed _self;
  final $Res Function(ReceiptCaptureFlowInputFailed) _then;

/// Create a copy of ReceiptCaptureFlowResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? errorCode = null,}) {
  return _then(ReceiptCaptureFlowInputFailed(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ReceiptInputSource,errorCode: null == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ReceiptCaptureFlowAnalysisFailed extends ReceiptCaptureFlowResult {
  const ReceiptCaptureFlowAnalysisFailed({required this.source, required this.errorCode}): super._();
  

@override final  ReceiptInputSource source;
 final  String errorCode;

/// Create a copy of ReceiptCaptureFlowResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptCaptureFlowAnalysisFailedCopyWith<ReceiptCaptureFlowAnalysisFailed> get copyWith => _$ReceiptCaptureFlowAnalysisFailedCopyWithImpl<ReceiptCaptureFlowAnalysisFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptCaptureFlowAnalysisFailed&&(identical(other.source, source) || other.source == source)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode));
}


@override
int get hashCode => Object.hash(runtimeType,source,errorCode);

@override
String toString() {
  return 'ReceiptCaptureFlowResult.analysisFailed(source: $source, errorCode: $errorCode)';
}


}

/// @nodoc
abstract mixin class $ReceiptCaptureFlowAnalysisFailedCopyWith<$Res> implements $ReceiptCaptureFlowResultCopyWith<$Res> {
  factory $ReceiptCaptureFlowAnalysisFailedCopyWith(ReceiptCaptureFlowAnalysisFailed value, $Res Function(ReceiptCaptureFlowAnalysisFailed) _then) = _$ReceiptCaptureFlowAnalysisFailedCopyWithImpl;
@override @useResult
$Res call({
 ReceiptInputSource source, String errorCode
});




}
/// @nodoc
class _$ReceiptCaptureFlowAnalysisFailedCopyWithImpl<$Res>
    implements $ReceiptCaptureFlowAnalysisFailedCopyWith<$Res> {
  _$ReceiptCaptureFlowAnalysisFailedCopyWithImpl(this._self, this._then);

  final ReceiptCaptureFlowAnalysisFailed _self;
  final $Res Function(ReceiptCaptureFlowAnalysisFailed) _then;

/// Create a copy of ReceiptCaptureFlowResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? errorCode = null,}) {
  return _then(ReceiptCaptureFlowAnalysisFailed(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ReceiptInputSource,errorCode: null == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
