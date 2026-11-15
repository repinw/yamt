// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kochmodus_target.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$KochmodusTarget {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is KochmodusTarget);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'KochmodusTarget()';
}


}

/// @nodoc
class $KochmodusTargetCopyWith<$Res>  {
$KochmodusTargetCopyWith(KochmodusTarget _, $Res Function(KochmodusTarget) __);
}


/// Adds pattern-matching-related methods to [KochmodusTarget].
extension KochmodusTargetPatterns on KochmodusTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( KochmodusRecipeTarget value)?  recipe,TResult Function( KochmodusRunTarget value)?  run,TResult Function( KochmodusFreeTarget value)?  free,required TResult orElse(),}){
final _that = this;
switch (_that) {
case KochmodusRecipeTarget() when recipe != null:
return recipe(_that);case KochmodusRunTarget() when run != null:
return run(_that);case KochmodusFreeTarget() when free != null:
return free(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( KochmodusRecipeTarget value)  recipe,required TResult Function( KochmodusRunTarget value)  run,required TResult Function( KochmodusFreeTarget value)  free,}){
final _that = this;
switch (_that) {
case KochmodusRecipeTarget():
return recipe(_that);case KochmodusRunTarget():
return run(_that);case KochmodusFreeTarget():
return free(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( KochmodusRecipeTarget value)?  recipe,TResult? Function( KochmodusRunTarget value)?  run,TResult? Function( KochmodusFreeTarget value)?  free,}){
final _that = this;
switch (_that) {
case KochmodusRecipeTarget() when recipe != null:
return recipe(_that);case KochmodusRunTarget() when run != null:
return run(_that);case KochmodusFreeTarget() when free != null:
return free(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String recipeId,  int? portions)?  recipe,TResult Function( String runId)?  run,TResult Function( String runId)?  free,required TResult orElse(),}) {final _that = this;
switch (_that) {
case KochmodusRecipeTarget() when recipe != null:
return recipe(_that.recipeId,_that.portions);case KochmodusRunTarget() when run != null:
return run(_that.runId);case KochmodusFreeTarget() when free != null:
return free(_that.runId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String recipeId,  int? portions)  recipe,required TResult Function( String runId)  run,required TResult Function( String runId)  free,}) {final _that = this;
switch (_that) {
case KochmodusRecipeTarget():
return recipe(_that.recipeId,_that.portions);case KochmodusRunTarget():
return run(_that.runId);case KochmodusFreeTarget():
return free(_that.runId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String recipeId,  int? portions)?  recipe,TResult? Function( String runId)?  run,TResult? Function( String runId)?  free,}) {final _that = this;
switch (_that) {
case KochmodusRecipeTarget() when recipe != null:
return recipe(_that.recipeId,_that.portions);case KochmodusRunTarget() when run != null:
return run(_that.runId);case KochmodusFreeTarget() when free != null:
return free(_that.runId);case _:
  return null;

}
}

}

/// @nodoc


class KochmodusRecipeTarget extends KochmodusTarget {
  const KochmodusRecipeTarget({required this.recipeId, this.portions}): super._();
  

 final  String recipeId;
 final  int? portions;

/// Create a copy of KochmodusTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KochmodusRecipeTargetCopyWith<KochmodusRecipeTarget> get copyWith => _$KochmodusRecipeTargetCopyWithImpl<KochmodusRecipeTarget>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is KochmodusRecipeTarget&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.portions, portions) || other.portions == portions));
}


@override
int get hashCode {
    return Object.hash(runtimeType,recipeId,portions);
}

@override
String toString() {
    return 'KochmodusTarget.recipe(recipeId: $recipeId, portions: $portions)';
}


}

/// @nodoc
abstract mixin class $KochmodusRecipeTargetCopyWith<$Res> implements $KochmodusTargetCopyWith<$Res> {
  factory $KochmodusRecipeTargetCopyWith(KochmodusRecipeTarget value, $Res Function(KochmodusRecipeTarget) _then) = _$KochmodusRecipeTargetCopyWithImpl;
@useResult
$Res call({
 String recipeId, int? portions
});




}
/// @nodoc
class _$KochmodusRecipeTargetCopyWithImpl<$Res>
    implements $KochmodusRecipeTargetCopyWith<$Res> {
  _$KochmodusRecipeTargetCopyWithImpl(this._self, this._then);

  final KochmodusRecipeTarget _self;
  final $Res Function(KochmodusRecipeTarget) _then;

/// Create a copy of KochmodusTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? recipeId = null,Object? portions = freezed,}) {
  return _then(KochmodusRecipeTarget(
recipeId: null == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String,portions: freezed == portions ? _self.portions : portions // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class KochmodusRunTarget extends KochmodusTarget {
  const KochmodusRunTarget(this.runId): super._();
  

 final  String runId;

/// Create a copy of KochmodusTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KochmodusRunTargetCopyWith<KochmodusRunTarget> get copyWith => _$KochmodusRunTargetCopyWithImpl<KochmodusRunTarget>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is KochmodusRunTarget&&(identical(other.runId, runId) || other.runId == runId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,runId);
}

@override
String toString() {
    return 'KochmodusTarget.run(runId: $runId)';
}


}

/// @nodoc
abstract mixin class $KochmodusRunTargetCopyWith<$Res> implements $KochmodusTargetCopyWith<$Res> {
  factory $KochmodusRunTargetCopyWith(KochmodusRunTarget value, $Res Function(KochmodusRunTarget) _then) = _$KochmodusRunTargetCopyWithImpl;
@useResult
$Res call({
 String runId
});




}
/// @nodoc
class _$KochmodusRunTargetCopyWithImpl<$Res>
    implements $KochmodusRunTargetCopyWith<$Res> {
  _$KochmodusRunTargetCopyWithImpl(this._self, this._then);

  final KochmodusRunTarget _self;
  final $Res Function(KochmodusRunTarget) _then;

/// Create a copy of KochmodusTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? runId = null,}) {
  return _then(KochmodusRunTarget(
null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class KochmodusFreeTarget extends KochmodusTarget {
  const KochmodusFreeTarget(this.runId): super._();
  

 final  String runId;

/// Create a copy of KochmodusTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KochmodusFreeTargetCopyWith<KochmodusFreeTarget> get copyWith => _$KochmodusFreeTargetCopyWithImpl<KochmodusFreeTarget>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is KochmodusFreeTarget&&(identical(other.runId, runId) || other.runId == runId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,runId);
}

@override
String toString() {
    return 'KochmodusTarget.free(runId: $runId)';
}


}

/// @nodoc
abstract mixin class $KochmodusFreeTargetCopyWith<$Res> implements $KochmodusTargetCopyWith<$Res> {
  factory $KochmodusFreeTargetCopyWith(KochmodusFreeTarget value, $Res Function(KochmodusFreeTarget) _then) = _$KochmodusFreeTargetCopyWithImpl;
@useResult
$Res call({
 String runId
});




}
/// @nodoc
class _$KochmodusFreeTargetCopyWithImpl<$Res>
    implements $KochmodusFreeTargetCopyWith<$Res> {
  _$KochmodusFreeTargetCopyWithImpl(this._self, this._then);

  final KochmodusFreeTarget _self;
  final $Res Function(KochmodusFreeTarget) _then;

/// Create a copy of KochmodusTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? runId = null,}) {
  return _then(KochmodusFreeTarget(
null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
