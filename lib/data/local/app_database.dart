import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../domain/model/travel_story.dart';

part 'app_database.g.dart';

/// 사용자 작성 코멘트 테이블
class MediaComments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mediaId => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 수동 위치 보정 테이블 (GPS 정보가 없거나 수정한 경우)
class ManualLocations extends Table {
  TextColumn get mediaId => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {mediaId};
}

/// 사용자가 지도/앱에서 숨기기로 지정한 미디어 테이블
class HiddenMedia extends Table {
  TextColumn get mediaId => text()();
  DateTimeColumn get hiddenAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {mediaId};
}

@DriftDatabase(tables: [MediaComments, ManualLocations, HiddenMedia])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createCustomTables();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(hiddenMedia);
          }
          if (from < 3) {
            await _createCustomTables();
          }
        },
        beforeOpen: (details) async {
          await _createCustomTables();
        },
      );

  Future<void> _createCustomTables() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS travel_stories (\n        id INTEGER PRIMARY KEY AUTOINCREMENT,\n        title TEXT NOT NULL,\n        place_name TEXT NOT NULL,\n        companions TEXT,\n        content TEXT,\n        event_date TEXT NOT NULL,\n        latitude REAL,\n        longitude REAL,\n        created_at TEXT NOT NULL,\n        updated_at TEXT NOT NULL\n      );\n    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS story_media (\n        id INTEGER PRIMARY KEY AUTOINCREMENT,\n        story_id INTEGER NOT NULL,\n        media_id TEXT NOT NULL,\n        is_cover INTEGER NOT NULL DEFAULT 0,\n        sort_order INTEGER NOT NULL DEFAULT 0\n      );\n    ''');
  }

  // ==========================================
  // 1. 코멘트 관련 쿼리
  // ==========================================
  Future<List<MediaComment>> getCommentsForMedia(String mediaId) {
    return (select(mediaComments)..where((tbl) => tbl.mediaId.equals(mediaId))).get();
  }

  /// 전체 코멘트 일괄 로드 (미디어 스캔 최적화용 O(1) 인메모리 맵)
  Future<Map<String, List<String>>> getAllCommentsMap() async {
    final rows = await select(mediaComments).get();
    final Map<String, List<String>> map = {};
    for (final row in rows) {
      map.putIfAbsent(row.mediaId, () => []).add(row.content);
    }
    return map;
  }

  Future<int> addComment(String mediaId, String content) {
    return into(mediaComments).insert(
      MediaCommentsCompanion.insert(
        mediaId: mediaId,
        content: content,
      ),
    );
  }

  Future<int> deleteComment(int id) {
    return (delete(mediaComments)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// 코멘트 내용 수정
  Future<void> updateCommentContent(String mediaId, String oldContent, String newContent) async {
    final row = await (select(mediaComments)
          ..where((tbl) => tbl.mediaId.equals(mediaId) & tbl.content.equals(oldContent))
          ..limit(1))
        .getSingleOrNull();
    if (row != null) {
      await (update(mediaComments)..where((tbl) => tbl.id.equals(row.id))).write(
        MediaCommentsCompanion(
          content: Value(newContent),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// 코멘트 내용 기반 단건 삭제
  Future<void> deleteCommentByContent(String mediaId, String content) async {
    final row = await (select(mediaComments)
          ..where((tbl) => tbl.mediaId.equals(mediaId) & tbl.content.equals(content))
          ..limit(1))
        .getSingleOrNull();
    if (row != null) {
      await (delete(mediaComments)..where((tbl) => tbl.id.equals(row.id))).go();
    }
  }

  // ==========================================
  // 2. 수동 위치 보정 관련 쿼리
  // ==========================================
  Future<ManualLocation?> getManualLocation(String mediaId) {
    return (select(manualLocations)..where((tbl) => tbl.mediaId.equals(mediaId))).getSingleOrNull();
  }

  /// 전체 수동 위치 일괄 로드 (미디어 스캔 최적화용 O(1) 인메모리 맵)
  Future<Map<String, ManualLocation>> getAllManualLocationsMap() async {
    final rows = await select(manualLocations).get();
    return {for (final row in rows) row.mediaId: row};
  }

  Future<void> setManualLocation(String mediaId, double latitude, double longitude) {
    return into(manualLocations).insertOnConflictUpdate(
      ManualLocationsCompanion.insert(
        mediaId: mediaId,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  // ==========================================
  // 3. 숨긴 미디어 관리 쿼리
  // ==========================================
  Future<Set<String>> getHiddenMediaIds() async {
    final rows = await select(hiddenMedia).get();
    return rows.map((r) => r.mediaId).toSet();
  }

  Future<void> hideMedia(String mediaId) {
    return into(hiddenMedia).insertOnConflictUpdate(
      HiddenMediaCompanion.insert(mediaId: mediaId),
    );
  }

  Future<int> unhideMedia(String mediaId) {
    return (delete(hiddenMedia)..where((tbl) => tbl.mediaId.equals(mediaId))).go();
  }

  // ==========================================
  // 4. 여행 스토리 (Travel Stories) CRUD 쿼리
  // ==========================================
  Future<List<TravelStory>> getAllStories() async {
    final storyRows = await customSelect(
      'SELECT * FROM travel_stories ORDER BY event_date DESC',
    ).get();

    final List<TravelStory> stories = [];

    for (final row in storyRows) {
      final storyId = row.read<int>('id');
      final title = row.read<String>('title');
      final placeName = row.read<String>('place_name');
      final companions = row.readNullable<String>('companions');
      final content = row.readNullable<String>('content');
      final eventDateStr = row.read<String>('event_date');
      final eventDate = DateTime.tryParse(eventDateStr) ?? DateTime.now();
      final latitude = row.readNullable<double>('latitude');
      final longitude = row.readNullable<double>('longitude');
      final createdAtStr = row.read<String>('created_at');
      final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();

      // 스토리에 포함된 선별 미디어 목록 조회
      final mediaRows = await customSelect(
        'SELECT media_id, is_cover FROM story_media WHERE story_id = ? ORDER BY sort_order ASC',
        variables: [Variable.withInt(storyId)],
      ).get();

      final List<String> mediaIds = [];
      String? coverMediaId;

      for (final mRow in mediaRows) {
        final mId = mRow.read<String>('media_id');
        final isCover = mRow.read<int>('is_cover') == 1;
        mediaIds.add(mId);
        if (isCover && coverMediaId == null) {
          coverMediaId = mId;
        }
      }

      if (coverMediaId == null && mediaIds.isNotEmpty) {
        coverMediaId = mediaIds.first;
      }

      LatLng? location;
      if (latitude != null && longitude != null && latitude != 0.0 && longitude != 0.0) {
        location = LatLng(latitude, longitude);
      }

      stories.add(
        TravelStory(
          id: storyId,
          title: title,
          placeName: placeName,
          companions: (companions != null && companions.isNotEmpty) ? companions : null,
          content: (content != null && content.isNotEmpty) ? content : null,
          eventDate: eventDate,
          location: location,
          mediaIds: mediaIds,
          coverMediaId: coverMediaId,
          createdAt: createdAt,
        ),
      );
    }

    return stories;
  }

  Future<int> insertStory({
    required String title,
    required String placeName,
    String? companions,
    String? content,
    required DateTime eventDate,
    LatLng? location,
    required List<String> mediaIds,
    String? coverMediaId,
  }) async {
    final nowStr = DateTime.now().toIso8601String();
    final storyId = await customInsert(
      '''
      INSERT INTO travel_stories (title, place_name, companions, content, event_date, latitude, longitude, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(title),
        Variable.withString(placeName),
        Variable.withString(companions ?? ''),
        Variable.withString(content ?? ''),
        Variable.withString(eventDate.toIso8601String()),
        location != null ? Variable.withReal(location.latitude) : const Variable<double>(null),
        location != null ? Variable.withReal(location.longitude) : const Variable<double>(null),
        Variable.withString(nowStr),
        Variable.withString(nowStr),
      ],
    );

    // 미디어 ID 매핑 저장
    for (int i = 0; i < mediaIds.length; i++) {
      final mId = mediaIds[i];
      final isCover = (mId == coverMediaId) || (coverMediaId == null && i == 0);
      await customInsert(
        '''
        INSERT INTO story_media (story_id, media_id, is_cover, sort_order)
        VALUES (?, ?, ?, ?)
        ''',
        variables: [
          Variable.withInt(storyId),
          Variable.withString(mId),
          Variable.withInt(isCover ? 1 : 0),
          Variable.withInt(i),
        ],
      );
    }

    return storyId;
  }

  Future<void> updateStory({
    required int id,
    required String title,
    required String placeName,
    String? companions,
    String? content,
    required DateTime eventDate,
    LatLng? location,
    required List<String> mediaIds,
    String? coverMediaId,
  }) async {
    final nowStr = DateTime.now().toIso8601String();
    await customUpdate(
      '''
      UPDATE travel_stories
      SET title = ?, place_name = ?, companions = ?, content = ?, event_date = ?, latitude = ?, longitude = ?, updated_at = ?
      WHERE id = ?
      ''',
      variables: [
        Variable.withString(title),
        Variable.withString(placeName),
        Variable.withString(companions ?? ''),
        Variable.withString(content ?? ''),
        Variable.withString(eventDate.toIso8601String()),
        location != null ? Variable.withReal(location.latitude) : const Variable<double>(null),
        location != null ? Variable.withReal(location.longitude) : const Variable<double>(null),
        Variable.withString(nowStr),
        Variable.withInt(id),
      ],
    );

    // 기존 미디어 매핑 삭제 후 재등록
    await customUpdate(
      'DELETE FROM story_media WHERE story_id = ?',
      variables: [Variable.withInt(id)],
    );

    for (int i = 0; i < mediaIds.length; i++) {
      final mId = mediaIds[i];
      final isCover = (mId == coverMediaId) || (coverMediaId == null && i == 0);
      await customInsert(
        '''
        INSERT INTO story_media (story_id, media_id, is_cover, sort_order)
        VALUES (?, ?, ?, ?)
        ''',
        variables: [
          Variable.withInt(id),
          Variable.withString(mId),
          Variable.withInt(isCover ? 1 : 0),
          Variable.withInt(i),
        ],
      );
    }
  }

  Future<void> deleteStory(int id) async {
    await customUpdate(
      'DELETE FROM story_media WHERE story_id = ?',
      variables: [Variable.withInt(id)],
    );
    await customUpdate(
      'DELETE FROM travel_stories WHERE id = ?',
      variables: [Variable.withInt(id)],
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'travler_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
