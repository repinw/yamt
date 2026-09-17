// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt_line_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReceiptLineItem {

/// Unique ID of this line within the receipt.
 String get id;/// Original raw text on the receipt (e.g. "JA! VOLLM 3.8% 1L").
 String get rawName;/// Printed total price on receipt before discounts.
 double get totalPrice;/// Line discount (e.g. 0.50 coupon or promotion).
 double get discount;/// Purchased quantity (e.g. 1.0 pieces or 0.450 kg).
 double get quantity;/// Unit price if printed on receipt.
 double? get unitPrice;/// Unit (e.g. "kg", "g", "l", "pcs").
 String? get unit;/// Store product category if listed on receipt.
 String? get rawCategory;/// Brand name or abbreviated brand marker extracted from the receipt.
 String? get rawBrand;/// Package content printed or inferred for this product (e.g. 200g, 1L).
 String? get packageWeight;/// Whether this is a deposit line item.
 bool get isDeposit;/// Whether this is a discount / voucher line item.
 bool get isDiscount;/// Current review status.
 ReceiptItemStatus get status;/// Currently matched product candidate.
 ProductCandidate? get matchedProduct;/// Alternative product candidates for this line item.
 List<ProductCandidate> get candidates;
/// Create a copy of ReceiptLineItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptLineItemCopyWith<ReceiptLineItem> get copyWith => _$ReceiptLineItemCopyWithImpl<ReceiptLineItem>(this as ReceiptLineItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReceiptLineItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptLineItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.rawName, _this.rawName) || other.rawName == _this.rawName)&&(identical(other.totalPrice, _this.totalPrice) || other.totalPrice == _this.totalPrice)&&(identical(other.discount, _this.discount) || other.discount == _this.discount)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.unitPrice, _this.unitPrice) || other.unitPrice == _this.unitPrice)&&(identical(other.unit, _this.unit) || other.unit == _this.unit)&&(identical(other.rawCategory, _this.rawCategory) || other.rawCategory == _this.rawCategory)&&(identical(other.rawBrand, _this.rawBrand) || other.rawBrand == _this.rawBrand)&&(identical(other.packageWeight, _this.packageWeight) || other.packageWeight == _this.packageWeight)&&(identical(other.isDeposit, _this.isDeposit) || other.isDeposit == _this.isDeposit)&&(identical(other.isDiscount, _this.isDiscount) || other.isDiscount == _this.isDiscount)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.matchedProduct, _this.matchedProduct) || other.matchedProduct == _this.matchedProduct)&&const DeepCollectionEquality().equals(other.candidates, _this.candidates));
}


@override
int get hashCode {
  final _this = this as ReceiptLineItem;
  return Object.hash(runtimeType,_this.id,_this.rawName,_this.totalPrice,_this.discount,_this.quantity,_this.unitPrice,_this.unit,_this.rawCategory,_this.rawBrand,_this.packageWeight,_this.isDeposit,_this.isDiscount,_this.status,_this.matchedProduct,const DeepCollectionEquality().hash(_this.candidates));
}

@override
String toString() {
  final _this = this as ReceiptLineItem;
  return 'ReceiptLineItem(id: ${_this.id}, rawName: ${_this.rawName}, totalPrice: ${_this.totalPrice}, discount: ${_this.discount}, quantity: ${_this.quantity}, unitPrice: ${_this.unitPrice}, unit: ${_this.unit}, rawCategory: ${_this.rawCategory}, rawBrand: ${_this.rawBrand}, packageWeight: ${_this.packageWeight}, isDeposit: ${_this.isDeposit}, isDiscount: ${_this.isDiscount}, status: ${_this.status}, matchedProduct: ${_this.matchedProduct}, candidates: ${_this.candidates})';
}


}

