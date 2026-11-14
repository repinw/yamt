// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_chef_exclusions.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiChefExclusions {

 List<String> get ingredients;
/// Create a copy of AiChefExclusions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiChefExclusionsCopyWith<AiChefExclusions> get copyWith => _$AiChefExclusionsCopyWithImpl<AiChefExclusions>(this as AiChefExclusions, _$identity);

  /// Serializes this AiChefExclusions to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AiChefExclusions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiChefExclusions&&const DeepCollectionEquality().equals(other.ingredients, _this.ingredients));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AiChefExclusions;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.ingredients));
}

@override
String toString() {
  final _this = this as AiChefExclusions;
  return 'AiChefExclusions(ingredients: ${_this.ingredients})';
}


}

/// @nodoc
abstract mixin class $AiChefExclusionsCopyWith<$Res>  {
  factory $AiChefExclusionsCopyWith(AiChefExclusions value, $Res Function(AiChefExclusions) _then) = _$AiChefExclusionsCopyWithImpl;
@useResult
$Res call({
 List<String> ingredients
});




}
/// @nodoc
class _$AiChefExclusionsCopyWithImpl<$Res>
    implements $AiChefExclusionsCopyWith<$Res> {
  _$AiChefExclusionsCopyWithImpl(this._self, this._then);

  final AiChefExclusions _self;
  final $Res Function(AiChefExclusions) _then;

/// Create a copy of AiChefExclusions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ingredients = null,}) {
  return _then(AiChefExclusions(
ingredients: null == ingredients ? _self.ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AiChefExclusions].
extension AiChefExclusionsPatterns on AiChefExclusions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiChefExclusions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiChefExclusions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiChefExclusions value)  $default,){
final _that = this;
switch (_that) {
case _AiChefExclusions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiChefExclusions value)?  $default,){
final _that = this;
switch (_that) {
case _AiChefExclusions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> ingredients)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiChefExclusions() when $default != null:
return $default(_that.ingredients);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> ingredients)  $default,) {final _that = this;
switch (_that) {
case _AiChefExclusions():
return $default(_that.ingredients);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> ingredients)?  $default,) {final _that = this;
switch (_that) {
case _AiChefExclusions() when $default != null:
return $default(_that.ingredients);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AiChefExclusions extends AiChefExclusions {
  const _AiChefExclusions({required  List<String> ingredients}): _ingredients = ingredients,super._();
  factory _AiChefExclusions.fromJson(Map<String, dynamic> json) => _$AiChefExclusionsFromJson(json);

 final  List<String> _ingredients;
@override List<String> get ingredients {
  if (_ingredients is EqualUnmodifiableListView) return _ingredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ingredients);
}


/// Create a copy of AiChefExclusions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiChefExclusionsCopyWith<_AiChefExclusions> get copyWith => __$AiChefExclusionsCopyWithImpl<_AiChefExclusions>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AiChefExclusionsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiChefExclusions&&const DeepCollectionEquality().equals(other.ingredients, _ingredients));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_ingredients));
}

@override
String toString() {
    return 'AiChefExclusions(ingredients: $ingredients)';
}


}

/// @nodoc
abstract mixin class _$AiChefExclusionsCopyWith<$Res> implements $AiChefExclusionsCopyWith<$Res> {
  factory _$AiChefExclusionsCopyWith(_AiChefExclusions value, $Res Function(_AiChefExclusions) _then) = __$AiChefExclusionsCopyWithImpl;
@override @useResult
$Res call({
 List<String> ingredients
});




}
/// @nodoc
class __$AiChefExclusionsCopyWithImpl<$Res>
    implements _$AiChefExclusionsCopyWith<$Res> {
  __$AiChefExclusionsCopyWithImpl(this._self, this._then);

  final _AiChefExclusions _self;
  final $Res Function(_AiChefExclusions) _then;

/// Create a copy of AiChefExclusions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ingredients = null,}) {
  return _then(_AiChefExclusions(
ingredients: null == ingredients ? _self._ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
