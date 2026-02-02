// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'act_type_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActTypeModel {

 String get id; String get name; ActCategory get category; bool get isActive; DateTime? get createdAt;
/// Create a copy of ActTypeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActTypeModelCopyWith<ActTypeModel> get copyWith => _$ActTypeModelCopyWithImpl<ActTypeModel>(this as ActTypeModel, _$identity);

  /// Serializes this ActTypeModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActTypeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,category,isActive,createdAt);

@override
String toString() {
  return 'ActTypeModel(id: $id, name: $name, category: $category, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ActTypeModelCopyWith<$Res>  {
  factory $ActTypeModelCopyWith(ActTypeModel value, $Res Function(ActTypeModel) _then) = _$ActTypeModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, ActCategory category, bool isActive, DateTime? createdAt
});




}
/// @nodoc
class _$ActTypeModelCopyWithImpl<$Res>
    implements $ActTypeModelCopyWith<$Res> {
  _$ActTypeModelCopyWithImpl(this._self, this._then);

  final ActTypeModel _self;
  final $Res Function(ActTypeModel) _then;

/// Create a copy of ActTypeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? category = null,Object? isActive = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ActCategory,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ActTypeModel].
extension ActTypeModelPatterns on ActTypeModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActTypeModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActTypeModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActTypeModel value)  $default,){
final _that = this;
switch (_that) {
case _ActTypeModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActTypeModel value)?  $default,){
final _that = this;
switch (_that) {
case _ActTypeModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  ActCategory category,  bool isActive,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActTypeModel() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  ActCategory category,  bool isActive,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _ActTypeModel():
return $default(_that.id,_that.name,_that.category,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  ActCategory category,  bool isActive,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ActTypeModel() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.isActive,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActTypeModel implements ActTypeModel {
  const _ActTypeModel({required this.id, required this.name, required this.category, this.isActive = true, this.createdAt});
  factory _ActTypeModel.fromJson(Map<String, dynamic> json) => _$ActTypeModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  ActCategory category;
@override@JsonKey() final  bool isActive;
@override final  DateTime? createdAt;

/// Create a copy of ActTypeModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActTypeModelCopyWith<_ActTypeModel> get copyWith => __$ActTypeModelCopyWithImpl<_ActTypeModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActTypeModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActTypeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,category,isActive,createdAt);

@override
String toString() {
  return 'ActTypeModel(id: $id, name: $name, category: $category, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ActTypeModelCopyWith<$Res> implements $ActTypeModelCopyWith<$Res> {
  factory _$ActTypeModelCopyWith(_ActTypeModel value, $Res Function(_ActTypeModel) _then) = __$ActTypeModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, ActCategory category, bool isActive, DateTime? createdAt
});




}
/// @nodoc
class __$ActTypeModelCopyWithImpl<$Res>
    implements _$ActTypeModelCopyWith<$Res> {
  __$ActTypeModelCopyWithImpl(this._self, this._then);

  final _ActTypeModel _self;
  final $Res Function(_ActTypeModel) _then;

/// Create a copy of ActTypeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? category = null,Object? isActive = null,Object? createdAt = freezed,}) {
  return _then(_ActTypeModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ActCategory,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
