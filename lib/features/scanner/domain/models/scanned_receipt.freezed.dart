// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scanned_receipt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScannedReceipt {

/// Unique ID for this scan session.
 String get id;/// Recognized store name (e.g. "Lidl", "Rewe", "Aldi Süd").
 String? get storeName;/// Purchase date and time from the receipt.
 DateTime? get dateTime;/// Printed total amount on the receipt (e.g. 24.89).
 double? get printedTotal;/// File paths of original receipt files
/// (e.g. multiple photos for long receipts).
 List<String> get sourceFilePaths;/// MIME type of the original receipts (e.g. 'image/jpeg' or 'application/pdf').
 String? get sourceMimeType;/// Overall OCR / parsing confidence score (0.0 to 1.0).
 double get confidenceScore;/// Unprocessed raw text of the receipt (for debugging and transparency).
 String? get rawText;/// Currency (default: 'EUR').
 String get currency;/// All line items extracted from the receipt.
 List<ReceiptLineItem> get items;
/// Create a copy of ScannedReceipt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScannedReceiptCopyWith<ScannedReceipt> get copyWith => _$ScannedReceiptCopyWithImpl<ScannedReceipt>(this as ScannedReceipt, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ScannedReceipt;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScannedReceipt&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.storeName, _this.storeName) || other.storeName == _this.storeName)&&(identical(other.dateTime, _this.dateTime) || other.dateTime == _this.dateTime)&&(identical(other.printedTotal, _this.printedTotal) || other.printedTotal == _this.printedTotal)&&const DeepCollectionEquality().equals(other.sourceFilePaths, _this.sourceFilePaths)&&(identical(other.sourceMimeType, _this.sourceMimeType) || other.sourceMimeType == _this.sourceMimeType)&&(identical(other.confidenceScore, _this.confidenceScore) || other.confidenceScore == _this.confidenceScore)&&(identical(other.rawText, _this.rawText) || other.rawText == _this.rawText)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&const DeepCollectionEquality().equals(other.items, _this.items));
}