/// @nodoc
abstract mixin class $ReceiptLineItemCopyWith<$Res>  {
  factory $ReceiptLineItemCopyWith(ReceiptLineItem value, $Res Function(ReceiptLineItem) _then) = _$ReceiptLineItemCopyWithImpl;
@useResult
$Res call({
 String id, String rawName, double totalPrice, double discount, double quantity, double? unitPrice, String? unit, String? rawCategory, String? rawBrand, String? packageWeight, bool isDeposit, bool isDiscount, ReceiptItemStatus status, ProductCandidate? matchedProduct, List<ProductCandidate> candidates
});


$ProductCandidateCopyWith<$Res>? get matchedProduct;

}
/// @nodoc
class _$ReceiptLineItemCopyWithImpl<$Res>
    implements $ReceiptLineItemCopyWith<$Res> {
  _$ReceiptLineItemCopyWithImpl(this._self, this._then);

  final ReceiptLineItem _self;
  final $Res Function(ReceiptLineItem) _then;

/// Create a copy of ReceiptLineItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? rawName = null,Object? totalPrice = null,Object? discount = null,Object? quantity = null,Object? unitPrice = freezed,Object? unit = freezed,Object? rawCategory = freezed,Object? rawBrand = freezed,Object? packageWeight = freezed,Object? isDeposit = null,Object? isDiscount = null,Object? status = null,Object? matchedProduct = freezed,Object? candidates = null,}) {
  return _then(ReceiptLineItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rawName: null == rawName ? _self.rawName : rawName // ignore: cast_nullable_to_non_nullable
as String,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as double,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,rawCategory: freezed == rawCategory ? _self.rawCategory : rawCategory // ignore: cast_nullable_to_non_nullable
as String?,rawBrand: freezed == rawBrand ? _self.rawBrand : rawBrand // ignore: cast_nullable_to_non_nullable
as String?,packageWeight: freezed == packageWeight ? _self.packageWeight : packageWeight // ignore: cast_nullable_to_non_nullable
as String?,isDeposit: null == isDeposit ? _self.isDeposit : isDeposit // ignore: cast_nullable_to_non_nullable
as bool,isDiscount: null == isDiscount ? _self.isDiscount : isDiscount // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReceiptItemStatus,matchedProduct: freezed == matchedProduct ? _self.matchedProduct : matchedProduct // ignore: cast_nullable_to_non_nullable
as ProductCandidate?,candidates: null == candidates ? _self.candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<ProductCandidate>,
  ));
}
/// Create a copy of ReceiptLineItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductCandidateCopyWith<$Res>? get matchedProduct {
    if (_self.matchedProduct == null) {
    return null;
  }

  return $ProductCandidateCopyWith<$Res>(_self.matchedProduct!, (value) {
    return _then(_self.copyWith(matchedProduct: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReceiptLineItem].
extension ReceiptLineItemPatterns on ReceiptLineItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceiptLineItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceiptLineItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceiptLineItem value)  $default,){
final _that = this;
switch (_that) {
case _ReceiptLineItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceiptLineItem value)?  $default,){
final _that = this;
switch (_that) {
case _ReceiptLineItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String rawName,  double totalPrice,  double discount,  double quantity,  double? unitPrice,  String? unit,  String? rawCategory,  String? rawBrand,  String? packageWeight,  bool isDeposit,  bool isDiscount,  ReceiptItemStatus status,  ProductCandidate? matchedProduct,  List<ProductCandidate> candidates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceiptLineItem() when $default != null:
return $default(_that.id,_that.rawName,_that.totalPrice,_that.discount,_that.quantity,_that.unitPrice,_that.unit,_that.rawCategory,_that.rawBrand,_that.packageWeight,_that.isDeposit,_that.isDiscount,_that.status,_that.matchedProduct,_that.candidates);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String rawName,  double totalPrice,  double discount,  double quantity,  double? unitPrice,  String? unit,  String? rawCategory,  String? rawBrand,  String? packageWeight,  bool isDeposit,  bool isDiscount,  ReceiptItemStatus status,  ProductCandidate? matchedProduct,  List<ProductCandidate> candidates)  $default,) {final _that = this;
switch (_that) {
case _ReceiptLineItem():
return $default(_that.id,_that.rawName,_that.totalPrice,_that.discount,_that.quantity,_that.unitPrice,_that.unit,_that.rawCategory,_that.rawBrand,_that.packageWeight,_that.isDeposit,_that.isDiscount,_that.status,_that.matchedProduct,_that.candidates);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String rawName,  double totalPrice,  double discount,  double quantity,  double? unitPrice,  String? unit,  String? rawCategory,  String? rawBrand,  String? packageWeight,  bool isDeposit,  bool isDiscount,  ReceiptItemStatus status,  ProductCandidate? matchedProduct,  List<ProductCandidate> candidates)?  $default,) {final _that = this;
switch (_that) {
case _ReceiptLineItem() when $default != null:
return $default(_that.id,_that.rawName,_that.totalPrice,_that.discount,_that.quantity,_that.unitPrice,_that.unit,_that.rawCategory,_that.rawBrand,_that.packageWeight,_that.isDeposit,_that.isDiscount,_that.status,_that.matchedProduct,_that.candidates);case _:
  return null;

}
}

}

