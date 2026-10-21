-- ==============================================================================
-- TerraPoint MVP - Mobile SQLite Database Schema (Drift ORM + SQLCipher)
-- ==============================================================================

-- 1. Sesi Driver Lokal (Menyimpan kredensial token dan hash PIN untuk offline unlock)
CREATE TABLE IF NOT EXISTS local_driver_session (
    driver_id TEXT PRIMARY KEY,
    full_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    pin_hash TEXT NOT NULL,
    access_token TEXT NOT NULL,
    token_expires_at INTEGER NOT NULL, -- Unix Epoch Milliseconds
    last_login_at INTEGER NOT NULL     -- Unix Epoch Milliseconds
);

-- 2. Master Lokasi Tambang Lokal (Di-cache di SQLite untuk GPS Auto-Detect offline)
CREATE TABLE IF NOT EXISTS local_master_locations (
    location_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    location_type TEXT CHECK(location_type IN ('LOADING_POINT', 'DUMPING_POINT')) NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    radius_meters INTEGER NOT NULL DEFAULT 50
);

-- 3. Log Ritase Mandiri Lokal
CREATE TABLE IF NOT EXISTS local_tasks (
    task_id TEXT PRIMARY KEY,
    driver_id TEXT NOT NULL,
    title TEXT NOT NULL,
    start_point_name TEXT NOT NULL,
    start_lat REAL NOT NULL,
    start_lng REAL NOT NULL,
    start_radius INTEGER NOT NULL DEFAULT 50,
    end_point_name TEXT,
    end_lat REAL,
    end_lng REAL,
    end_radius INTEGER DEFAULT 50,
    is_tracking_enabled INTEGER NOT NULL DEFAULT 1,
    status TEXT CHECK(status IN ('ASSIGNED', 'IN_PROGRESS', 'PENDING_SYNC', 'SYNCING', 'SYNCED', 'CANCELLED', 'REJECTED')) NOT NULL DEFAULT 'IN_PROGRESS',
    created_at INTEGER NOT NULL, -- Unix Epoch Milliseconds
    updated_at INTEGER NOT NULL, -- Unix Epoch Milliseconds
    FOREIGN KEY(driver_id) REFERENCES local_driver_session(driver_id)
);

CREATE INDEX IF NOT EXISTS idx_local_tasks_status ON local_tasks(driver_id, status);

-- 4. Bukti Foto WebP Lokal
CREATE TABLE IF NOT EXISTS local_task_evidences (
    evidence_id TEXT PRIMARY KEY,
    task_id TEXT NOT NULL,
    checkpoint_type TEXT CHECK(checkpoint_type IN ('START', 'END')) NOT NULL,
    captured_lat REAL NOT NULL,
    captured_lng REAL NOT NULL,
    accuracy_meters REAL NOT NULL,
    captured_at INTEGER NOT NULL, -- TrueTime UTC Epoch Milliseconds
    file_path TEXT NOT NULL,       -- Path di context.filesDir
    file_size_bytes INTEGER NOT NULL,
    sync_status TEXT CHECK(sync_status IN ('PENDING', 'UPLOADING', 'SYNCED', 'FAILED')) NOT NULL DEFAULT 'PENDING',
    synced_at INTEGER,             -- Epoch Milliseconds saat berhasil SYNCED (acuan auto-purge 3 hari)
    FOREIGN KEY(task_id) REFERENCES local_tasks(task_id) ON DELETE CASCADE,
    CONSTRAINT uq_local_task_checkpoint UNIQUE (task_id, checkpoint_type)
);

CREATE INDEX IF NOT EXISTS idx_local_evidences_task ON local_task_evidences(task_id);
CREATE INDEX IF NOT EXISTS idx_local_evidences_purge ON local_task_evidences(sync_status, synced_at);

-- 5. Titik Rute Breadcrumbs Lokal (Mendukung Hidden Background Sync & Manual Sync)
CREATE TABLE IF NOT EXISTS local_task_breadcrumbs (
    point_id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    speed_kmh REAL,
    heading REAL,
    recorded_at INTEGER NOT NULL, -- Unix Epoch Milliseconds
    is_stealth_synced INTEGER NOT NULL DEFAULT 0, -- 0: Belum terkirim via hidden sync, 1: Sudah terkirim
    FOREIGN KEY(task_id) REFERENCES local_tasks(task_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_local_breadcrumbs_sync ON local_task_breadcrumbs(task_id, is_stealth_synced);
CREATE INDEX IF NOT EXISTS idx_local_breadcrumbs_time ON local_task_breadcrumbs(task_id, recorded_at);
