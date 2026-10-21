-- ==============================================================================
-- TerraPoint Revision: Project-Based Hauling & Wheel-Type Trip Management
-- ==============================================================================

-- 1. Tambah Kolom Jenis Roda Truk & Penugasan Proyek pada Tabel Drivers
ALTER TABLE drivers 
ADD COLUMN IF NOT EXISTS truck_wheel_type VARCHAR(50) DEFAULT '6 Roda (Dump Truck)',
ADD COLUMN IF NOT EXISTS assigned_project_id VARCHAR(36);

-- 2. Master Tabel Proyek Hauling (1 Proyek = 1 Titik Muat Luas + 1 Titik Bongkar Spesifik)
CREATE TABLE IF NOT EXISTS projects (
    project_id VARCHAR(36) PRIMARY KEY,
    project_name VARCHAR(150) NOT NULL,
    client_name VARCHAR(100),
    material_type VARCHAR(100) DEFAULT 'Material Tambang Utama',
    
    -- Titik Muat (1 Titik saja dengan Radius Luas, misal 200m)
    start_location_id VARCHAR(32) REFERENCES master_locations(location_id),
    start_point_name VARCHAR(100) NOT NULL,
    start_lat DOUBLE PRECISION NOT NULL,
    start_lng DOUBLE PRECISION NOT NULL,
    start_radius_meters INT DEFAULT 200 NOT NULL,
    
    -- Titik Bongkar (1 Titik dengan Radius Lebih Kecil / Spesifik, misal 40m)
    end_location_id VARCHAR(32) REFERENCES master_locations(location_id),
    end_point_name VARCHAR(100) NOT NULL,
    end_lat DOUBLE PRECISION NOT NULL,
    end_lng DOUBLE PRECISION NOT NULL,
    end_radius_meters INT DEFAULT 40 NOT NULL,
    
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 3. Tabel Catatan Pengantaran / Trips (Per Driver, Per Project, Dual Photo Bongkar + Nota)
CREATE TABLE IF NOT EXISTS project_trips (
    trip_id VARCHAR(36) PRIMARY KEY,
    project_id VARCHAR(36) NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    driver_id VARCHAR(32) NOT NULL REFERENCES drivers(driver_id),
    truck_wheel_type VARCHAR(50) NOT NULL, -- 4 Roda, 6 Roda, 10 Roda, 12 Roda
    trip_sequence INT DEFAULT 1 NOT NULL, -- Trip ke-1, 2, dst hari ini
    
    status VARCHAR(30) DEFAULT 'IN_TRANSIT' NOT NULL
        CHECK (status IN ('LOADING', 'IN_TRANSIT', 'COMPLETED', 'REJECTED')),
    
    -- Bukti Muat di Titik Muat (Pit)
    load_photo_url TEXT,
    load_lat DOUBLE PRECISION,
    load_lng DOUBLE PRECISION,
    load_deviation_m DOUBLE PRECISION,
    load_at TIMESTAMPTZ,
    
    -- Bukti Bongkar & Foto Nota / Invoice / Surat Jalan
    dump_photo_url TEXT,
    invoice_photo_url TEXT, -- FOTO NOTA / SURAT JALAN
    dump_lat DOUBLE PRECISION,
    dump_lng DOUBLE PRECISION,
    dump_deviation_m DOUBLE PRECISION,
    dump_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_project_trips_proj_driver ON project_trips(project_id, driver_id, status);
CREATE INDEX IF NOT EXISTS idx_project_trips_created ON project_trips(created_at DESC);

-- 4. Seed Data Proyek Default & Jenis Roda Driver
INSERT INTO projects (
    project_id, project_name, client_name, material_type,
    start_location_id, start_point_name, start_lat, start_lng, start_radius_meters,
    end_location_id, end_point_name, end_lat, end_lng, end_radius_meters,
    is_active
) VALUES (
    'PRJ-HAULING-01', 'Proyek Hauling Pit 2 ke ROM Stockpile 1', 'PT Tambang Mineral Mandiri', 'Material Tambang Utama',
    'LOC-PIT-02', 'Loading Point Pit 2 Barat', -3.131000, 115.119000, 250,
    'LOC-ROM-01', 'ROM Stockpile 1', -3.145000, 115.148000, 40,
    TRUE
) ON CONFLICT (project_id) DO UPDATE SET
    start_radius_meters = EXCLUDED.start_radius_meters,
    end_radius_meters = EXCLUDED.end_radius_meters;

-- Update Driver Wheel Types & Assign default project
UPDATE drivers SET 
    truck_wheel_type = '6 Roda (Dump Truck)',
    assigned_project_id = 'PRJ-HAULING-01'
WHERE driver_id = 'DRV-001';

UPDATE drivers SET 
    truck_wheel_type = '10 Roda (Tronton)',
    assigned_project_id = 'PRJ-HAULING-01'
WHERE driver_id = 'DRV-002';

UPDATE drivers SET 
    truck_wheel_type = '12 Roda (Trailer Heavy)',
    assigned_project_id = 'PRJ-HAULING-01'
WHERE driver_id = 'DRV-003';
