// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_candidate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductCandidate {

/// Eindeutige ID im Katalog (z. B. GlobalFoodItem-ID oder Barcode).
 String get id;/// Vollständiger Artikelname (z. B. "Ja! Frische Vollmilch 3,8%").
 String get name;/// Marke (z. B. "Ja!", "Milbona", "Bauer").
 String? get brand;/// Kategorie (z. B. "Milch & Molkereiprodukte").
 String? get category;/// EAN / Barcode (falls bekannt).
 String? get barcode;/// Bild-URL des Produkts.
 String? get imageUrl;/// Packungsgröße als Text (z. B. "1 l", "500 g", "4x125g").
 String? get packageSize;/// Konfidenzwert zwischen 0.0 und 1.0.
 double get confidence;/// Woher stammt dieser Vorschlag?
 CandidateSource get source;/// Whether this candidate must be added to the global food catalog before
/// inventory items and receipt aliases may reference it.
 bool get requiresPersistence;/// Nährwerte pro 100g/ml.
 GlobalFoodNutrition? get nutrition;
/// Create a copy of ProductCandidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCandidateCopyWith<ProductCandidate> get copyWith => _$ProductCandidateCopyWithImpl<ProductCandidate>(this as ProductCandidate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProductCandidate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductCandidate&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.brand, _this.brand) || other.brand == _this.brand)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.barcode, _this.barcode) || other.barcode == _this.barcode)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl)&&(identical(other.packageSize, _this.packageSize) || other.packageSize == _this.packageSize)&&(identical(other.confidence, _this.confidence) || other.confidence == _this.confidence)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.requiresPersistence, _this.requiresPersistence) || other.requiresPersistence == _this.requiresPersistence)&&(identical(other.nutrition, _this.nutrition) || other.nutrition == _this.nutrition));
}


@override
int get hashCode {
  final _this = this as ProductCandidate;
  return Object.hash(runtimeType,_this.id,_this.name,_this.brand,_this.category,_this.barcode,_this.imageUrl,_this.packageSize,_this.confidence,_this.source,_this.requiresPersistence,_this.nutrition);
}

@override
String toString() {
  final _this = this as ProductCandidate;
  return 'ProductCandidate(id: ${_this.id}, name: ${_this.name}, brand: ${_this.brand}, category: ${_this.category}, barcode: ${_this.barcode}, imageUrl: ${_this.imageUrl}, packageSize: ${_this.packageSize}, confidence: ${_this.confidence}, source: ${_this.source}, requiresPersistence: ${_this.requiresPersistence}, nutrition: ${_this.nutrition})';
}


}

/// @nodoc
abstract mixin class $ProductCandidateCopyWith<$Res>  {
  factory $ProductCandidateCopyWith(ProductCandidate value, $Res Function(ProductCandidate) _then) = _$ProductCandidateCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? brand, String? category, String? barcode, String? imageUrl, String? packageSize, double confidence, CandidateSource source, bool requiresPersistence, GlobalFoodNutrition? nutrition
});


$GlobalFoodNutritionCopyWith<$Res>? get nutrition;

}
/// @nodoc
class _$ProductCandidateCopyWithImpl<$Res>
    implements $ProductCandidateCopyWith<$Res> {
  _$ProductCandidateCopyWithImpl(this._self, this._then);

  final ProductCandidate _self;
  final $Res Function(ProductCandidate) _then;

/// Create a copy of ProductCandidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? brand = freezed,Object? category = freezed,Object? barcode = freezed,Object? imageUrl = freezed,Object? packageSize = freezed,Object? confidence = null,Object? source = null,Object? requiresPersistence = null,Object? nutrition = freezed,}) {
  return _then(ProductCandidate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,packageSize: freezed == packageSize ? _self.packageSize : packageSize // ignore: cast_nullable_to_non_nullable
as String?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as CandidateSource,requiresPersistence: null == requiresPersistence ? _self.requiresPersistence : requiresPersistence // ignore: cast_nullable_to_non_nullable
as bool,nutrition: freezed == nutrition ? _self.nutrition : nutrition // ignore: cast_nullable_to_non_nullable
as GlobalFoodNutrition?,
  ));
}
/// Create a copy of ProductCandidate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GlobalFoodNutritionCopyWith<$Res>? get nutrition {
    if (_self.nutrition == null) {
    return null;
  }

  return $GlobalFoodNutritionCopyWith<$Res>(_self.nutrition!, (value) {
    return _then(_self.copyWith(nutrition: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProductCandidate].
extension ProductCandidatePatterns on ProductCandidate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductCandidate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductCandidate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductCandidate value)  $default,){
final _that = this;
switch (_that) {
case _ProductCandidate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductCandidate value)?  $default,){
final _that = this;
switch (_that) {
case _ProductCandidate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? brand,  String? category,  String? barcode,  String? imageUrl,  String? packageSize,  double confidence,  CandidateSource source,  bool requiresPersistence,  GlobalFoodNutrition? nutrition)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductCandidate() when $default != null:
return $default(_that.id,_that.name,_that.brand,_that.category,_that.barcode,_that.imageUrl,_that.packageSize,_that.confidence,_that.source,_that.requiresPersistence,_that.nutrition);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? brand,  String? category,  String? barcode,  String? imageUrl,  String? packageSize,  double confidence,  CandidateSource source,  bool requiresPersistence,  GlobalFoodNutrition? nutrition)  $default,) {final _that = this;
switch (_that) {
case _ProductCandidate():
return $default(_that.id,_that.name,_that.brand,_that.category,_that.barcode,_that.imageUrl,_that.packageSize,_that.confidence,_that.source,_that.requiresPersistence,_that.nutrition);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? brand,  String? category,  String? barcode,  String? imageUrl,  String? packageSize,  double confidence,  CandidateSource source,  bool requiresPersistence,  GlobalFoodNutrition? nutrition)?  $default,) {final _that = this;
switch (_that) {
case _ProductCandidate() when $default != null:
return $default(_that.id,_that.name,_that.brand,_that.category,_that.barcode,_that.imageUrl,_that.packageSize,_that.confidence,_that.source,_that.requiresPersistence,_that.nutrition);case _:
  return null;

}
}

}

