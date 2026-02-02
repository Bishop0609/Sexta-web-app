// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'statistics_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IndividualKPI {

 String get userId; int get efectivaCount; int get abonoCount; double get efectivaPct; double get abonoPct; int get totalAttendance;
/// Create a copy of IndividualKPI
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IndividualKPICopyWith<IndividualKPI> get copyWith => _$IndividualKPICopyWithImpl<IndividualKPI>(this as IndividualKPI, _$identity);

  /// Serializes this IndividualKPI to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IndividualKPI&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.efectivaCount, efectivaCount) || other.efectivaCount == efectivaCount)&&(identical(other.abonoCount, abonoCount) || other.abonoCount == abonoCount)&&(identical(other.efectivaPct, efectivaPct) || other.efectivaPct == efectivaPct)&&(identical(other.abonoPct, abonoPct) || other.abonoPct == abonoPct)&&(identical(other.totalAttendance, totalAttendance) || other.totalAttendance == totalAttendance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,efectivaCount,abonoCount,efectivaPct,abonoPct,totalAttendance);

@override
String toString() {
  return 'IndividualKPI(userId: $userId, efectivaCount: $efectivaCount, abonoCount: $abonoCount, efectivaPct: $efectivaPct, abonoPct: $abonoPct, totalAttendance: $totalAttendance)';
}


}

