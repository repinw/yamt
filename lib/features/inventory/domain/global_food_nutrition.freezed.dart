// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'global_food_nutrition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GlobalFoodNutrition {

 GlobalFoodNutritionQualityStatus get qualityStatus; double? get per100Kcal; double? get per100Protein; double? get per100Carbs; double? get per100Fat; double? get per100Salt; double? get per100SaturatedFat; double? get per100PolyunsaturatedFat; double? get per100Sugar; double? get per100Fiber;
/// Create a copy of GlobalFoodNutrition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GlobalFoodNutritionCopyWith<GlobalFoodNutrition> get copyWith => _$GlobalFoodNutritionCopyWithImpl<GlobalFoodNutrition>(this as GlobalFoodNutrition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GlobalFoodNutrition&&(identical(other.qualityStatus, qualityStatus) || other.qualityStatus == qualityStatus)&&(identical(other.per100Kcal, per100Kcal) || other.per100Kcal == per100Kcal)&&(identical(other.per100Protein, per100Protein) || other.per100Protein == per100Protein)&&(identical(other.per100Carbs, per100Carbs) || other.per100Carbs == per100Carbs)&&(identical(other.per100Fat, per100Fat) || other.per100Fat == per100Fat)&&(identical(other.per100Salt, per100Salt) || other.per100Salt == per100Salt)&&(identical(other.per100SaturatedFat, per100SaturatedFat) || other.per100SaturatedFat == per100SaturatedFat)&&(identical(other.per100PolyunsaturatedFat, per100PolyunsaturatedFat) || other.per100PolyunsaturatedFat == per100PolyunsaturatedFat)&&(identical(other.per100Sugar, per100Sugar) || other.per100Sugar == per100Sugar)&&(identical(other.per100Fiber, per100Fiber) || other.per100Fiber == per100Fiber));
}


@override
int get hashCode => Object.hash(runtimeType,qualityStatus,per100Kcal,per100Protein,per100Carbs,per100Fat,per100Salt,per100SaturatedFat,per100PolyunsaturatedFat,per100Sugar,per100Fiber);

@override
String toString() {
  return 'GlobalFoodNutrition(qualityStatus: $qualityStatus, per100Kcal: $per100Kcal, per100Protein: $per100Protein, per100Carbs: $per100Carbs, per100Fat: $per100Fat, per100Salt: $per100Salt, per100SaturatedFat: $per100SaturatedFat, per100PolyunsaturatedFat: $per100PolyunsaturatedFat, per100Sugar: $per100Sugar, per100Fiber: $per100Fiber)';
}


}