/// @nodoc


class _ProductCandidate extends ProductCandidate {
  const _ProductCandidate({required this.id, required this.name, this.brand, this.category, this.barcode, this.imageUrl, this.packageSize, this.confidence = 1.0, this.source = CandidateSource.catalogFuzzy, this.requiresPersistence = false, this.nutrition}): super._();
  

/// Eindeutige ID im Katalog (z. B. GlobalFoodItem-ID oder Barcode).
@override final  String id;
/// Vollständiger Artikelname (z. B. "Ja! Frische Vollmilch 3,8%").
@override final  String name;
/// Marke (z. B. "Ja!", "Milbona", "Bauer").
@override final  String? brand;
/// Kategorie (z. B. "Milch & Molkereiprodukte").
@override final  String? category;
/// EAN / Barcode (falls bekannt).
@override final  String? barcode;
/// Bild-URL des Produkts.
@override final  String? imageUrl;
/// Packungsgröße als Text (z. B. "1 l", "500 g", "4x125g").
@override final  String? packageSize;
/// Konfidenzwert zwischen 0.0 und 1.0.
@override@JsonKey() final  double confidence;
/// Woher stammt dieser Vorschlag?
@override@JsonKey() final  CandidateSource source;
/// Whether this candidate must be added to the global food catalog before
/// inventory items and receipt aliases may reference it.
@override@JsonKey() final  bool requiresPersistence;
/// Nährwerte pro 100g/ml.
@override final  GlobalFoodNutrition? nutrition;

/// Create a copy of ProductCandidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCandidateCopyWith<_ProductCandidate> get copyWith => __$ProductCandidateCopyWithImpl<_ProductCandidate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductCandidate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.category, category) || other.category == category)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.packageSize, packageSize) || other.packageSize == packageSize)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.source, source) || other.source == source)&&(identical(other.requiresPersistence, requiresPersistence) || other.requiresPersistence == requiresPersistence)&&(identical(other.nutrition, nutrition) || other.nutrition == nutrition));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,brand,category,barcode,imageUrl,packageSize,confidence,source,requiresPersistence,nutrition);
}

@override
String toString() {
    return 'ProductCandidate(id: $id, name: $name, brand: $brand, category: $category, barcode: $barcode, imageUrl: $imageUrl, packageSize: $packageSize, confidence: $confidence, source: $source, requiresPersistence: $requiresPersistence, nutrition: $nutrition)';
}


}

/// @nodoc
abstract mixin class _$ProductCandidateCopyWith<$Res> implements $ProductCandidateCopyWith<$Res> {
  factory _$ProductCandidateCopyWith(_ProductCandidate value, $Res Function(_ProductCandidate) _then) = __$ProductCandidateCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? brand, String? category, String? barcode, String? imageUrl, String? packageSize, double confidence, CandidateSource source, bool requiresPersistence, GlobalFoodNutrition? nutrition
});


@override $GlobalFoodNutritionCopyWith<$Res>? get nutrition;

}
/// @nodoc
class __$ProductCandidateCopyWithImpl<$Res>
    implements _$ProductCandidateCopyWith<$Res> {
  __$ProductCandidateCopyWithImpl(this._self, this._then);

  final _ProductCandidate _self;
  final $Res Function(_ProductCandidate) _then;

/// Create a copy of ProductCandidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? brand = freezed,Object? category = freezed,Object? barcode = freezed,Object? imageUrl = freezed,Object? packageSize = freezed,Object? confidence = null,Object? source = null,Object? requiresPersistence = null,Object? nutrition = freezed,}) {
  return _then(_ProductCandidate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,packageSize: freezed == packageSize ? _self.packageSize : packageSize // ignore: cast_nullable_to_non_nullable
as String?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as CandidateSource,requiresPersistence: null == requiresPersistence ? _self.requiresPersistence : requiresPersistence // ignore: cast_nullable_to_non_nullable
as bool,nutrition: freezed == nutrition ? _self.nutrition : nutrition // ignore: cast_nullable_to_non_nullable
as GlobalFoodNutrition?,
  ));
}

/// Create a copy of ProductCandidate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GlobalFoodNutritionCopyWith<$Res>? get nutrition {
    if (_self.nutrition == null) {
    return null;
  }

  return $GlobalFoodNutritionCopyWith<$Res>(_self.nutrition!, (value) {
    return _then(_self.copyWith(nutrition: value));
  });
}
}

// dart format on