/// @nodoc
abstract mixin class $IndividualKPICopyWith<$Res>  {
  factory $IndividualKPICopyWith(IndividualKPI value, $Res Function(IndividualKPI) _then) = _$IndividualKPICopyWithImpl;
@useResult
$Res call({
 String userId, int efectivaCount, int abonoCount, double efectivaPct, double abonoPct, int totalAttendance
});




}
/// @nodoc
class _$IndividualKPICopyWithImpl<$Res>
    implements $IndividualKPICopyWith<$Res> {
  _$IndividualKPICopyWithImpl(this._self, this._then);

  final IndividualKPI _self;
  final $Res Function(IndividualKPI) _then;

/// Create a copy of IndividualKPI
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? efectivaCount = null,Object? abonoCount = null,Object? efectivaPct = null,Object? abonoPct = null,Object? totalAttendance = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,efectivaCount: null == efectivaCount ? _self.efectivaCount : efectivaCount // ignore: cast_nullable_to_non_nullable
as int,abonoCount: null == abonoCount ? _self.abonoCount : abonoCount // ignore: cast_nullable_to_non_nullable
as int,efectivaPct: null == efectivaPct ? _self.efectivaPct : efectivaPct // ignore: cast_nullable_to_non_nullable
as double,abonoPct: null == abonoPct ? _self.abonoPct : abonoPct // ignore: cast_nullable_to_non_nullable
as double,totalAttendance: null == totalAttendance ? _self.totalAttendance : totalAttendance // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [IndividualKPI].
extension IndividualKPIPatterns on IndividualKPI {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IndividualKPI value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IndividualKPI() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IndividualKPI value)  $default,){
final _that = this;
switch (_that) {
case _IndividualKPI():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IndividualKPI value)?  $default,){
final _that = this;
switch (_that) {
case _IndividualKPI() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  int efectivaCount,  int abonoCount,  double efectivaPct,  double abonoPct,  int totalAttendance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IndividualKPI() when $default != null:
return $default(_that.userId,_that.efectivaCount,_that.abonoCount,_that.efectivaPct,_that.abonoPct,_that.totalAttendance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  int efectivaCount,  int abonoCount,  double efectivaPct,  double abonoPct,  int totalAttendance)  $default,) {final _that = this;
switch (_that) {
case _IndividualKPI():
return $default(_that.userId,_that.efectivaCount,_that.abonoCount,_that.efectivaPct,_that.abonoPct,_that.totalAttendance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  int efectivaCount,  int abonoCount,  double efectivaPct,  double abonoPct,  int totalAttendance)?  $default,) {final _that = this;
switch (_that) {
case _IndividualKPI() when $default != null:
return $default(_that.userId,_that.efectivaCount,_that.abonoCount,_that.efectivaPct,_that.abonoPct,_that.totalAttendance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IndividualKPI implements IndividualKPI {
  const _IndividualKPI({required this.userId, required this.efectivaCount, required this.abonoCount, required this.efectivaPct, required this.abonoPct, required this.totalAttendance});
  factory _IndividualKPI.fromJson(Map<String, dynamic> json) => _$IndividualKPIFromJson(json);

@override final  String userId;
@override final  int efectivaCount;
@override final  int abonoCount;
@override final  double efectivaPct;
@override final  double abonoPct;
@override final  int totalAttendance;

/// Create a copy of IndividualKPI
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IndividualKPICopyWith<_IndividualKPI> get copyWith => __$IndividualKPICopyWithImpl<_IndividualKPI>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IndividualKPIToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IndividualKPI&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.efectivaCount, efectivaCount) || other.efectivaCount == efectivaCount)&&(identical(other.abonoCount, abonoCount) || other.abonoCount == abonoCount)&&(identical(other.efectivaPct, efectivaPct) || other.efectivaPct == efectivaPct)&&(identical(other.abonoPct, abonoPct) || other.abonoPct == abonoPct)&&(identical(other.totalAttendance, totalAttendance) || other.totalAttendance == totalAttendance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,efectivaCount,abonoCount,efectivaPct,abonoPct,totalAttendance);

@override
String toString() {
  return 'IndividualKPI(userId: $userId, efectivaCount: $efectivaCount, abonoCount: $abonoCount, efectivaPct: $efectivaPct, abonoPct: $abonoPct, totalAttendance: $totalAttendance)';
}


}

/// @nodoc
abstract mixin class _$IndividualKPICopyWith<$Res> implements $IndividualKPICopyWith<$Res> {
  factory _$IndividualKPICopyWith(_IndividualKPI value, $Res Function(_IndividualKPI) _then) = __$IndividualKPICopyWithImpl;
@override @useResult
$Res call({
 String userId, int efectivaCount, int abonoCount, double efectivaPct, double abonoPct, int totalAttendance
});




}
/// @nodoc
class __$IndividualKPICopyWithImpl<$Res>
    implements _$IndividualKPICopyWith<$Res> {
  __$IndividualKPICopyWithImpl(this._self, this._then);

  final _IndividualKPI _self;
  final $Res Function(_IndividualKPI) _then;

/// Create a copy of IndividualKPI
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? efectivaCount = null,Object? abonoCount = null,Object? efectivaPct = null,Object? abonoPct = null,Object? totalAttendance = null,}) {
  return _then(_IndividualKPI(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,efectivaCount: null == efectivaCount ? _self.efectivaCount : efectivaCount // ignore: cast_nullable_to_non_nullable
as int,abonoCount: null == abonoCount ? _self.abonoCount : abonoCount // ignore: cast_nullable_to_non_nullable
as int,efectivaPct: null == efectivaPct ? _self.efectivaPct : efectivaPct // ignore: cast_nullable_to_non_nullable
as double,abonoPct: null == abonoPct ? _self.abonoPct : abonoPct // ignore: cast_nullable_to_non_nullable
as double,totalAttendance: null == totalAttendance ? _self.totalAttendance : totalAttendance // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MonthlyStats {

 String get month; int get year; int get efectivaCount; int get abonoCount;
/// Create a copy of MonthlyStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthlyStatsCopyWith<MonthlyStats> get copyWith => _$MonthlyStatsCopyWithImpl<MonthlyStats>(this as MonthlyStats, _$identity);

  /// Serializes this MonthlyStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthlyStats&&(identical(other.month, month) || other.month == month)&&(identical(other.year, year) || other.year == year)&&(identical(other.efectivaCount, efectivaCount) || other.efectivaCount == efectivaCount)&&(identical(other.abonoCount, abonoCount) || other.abonoCount == abonoCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,year,efectivaCount,abonoCount);

@override
String toString() {
  return 'MonthlyStats(month: $month, year: $year, efectivaCount: $efectivaCount, abonoCount: $abonoCount)';
}


}

/// @nodoc
abstract mixin class $MonthlyStatsCopyWith<$Res>  {
  factory $MonthlyStatsCopyWith(MonthlyStats value, $Res Function(MonthlyStats) _then) = _$MonthlyStatsCopyWithImpl;
@useResult
$Res call({
 String month, int year, int efectivaCount, int abonoCount
});




}
/// @nodoc
class _$MonthlyStatsCopyWithImpl<$Res>
    implements $MonthlyStatsCopyWith<$Res> {
  _$MonthlyStatsCopyWithImpl(this._self, this._then);

  final MonthlyStats _self;
  final $Res Function(MonthlyStats) _then;

/// Create a copy of MonthlyStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? year = null,Object? efectivaCount = null,Object? abonoCount = null,}) {
  return _then(_self.copyWith(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,efectivaCount: null == efectivaCount ? _self.efectivaCount : efectivaCount // ignore: cast_nullable_to_non_nullable
as int,abonoCount: null == abonoCount ? _self.abonoCount : abonoCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthlyStats].
extension MonthlyStatsPatterns on MonthlyStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthlyStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthlyStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthlyStats value)  $default,){
final _that = this;
switch (_that) {
case _MonthlyStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthlyStats value)?  $default,){
final _that = this;
switch (_that) {
case _MonthlyStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String month,  int year,  int efectivaCount,  int abonoCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthlyStats() when $default != null:
return $default(_that.month,_that.year,_that.efectivaCount,_that.abonoCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String month,  int year,  int efectivaCount,  int abonoCount)  $default,) {final _that = this;
switch (_that) {
case _MonthlyStats():
return $default(_that.month,_that.year,_that.efectivaCount,_that.abonoCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String month,  int year,  int efectivaCount,  int abonoCount)?  $default,) {final _that = this;
switch (_that) {
case _MonthlyStats() when $default != null:
return $default(_that.month,_that.year,_that.efectivaCount,_that.abonoCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonthlyStats implements MonthlyStats {
  const _MonthlyStats({required this.month, required this.year, required this.efectivaCount, required this.abonoCount});
  factory _MonthlyStats.fromJson(Map<String, dynamic> json) => _$MonthlyStatsFromJson(json);

@override final  String month;
@override final  int year;
@override final  int efectivaCount;
@override final  int abonoCount;

/// Create a copy of MonthlyStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthlyStatsCopyWith<_MonthlyStats> get copyWith => __$MonthlyStatsCopyWithImpl<_MonthlyStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonthlyStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthlyStats&&(identical(other.month, month) || other.month == month)&&(identical(other.year, year) || other.year == year)&&(identical(other.efectivaCount, efectivaCount) || other.efectivaCount == efectivaCount)&&(identical(other.abonoCount, abonoCount) || other.abonoCount == abonoCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,year,efectivaCount,abonoCount);

@override
String toString() {
  return 'MonthlyStats(month: $month, year: $year, efectivaCount: $efectivaCount, abonoCount: $abonoCount)';
}


}

/// @nodoc
abstract mixin class _$MonthlyStatsCopyWith<$Res> implements $MonthlyStatsCopyWith<$Res> {
  factory _$MonthlyStatsCopyWith(_MonthlyStats value, $Res Function(_MonthlyStats) _then) = __$MonthlyStatsCopyWithImpl;
@override @useResult
$Res call({
 String month, int year, int efectivaCount, int abonoCount
});




}
/// @nodoc
class __$MonthlyStatsCopyWithImpl<$Res>
    implements _$MonthlyStatsCopyWith<$Res> {
  __$MonthlyStatsCopyWithImpl(this._self, this._then);

  final _MonthlyStats _self;
  final $Res Function(_MonthlyStats) _then;

/// Create a copy of MonthlyStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? year = null,Object? efectivaCount = null,Object? abonoCount = null,}) {
  return _then(_MonthlyStats(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,efectivaCount: null == efectivaCount ? _self.efectivaCount : efectivaCount // ignore: cast_nullable_to_non_nullable
as int,abonoCount: null == abonoCount ? _self.abonoCount : abonoCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AttendanceRanking {

 String get userId; String get fullName; String get rank; double get attendancePct; int get totalEvents;
/// Create a copy of AttendanceRanking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceRankingCopyWith<AttendanceRanking> get copyWith => _$AttendanceRankingCopyWithImpl<AttendanceRanking>(this as AttendanceRanking, _$identity);

  /// Serializes this AttendanceRanking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceRanking&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.attendancePct, attendancePct) || other.attendancePct == attendancePct)&&(identical(other.totalEvents, totalEvents) || other.totalEvents == totalEvents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,rank,attendancePct,totalEvents);

@override
String toString() {
  return 'AttendanceRanking(userId: $userId, fullName: $fullName, rank: $rank, attendancePct: $attendancePct, totalEvents: $totalEvents)';
}


}

/// @nodoc
abstract mixin class $AttendanceRankingCopyWith<$Res>  {
  factory $AttendanceRankingCopyWith(AttendanceRanking value, $Res Function(AttendanceRanking) _then) = _$AttendanceRankingCopyWithImpl;
@useResult
$Res call({
 String userId, String fullName, String rank, double attendancePct, int totalEvents
});




}
/// @nodoc
class _$AttendanceRankingCopyWithImpl<$Res>
    implements $AttendanceRankingCopyWith<$Res> {
  _$AttendanceRankingCopyWithImpl(this._self, this._then);

  final AttendanceRanking _self;
  final $Res Function(AttendanceRanking) _then;

/// Create a copy of AttendanceRanking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? fullName = null,Object? rank = null,Object? attendancePct = null,Object? totalEvents = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as String,attendancePct: null == attendancePct ? _self.attendancePct : attendancePct // ignore: cast_nullable_to_non_nullable
as double,totalEvents: null == totalEvents ? _self.totalEvents : totalEvents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendanceRanking].
extension AttendanceRankingPatterns on AttendanceRanking {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendanceRanking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendanceRanking() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendanceRanking value)  $default,){
final _that = this;
switch (_that) {
case _AttendanceRanking():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendanceRanking value)?  $default,){
final _that = this;
switch (_that) {
case _AttendanceRanking() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String fullName,  String rank,  double attendancePct,  int totalEvents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendanceRanking() when $default != null:
return $default(_that.userId,_that.fullName,_that.rank,_that.attendancePct,_that.totalEvents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String fullName,  String rank,  double attendancePct,  int totalEvents)  $default,) {final _that = this;
switch (_that) {
case _AttendanceRanking():
return $default(_that.userId,_that.fullName,_that.rank,_that.attendancePct,_that.totalEvents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String fullName,  String rank,  double attendancePct,  int totalEvents)?  $default,) {final _that = this;
switch (_that) {
case _AttendanceRanking() when $default != null:
return $default(_that.userId,_that.fullName,_that.rank,_that.attendancePct,_that.totalEvents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttendanceRanking implements AttendanceRanking {
  const _AttendanceRanking({required this.userId, required this.fullName, required this.rank, required this.attendancePct, required this.totalEvents});
  factory _AttendanceRanking.fromJson(Map<String, dynamic> json) => _$AttendanceRankingFromJson(json);

@override final  String userId;
@override final  String fullName;
@override final  String rank;
@override final  double attendancePct;
@override final  int totalEvents;

/// Create a copy of AttendanceRanking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendanceRankingCopyWith<_AttendanceRanking> get copyWith => __$AttendanceRankingCopyWithImpl<_AttendanceRanking>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttendanceRankingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendanceRanking&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.attendancePct, attendancePct) || other.attendancePct == attendancePct)&&(identical(other.totalEvents, totalEvents) || other.totalEvents == totalEvents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,rank,attendancePct,totalEvents);

@override
String toString() {
  return 'AttendanceRanking(userId: $userId, fullName: $fullName, rank: $rank, attendancePct: $attendancePct, totalEvents: $totalEvents)';
}


}

/// @nodoc
abstract mixin class _$AttendanceRankingCopyWith<$Res> implements $AttendanceRankingCopyWith<$Res> {
  factory _$AttendanceRankingCopyWith(_AttendanceRanking value, $Res Function(_AttendanceRanking) _then) = __$AttendanceRankingCopyWithImpl;
@override @useResult
$Res call({
 String userId, String fullName, String rank, double attendancePct, int totalEvents
});




}
/// @nodoc
class __$AttendanceRankingCopyWithImpl<$Res>
    implements _$AttendanceRankingCopyWith<$Res> {
  __$AttendanceRankingCopyWithImpl(this._self, this._then);

  final _AttendanceRanking _self;
  final $Res Function(_AttendanceRanking) _then;

/// Create a copy of AttendanceRanking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? fullName = null,Object? rank = null,Object? attendancePct = null,Object? totalEvents = null,}) {
  return _then(_AttendanceRanking(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as String,attendancePct: null == attendancePct ? _self.attendancePct : attendancePct // ignore: cast_nullable_to_non_nullable
as double,totalEvents: null == totalEvents ? _self.totalEvents : totalEvents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$LowAttendanceAlert {

 String get userId; String get fullName; String get rank; double get attendancePct; String get severity;
/// Create a copy of LowAttendanceAlert
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LowAttendanceAlertCopyWith<LowAttendanceAlert> get copyWith => _$LowAttendanceAlertCopyWithImpl<LowAttendanceAlert>(this as LowAttendanceAlert, _$identity);

  /// Serializes this LowAttendanceAlert to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LowAttendanceAlert&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.attendancePct, attendancePct) || other.attendancePct == attendancePct)&&(identical(other.severity, severity) || other.severity == severity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,rank,attendancePct,severity);

@override
String toString() {
  return 'LowAttendanceAlert(userId: $userId, fullName: $fullName, rank: $rank, attendancePct: $attendancePct, severity: $severity)';
}


}

/// @nodoc
abstract mixin class $LowAttendanceAlertCopyWith<$Res>  {
  factory $LowAttendanceAlertCopyWith(LowAttendanceAlert value, $Res Function(LowAttendanceAlert) _then) = _$LowAttendanceAlertCopyWithImpl;
@useResult
$Res call({
 String userId, String fullName, String rank, double attendancePct, String severity
});




}
/// @nodoc
class _$LowAttendanceAlertCopyWithImpl<$Res>
    implements $LowAttendanceAlertCopyWith<$Res> {
  _$LowAttendanceAlertCopyWithImpl(this._self, this._then);

  final LowAttendanceAlert _self;
  final $Res Function(LowAttendanceAlert) _then;

/// Create a copy of LowAttendanceAlert
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? fullName = null,Object? rank = null,Object? attendancePct = null,Object? severity = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as String,attendancePct: null == attendancePct ? _self.attendancePct : attendancePct // ignore: cast_nullable_to_non_nullable
as double,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LowAttendanceAlert].
extension LowAttendanceAlertPatterns on LowAttendanceAlert {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LowAttendanceAlert value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LowAttendanceAlert() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LowAttendanceAlert value)  $default,){
final _that = this;
switch (_that) {
case _LowAttendanceAlert():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LowAttendanceAlert value)?  $default,){
final _that = this;
switch (_that) {
case _LowAttendanceAlert() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String fullName,  String rank,  double attendancePct,  String severity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LowAttendanceAlert() when $default != null:
return $default(_that.userId,_that.fullName,_that.rank,_that.attendancePct,_that.severity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String fullName,  String rank,  double attendancePct,  String severity)  $default,) {final _that = this;
switch (_that) {
case _LowAttendanceAlert():
return $default(_that.userId,_that.fullName,_that.rank,_that.attendancePct,_that.severity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String fullName,  String rank,  double attendancePct,  String severity)?  $default,) {final _that = this;
switch (_that) {
case _LowAttendanceAlert() when $default != null:
return $default(_that.userId,_that.fullName,_that.rank,_that.attendancePct,_that.severity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LowAttendanceAlert implements LowAttendanceAlert {
  const _LowAttendanceAlert({required this.userId, required this.fullName, required this.rank, required this.attendancePct, required this.severity});
  factory _LowAttendanceAlert.fromJson(Map<String, dynamic> json) => _$LowAttendanceAlertFromJson(json);

@override final  String userId;
@override final  String fullName;
@override final  String rank;
@override final  double attendancePct;
@override final  String severity;

/// Create a copy of LowAttendanceAlert
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LowAttendanceAlertCopyWith<_LowAttendanceAlert> get copyWith => __$LowAttendanceAlertCopyWithImpl<_LowAttendanceAlert>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LowAttendanceAlertToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LowAttendanceAlert&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.attendancePct, attendancePct) || other.attendancePct == attendancePct)&&(identical(other.severity, severity) || other.severity == severity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,rank,attendancePct,severity);

@override
String toString() {
  return 'LowAttendanceAlert(userId: $userId, fullName: $fullName, rank: $rank, attendancePct: $attendancePct, severity: $severity)';
}


}

/// @nodoc
abstract mixin class _$LowAttendanceAlertCopyWith<$Res> implements $LowAttendanceAlertCopyWith<$Res> {
  factory _$LowAttendanceAlertCopyWith(_LowAttendanceAlert value, $Res Function(_LowAttendanceAlert) _then) = __$LowAttendanceAlertCopyWithImpl;
@override @useResult
$Res call({
 String userId, String fullName, String rank, double attendancePct, String severity
});




}
/// @nodoc
class __$LowAttendanceAlertCopyWithImpl<$Res>
    implements _$LowAttendanceAlertCopyWith<$Res> {
  __$LowAttendanceAlertCopyWithImpl(this._self, this._then);

  final _LowAttendanceAlert _self;
  final $Res Function(_LowAttendanceAlert) _then;

/// Create a copy of LowAttendanceAlert
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? fullName = null,Object? rank = null,Object? attendancePct = null,Object? severity = null,}) {
  return _then(_LowAttendanceAlert(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as String,attendancePct: null == attendancePct ? _self.attendancePct : attendancePct // ignore: cast_nullable_to_non_nullable
as double,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ShiftCompliance {

 String get userId; String get fullName; String get maritalStatus; int get requiredShiftsPerWeek; double get averageShiftsPerWeek; bool get meetsRequirement;
/// Create a copy of ShiftCompliance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftComplianceCopyWith<ShiftCompliance> get copyWith => _$ShiftComplianceCopyWithImpl<ShiftCompliance>(this as ShiftCompliance, _$identity);

  /// Serializes this ShiftCompliance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShiftCompliance&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.maritalStatus, maritalStatus) || other.maritalStatus == maritalStatus)&&(identical(other.requiredShiftsPerWeek, requiredShiftsPerWeek) || other.requiredShiftsPerWeek == requiredShiftsPerWeek)&&(identical(other.averageShiftsPerWeek, averageShiftsPerWeek) || other.averageShiftsPerWeek == averageShiftsPerWeek)&&(identical(other.meetsRequirement, meetsRequirement) || other.meetsRequirement == meetsRequirement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,maritalStatus,requiredShiftsPerWeek,averageShiftsPerWeek,meetsRequirement);

@override
String toString() {
  return 'ShiftCompliance(userId: $userId, fullName: $fullName, maritalStatus: $maritalStatus, requiredShiftsPerWeek: $requiredShiftsPerWeek, averageShiftsPerWeek: $averageShiftsPerWeek, meetsRequirement: $meetsRequirement)';
}


}

/// @nodoc
abstract mixin class $ShiftComplianceCopyWith<$Res>  {
  factory $ShiftComplianceCopyWith(ShiftCompliance value, $Res Function(ShiftCompliance) _then) = _$ShiftComplianceCopyWithImpl;
@useResult
$Res call({
 String userId, String fullName, String maritalStatus, int requiredShiftsPerWeek, double averageShiftsPerWeek, bool meetsRequirement
});




}
/// @nodoc
class _$ShiftComplianceCopyWithImpl<$Res>
    implements $ShiftComplianceCopyWith<$Res> {
  _$ShiftComplianceCopyWithImpl(this._self, this._then);

  final ShiftCompliance _self;
  final $Res Function(ShiftCompliance) _then;

/// Create a copy of ShiftCompliance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? fullName = null,Object? maritalStatus = null,Object? requiredShiftsPerWeek = null,Object? averageShiftsPerWeek = null,Object? meetsRequirement = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,maritalStatus: null == maritalStatus ? _self.maritalStatus : maritalStatus // ignore: cast_nullable_to_non_nullable
as String,requiredShiftsPerWeek: null == requiredShiftsPerWeek ? _self.requiredShiftsPerWeek : requiredShiftsPerWeek // ignore: cast_nullable_to_non_nullable
as int,averageShiftsPerWeek: null == averageShiftsPerWeek ? _self.averageShiftsPerWeek : averageShiftsPerWeek // ignore: cast_nullable_to_non_nullable
as double,meetsRequirement: null == meetsRequirement ? _self.meetsRequirement : meetsRequirement // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ShiftCompliance].
extension ShiftCompliancePatterns on ShiftCompliance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShiftCompliance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShiftCompliance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShiftCompliance value)  $default,){
final _that = this;
switch (_that) {
case _ShiftCompliance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShiftCompliance value)?  $default,){
final _that = this;
switch (_that) {
case _ShiftCompliance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String fullName,  String maritalStatus,  int requiredShiftsPerWeek,  double averageShiftsPerWeek,  bool meetsRequirement)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShiftCompliance() when $default != null:
return $default(_that.userId,_that.fullName,_that.maritalStatus,_that.requiredShiftsPerWeek,_that.averageShiftsPerWeek,_that.meetsRequirement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String fullName,  String maritalStatus,  int requiredShiftsPerWeek,  double averageShiftsPerWeek,  bool meetsRequirement)  $default,) {final _that = this;
switch (_that) {
case _ShiftCompliance():
return $default(_that.userId,_that.fullName,_that.maritalStatus,_that.requiredShiftsPerWeek,_that.averageShiftsPerWeek,_that.meetsRequirement);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String fullName,  String maritalStatus,  int requiredShiftsPerWeek,  double averageShiftsPerWeek,  bool meetsRequirement)?  $default,) {final _that = this;
switch (_that) {
case _ShiftCompliance() when $default != null:
return $default(_that.userId,_that.fullName,_that.maritalStatus,_that.requiredShiftsPerWeek,_that.averageShiftsPerWeek,_that.meetsRequirement);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShiftCompliance implements ShiftCompliance {
  const _ShiftCompliance({required this.userId, required this.fullName, required this.maritalStatus, required this.requiredShiftsPerWeek, required this.averageShiftsPerWeek, required this.meetsRequirement});
  factory _ShiftCompliance.fromJson(Map<String, dynamic> json) => _$ShiftComplianceFromJson(json);

@override final  String userId;
@override final  String fullName;
@override final  String maritalStatus;
@override final  int requiredShiftsPerWeek;
@override final  double averageShiftsPerWeek;
@override final  bool meetsRequirement;

/// Create a copy of ShiftCompliance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftComplianceCopyWith<_ShiftCompliance> get copyWith => __$ShiftComplianceCopyWithImpl<_ShiftCompliance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShiftComplianceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShiftCompliance&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.maritalStatus, maritalStatus) || other.maritalStatus == maritalStatus)&&(identical(other.requiredShiftsPerWeek, requiredShiftsPerWeek) || other.requiredShiftsPerWeek == requiredShiftsPerWeek)&&(identical(other.averageShiftsPerWeek, averageShiftsPerWeek) || other.averageShiftsPerWeek == averageShiftsPerWeek)&&(identical(other.meetsRequirement, meetsRequirement) || other.meetsRequirement == meetsRequirement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,maritalStatus,requiredShiftsPerWeek,averageShiftsPerWeek,meetsRequirement);

@override
String toString() {
  return 'ShiftCompliance(userId: $userId, fullName: $fullName, maritalStatus: $maritalStatus, requiredShiftsPerWeek: $requiredShiftsPerWeek, averageShiftsPerWeek: $averageShiftsPerWeek, meetsRequirement: $meetsRequirement)';
}


}

/// @nodoc
abstract mixin class _$ShiftComplianceCopyWith<$Res> implements $ShiftComplianceCopyWith<$Res> {
  factory _$ShiftComplianceCopyWith(_ShiftCompliance value, $Res Function(_ShiftCompliance) _then) = __$ShiftComplianceCopyWithImpl;
@override @useResult
$Res call({
 String userId, String fullName, String maritalStatus, int requiredShiftsPerWeek, double averageShiftsPerWeek, bool meetsRequirement
});




}
/// @nodoc
class __$ShiftComplianceCopyWithImpl<$Res>
    implements _$ShiftComplianceCopyWith<$Res> {
  __$ShiftComplianceCopyWithImpl(this._self, this._then);

  final _ShiftCompliance _self;
  final $Res Function(_ShiftCompliance) _then;

/// Create a copy of ShiftCompliance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? fullName = null,Object? maritalStatus = null,Object? requiredShiftsPerWeek = null,Object? averageShiftsPerWeek = null,Object? meetsRequirement = null,}) {
  return _then(_ShiftCompliance(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,maritalStatus: null == maritalStatus ? _self.maritalStatus : maritalStatus // ignore: cast_nullable_to_non_nullable
as String,requiredShiftsPerWeek: null == requiredShiftsPerWeek ? _self.requiredShiftsPerWeek : requiredShiftsPerWeek // ignore: cast_nullable_to_non_nullable
as int,averageShiftsPerWeek: null == averageShiftsPerWeek ? _self.averageShiftsPerWeek : averageShiftsPerWeek // ignore: cast_nullable_to_non_nullable
as double,meetsRequirement: null == meetsRequirement ? _self.meetsRequirement : meetsRequirement // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
