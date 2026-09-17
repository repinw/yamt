// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt_review_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReceiptReviewState {

/// Currently reviewed receipt.
 ScannedReceipt get receipt;/// Whether saving to inventory is in progress.
 bool get isSaving;/// Whether product / barcode resolution is in progress.
 bool get isResolving;/// Whether the receipt was saved successfully.
 bool get saveSuccess;/// Optional error message for snackbars or banners.
 String? get errorMessage;
/// Create a copy of ReceiptReviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptReviewStateCopyWith<ReceiptReviewState> get copyWith => _$ReceiptReviewStateCopyWithImpl<ReceiptReviewState>(this as ReceiptReviewState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReceiptReviewState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptReviewState&&(identical(other.receipt, _this.receipt) || other.receipt == _this.receipt)&&(identical(other.isSaving, _this.isSaving) || other.isSaving == _this.isSaving)&&(identical(other.isResolving, _this.isResolving) || other.isResolving == _this.isResolving)&&(identical(other.saveSuccess, _this.saveSuccess) || other.saveSuccess == _this.saveSuccess)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as ReceiptReviewState;
  return Object.hash(runtimeType,_this.receipt,_this.isSaving,_this.isResolving,_this.saveSuccess,_this.errorMessage);
}

@override
String toString() {
  final _this = this as ReceiptReviewState;
  return 'ReceiptReviewState(receipt: ${_this.receipt}, isSaving: ${_this.isSaving}, isResolving: ${_this.isResolving}, saveSuccess: ${_this.saveSuccess}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $ReceiptReviewStateCopyWith<$Res>  {
  factory $ReceiptReviewStateCopyWith(ReceiptReviewState value, $Res Function(ReceiptReviewState) _then) = _$ReceiptReviewStateCopyWithImpl;
@useResult
$Res call({
 ScannedReceipt receipt, bool isSaving, bool isResolving, bool saveSuccess, String? errorMessage
});


$ScannedReceiptCopyWith<$Res> get receipt;

}
/// @nodoc
class _$ReceiptReviewStateCopyWithImpl<$Res>
    implements $ReceiptReviewStateCopyWith<$Res> {
  _$ReceiptReviewStateCopyWithImpl(this._self, this._then);

  final ReceiptReviewState _self;
  final $Res Function(ReceiptReviewState) _then;

/// Create a copy of ReceiptReviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? receipt = null,Object? isSaving = null,Object? isResolving = null,Object? saveSuccess = null,Object? errorMessage = freezed,}) {
  return _then(ReceiptReviewState(
receipt: null == receipt ? _self.receipt : receipt // ignore: cast_nullable_to_non_nullable
as ScannedReceipt,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,isResolving: null == isResolving ? _self.isResolving : isResolving // ignore: cast_nullable_to_non_nullable
as bool,saveSuccess: null == saveSuccess ? _self.saveSuccess : saveSuccess // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ReceiptReviewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScannedReceiptCopyWith<$Res> get receipt {
  
  return $ScannedReceiptCopyWith<$Res>(_self.receipt, (value) {
    return _then(_self.copyWith(receipt: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReceiptReviewState].
extension ReceiptReviewStatePatterns on ReceiptReviewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceiptReviewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceiptReviewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceiptReviewState value)  $default,){
final _that = this;
switch (_that) {
case _ReceiptReviewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceiptReviewState value)?  $default,){
final _that = this;
switch (_that) {
case _ReceiptReviewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ScannedReceipt receipt,  bool isSaving,  bool isResolving,  bool saveSuccess,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceiptReviewState() when $default != null:
return $default(_that.receipt,_that.isSaving,_that.isResolving,_that.saveSuccess,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ScannedReceipt receipt,  bool isSaving,  bool isResolving,  bool saveSuccess,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _ReceiptReviewState():
return $default(_that.receipt,_that.isSaving,_that.isResolving,_that.saveSuccess,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ScannedReceipt receipt,  bool isSaving,  bool isResolving,  bool saveSuccess,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _ReceiptReviewState() when $default != null:
return $default(_that.receipt,_that.isSaving,_that.isResolving,_that.saveSuccess,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _ReceiptReviewState extends ReceiptReviewState {
  const _ReceiptReviewState({required this.receipt, this.isSaving = false, this.isResolving = false, this.saveSuccess = false, this.errorMessage}): super._();
  

/// Currently reviewed receipt.
@override final  ScannedReceipt receipt;
/// Whether saving to inventory is in progress.
@override@JsonKey() final  bool isSaving;
/// Whether product / barcode resolution is in progress.
@override@JsonKey() final  bool isResolving;
/// Whether the receipt was saved successfully.
@override@JsonKey() final  bool saveSuccess;
/// Optional error message for snackbars or banners.
@override final  String? errorMessage;

/// Create a copy of ReceiptReviewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptReviewStateCopyWith<_ReceiptReviewState> get copyWith => __$ReceiptReviewStateCopyWithImpl<_ReceiptReviewState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptReviewState&&(identical(other.receipt, receipt) || other.receipt == receipt)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.isResolving, isResolving) || other.isResolving == isResolving)&&(identical(other.saveSuccess, saveSuccess) || other.saveSuccess == saveSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,receipt,isSaving,isResolving,saveSuccess,errorMessage);
}

@override
String toString() {
    return 'ReceiptReviewState(receipt: $receipt, isSaving: $isSaving, isResolving: $isResolving, saveSuccess: $saveSuccess, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$ReceiptReviewStateCopyWith<$Res> implements $ReceiptReviewStateCopyWith<$Res> {
  factory _$ReceiptReviewStateCopyWith(_ReceiptReviewState value, $Res Function(_ReceiptReviewState) _then) = __$ReceiptReviewStateCopyWithImpl;
@override @useResult
$Res call({
 ScannedReceipt receipt, bool isSaving, bool isResolving, bool saveSuccess, String? errorMessage
});


@override $ScannedReceiptCopyWith<$Res> get receipt;

}
/// @nodoc
class __$ReceiptReviewStateCopyWithImpl<$Res>
    implements _$ReceiptReviewStateCopyWith<$Res> {
  __$ReceiptReviewStateCopyWithImpl(this._self, this._then);

  final _ReceiptReviewState _self;
  final $Res Function(_ReceiptReviewState) _then;

/// Create a copy of ReceiptReviewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? receipt = null,Object? isSaving = null,Object? isResolving = null,Object? saveSuccess = null,Object? errorMessage = freezed,}) {
  return _then(_ReceiptReviewState(
receipt: null == receipt ? _self.receipt : receipt // ignore: cast_nullable_to_non_nullable
as ScannedReceipt,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,isResolving: null == isResolving ? _self.isResolving : isResolving // ignore: cast_nullable_to_non_nullable
as bool,saveSuccess: null == saveSuccess ? _self.saveSuccess : saveSuccess // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ReceiptReviewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScannedReceiptCopyWith<$Res> get receipt {
  
  return $ScannedReceiptCopyWith<$Res>(_self.receipt, (value) {
    return _then(_self.copyWith(receipt: value));
  });
}
}

// dart format on
