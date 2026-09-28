// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'household_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HouseholdMember {

 String get uid; HouseholdRole get role;@JsonKey(name: 'joined_at')@DateTimeJsonConverter() DateTime get joinedAt;@JsonKey(includeFromJson: false, includeToJson: false) String? get displayName;@JsonKey(includeFromJson: false, includeToJson: false) String? get email;
/// Create a copy of HouseholdMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HouseholdMemberCopyWith<HouseholdMember> get copyWith => _$HouseholdMemberCopyWithImpl<HouseholdMember>(this as HouseholdMember, _$identity);

  /// Serializes this HouseholdMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HouseholdMember;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HouseholdMember&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.joinedAt, _this.joinedAt) || other.joinedAt == _this.joinedAt)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.email, _this.email) || other.email == _this.email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HouseholdMember;
  return Object.hash(runtimeType,_this.uid,_this.role,_this.joinedAt,_this.displayName,_this.email);
}

@override
String toString() {
  final _this = this as HouseholdMember;
  return 'HouseholdMember(uid: ${_this.uid}, role: ${_this.role}, joinedAt: ${_this.joinedAt}, displayName: ${_this.displayName}, email: ${_this.email})';
}


}

/// @nodoc
abstract mixin class $HouseholdMemberCopyWith<$Res>  {
  factory $HouseholdMemberCopyWith(HouseholdMember value, $Res Function(HouseholdMember) _then) = _$HouseholdMemberCopyWithImpl;
@useResult
$Res call({
 String uid, HouseholdRole role,@JsonKey(name: 'joined_at')@DateTimeJsonConverter() DateTime joinedAt,@JsonKey(includeFromJson: false, includeToJson: false) String? displayName,@JsonKey(includeFromJson: false, includeToJson: false) String? email
});




}
/// @nodoc
class _$HouseholdMemberCopyWithImpl<$Res>
    implements $HouseholdMemberCopyWith<$Res> {
  _$HouseholdMemberCopyWithImpl(this._self, this._then);

  final HouseholdMember _self;
  final $Res Function(HouseholdMember) _then;

/// Create a copy of HouseholdMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? role = null,Object? joinedAt = null,Object? displayName = freezed,Object? email = freezed,}) {
  return _then(HouseholdMember(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as HouseholdRole,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HouseholdMember].
extension HouseholdMemberPatterns on HouseholdMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HouseholdMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HouseholdMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HouseholdMember value)  $default,){
final _that = this;
switch (_that) {
case _HouseholdMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HouseholdMember value)?  $default,){
final _that = this;
switch (_that) {
case _HouseholdMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  HouseholdRole role, @JsonKey(name: 'joined_at')@DateTimeJsonConverter()  DateTime joinedAt, @JsonKey(includeFromJson: false, includeToJson: false)  String? displayName, @JsonKey(includeFromJson: false, includeToJson: false)  String? email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HouseholdMember() when $default != null:
return $default(_that.uid,_that.role,_that.joinedAt,_that.displayName,_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  HouseholdRole role, @JsonKey(name: 'joined_at')@DateTimeJsonConverter()  DateTime joinedAt, @JsonKey(includeFromJson: false, includeToJson: false)  String? displayName, @JsonKey(includeFromJson: false, includeToJson: false)  String? email)  $default,) {final _that = this;
switch (_that) {
case _HouseholdMember():
return $default(_that.uid,_that.role,_that.joinedAt,_that.displayName,_that.email);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  HouseholdRole role, @JsonKey(name: 'joined_at')@DateTimeJsonConverter()  DateTime joinedAt, @JsonKey(includeFromJson: false, includeToJson: false)  String? displayName, @JsonKey(includeFromJson: false, includeToJson: false)  String? email)?  $default,) {final _that = this;
switch (_that) {
case _HouseholdMember() when $default != null:
return $default(_that.uid,_that.role,_that.joinedAt,_that.displayName,_that.email);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HouseholdMember extends HouseholdMember {
  const _HouseholdMember({required this.uid, required this.role, @JsonKey(name: 'joined_at')@DateTimeJsonConverter() required this.joinedAt, @JsonKey(includeFromJson: false, includeToJson: false) this.displayName, @JsonKey(includeFromJson: false, includeToJson: false) this.email}): super._();
  factory _HouseholdMember.fromJson(Map<String, dynamic> json) => _$HouseholdMemberFromJson(json);

@override final  String uid;
@override final  HouseholdRole role;
@override@JsonKey(name: 'joined_at')@DateTimeJsonConverter() final  DateTime joinedAt;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String? displayName;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String? email;

/// Create a copy of HouseholdMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HouseholdMemberCopyWith<_HouseholdMember> get copyWith => __$HouseholdMemberCopyWithImpl<_HouseholdMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HouseholdMemberToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HouseholdMember&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,uid,role,joinedAt,displayName,email);
}

@override
String toString() {
    return 'HouseholdMember(uid: $uid, role: $role, joinedAt: $joinedAt, displayName: $displayName, email: $email)';
}


}

/// @nodoc
abstract mixin class _$HouseholdMemberCopyWith<$Res> implements $HouseholdMemberCopyWith<$Res> {
  factory _$HouseholdMemberCopyWith(_HouseholdMember value, $Res Function(_HouseholdMember) _then) = __$HouseholdMemberCopyWithImpl;
@override @useResult
$Res call({
 String uid, HouseholdRole role,@JsonKey(name: 'joined_at')@DateTimeJsonConverter() DateTime joinedAt,@JsonKey(includeFromJson: false, includeToJson: false) String? displayName,@JsonKey(includeFromJson: false, includeToJson: false) String? email
});




}
/// @nodoc
class __$HouseholdMemberCopyWithImpl<$Res>
    implements _$HouseholdMemberCopyWith<$Res> {
  __$HouseholdMemberCopyWithImpl(this._self, this._then);

  final _HouseholdMember _self;
  final $Res Function(_HouseholdMember) _then;

/// Create a copy of HouseholdMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? role = null,Object? joinedAt = null,Object? displayName = freezed,Object? email = freezed,}) {
  return _then(_HouseholdMember(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as HouseholdRole,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