/// @nodoc
abstract mixin class $GlobalFoodNutritionCopyWith<$Res>  {
  factory $GlobalFoodNutritionCopyWith(GlobalFoodNutrition value, $Res Function(GlobalFoodNutrition) _then) = _$GlobalFoodNutritionCopyWithImpl;
@useResult
$Res call({
 GlobalFoodNutritionQualityStatus qualityStatus, double? per100Kcal, double? per100Protein, double? per100Carbs, double? per100Fat, double? per100Salt, double? per100SaturatedFat, double? per100PolyunsaturatedFat, double? per100Sugar, double? per100Fiber
});




}
/// @nodoc
class _$GlobalFoodNutritionCopyWithImpl<$Res>
    implements $GlobalFoodNutritionCopyWith<$Res> {
  _$GlobalFoodNutritionCopyWithImpl(this._self, this._then);

  final GlobalFoodNutrition _self;
  final $Res Function(GlobalFoodNutrition) _then;

/// Create a copy of GlobalFoodNutrition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? qualityStatus = null,Object? per100Kcal = freezed,Object? per100Protein = freezed,Object? per100Carbs = freezed,Object? per100Fat = freezed,Object? per100Salt = freezed,Object? per100SaturatedFat = freezed,Object? per100PolyunsaturatedFat = freezed,Object? per100Sugar = freezed,Object? per100Fiber = freezed,}) {
  return _then(_self.copyWith(
qualityStatus: null == qualityStatus ? _self.qualityStatus : qualityStatus // ignore: cast_nullable_to_non_nullable
as GlobalFoodNutritionQualityStatus,per100Kcal: freezed == per100Kcal ? _self.per100Kcal : per100Kcal // ignore: cast_nullable_to_non_nullable
as double?,per100Protein: freezed == per100Protein ? _self.per100Protein : per100Protein // ignore: cast_nullable_to_non_nullable
as double?,per100Carbs: freezed == per100Carbs ? _self.per100Carbs : per100Carbs // ignore: cast_nullable_to_non_nullable
as double?,per100Fat: freezed == per100Fat ? _self.per100Fat : per100Fat // ignore: cast_nullable_to_non_nullable
as double?,per100Salt: freezed == per100Salt ? _self.per100Salt : per100Salt // ignore: cast_nullable_to_non_nullable
as double?,per100SaturatedFat: freezed == per100SaturatedFat ? _self.per100SaturatedFat : per100SaturatedFat // ignore: cast_nullable_to_non_nullable
as double?,per100PolyunsaturatedFat: freezed == per100PolyunsaturatedFat ? _self.per100PolyunsaturatedFat : per100PolyunsaturatedFat // ignore: cast_nullable_to_non_nullable
as double?,per100Sugar: freezed == per100Sugar ? _self.per100Sugar : per100Sugar // ignore: cast_nullable_to_non_nullable
as double?,per100Fiber: freezed == per100Fiber ? _self.per100Fiber : per100Fiber // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [GlobalFoodNutrition].
extension GlobalFoodNutritionPatterns on GlobalFoodNutrition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GlobalFoodNutrition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GlobalFoodNutrition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GlobalFoodNutrition value)  $default,){
final _that = this;
switch (_that) {
case _GlobalFoodNutrition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GlobalFoodNutrition value)?  $default,){
final _that = this;
switch (_that) {
case _GlobalFoodNutrition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GlobalFoodNutritionQualityStatus qualityStatus,  double? per100Kcal,  double? per100Protein,  double? per100Carbs,  double? per100Fat,  double? per100Salt,  double? per100SaturatedFat,  double? per100PolyunsaturatedFat,  double? per100Sugar,  double? per100Fiber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GlobalFoodNutrition() when $default != null:
return $default(_that.qualityStatus,_that.per100Kcal,_that.per100Protein,_that.per100Carbs,_that.per100Fat,_that.per100Salt,_that.per100SaturatedFat,_that.per100PolyunsaturatedFat,_that.per100Sugar,_that.per100Fiber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GlobalFoodNutritionQualityStatus qualityStatus,  double? per100Kcal,  double? per100Protein,  double? per100Carbs,  double? per100Fat,  double? per100Salt,  double? per100SaturatedFat,  double? per100PolyunsaturatedFat,  double? per100Sugar,  double? per100Fiber)  $default,) {final _that = this;
switch (_that) {
case _GlobalFoodNutrition():
return $default(_that.qualityStatus,_that.per100Kcal,_that.per100Protein,_that.per100Carbs,_that.per100Fat,_that.per100Salt,_that.per100SaturatedFat,_that.per100PolyunsaturatedFat,_that.per100Sugar,_that.per100Fiber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GlobalFoodNutritionQualityStatus qualityStatus,  double? per100Kcal,  double? per100Protein,  double? per100Carbs,  double? per100Fat,  double? per100Salt,  double? per100SaturatedFat,  double? per100PolyunsaturatedFat,  double? per100Sugar,  double? per100Fiber)?  $default,) {final _that = this;
switch (_that) {
case _GlobalFoodNutrition() when $default != null:
return $default(_that.qualityStatus,_that.per100Kcal,_that.per100Protein,_that.per100Carbs,_that.per100Fat,_that.per100Salt,_that.per100SaturatedFat,_that.per100PolyunsaturatedFat,_that.per100Sugar,_that.per100Fiber);case _:
  return null;

}
}

}

/// @nodoc


class _GlobalFoodNutrition extends GlobalFoodNutrition {
  const _GlobalFoodNutrition({required this.qualityStatus, this.per100Kcal, this.per100Protein, this.per100Carbs, this.per100Fat, this.per100Salt, this.per100SaturatedFat, this.per100PolyunsaturatedFat, this.per100Sugar, this.per100Fiber}): super._();
  

@override final  GlobalFoodNutritionQualityStatus qualityStatus;
@override final  double? per100Kcal;
@override final  double? per100Protein;
@override final  double? per100Carbs;
@override final  double? per100Fat;
@override final  double? per100Salt;
@override final  double? per100SaturatedFat;
@override final  double? per100PolyunsaturatedFat;
@override final  double? per100Sugar;
@override final  double? per100Fiber;

/// Create a copy of GlobalFoodNutrition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GlobalFoodNutritionCopyWith<_GlobalFoodNutrition> get copyWith => __$GlobalFoodNutritionCopyWithImpl<_GlobalFoodNutrition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GlobalFoodNutrition&&(identical(other.qualityStatus, qualityStatus) || other.qualityStatus == qualityStatus)&&(identical(other.per100Kcal, per100Kcal) || other.per100Kcal == per100Kcal)&&(identical(other.per100Protein, per100Protein) || other.per100Protein == per100Protein)&&(identical(other.per100Carbs, per100Carbs) || other.per100Carbs == per100Carbs)&&(identical(other.per100Fat, per100Fat) || other.per100Fat == per100Fat)&&(identical(other.per100Salt, per100Salt) || other.per100Salt == per100Salt)&&(identical(other.per100SaturatedFat, per100SaturatedFat) || other.per100SaturatedFat == per100SaturatedFat)&&(identical(other.per100PolyunsaturatedFat, per100PolyunsaturatedFat) || other.per100PolyunsaturatedFat == per100PolyunsaturatedFat)&&(identical(other.per100Sugar, per100Sugar) || other.per100Sugar == per100Sugar)&&(identical(other.per100Fiber, per100Fiber) || other.per100Fiber == per100Fiber));
}


@override
int get hashCode => Object.hash(runtimeType,qualityStatus,per100Kcal,per100Protein,per100Carbs,per100Fat,per100Salt,per100SaturatedFat,per100PolyunsaturatedFat,per100Sugar,per100Fiber);

@override
String toString() {
  return 'GlobalFoodNutrition(qualityStatus: $qualityStatus, per100Kcal: $per100Kcal, per100Protein: $per100Protein, per100Carbs: $per100Carbs, per100Fat: $per100Fat, per100Salt: $per100Salt, per100SaturatedFat: $per100SaturatedFat, per100PolyunsaturatedFat: $per100PolyunsaturatedFat, per100Sugar: $per100Sugar, per100Fiber: $per100Fiber)';
}


}

/// @nodoc
abstract mixin class _$GlobalFoodNutritionCopyWith<$Res> implements $GlobalFoodNutritionCopyWith<$Res> {
  factory _$GlobalFoodNutritionCopyWith(_GlobalFoodNutrition value, $Res Function(_GlobalFoodNutrition) _then) = __$GlobalFoodNutritionCopyWithImpl;
@override @useResult
$Res call({
 GlobalFoodNutritionQualityStatus qualityStatus, double? per100Kcal, double? per100Protein, double? per100Carbs, double? per100Fat, double? per100Salt, double? per100SaturatedFat, double? per100PolyunsaturatedFat, double? per100Sugar, double? per100Fiber
});




}
/// @nodoc
class __$GlobalFoodNutritionCopyWithImpl<$Res>
    implements _$GlobalFoodNutritionCopyWith<$Res> {
  __$GlobalFoodNutritionCopyWithImpl(this._self, this._then);

  final _GlobalFoodNutrition _self;
  final $Res Function(_GlobalFoodNutrition) _then;

/// Create a copy of GlobalFoodNutrition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? qualityStatus = null,Object? per100Kcal = freezed,Object? per100Protein = freezed,Object? per100Carbs = freezed,Object? per100Fat = freezed,Object? per100Salt = freezed,Object? per100SaturatedFat = freezed,Object? per100PolyunsaturatedFat = freezed,Object? per100Sugar = freezed,Object? per100Fiber = freezed,}) {
  return _then(_GlobalFoodNutrition(
qualityStatus: null == qualityStatus ? _self.qualityStatus : qualityStatus // ignore: cast_nullable_to_non_nullable
as GlobalFoodNutritionQualityStatus,per100Kcal: freezed == per100Kcal ? _self.per100Kcal : per100Kcal // ignore: cast_nullable_to_non_nullable
as double?,per100Protein: freezed == per100Protein ? _self.per100Protein : per100Protein // ignore: cast_nullable_to_non_nullable
as double?,per100Carbs: freezed == per100Carbs ? _self.per100Carbs : per100Carbs // ignore: cast_nullable_to_non_nullable
as double?,per100Fat: freezed == per100Fat ? _self.per100Fat : per100Fat // ignore: cast_nullable_to_non_nullable
as double?,per100Salt: freezed == per100Salt ? _self.per100Salt : per100Salt // ignore: cast_nullable_to_non_nullable
as double?,per100SaturatedFat: freezed == per100SaturatedFat ? _self.per100SaturatedFat : per100SaturatedFat // ignore: cast_nullable_to_non_nullable
as double?,per100PolyunsaturatedFat: freezed == per100PolyunsaturatedFat ? _self.per100PolyunsaturatedFat : per100PolyunsaturatedFat // ignore: cast_nullable_to_non_nullable
as double?,per100Sugar: freezed == per100Sugar ? _self.per100Sugar : per100Sugar // ignore: cast_nullable_to_non_nullable
as double?,per100Fiber: freezed == per100Fiber ? _self.per100Fiber : per100Fiber // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
