// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt_analysis_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReceiptAnalysisExtraction {

 Map<String, dynamic> get root; List<ReceiptAnalysisItem> get items;
/// Create a copy of ReceiptAnalysisExtraction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptAnalysisExtractionCopyWith<ReceiptAnalysisExtraction> get copyWith => _$ReceiptAnalysisExtractionCopyWithImpl<ReceiptAnalysisExtraction>(this as ReceiptAnalysisExtraction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptAnalysisExtraction&&const DeepCollectionEquality().equals(other.root, root)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(root),const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'ReceiptAnalysisExtraction(root: $root, items: $items)';
}


}

/// @nodoc
abstract mixin class $ReceiptAnalysisExtractionCopyWith<$Res>  {
  factory $ReceiptAnalysisExtractionCopyWith(ReceiptAnalysisExtraction value, $Res Function(ReceiptAnalysisExtraction) _then) = _$ReceiptAnalysisExtractionCopyWithImpl;
@useResult
$Res call({
 Map<String, dynamic> root, List<ReceiptAnalysisItem> items
});




}
/// @nodoc
class _$ReceiptAnalysisExtractionCopyWithImpl<$Res>
    implements $ReceiptAnalysisExtractionCopyWith<$Res> {
  _$ReceiptAnalysisExtractionCopyWithImpl(this._self, this._then);

  final ReceiptAnalysisExtraction _self;
  final $Res Function(ReceiptAnalysisExtraction) _then;

/// Create a copy of ReceiptAnalysisExtraction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? root = null,Object? items = null,}) {
  return _then(_self.copyWith(
root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ReceiptAnalysisItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceiptAnalysisExtraction].
extension ReceiptAnalysisExtractionPatterns on ReceiptAnalysisExtraction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceiptAnalysisExtraction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceiptAnalysisExtraction() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceiptAnalysisExtraction value)  $default,){
final _that = this;
switch (_that) {
case _ReceiptAnalysisExtraction():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceiptAnalysisExtraction value)?  $default,){
final _that = this;
switch (_that) {
case _ReceiptAnalysisExtraction() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, dynamic> root,  List<ReceiptAnalysisItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceiptAnalysisExtraction() when $default != null:
return $default(_that.root,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, dynamic> root,  List<ReceiptAnalysisItem> items)  $default,) {final _that = this;
switch (_that) {
case _ReceiptAnalysisExtraction():
return $default(_that.root,_that.items);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, dynamic> root,  List<ReceiptAnalysisItem> items)?  $default,) {final _that = this;
switch (_that) {
case _ReceiptAnalysisExtraction() when $default != null:
return $default(_that.root,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _ReceiptAnalysisExtraction implements ReceiptAnalysisExtraction {
  const _ReceiptAnalysisExtraction({required final  Map<String, dynamic> root, required final  List<ReceiptAnalysisItem> items}): _root = root,_items = items;
  

 final  Map<String, dynamic> _root;
@override Map<String, dynamic> get root {
  if (_root is EqualUnmodifiableMapView) return _root;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_root);
}

 final  List<ReceiptAnalysisItem> _items;
@override List<ReceiptAnalysisItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of ReceiptAnalysisExtraction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptAnalysisExtractionCopyWith<_ReceiptAnalysisExtraction> get copyWith => __$ReceiptAnalysisExtractionCopyWithImpl<_ReceiptAnalysisExtraction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptAnalysisExtraction&&const DeepCollectionEquality().equals(other._root, _root)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_root),const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'ReceiptAnalysisExtraction(root: $root, items: $items)';
}


}

/// @nodoc
abstract mixin class _$ReceiptAnalysisExtractionCopyWith<$Res> implements $ReceiptAnalysisExtractionCopyWith<$Res> {
  factory _$ReceiptAnalysisExtractionCopyWith(_ReceiptAnalysisExtraction value, $Res Function(_ReceiptAnalysisExtraction) _then) = __$ReceiptAnalysisExtractionCopyWithImpl;
@override @useResult
$Res call({
 Map<String, dynamic> root, List<ReceiptAnalysisItem> items
});




}
/// @nodoc
class __$ReceiptAnalysisExtractionCopyWithImpl<$Res>
    implements _$ReceiptAnalysisExtractionCopyWith<$Res> {
  __$ReceiptAnalysisExtractionCopyWithImpl(this._self, this._then);

  final _ReceiptAnalysisExtraction _self;
  final $Res Function(_ReceiptAnalysisExtraction) _then;

/// Create a copy of ReceiptAnalysisExtraction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? root = null,Object? items = null,}) {
  return _then(_ReceiptAnalysisExtraction(
root: null == root ? _self._root : root // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ReceiptAnalysisItem>,
  ));
}


}

