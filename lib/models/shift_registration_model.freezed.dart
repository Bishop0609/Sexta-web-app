// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift_registration_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShiftRegistrationModel {

 String get id; String get configId; String get userId; DateTime get shiftDate; DateTime? get createdAt;
/// Create a copy of ShiftRegistrationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftRegistrationModelCopyWith<ShiftRegistrationModel> get copyWith => _$ShiftRegistrationModelCopyWithImpl<ShiftRegistrationModel>(this as ShiftRegistrationModel, _$identity);

  /// Serializes this ShiftRegistrationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShiftRegistrationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.configId, configId) || other.configId == configId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.shiftDate, shiftDate) || other.shiftDate == shiftDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,configId,userId,shiftDate,createdAt);

@override
String toString() {
  return 'ShiftRegistrationModel(id: $id, configId: $configId, userId: $userId, shiftDate: $shiftDate, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ShiftRegistrationModelCopyWith<$Res>  {
  factory $ShiftRegistrationModelCopyWith(ShiftRegistrationModel value, $Res Function(ShiftRegistrationModel) _then) = _$ShiftRegistrationModelCopyWithImpl;
@useResult
$Res call({
 String id, String configId, String userId, DateTime shiftDate, DateTime? createdAt
});




}
/// @nodoc
class _$ShiftRegistrationModelCopyWithImpl<$Res>
    implements $ShiftRegistrationModelCopyWith<$Res> {
  _$ShiftRegistrationModelCopyWithImpl(this._self, this._then);

  final ShiftRegistrationModel _self;
  final $Res Function(ShiftRegistrationModel) _then;

/// Create a copy of ShiftRegistrationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? configId = null,Object? userId = null,Object? shiftDate = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,configId: null == configId ? _self.configId : configId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,shiftDate: null == shiftDate ? _self.shiftDate : shiftDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShiftRegistrationModel].
extension ShiftRegistrationModelPatterns on ShiftRegistrationModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShiftRegistrationModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShiftRegistrationModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShiftRegistrationModel value)  $default,){
final _that = this;
switch (_that) {
case _ShiftRegistrationModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShiftRegistrationModel value)?  $default,){
final _that = this;
switch (_that) {
case _ShiftRegistrationModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String configId,  String userId,  DateTime shiftDate,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShiftRegistrationModel() when $default != null:
return $default(_that.id,_that.configId,_that.userId,_that.shiftDate,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String configId,  String userId,  DateTime shiftDate,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _ShiftRegistrationModel():
return $default(_that.id,_that.configId,_that.userId,_that.shiftDate,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String configId,  String userId,  DateTime shiftDate,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ShiftRegistrationModel() when $default != null:
return $default(_that.id,_that.configId,_that.userId,_that.shiftDate,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShiftRegistrationModel implements ShiftRegistrationModel {
  const _ShiftRegistrationModel({required this.id, required this.configId, required this.userId, required this.shiftDate, this.createdAt});
  factory _ShiftRegistrationModel.fromJson(Map<String, dynamic> json) => _$ShiftRegistrationModelFromJson(json);

@override final  String id;
@override final  String configId;
@override final  String userId;
@override final  DateTime shiftDate;
@override final  DateTime? createdAt;

/// Create a copy of ShiftRegistrationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftRegistrationModelCopyWith<_ShiftRegistrationModel> get copyWith => __$ShiftRegistrationModelCopyWithImpl<_ShiftRegistrationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShiftRegistrationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShiftRegistrationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.configId, configId) || other.configId == configId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.shiftDate, shiftDate) || other.shiftDate == shiftDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,configId,userId,shiftDate,createdAt);

@override
String toString() {
  return 'ShiftRegistrationModel(id: $id, configId: $configId, userId: $userId, shiftDate: $shiftDate, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ShiftRegistrationModelCopyWith<$Res> implements $ShiftRegistrationModelCopyWith<$Res> {
  factory _$ShiftRegistrationModelCopyWith(_ShiftRegistrationModel value, $Res Function(_ShiftRegistrationModel) _then) = __$ShiftRegistrationModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String configId, String userId, DateTime shiftDate, DateTime? createdAt
});




}
/// @nodoc
class __$ShiftRegistrationModelCopyWithImpl<$Res>
    implements _$ShiftRegistrationModelCopyWith<$Res> {
  __$ShiftRegistrationModelCopyWithImpl(this._self, this._then);

  final _ShiftRegistrationModel _self;
  final $Res Function(_ShiftRegistrationModel) _then;

/// Create a copy of ShiftRegistrationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? configId = null,Object? userId = null,Object? shiftDate = null,Object? createdAt = freezed,}) {
  return _then(_ShiftRegistrationModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,configId: null == configId ? _self.configId : configId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,shiftDate: null == shiftDate ? _self.shiftDate : shiftDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
