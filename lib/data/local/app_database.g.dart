// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MediaCommentsTable extends MediaComments
    with TableInfo<$MediaCommentsTable, MediaComment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaCommentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _mediaIdMeta =
      const VerificationMeta('mediaId');
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
      'media_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, mediaId, content, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_comments';
  @override
  VerificationContext validateIntegrity(Insertable<MediaComment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('media_id')) {
      context.handle(_mediaIdMeta,
          mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta));
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaComment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaComment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      mediaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $MediaCommentsTable createAlias(String alias) {
    return $MediaCommentsTable(attachedDatabase, alias);
  }
}

class MediaComment extends DataClass implements Insertable<MediaComment> {
  final int id;
  final String mediaId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MediaComment(
      {required this.id,
      required this.mediaId,
      required this.content,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['media_id'] = Variable<String>(mediaId);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MediaCommentsCompanion toCompanion(bool nullToAbsent) {
    return MediaCommentsCompanion(
      id: Value(id),
      mediaId: Value(mediaId),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MediaComment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaComment(
      id: serializer.fromJson<int>(json['id']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mediaId': serializer.toJson<String>(mediaId),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MediaComment copyWith(
          {int? id,
          String? mediaId,
          String? content,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      MediaComment(
        id: id ?? this.id,
        mediaId: mediaId ?? this.mediaId,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  MediaComment copyWithCompanion(MediaCommentsCompanion data) {
    return MediaComment(
      id: data.id.present ? data.id.value : this.id,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaComment(')
          ..write('id: $id, ')
          ..write('mediaId: $mediaId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mediaId, content, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaComment &&
          other.id == this.id &&
          other.mediaId == this.mediaId &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MediaCommentsCompanion extends UpdateCompanion<MediaComment> {
  final Value<int> id;
  final Value<String> mediaId;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MediaCommentsCompanion({
    this.id = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MediaCommentsCompanion.insert({
    this.id = const Value.absent(),
    required String mediaId,
    required String content,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : mediaId = Value(mediaId),
        content = Value(content);
  static Insertable<MediaComment> custom({
    Expression<int>? id,
    Expression<String>? mediaId,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaId != null) 'media_id': mediaId,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MediaCommentsCompanion copyWith(
      {Value<int>? id,
      Value<String>? mediaId,
      Value<String>? content,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return MediaCommentsCompanion(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaCommentsCompanion(')
          ..write('id: $id, ')
          ..write('mediaId: $mediaId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ManualLocationsTable extends ManualLocations
    with TableInfo<$ManualLocationsTable, ManualLocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ManualLocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta =
      const VerificationMeta('mediaId');
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
      'media_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [mediaId, latitude, longitude, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'manual_locations';
  @override
  VerificationContext validateIntegrity(Insertable<ManualLocation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(_mediaIdMeta,
          mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta));
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId};
  @override
  ManualLocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ManualLocation(
      mediaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_id'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ManualLocationsTable createAlias(String alias) {
    return $ManualLocationsTable(attachedDatabase, alias);
  }
}

class ManualLocation extends DataClass implements Insertable<ManualLocation> {
  final String mediaId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;
  const ManualLocation(
      {required this.mediaId,
      required this.latitude,
      required this.longitude,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<String>(mediaId);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ManualLocationsCompanion toCompanion(bool nullToAbsent) {
    return ManualLocationsCompanion(
      mediaId: Value(mediaId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      updatedAt: Value(updatedAt),
    );
  }

  factory ManualLocation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ManualLocation(
      mediaId: serializer.fromJson<String>(json['mediaId']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<String>(mediaId),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ManualLocation copyWith(
          {String? mediaId,
          double? latitude,
          double? longitude,
          DateTime? updatedAt}) =>
      ManualLocation(
        mediaId: mediaId ?? this.mediaId,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ManualLocation copyWithCompanion(ManualLocationsCompanion data) {
    return ManualLocation(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ManualLocation(')
          ..write('mediaId: $mediaId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mediaId, latitude, longitude, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ManualLocation &&
          other.mediaId == this.mediaId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.updatedAt == this.updatedAt);
}

class ManualLocationsCompanion extends UpdateCompanion<ManualLocation> {
  final Value<String> mediaId;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ManualLocationsCompanion({
    this.mediaId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ManualLocationsCompanion.insert({
    required String mediaId,
    required double latitude,
    required double longitude,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : mediaId = Value(mediaId),
        latitude = Value(latitude),
        longitude = Value(longitude);
  static Insertable<ManualLocation> custom({
    Expression<String>? mediaId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ManualLocationsCompanion copyWith(
      {Value<String>? mediaId,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ManualLocationsCompanion(
      mediaId: mediaId ?? this.mediaId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ManualLocationsCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HiddenMediaTable extends HiddenMedia
    with TableInfo<$HiddenMediaTable, HiddenMediaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HiddenMediaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta =
      const VerificationMeta('mediaId');
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
      'media_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hiddenAtMeta =
      const VerificationMeta('hiddenAt');
  @override
  late final GeneratedColumn<DateTime> hiddenAt = GeneratedColumn<DateTime>(
      'hidden_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [mediaId, hiddenAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hidden_media';
  @override
  VerificationContext validateIntegrity(Insertable<HiddenMediaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(_mediaIdMeta,
          mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta));
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('hidden_at')) {
      context.handle(_hiddenAtMeta,
          hiddenAt.isAcceptableOrUnknown(data['hidden_at']!, _hiddenAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId};
  @override
  HiddenMediaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HiddenMediaData(
      mediaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_id'])!,
      hiddenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}hidden_at'])!,
    );
  }

  @override
  $HiddenMediaTable createAlias(String alias) {
    return $HiddenMediaTable(attachedDatabase, alias);
  }
}

class HiddenMediaData extends DataClass implements Insertable<HiddenMediaData> {
  final String mediaId;
  final DateTime hiddenAt;
  const HiddenMediaData({required this.mediaId, required this.hiddenAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<String>(mediaId);
    map['hidden_at'] = Variable<DateTime>(hiddenAt);
    return map;
  }

  HiddenMediaCompanion toCompanion(bool nullToAbsent) {
    return HiddenMediaCompanion(
      mediaId: Value(mediaId),
      hiddenAt: Value(hiddenAt),
    );
  }

  factory HiddenMediaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HiddenMediaData(
      mediaId: serializer.fromJson<String>(json['mediaId']),
      hiddenAt: serializer.fromJson<DateTime>(json['hiddenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<String>(mediaId),
      'hiddenAt': serializer.toJson<DateTime>(hiddenAt),
    };
  }

  HiddenMediaData copyWith({String? mediaId, DateTime? hiddenAt}) =>
      HiddenMediaData(
        mediaId: mediaId ?? this.mediaId,
        hiddenAt: hiddenAt ?? this.hiddenAt,
      );
  HiddenMediaData copyWithCompanion(HiddenMediaCompanion data) {
    return HiddenMediaData(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      hiddenAt: data.hiddenAt.present ? data.hiddenAt.value : this.hiddenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HiddenMediaData(')
          ..write('mediaId: $mediaId, ')
          ..write('hiddenAt: $hiddenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mediaId, hiddenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HiddenMediaData &&
          other.mediaId == this.mediaId &&
          other.hiddenAt == this.hiddenAt);
}

class HiddenMediaCompanion extends UpdateCompanion<HiddenMediaData> {
  final Value<String> mediaId;
  final Value<DateTime> hiddenAt;
  final Value<int> rowid;
  const HiddenMediaCompanion({
    this.mediaId = const Value.absent(),
    this.hiddenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HiddenMediaCompanion.insert({
    required String mediaId,
    this.hiddenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : mediaId = Value(mediaId);
  static Insertable<HiddenMediaData> custom({
    Expression<String>? mediaId,
    Expression<DateTime>? hiddenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (hiddenAt != null) 'hidden_at': hiddenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HiddenMediaCompanion copyWith(
      {Value<String>? mediaId, Value<DateTime>? hiddenAt, Value<int>? rowid}) {
    return HiddenMediaCompanion(
      mediaId: mediaId ?? this.mediaId,
      hiddenAt: hiddenAt ?? this.hiddenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (hiddenAt.present) {
      map['hidden_at'] = Variable<DateTime>(hiddenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HiddenMediaCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('hiddenAt: $hiddenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MediaCommentsTable mediaComments = $MediaCommentsTable(this);
  late final $ManualLocationsTable manualLocations =
      $ManualLocationsTable(this);
  late final $HiddenMediaTable hiddenMedia = $HiddenMediaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [mediaComments, manualLocations, hiddenMedia];
}

typedef $$MediaCommentsTableCreateCompanionBuilder = MediaCommentsCompanion
    Function({
  Value<int> id,
  required String mediaId,
  required String content,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$MediaCommentsTableUpdateCompanionBuilder = MediaCommentsCompanion
    Function({
  Value<int> id,
  Value<String> mediaId,
  Value<String> content,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$MediaCommentsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaCommentsTable> {
  $$MediaCommentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$MediaCommentsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaCommentsTable> {
  $$MediaCommentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$MediaCommentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaCommentsTable> {
  $$MediaCommentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MediaCommentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaCommentsTable,
    MediaComment,
    $$MediaCommentsTableFilterComposer,
    $$MediaCommentsTableOrderingComposer,
    $$MediaCommentsTableAnnotationComposer,
    $$MediaCommentsTableCreateCompanionBuilder,
    $$MediaCommentsTableUpdateCompanionBuilder,
    (
      MediaComment,
      BaseReferences<_$AppDatabase, $MediaCommentsTable, MediaComment>
    ),
    MediaComment,
    PrefetchHooks Function()> {
  $$MediaCommentsTableTableManager(_$AppDatabase db, $MediaCommentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaCommentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaCommentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaCommentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> mediaId = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              MediaCommentsCompanion(
            id: id,
            mediaId: mediaId,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String mediaId,
            required String content,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              MediaCommentsCompanion.insert(
            id: id,
            mediaId: mediaId,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MediaCommentsTable, MediaComment>(table),
                    BaseReferences<_$AppDatabase, $MediaCommentsTable,
                        MediaComment>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaCommentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaCommentsTable,
    MediaComment,
    $$MediaCommentsTableFilterComposer,
    $$MediaCommentsTableOrderingComposer,
    $$MediaCommentsTableAnnotationComposer,
    $$MediaCommentsTableCreateCompanionBuilder,
    $$MediaCommentsTableUpdateCompanionBuilder,
    (
      MediaComment,
      BaseReferences<_$AppDatabase, $MediaCommentsTable, MediaComment>
    ),
    MediaComment,
    PrefetchHooks Function()>;
typedef $$ManualLocationsTableCreateCompanionBuilder = ManualLocationsCompanion
    Function({
  required String mediaId,
  required double latitude,
  required double longitude,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$ManualLocationsTableUpdateCompanionBuilder = ManualLocationsCompanion
    Function({
  Value<String> mediaId,
  Value<double> latitude,
  Value<double> longitude,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ManualLocationsTableFilterComposer
    extends Composer<_$AppDatabase, $ManualLocationsTable> {
  $$ManualLocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ManualLocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ManualLocationsTable> {
  $$ManualLocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ManualLocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ManualLocationsTable> {
  $$ManualLocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ManualLocationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ManualLocationsTable,
    ManualLocation,
    $$ManualLocationsTableFilterComposer,
    $$ManualLocationsTableOrderingComposer,
    $$ManualLocationsTableAnnotationComposer,
    $$ManualLocationsTableCreateCompanionBuilder,
    $$ManualLocationsTableUpdateCompanionBuilder,
    (
      ManualLocation,
      BaseReferences<_$AppDatabase, $ManualLocationsTable, ManualLocation>
    ),
    ManualLocation,
    PrefetchHooks Function()> {
  $$ManualLocationsTableTableManager(
      _$AppDatabase db, $ManualLocationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ManualLocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ManualLocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ManualLocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> mediaId = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ManualLocationsCompanion(
            mediaId: mediaId,
            latitude: latitude,
            longitude: longitude,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String mediaId,
            required double latitude,
            required double longitude,
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ManualLocationsCompanion.insert(
            mediaId: mediaId,
            latitude: latitude,
            longitude: longitude,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ManualLocationsTable, ManualLocation>(table),
                    BaseReferences<_$AppDatabase, $ManualLocationsTable,
                        ManualLocation>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ManualLocationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ManualLocationsTable,
    ManualLocation,
    $$ManualLocationsTableFilterComposer,
    $$ManualLocationsTableOrderingComposer,
    $$ManualLocationsTableAnnotationComposer,
    $$ManualLocationsTableCreateCompanionBuilder,
    $$ManualLocationsTableUpdateCompanionBuilder,
    (
      ManualLocation,
      BaseReferences<_$AppDatabase, $ManualLocationsTable, ManualLocation>
    ),
    ManualLocation,
    PrefetchHooks Function()>;
typedef $$HiddenMediaTableCreateCompanionBuilder = HiddenMediaCompanion
    Function({
  required String mediaId,
  Value<DateTime> hiddenAt,
  Value<int> rowid,
});
typedef $$HiddenMediaTableUpdateCompanionBuilder = HiddenMediaCompanion
    Function({
  Value<String> mediaId,
  Value<DateTime> hiddenAt,
  Value<int> rowid,
});

class $$HiddenMediaTableFilterComposer
    extends Composer<_$AppDatabase, $HiddenMediaTable> {
  $$HiddenMediaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get hiddenAt => $composableBuilder(
      column: $table.hiddenAt, builder: (column) => ColumnFilters(column));
}

class $$HiddenMediaTableOrderingComposer
    extends Composer<_$AppDatabase, $HiddenMediaTable> {
  $$HiddenMediaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get hiddenAt => $composableBuilder(
      column: $table.hiddenAt, builder: (column) => ColumnOrderings(column));
}

class $$HiddenMediaTableAnnotationComposer
    extends Composer<_$AppDatabase, $HiddenMediaTable> {
  $$HiddenMediaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<DateTime> get hiddenAt =>
      $composableBuilder(column: $table.hiddenAt, builder: (column) => column);
}

class $$HiddenMediaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HiddenMediaTable,
    HiddenMediaData,
    $$HiddenMediaTableFilterComposer,
    $$HiddenMediaTableOrderingComposer,
    $$HiddenMediaTableAnnotationComposer,
    $$HiddenMediaTableCreateCompanionBuilder,
    $$HiddenMediaTableUpdateCompanionBuilder,
    (
      HiddenMediaData,
      BaseReferences<_$AppDatabase, $HiddenMediaTable, HiddenMediaData>
    ),
    HiddenMediaData,
    PrefetchHooks Function()> {
  $$HiddenMediaTableTableManager(_$AppDatabase db, $HiddenMediaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HiddenMediaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HiddenMediaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HiddenMediaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> mediaId = const Value.absent(),
            Value<DateTime> hiddenAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HiddenMediaCompanion(
            mediaId: mediaId,
            hiddenAt: hiddenAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String mediaId,
            Value<DateTime> hiddenAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HiddenMediaCompanion.insert(
            mediaId: mediaId,
            hiddenAt: hiddenAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$HiddenMediaTable, HiddenMediaData>(table),
                    BaseReferences<_$AppDatabase, $HiddenMediaTable,
                        HiddenMediaData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HiddenMediaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HiddenMediaTable,
    HiddenMediaData,
    $$HiddenMediaTableFilterComposer,
    $$HiddenMediaTableOrderingComposer,
    $$HiddenMediaTableAnnotationComposer,
    $$HiddenMediaTableCreateCompanionBuilder,
    $$HiddenMediaTableUpdateCompanionBuilder,
    (
      HiddenMediaData,
      BaseReferences<_$AppDatabase, $HiddenMediaTable, HiddenMediaData>
    ),
    HiddenMediaData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MediaCommentsTableTableManager get mediaComments =>
      $$MediaCommentsTableTableManager(_db, _db.mediaComments);
  $$ManualLocationsTableTableManager get manualLocations =>
      $$ManualLocationsTableTableManager(_db, _db.manualLocations);
  $$HiddenMediaTableTableManager get hiddenMedia =>
      $$HiddenMediaTableTableManager(_db, _db.hiddenMedia);
}