/// @nodoc
mixin _$ReceiptAnalysisItem {

 String get name; Map<String, dynamic> get rawPayload;
/// Create a copy of ReceiptAnalysisItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptAnalysisItemCopyWith<ReceiptAnalysisItem> get copyWith => _$ReceiptAnalysisItemCopyWithImpl<ReceiptAnalysisItem>(this as ReceiptAnalysisItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptAnalysisItem&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.rawPayload, rawPayload));
}


@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(rawPayload));

@override
String toString() {
  return 'ReceiptAnalysisItem(name: $name, rawPayload: $rawPayload)';
}


}

/// @nodoc
abstract mixin class $ReceiptAnalysisItemCopyWith<$Res>  {
  factory $ReceiptAnalysisItemCopyWith(ReceiptAnalysisItem value, $Res Function(ReceiptAnalysisItem) _then) = _$ReceiptAnalysisItemCopyWithImpl;
@useResult
$Res call({
 String name, Map<String, dynamic> rawPayload
});




}
/// @nodoc
class _$ReceiptAnalysisItemCopyWithImpl<$Res>
    implements $ReceiptAnalysisItemCopyWith<$Res> {
  _$ReceiptAnalysisItemCopyWithImpl(this._self, this._then);

  final ReceiptAnalysisItem _self;
  final $Res Function(ReceiptAnalysisItem) _then;

/// Create a copy of ReceiptAnalysisItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? rawPayload = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rawPayload: null == rawPayload ? _self.rawPayload : rawPayload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceiptAnalysisItem].
extension ReceiptAnalysisItemPatterns on ReceiptAnalysisItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceiptAnalysisItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceiptAnalysisItem() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceiptAnalysisItem value)  $default,){
final _that = this;
switch (_that) {
case _ReceiptAnalysisItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceiptAnalysisItem value)?  $default,){
final _that = this;
switch (_that) {
case _ReceiptAnalysisItem() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  Map<String, dynamic> rawPayload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceiptAnalysisItem() when $default != null:
return $default(_that.name,_that.rawPayload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  Map<String, dynamic> rawPayload)  $default,) {final _that = this;
switch (_that) {
case _ReceiptAnalysisItem():
return $default(_that.name,_that.rawPayload);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  Map<String, dynamic> rawPayload)?  $default,) {final _that = this;
switch (_that) {
case _ReceiptAnalysisItem() when $default != null:
return $default(_that.name,_that.rawPayload);case _:
  return null;

}
}

}

/// @nodoc


class _ReceiptAnalysisItem implements ReceiptAnalysisItem {
  const _ReceiptAnalysisItem({required this.name, required final  Map<String, dynamic> rawPayload}): _rawPayload = rawPayload;
  

@override final  String name;
 final  Map<String, dynamic> _rawPayload;
@override Map<String, dynamic> get rawPayload {
  if (_rawPayload is EqualUnmodifiableMapView) return _rawPayload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_rawPayload);
}


