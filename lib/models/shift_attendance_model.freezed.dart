// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift_attendance_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShiftAttendanceModel {

 String get id; DateTime get shiftDate; String get userId; bool get checkedIn; String? get replacementUserId;// User who replaced this firefighter (Abono)
 bool get isExtra;// Extra firefighter not in schedule
 DateTime? get createdAt;
/// Create a copy of ShiftAttendanceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftAttendanceModelCopyWith<ShiftAttendanceModel> get copyWith => _$ShiftAttendanceModelCopyWithImpl<ShiftAttendanceModel>(this as ShiftAttendanceModel, _$identity);

  /// Serializes this ShiftAttendanceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShiftAttendanceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.shiftDate, shiftDate) || other.shiftDate == shiftDate)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.checkedIn, checkedIn) || other.checkedIn == checkedIn)&&(identical(other.replacementUserId, replacementUserId) || other.replacementUserId == replacementUserId)&&(identical(other.isExtra, isExtra) || other.isExtra == isExtra)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,shiftDate,userId,checkedIn,replacementUserId,isExtra,createdAt);

@override
String toString() {
  return 'ShiftAttendanceModel(id: $id, shiftDate: $shiftDate, userId: $userId, checkedIn: $checkedIn, replacementUserId: $replacementUserId, isExtra: $isExtra, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ShiftAttendanceModelCopyWith<$Res>  {
  factory $ShiftAttendanceModelCopyWith(ShiftAttendanceModel value, $Res Function(ShiftAttendanceModel) _then) = _$ShiftAttendanceModelCopyWithImpl;
@useResult
$Res call({
 String id, DateTime shiftDate, String userId, bool checkedIn, String? replacementUserId, bool isExtra, DateTime? createdAt
});




}
/// @nodoc
class _$ShiftAttendanceModelCopyWithImpl<$Res>
    implements $ShiftAttendanceModelCopyWith<$Res> {
  _$ShiftAttendanceModelCopyWithImpl(this._self, this._then);

  final ShiftAttendanceModel _self;
  final $Res Function(ShiftAttendanceModel) _then;

/// Create a copy of ShiftAttendanceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? shiftDate = null,Object? userId = null,Object? checkedIn = null,Object? replacementUserId = freezed,Object? isExtra = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shiftDate: null == shiftDate ? _self.shiftDate : shiftDate // ignore: cast_nullable_to_non_nullable
as DateTime,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,checkedIn: null == checkedIn ? _self.checkedIn : checkedIn // ignore: cast_nullable_to_non_nullable
as bool,replacementUserId: freezed == replacementUserId ? _self.replacementUserId : replacementUserId // ignore: cast_nullable_to_non_nullable
as String?,isExtra: null == isExtra ? _self.isExtra : isExtra // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShiftAttendanceModel].
extension ShiftAttendanceModelPatterns on ShiftAttendanceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShiftAttendanceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShiftAttendanceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShiftAttendanceModel value)  $default,){
final _that = this;
switch (_that) {
case _ShiftAttendanceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShiftAttendanceModel value)?  $default,){
final _that = this;
switch (_that) {
case _ShiftAttendanceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime shiftDate,  String userId,  bool checkedIn,  String? replacementUserId,  bool isExtra,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShiftAttendanceModel() when $default != null:
return $default(_that.id,_that.shiftDate,_that.userId,_that.checkedIn,_that.replacementUserId,_that.isExtra,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime shiftDate,  String userId,  bool checkedIn,  String? replacementUserId,  bool isExtra,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _ShiftAttendanceModel():
return $default(_that.id,_that.shiftDate,_that.userId,_that.checkedIn,_that.replacementUserId,_that.isExtra,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime shiftDate,  String userId,  bool checkedIn,  String? replacementUserId,  bool isExtra,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ShiftAttendanceModel() when $default != null:
return $default(_that.id,_that.shiftDate,_that.userId,_that.checkedIn,_that.replacementUserId,_that.isExtra,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShiftAttendanceModel implements ShiftAttendanceModel {
  const _ShiftAttendanceModel({required this.id, required this.shiftDate, required this.userId, this.checkedIn = false, this.replacementUserId, this.isExtra = false, this.createdAt});
  factory _ShiftAttendanceModel.fromJson(Map<String, dynamic> json) => _$ShiftAttendanceModelFromJson(json);

@override final  String id;
@override final  DateTime shiftDate;
@override final  String userId;
@override@JsonKey() final  bool checkedIn;
@override final  String? replacementUserId;
// User who replaced this firefighter (Abono)
@override@JsonKey() final  bool isExtra;
// Extra firefighter not in schedule
@override final  DateTime? createdAt;

/// Create a copy of ShiftAttendanceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftAttendanceModelCopyWith<_ShiftAttendanceModel> get copyWith => __$ShiftAttendanceModelCopyWithImpl<_ShiftAttendanceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShiftAttendanceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShiftAttendanceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.shiftDate, shiftDate) || other.shiftDate == shiftDate)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.checkedIn, checkedIn) || other.checkedIn == checkedIn)&&(identical(other.replacementUserId, replacementUserId) || other.replacementUserId == replacementUserId)&&(identical(other.isExtra, isExtra) || other.isExtra == isExtra)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,shiftDate,userId,checkedIn,replacementUserId,isExtra,createdAt);

@override
String toString() {
  return 'ShiftAttendanceModel(id: $id, shiftDate: $shiftDate, userId: $userId, checkedIn: $checkedIn, replacementUserId: $replacementUserId, isExtra: $isExtra, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ShiftAttendanceModelCopyWith<$Res> implements $ShiftAttendanceModelCopyWith<$Res> {
  factory _$ShiftAttendanceModelCopyWith(_ShiftAttendanceModel value, $Res Function(_ShiftAttendanceModel) _then) = __$ShiftAttendanceModelCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime shiftDate, String userId, bool checkedIn, String? replacementUserId, bool isExtra, DateTime? createdAt
});




}
/// @nodoc
class __$ShiftAttendanceModelCopyWithImpl<$Res>
    implements _$ShiftAttendanceModelCopyWith<$Res> {
  __$ShiftAttendanceModelCopyWithImpl(this._self, this._then);

  final _ShiftAttendanceModel _self;
  final $Res Function(_ShiftAttendanceModel) _then;

/// Create a copy of ShiftAttendanceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? shiftDate = null,Object? userId = null,Object? checkedIn = null,Object? replacementUserId = freezed,Object? isExtra = null,Object? createdAt = freezed,}) {
  return _then(_ShiftAttendanceModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shiftDate: null == shiftDate ? _self.shiftDate : shiftDate // ignore: cast_nullable_to_non_nullable
as DateTime,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,checkedIn: null == checkedIn ? _self.checkedIn : checkedIn // ignore: cast_nullable_to_non_nullable
as bool,replacementUserId: freezed == replacementUserId ? _self.replacementUserId : replacementUserId // ignore: cast_nullable_to_non_nullable
as String?,isExtra: null == isExtra ? _self.isExtra : isExtra // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
