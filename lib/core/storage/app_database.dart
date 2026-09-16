import 'package:drift/drift.dart';
import 'connection/connection.dart' as impl;

part 'app_database.g.dart';

/// Drift database table storing all download tasks and their local metadata.
class DownloadRecords extends Table {
  TextColumn get id => text()();
  TextColumn get url => text()();
  TextColumn get title => text()();
  TextColumn get author => text()();
  TextColumn get authorAvatarUrl => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get filePath => text()();
  TextColumn get fileName => text()();
  TextColumn get storageType => text().withDefault(const Constant('media_store'))();
  TextColumn get storageUri => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get fileSizeBytes => integer().withDefault(const Constant(0))();
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();
  BoolColumn get hasWatermark => boolean().withDefault(const Constant(false))();
  BoolColumn get isAudioOnly => boolean().withDefault(const Constant(false))();
  TextColumn get status => text()();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Key-value settings table.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [DownloadRecords, AppSettings],
  daos: [DownloadDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? impl.openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(downloadRecords, downloadRecords.storageType);
          await m.addColumn(downloadRecords, downloadRecords.storageUri);
          await m.addColumn(downloadRecords, downloadRecords.mimeType);
        }
      },
    );
  }
}

@DriftAccessor(tables: [DownloadRecords])
class DownloadDao extends DatabaseAccessor<AppDatabase> with _$DownloadDaoMixin {
  DownloadDao(super.db);

  /// Watch all downloads ordered by createdAt DESC.
  Stream<List<DownloadRecord>> watchAllDownloads() {
    return (select(downloadRecords)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Watch only active downloads (queued, downloading, paused, finalizing).
  Stream<List<DownloadRecord>> watchActiveDownloads() {
    return (select(downloadRecords)
          ..where((t) => t.status.isIn(['queued', 'downloading', 'paused', 'finalizing']))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Watch completed history downloads.
  Stream<List<DownloadRecord>> watchCompletedDownloads() {
    return (select(downloadRecords)
          ..where((t) => t.status.equals('completed'))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Get recent completed downloads (limit count).
  Future<List<DownloadRecord>> getRecentCompleted(int limit) {
    return (select(downloadRecords)
          ..where((t) => t.status.equals('completed'))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .get();
  }

  /// Search history by title, author, or filename.
  Future<List<DownloadRecord>> searchHistory(String query) {
    final pattern = '%$query%';
    return (select(downloadRecords)
          ..where((t) =>
              t.status.equals('completed') &
              (t.title.like(pattern) |
                  t.author.like(pattern) |
                  t.fileName.like(pattern)))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// Get single record by ID.
  Future<DownloadRecord?> getById(String id) {
    return (select(downloadRecords)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert or replace a download record.
  Future<int> insertOrUpdate(DownloadRecordsCompanion record) {
    return into(downloadRecords).insertOnConflictUpdate(record);
  }

  /// Update download progress.
  Future<int> updateProgress({
    required String id,
    required int downloadedBytes,
    required int totalBytes,
    required String status,
  }) {
    return (update(downloadRecords)..where((t) => t.id.equals(id))).write(
      DownloadRecordsCompanion(
        downloadedBytes: Value(downloadedBytes),
        fileSizeBytes: Value(totalBytes),
        status: Value(status),
      ),
    );
  }

  /// Mark download as completed with storage identifiers.
  Future<int> markCompleted({
    required String id,
    required String finalFilePath,
    required int finalSizeBytes,
    String storageType = 'media_store',
    String? storageUri,
    String? mimeType,
  }) {
    return (update(downloadRecords)..where((t) => t.id.equals(id))).write(
      DownloadRecordsCompanion(
        filePath: Value(finalFilePath),
        storageType: Value(storageType),
        storageUri: Value(storageUri),
        mimeType: Value(mimeType),
        fileSizeBytes: Value(finalSizeBytes),
        downloadedBytes: Value(finalSizeBytes),
        status: const Value('completed'),
        completedAt: Value(DateTime.now()),
        errorMessage: const Value(null),
      ),
    );
  }

  /// Mark download as failed.
  Future<int> markFailed(String id, String errorMessage) {
    return (update(downloadRecords)..where((t) => t.id.equals(id))).write(
      DownloadRecordsCompanion(
        status: const Value('failed'),
        errorMessage: Value(errorMessage),
      ),
    );
  }

  /// Update status of a download.
  Future<int> updateStatus(String id, String status) {
    return (update(downloadRecords)..where((t) => t.id.equals(id))).write(
      DownloadRecordsCompanion(
        status: Value(status),
      ),
    );
  }

  /// Delete record by ID.
  Future<int> deleteRecord(String id) {
    return (delete(downloadRecords)..where((t) => t.id.equals(id))).go();
  }

  /// Clear all completed history.
  Future<int> clearCompletedHistory() {
    return (delete(downloadRecords)..where((t) => t.status.equals('completed')))
        .go();
  }

  /// Prune oldest history if exceeding count limit.
  Future<void> pruneOldHistory(int maxEntries) async {
    final countExp = downloadRecords.id.count();
    final query = selectOnly(downloadRecords)
      ..addColumns([countExp])
      ..where(downloadRecords.status.equals('completed'));
    final totalCount = await query.map((row) => row.read(countExp)).getSingle();

    if (totalCount != null && totalCount > maxEntries) {
      final excess = totalCount - maxEntries;
      final oldestToPrune = await (select(downloadRecords)
            ..where((t) => t.status.equals('completed'))
            ..orderBy([
              (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)
            ])
            ..limit(excess))
          .get();

      final idsToPrune = oldestToPrune.map((e) => e.id).toList();
      await (delete(downloadRecords)..where((t) => t.id.isIn(idsToPrune))).go();
    }
  }
}

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Watch a setting value by key.
  Stream<String?> watchSetting(String key) {
    return (select(appSettings)..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  /// Get setting value by key.
  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Set setting value (insert or update).
  Future<int> setSetting(String key, String value) {
    return into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }

  /// Delete setting by key.
  Future<int> deleteSetting(String key) {
    return (delete(appSettings)..where((t) => t.key.equals(key))).go();
  }
}