/// Create a copy of ReceiptAnalysisItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptAnalysisItemCopyWith<_ReceiptAnalysisItem> get copyWith => __$ReceiptAnalysisItemCopyWithImpl<_ReceiptAnalysisItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptAnalysisItem&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._rawPayload, _rawPayload));
}


@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_rawPayload));

@override
String toString() {
  return 'ReceiptAnalysisItem(name: $name, rawPayload: $rawPayload)';
}


}

/// @nodoc
abstract mixin class _$ReceiptAnalysisItemCopyWith<$Res> implements $ReceiptAnalysisItemCopyWith<$Res> {
  factory _$ReceiptAnalysisItemCopyWith(_ReceiptAnalysisItem value, $Res Function(_ReceiptAnalysisItem) _then) = __$ReceiptAnalysisItemCopyWithImpl;
@override @useResult
$Res call({
 String name, Map<String, dynamic> rawPayload
});




}
/// @nodoc
class __$ReceiptAnalysisItemCopyWithImpl<$Res>
    implements _$ReceiptAnalysisItemCopyWith<$Res> {
  __$ReceiptAnalysisItemCopyWithImpl(this._self, this._then);

  final _ReceiptAnalysisItem _self;
  final $Res Function(_ReceiptAnalysisItem) _then;

/// Create a copy of ReceiptAnalysisItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? rawPayload = null,}) {
  return _then(_ReceiptAnalysisItem(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rawPayload: null == rawPayload ? _self._rawPayload : rawPayload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

/// @nodoc
mixin _$ReceiptAnalysisResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptAnalysisResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReceiptAnalysisResult()';
}


}

/// @nodoc
class $ReceiptAnalysisResultCopyWith<$Res>  {
$ReceiptAnalysisResultCopyWith(ReceiptAnalysisResult _, $Res Function(ReceiptAnalysisResult) __);
}


/// Adds pattern-matching-related methods to [ReceiptAnalysisResult].
extension ReceiptAnalysisResultPatterns on ReceiptAnalysisResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReceiptAnalysisSuccess value)?  succeeded,TResult Function( ReceiptAnalysisFailure value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReceiptAnalysisSuccess() when succeeded != null:
return succeeded(_that);case ReceiptAnalysisFailure() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReceiptAnalysisSuccess value)  succeeded,required TResult Function( ReceiptAnalysisFailure value)  failed,}){
final _that = this;
switch (_that) {
case ReceiptAnalysisSuccess():
return succeeded(_that);case ReceiptAnalysisFailure():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReceiptAnalysisSuccess value)?  succeeded,TResult? Function( ReceiptAnalysisFailure value)?  failed,}){
final _that = this;
switch (_that) {
case ReceiptAnalysisSuccess() when succeeded != null:
return succeeded(_that);case ReceiptAnalysisFailure() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String rawResponse,  ReceiptAnalysisExtraction extraction)?  succeeded,TResult Function( String errorCode)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReceiptAnalysisSuccess() when succeeded != null:
return succeeded(_that.rawResponse,_that.extraction);case ReceiptAnalysisFailure() when failed != null:
return failed(_that.errorCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String rawResponse,  ReceiptAnalysisExtraction extraction)  succeeded,required TResult Function( String errorCode)  failed,}) {final _that = this;
switch (_that) {
case ReceiptAnalysisSuccess():
return succeeded(_that.rawResponse,_that.extraction);case ReceiptAnalysisFailure():
return failed(_that.errorCode);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String rawResponse,  ReceiptAnalysisExtraction extraction)?  succeeded,TResult? Function( String errorCode)?  failed,}) {final _that = this;
switch (_that) {
case ReceiptAnalysisSuccess() when succeeded != null:
return succeeded(_that.rawResponse,_that.extraction);case ReceiptAnalysisFailure() when failed != null:
return failed(_that.errorCode);case _:
  return null;

}
}

}

/// @nodoc