/// @nodoc


class _ReceiptLineItem extends ReceiptLineItem {
  const _ReceiptLineItem({required this.id, required this.rawName, required this.totalPrice, this.discount = 0.0, this.quantity = 1.0, this.unitPrice, this.unit, this.rawCategory, this.rawBrand, this.packageWeight, this.isDeposit = false, this.isDiscount = false, this.status = ReceiptItemStatus.unmatched, this.matchedProduct,  List<ProductCandidate> candidates = const <ProductCandidate>[]}): _candidates = candidates,super._();
  

/// Unique ID of this line within the receipt.
@override final  String id;
/// Original raw text on the receipt (e.g. "JA! VOLLM 3.8% 1L").
@override final  String rawName;
/// Printed total price on receipt before discounts.
@override final  double totalPrice;
/// Line discount (e.g. 0.50 coupon or promotion).
@override@JsonKey() final  double discount;
/// Purchased quantity (e.g. 1.0 pieces or 0.450 kg).
@override@JsonKey() final  double quantity;
/// Unit price if printed on receipt.
@override final  double? unitPrice;
/// Unit (e.g. "kg", "g", "l", "pcs").
@override final  String? unit;
/// Store product category if listed on receipt.
@override final  String? rawCategory;
/// Brand name or abbreviated brand marker extracted from the receipt.
@override final  String? rawBrand;
/// Package content printed or inferred for this product (e.g. 200g, 1L).
@override final  String? packageWeight;
/// Whether this is a deposit line item.
@override@JsonKey() final  bool isDeposit;
/// Whether this is a discount / voucher line item.
@override@JsonKey() final  bool isDiscount;
/// Current review status.
@override@JsonKey() final  ReceiptItemStatus status;
/// Currently matched product candidate.
@override final  ProductCandidate? matchedProduct;
/// Alternative product candidates for this line item.
 final  List<ProductCandidate> _candidates;
/// Alternative product candidates for this line item.
@override@JsonKey() List<ProductCandidate> get candidates {
  if (_candidates is EqualUnmodifiableListView) return _candidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_candidates);
}


/// Create a copy of ReceiptLineItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptLineItemCopyWith<_ReceiptLineItem> get copyWith => __$ReceiptLineItemCopyWithImpl<_ReceiptLineItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptLineItem&&(identical(other.id, id) || other.id == id)&&(identical(other.rawName, rawName) || other.rawName == rawName)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.rawCategory, rawCategory) || other.rawCategory == rawCategory)&&(identical(other.rawBrand, rawBrand) || other.rawBrand == rawBrand)&&(identical(other.packageWeight, packageWeight) || other.packageWeight == packageWeight)&&(identical(other.isDeposit, isDeposit) || other.isDeposit == isDeposit)&&(identical(other.isDiscount, isDiscount) || other.isDiscount == isDiscount)&&(identical(other.status, status) || other.status == status)&&(identical(other.matchedProduct, matchedProduct) || other.matchedProduct == matchedProduct)&&const DeepCollectionEquality().equals(other.candidates, _candidates));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,rawName,totalPrice,discount,quantity,unitPrice,unit,rawCategory,rawBrand,packageWeight,isDeposit,isDiscount,status,matchedProduct,const DeepCollectionEquality().hash(_candidates));
}

