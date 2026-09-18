-- ==============================================================================
-- TerraPoint MVP - Database Migration (Up)
-- Database Engine: Supabase / PostgreSQL 16 (Standard Plain DB)
-- ==============================================================================

-- 1. Master Tabel Drivers
CREATE TABLE IF NOT EXISTS drivers (
    driver_id VARCHAR(32) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    pin_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 2. Master Tabel Lokasi Tambang (Pit & ROM Checkpoints untuk GPS Auto-Detect)
CREATE TABLE IF NOT EXISTS master_locations (
    location_id VARCHAR(32) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location_type VARCHAR(20) NOT NULL CHECK (location_type IN ('LOADING_POINT', 'DUMPING_POINT')),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    radius_meters INT DEFAULT 50 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 3. Tabel Penugasan & Log Ritase (Tasks)
CREATE TABLE IF NOT EXISTS tasks (
    task_id VARCHAR(36) PRIMARY KEY, -- UUID v4 / Client-Generated ID
    driver_id VARCHAR(32) NOT NULL REFERENCES drivers(driver_id),
    title VARCHAR(150) NOT NULL,
    
    -- Titik Awal (Loading Point terdeteksi otomatis oleh GPS)
    start_point_name VARCHAR(100) NOT NULL,
    start_lat DOUBLE PRECISION NOT NULL,
    start_lng DOUBLE PRECISION NOT NULL,
    start_radius_meters INT DEFAULT 50 NOT NULL,
    
    -- Titik Akhir (Dumping Point terdeteksi otomatis oleh GPS saat tiba)
    end_point_name VARCHAR(100),
    end_lat DOUBLE PRECISION,
    end_lng DOUBLE PRECISION,
    end_radius_meters INT DEFAULT 50,
    
    is_tracking_enabled BOOLEAN DEFAULT TRUE NOT NULL,
    
    -- Penyimpanan Array Rute Hauling (JSONB Native untuk Leaflet L.polyline)
    actual_route JSONB DEFAULT '[]'::JSONB NOT NULL,
    
    status VARCHAR(30) DEFAULT 'IN_PROGRESS' NOT NULL 
        CHECK (status IN ('ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'REJECTED_GEOFENCE')),
    
    cancellation_reason TEXT,
    last_stealth_sync_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    completed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_tasks_driver_status ON tasks(driver_id, status);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at DESC);

-- 4. Tabel Bukti Foto WebP (Tersimpan di Cloudflare R2)
CREATE TABLE IF NOT EXISTS task_evidences (
    evidence_id VARCHAR(36) PRIMARY KEY,
    task_id VARCHAR(36) NOT NULL REFERENCES tasks(task_id) ON DELETE CASCADE,
    checkpoint_type VARCHAR(10) NOT NULL CHECK (checkpoint_type IN ('START', 'END')),
    
    captured_lat DOUBLE PRECISION NOT NULL,
    captured_lng DOUBLE PRECISION NOT NULL,
    accuracy_meters DOUBLE PRECISION NOT NULL,
    deviation_meters DOUBLE PRECISION NOT NULL,
    
    r2_storage_url TEXT NOT NULL, -- URL Cloudflare R2
    file_size_bytes BIGINT NOT NULL,
    captured_at TIMESTAMPTZ NOT NULL,
    verified_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    CONSTRAINT uq_task_checkpoint UNIQUE (task_id, checkpoint_type)
);

CREATE INDEX IF NOT EXISTS idx_evidences_task ON task_evidences(task_id);

-- 5. Tabel Raw Telemetry Breadcrumbs (Hidden Auto Sync Stream)
CREATE TABLE IF NOT EXISTS task_raw_breadcrumbs (
    breadcrumb_id BIGSERIAL PRIMARY KEY,
    task_id VARCHAR(36) NOT NULL REFERENCES tasks(task_id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    speed_kmh DOUBLE PRECISION,
    heading DOUBLE PRECISION,
    recorded_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT uq_task_point UNIQUE (task_id, recorded_at)
);

CREATE INDEX IF NOT EXISTS idx_raw_breadcrumbs_task_time ON task_raw_breadcrumbs(task_id, recorded_at);

-- ==============================================================================
-- SEED DATA (Master Lokasi Tambang & Driver Dummy)
-- Area Koordinat: Tambang Batubara Kalimantan Selatan
-- ==============================================================================

INSERT INTO drivers (driver_id, full_name, phone_number, pin_hash, is_active)
VALUES 
    ('DRV-001', 'Ahmad Fauzi', '081234567890', '$2a$10$7EqJtq98hPqEX7fNZaFWoO5L5pL6b4b4b4b4b4b4b4b4b4b4b4b4b', TRUE),
    ('DRV-002', 'Budi Santoso', '081234567891', '$2a$10$7EqJtq98hPqEX7fNZaFWoO5L5pL6b4b4b4b4b4b4b4b4b4b4b4b4b', TRUE)
ON CONFLICT (driver_id) DO NOTHING;

INSERT INTO master_locations (location_id, name, location_type, latitude, longitude, radius_meters, is_active)
VALUES 
    ('LOC-PIT-03', 'Loading Point Pit 3 Utara', 'LOADING_POINT', -3.123456, 115.123456, 50, TRUE),
    ('LOC-PIT-02', 'Loading Point Pit 2 Barat', 'LOADING_POINT', -3.131000, 115.119000, 50, TRUE),
    ('LOC-ROM-01', 'ROM Stockpile 1', 'DUMPING_POINT', -3.145000, 115.148000, 50, TRUE),
    ('LOC-ROM-02', 'ROM Stockpile 2', 'DUMPING_POINT', -3.152000, 115.155000, 50, TRUE),
    ('LOC-DSP-04', 'Disposal Area 4', 'DUMPING_POINT', -3.160000, 115.162000, 50, TRUE)
ON CONFLICT (location_id) DO NOTHING;