class ReceiptAnalysisSuccess extends ReceiptAnalysisResult {
  const ReceiptAnalysisSuccess({required this.rawResponse, required this.extraction}): super._();
  

 final  String rawResponse;
 final  ReceiptAnalysisExtraction extraction;

/// Create a copy of ReceiptAnalysisResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptAnalysisSuccessCopyWith<ReceiptAnalysisSuccess> get copyWith => _$ReceiptAnalysisSuccessCopyWithImpl<ReceiptAnalysisSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptAnalysisSuccess&&(identical(other.rawResponse, rawResponse) || other.rawResponse == rawResponse)&&(identical(other.extraction, extraction) || other.extraction == extraction));
}


@override
int get hashCode => Object.hash(runtimeType,rawResponse,extraction);

@override
String toString() {
  return 'ReceiptAnalysisResult.succeeded(rawResponse: $rawResponse, extraction: $extraction)';
}


}

/// @nodoc
abstract mixin class $ReceiptAnalysisSuccessCopyWith<$Res> implements $ReceiptAnalysisResultCopyWith<$Res> {
  factory $ReceiptAnalysisSuccessCopyWith(ReceiptAnalysisSuccess value, $Res Function(ReceiptAnalysisSuccess) _then) = _$ReceiptAnalysisSuccessCopyWithImpl;
@useResult
$Res call({
 String rawResponse, ReceiptAnalysisExtraction extraction
});


$ReceiptAnalysisExtractionCopyWith<$Res> get extraction;

}
/// @nodoc
class _$ReceiptAnalysisSuccessCopyWithImpl<$Res>
    implements $ReceiptAnalysisSuccessCopyWith<$Res> {
  _$ReceiptAnalysisSuccessCopyWithImpl(this._self, this._then);

  final ReceiptAnalysisSuccess _self;
  final $Res Function(ReceiptAnalysisSuccess) _then;

/// Create a copy of ReceiptAnalysisResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rawResponse = null,Object? extraction = null,}) {
  return _then(ReceiptAnalysisSuccess(
rawResponse: null == rawResponse ? _self.rawResponse : rawResponse // ignore: cast_nullable_to_non_nullable
as String,extraction: null == extraction ? _self.extraction : extraction // ignore: cast_nullable_to_non_nullable
as ReceiptAnalysisExtraction,
  ));
}

/// Create a copy of ReceiptAnalysisResult
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


class ReceiptAnalysisFailure extends ReceiptAnalysisResult {
  const ReceiptAnalysisFailure({required this.errorCode}): super._();
  

 final  String errorCode;

/// Create a copy of ReceiptAnalysisResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptAnalysisFailureCopyWith<ReceiptAnalysisFailure> get copyWith => _$ReceiptAnalysisFailureCopyWithImpl<ReceiptAnalysisFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptAnalysisFailure&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode));
}


@override
int get hashCode => Object.hash(runtimeType,errorCode);

@override
String toString() {
  return 'ReceiptAnalysisResult.failed(errorCode: $errorCode)';
}


}

/// @nodoc
abstract mixin class $ReceiptAnalysisFailureCopyWith<$Res> implements $ReceiptAnalysisResultCopyWith<$Res> {
  factory $ReceiptAnalysisFailureCopyWith(ReceiptAnalysisFailure value, $Res Function(ReceiptAnalysisFailure) _then) = _$ReceiptAnalysisFailureCopyWithImpl;
@useResult
$Res call({
 String errorCode
});




}
/// @nodoc
class _$ReceiptAnalysisFailureCopyWithImpl<$Res>
    implements $ReceiptAnalysisFailureCopyWith<$Res> {
  _$ReceiptAnalysisFailureCopyWithImpl(this._self, this._then);

  final ReceiptAnalysisFailure _self;
  final $Res Function(ReceiptAnalysisFailure) _then;

/// Create a copy of ReceiptAnalysisResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorCode = null,}) {
  return _then(ReceiptAnalysisFailure(
errorCode: null == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
