import 'package:drift/drift.dart';

// 1. Sesi Driver Lokal
class LocalDriverSessions extends Table {
  TextColumn get driverId => text()();
  TextColumn get fullName => text()();
  TextColumn get phoneNumber => text()();
  TextColumn get pinHash => text()();
  TextColumn get accessToken => text()();
  IntColumn get tokenExpiresAt => integer()();
  IntColumn get lastLoginAt => integer()();

  @override
  Set<Column> get primaryKey => {driverId};
}

// 2. Master Lokasi Tambang Lokal (Pit & ROM Checkpoints)
class LocalMasterLocations extends Table {
  TextColumn get locationId => text()();
  TextColumn get name => text()();
  TextColumn get locationType => text()(); // 'LOADING_POINT' | 'DUMPING_POINT'
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get radiusMeters => integer().withDefault(const Constant(50))();

  @override
  Set<Column> get primaryKey => {locationId};
}

// 3. Log Ritase Mandiri Lokal
class LocalTasks extends Table {
  TextColumn get taskId => text()();
  TextColumn get driverId => text()();
  TextColumn get title => text()();
  TextColumn get startPointName => text()();
  RealColumn get startLat => real()();
  RealColumn get startLng => real()();
  IntColumn get startRadius => integer().withDefault(const Constant(50))();
  TextColumn get endPointName => text().nullable()();
  RealColumn get endLat => real().nullable()();
  RealColumn get endLng => real().nullable()();
  IntColumn get endRadius => integer().nullable().withDefault(const Constant(50))();
  IntColumn get isTrackingEnabled => integer().withDefault(const Constant(1))();
  // Status: 'ASSIGNED', 'IN_PROGRESS', 'PENDING_SYNC', 'SYNCING', 'SYNCED', 'CANCELLED', 'REJECTED'
  TextColumn get status => text().withDefault(const Constant('IN_PROGRESS'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {taskId};
}

// 4. Bukti Foto WebP Lokal
class LocalTaskEvidences extends Table {
  TextColumn get evidenceId => text()();
  TextColumn get taskId => text()();
  TextColumn get checkpointType => text()(); // 'START' | 'END'
  RealColumn get capturedLat => real()();
  RealColumn get capturedLng => real()();
  RealColumn get accuracyMeters => real()();
  IntColumn get capturedAt => integer()();
  TextColumn get filePath => text()();
  IntColumn get fileSizeBytes => integer()();
  // SyncStatus: 'PENDING', 'UPLOADING', 'SYNCED', 'FAILED'
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))();
  IntColumn get syncedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {evidenceId};
}

// 5. Titik Rute Breadcrumbs Lokal
class LocalTaskBreadcrumbs extends Table {
  IntColumn get pointId => integer().autoIncrement()();
  TextColumn get taskId => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get speedKmh => real().nullable()();
  RealColumn get heading => real().nullable()();
  IntColumn get recordedAt => integer()();
  IntColumn get isStealthSynced => integer().withDefault(const Constant(0))();
}