@override
String toString() {
    return 'ReceiptLineItem(id: $id, rawName: $rawName, totalPrice: $totalPrice, discount: $discount, quantity: $quantity, unitPrice: $unitPrice, unit: $unit, rawCategory: $rawCategory, rawBrand: $rawBrand, packageWeight: $packageWeight, isDeposit: $isDeposit, isDiscount: $isDiscount, status: $status, matchedProduct: $matchedProduct, candidates: $candidates)';
}


}

/// @nodoc
abstract mixin class _$ReceiptLineItemCopyWith<$Res> implements $ReceiptLineItemCopyWith<$Res> {
  factory _$ReceiptLineItemCopyWith(_ReceiptLineItem value, $Res Function(_ReceiptLineItem) _then) = __$ReceiptLineItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String rawName, double totalPrice, double discount, double quantity, double? unitPrice, String? unit, String? rawCategory, String? rawBrand, String? packageWeight, bool isDeposit, bool isDiscount, ReceiptItemStatus status, ProductCandidate? matchedProduct, List<ProductCandidate> candidates
});


@override $ProductCandidateCopyWith<$Res>? get matchedProduct;

}
/// @nodoc
class __$ReceiptLineItemCopyWithImpl<$Res>
    implements _$ReceiptLineItemCopyWith<$Res> {
  __$ReceiptLineItemCopyWithImpl(this._self, this._then);

  final _ReceiptLineItem _self;
  final $Res Function(_ReceiptLineItem) _then;

/// Create a copy of ReceiptLineItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? rawName = null,Object? totalPrice = null,Object? discount = null,Object? quantity = null,Object? unitPrice = freezed,Object? unit = freezed,Object? rawCategory = freezed,Object? rawBrand = freezed,Object? packageWeight = freezed,Object? isDeposit = null,Object? isDiscount = null,Object? status = null,Object? matchedProduct = freezed,Object? candidates = null,}) {
  return _then(_ReceiptLineItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rawName: null == rawName ? _self.rawName : rawName // ignore: cast_nullable_to_non_nullable
as String,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as double,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,rawCategory: freezed == rawCategory ? _self.rawCategory : rawCategory // ignore: cast_nullable_to_non_nullable
as String?,rawBrand: freezed == rawBrand ? _self.rawBrand : rawBrand // ignore: cast_nullable_to_non_nullable
as String?,packageWeight: freezed == packageWeight ? _self.packageWeight : packageWeight // ignore: cast_nullable_to_non_nullable
as String?,isDeposit: null == isDeposit ? _self.isDeposit : isDeposit // ignore: cast_nullable_to_non_nullable
as bool,isDiscount: null == isDiscount ? _self.isDiscount : isDiscount // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReceiptItemStatus,matchedProduct: freezed == matchedProduct ? _self.matchedProduct : matchedProduct // ignore: cast_nullable_to_non_nullable
as ProductCandidate?,candidates: null == candidates ? _self._candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<ProductCandidate>,
  ));
}

/// Create a copy of ReceiptLineItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductCandidateCopyWith<$Res>? get matchedProduct {
    if (_self.matchedProduct == null) {
    return null;
  }

  return $ProductCandidateCopyWith<$Res>(_self.matchedProduct!, (value) {
    return _then(_self.copyWith(matchedProduct: value));
  });
}
}

// dart format on