@override
int get hashCode {
  final _this = this as ScannedReceipt;
  return Object.hash(runtimeType,_this.id,_this.storeName,_this.dateTime,_this.printedTotal,const DeepCollectionEquality().hash(_this.sourceFilePaths),_this.sourceMimeType,_this.confidenceScore,_this.rawText,_this.currency,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as ScannedReceipt;
  return 'ScannedReceipt(id: ${_this.id}, storeName: ${_this.storeName}, dateTime: ${_this.dateTime}, printedTotal: ${_this.printedTotal}, sourceFilePaths: ${_this.sourceFilePaths}, sourceMimeType: ${_this.sourceMimeType}, confidenceScore: ${_this.confidenceScore}, rawText: ${_this.rawText}, currency: ${_this.currency}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $ScannedReceiptCopyWith<$Res>  {
  factory $ScannedReceiptCopyWith(ScannedReceipt value, $Res Function(ScannedReceipt) _then) = _$ScannedReceiptCopyWithImpl;
@useResult
$Res call({
 String id, String? storeName, DateTime? dateTime, double? printedTotal, List<String> sourceFilePaths, String? sourceMimeType, double confidenceScore, String? rawText, String currency, List<ReceiptLineItem> items
});




}
/// @nodoc
class _$ScannedReceiptCopyWithImpl<$Res>
    implements $ScannedReceiptCopyWith<$Res> {
  _$ScannedReceiptCopyWithImpl(this._self, this._then);

  final ScannedReceipt _self;
  final $Res Function(ScannedReceipt) _then;

/// Create a copy of ScannedReceipt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? storeName = freezed,Object? dateTime = freezed,Object? printedTotal = freezed,Object? sourceFilePaths = null,Object? sourceMimeType = freezed,Object? confidenceScore = null,Object? rawText = freezed,Object? currency = null,Object? items = null,}) {
  return _then(ScannedReceipt(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeName: freezed == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String?,dateTime: freezed == dateTime ? _self.dateTime : dateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,printedTotal: freezed == printedTotal ? _self.printedTotal : printedTotal // ignore: cast_nullable_to_non_nullable
as double?,sourceFilePaths: null == sourceFilePaths ? _self.sourceFilePaths : sourceFilePaths // ignore: cast_nullable_to_non_nullable
as List<String>,sourceMimeType: freezed == sourceMimeType ? _self.sourceMimeType : sourceMimeType // ignore: cast_nullable_to_non_nullable
as String?,confidenceScore: null == confidenceScore ? _self.confidenceScore : confidenceScore // ignore: cast_nullable_to_non_nullable
as double,rawText: freezed == rawText ? _self.rawText : rawText // ignore: cast_nullable_to_non_nullable
as String?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ReceiptLineItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [ScannedReceipt].
extension ScannedReceiptPatterns on ScannedReceipt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScannedReceipt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScannedReceipt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScannedReceipt value)  $default,){
final _that = this;
switch (_that) {
case _ScannedReceipt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScannedReceipt value)?  $default,){
final _that = this;
switch (_that) {
case _ScannedReceipt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? storeName,  DateTime? dateTime,  double? printedTotal,  List<String> sourceFilePaths,  String? sourceMimeType,  double confidenceScore,  String? rawText,  String currency,  List<ReceiptLineItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScannedReceipt() when $default != null:
return $default(_that.id,_that.storeName,_that.dateTime,_that.printedTotal,_that.sourceFilePaths,_that.sourceMimeType,_that.confidenceScore,_that.rawText,_that.currency,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? storeName,  DateTime? dateTime,  double? printedTotal,  List<String> sourceFilePaths,  String? sourceMimeType,  double confidenceScore,  String? rawText,  String currency,  List<ReceiptLineItem> items)  $default,) {final _that = this;
switch (_that) {
case _ScannedReceipt():
return $default(_that.id,_that.storeName,_that.dateTime,_that.printedTotal,_that.sourceFilePaths,_that.sourceMimeType,_that.confidenceScore,_that.rawText,_that.currency,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? storeName,  DateTime? dateTime,  double? printedTotal,  List<String> sourceFilePaths,  String? sourceMimeType,  double confidenceScore,  String? rawText,  String currency,  List<ReceiptLineItem> items)?  $default,) {final _that = this;
switch (_that) {
case _ScannedReceipt() when $default != null:
return $default(_that.id,_that.storeName,_that.dateTime,_that.printedTotal,_that.sourceFilePaths,_that.sourceMimeType,_that.confidenceScore,_that.rawText,_that.currency,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _ScannedReceipt extends ScannedReceipt {
  const _ScannedReceipt({required this.id, this.storeName, this.dateTime, this.printedTotal,  List<String> sourceFilePaths = const <String>[], this.sourceMimeType, this.confidenceScore = 1.0, this.rawText, this.currency = 'EUR',  List<ReceiptLineItem> items = const <ReceiptLineItem>[]}): _sourceFilePaths = sourceFilePaths,_items = items,super._();
  

/// Unique ID for this scan session.
@override final  String id;
/// Recognized store name (e.g. "Lidl", "Rewe", "Aldi Süd").
@override final  String? storeName;
/// Purchase date and time from the receipt.
@override final  DateTime? dateTime;
/// Printed total amount on the receipt (e.g. 24.89).
@override final  double? printedTotal;
/// File paths of original receipt files
/// (e.g. multiple photos for long receipts).
 final  List<String> _sourceFilePaths;
/// File paths of original receipt files
/// (e.g. multiple photos for long receipts).
@override@JsonKey() List<String> get sourceFilePaths {
  if (_sourceFilePaths is EqualUnmodifiableListView) return _sourceFilePaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sourceFilePaths);
}

/// MIME type of the original receipts (e.g. 'image/jpeg' or 'application/pdf').
@override final  String? sourceMimeType;
/// Overall OCR / parsing confidence score (0.0 to 1.0).
@override@JsonKey() final  double confidenceScore;
/// Unprocessed raw text of the receipt (for debugging and transparency).
@override final  String? rawText;
/// Currency (default: 'EUR').
@override@JsonKey() final  String currency;
/// All line items extracted from the receipt.
 final  List<ReceiptLineItem> _items;
/// All line items extracted from the receipt.
@override@JsonKey() List<ReceiptLineItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of ScannedReceipt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScannedReceiptCopyWith<_ScannedReceipt> get copyWith => __$ScannedReceiptCopyWithImpl<_ScannedReceipt>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScannedReceipt&&(identical(other.id, id) || other.id == id)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.dateTime, dateTime) || other.dateTime == dateTime)&&(identical(other.printedTotal, printedTotal) || other.printedTotal == printedTotal)&&const DeepCollectionEquality().equals(other.sourceFilePaths, _sourceFilePaths)&&(identical(other.sourceMimeType, sourceMimeType) || other.sourceMimeType == sourceMimeType)&&(identical(other.confidenceScore, confidenceScore) || other.confidenceScore == confidenceScore)&&(identical(other.rawText, rawText) || other.rawText == rawText)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other.items, _items));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,storeName,dateTime,printedTotal,const DeepCollectionEquality().hash(_sourceFilePaths),sourceMimeType,confidenceScore,rawText,currency,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'ScannedReceipt(id: $id, storeName: $storeName, dateTime: $dateTime, printedTotal: $printedTotal, sourceFilePaths: $sourceFilePaths, sourceMimeType: $sourceMimeType, confidenceScore: $confidenceScore, rawText: $rawText, currency: $currency, items: $items)';
}


}

/// @nodoc
abstract mixin class _$ScannedReceiptCopyWith<$Res> implements $ScannedReceiptCopyWith<$Res> {
  factory _$ScannedReceiptCopyWith(_ScannedReceipt value, $Res Function(_ScannedReceipt) _then) = __$ScannedReceiptCopyWithImpl;
@override @useResult
$Res call({
 String id, String? storeName, DateTime? dateTime, double? printedTotal, List<String> sourceFilePaths, String? sourceMimeType, double confidenceScore, String? rawText, String currency, List<ReceiptLineItem> items
});




}
/// @nodoc
class __$ScannedReceiptCopyWithImpl<$Res>
    implements _$ScannedReceiptCopyWith<$Res> {
  __$ScannedReceiptCopyWithImpl(this._self, this._then);

  final _ScannedReceipt _self;
  final $Res Function(_ScannedReceipt) _then;

/// Create a copy of ScannedReceipt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? storeName = freezed,Object? dateTime = freezed,Object? printedTotal = freezed,Object? sourceFilePaths = null,Object? sourceMimeType = freezed,Object? confidenceScore = null,Object? rawText = freezed,Object? currency = null,Object? items = null,}) {
  return _then(_ScannedReceipt(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeName: freezed == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String?,dateTime: freezed == dateTime ? _self.dateTime : dateTime // ignore: cast_nullable_to_non_nullable
as DateTime?,printedTotal: freezed == printedTotal ? _self.printedTotal : printedTotal // ignore: cast_nullable_to_non_nullable
as double?,sourceFilePaths: null == sourceFilePaths ? _self._sourceFilePaths : sourceFilePaths // ignore: cast_nullable_to_non_nullable
as List<String>,sourceMimeType: freezed == sourceMimeType ? _self.sourceMimeType : sourceMimeType // ignore: cast_nullable_to_non_nullable
as String?,confidenceScore: null == confidenceScore ? _self.confidenceScore : confidenceScore // ignore: cast_nullable_to_non_nullable
as double,rawText: freezed == rawText ? _self.rawText : rawText // ignore: cast_nullable_to_non_nullable
as String?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ReceiptLineItem>,
  ));
}


}

// dart format on
