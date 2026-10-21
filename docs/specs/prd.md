# Product Requirement Document (PRD) — MVP Edition

---

**Nama Produk:** TerraPoint
**Deskripsi Singkat:** Sistem audit kepatuhan rute hauling dan bukti visual operasional tambang berbasis *offline-first* dengan verifikasi geospasial & *stealth background telemetry*
**Sektor Industri:** Mining Logistics & Heavy Equipment Operations
**Versi Dokumen:** 4.1 (Zero-Click GPS Auto-Detection — Supabase PostgreSQL & Auth, Cloudflare R2 Media Storage, Cloudflare Pages PWA, Flutter Offline Engine)
**Status:** Approved for Implementation

---

## 1. Ringkasan Eksekutif & Sasaran Produk

### 1.1 Latar Belakang Masalah
Operasional logistik dan transportasi hauling tambang batubara/mineral (*pit to ROM, disposal, or port*) menghadapi tantangan lingkungan nyata:
1. **Area Blank Spot Lapangan:** Koridor tambang aktif dan jalan hauling umumnya tidak memiliki jangkauan sinyal seluler (LTE/3G).
2. **Kecurangan Data & Manipulasi Bukti:** Praktik manipulasi absensi/ritase menggunakan *mock GPS* (aplikasi pemalsu lokasi), manipulasi jam perangkat lokal, serta penggunaan foto galeri lama sebagai bukti muat/bongkar palsu.
3. **Penyimpangan Rute (Safety & Compliance):** Pengemudi *dump truck* keluar dari rute resmi yang telah ditentukan (*designated haul road*) tanpa tercatat oleh tim operasional.
4. **Kendala Birokrasi & Salah Pilih Rute:** Mewajibkan driver memilih rute manual dari daftar di layar sering memicu kesalahan input (*human error*) dan menambah beban kognitif pengemudi di kabin truk yang bergetar.

### 1.2 Pernyataan Solusi MVP
**TerraPoint MVP** menyediakan platform pencatatan lapangan terpadu yang efisien, tangguh, dan berfokus pada kemudahan pengemudi:
1. **Zero-Click GPS Auto-Detection (Hanya 2 Aksi per Ritase):**
   - **Di Pit:** Driver buka aplikasi $\rightarrow$ GPS otomatis mendeteksi titik muat (Pit 3) dalam radius $\le 50\text{m}$ $\rightarrow$ Driver tekan **"AMBIL FOTO MUAT & MULAI"** $\rightarrow$ Ritase otomatis dimulai tanpa pilih rute manual!
   - **Di ROM:** Driver tiba di area bongkar $\rightarrow$ GPS otomatis mendeteksi ROM 1 $\rightarrow$ Driver tekan **"FOTO BONGKAR (SELESAI)"** $\rightarrow$ Ritase selesai.
2. **Direct-Capture Viewfinder dengan Geofence 50m:** Kamera kustom internal tanpa akses galeri. Tombol foto aktif saat driver berada dalam **radius 50 meter** dari titik target dengan pesan ramah: *"Anda terlalu jauh dari titik awal/akhir"* atau *"Posisi sesuai, siap ambil foto"*.
3. **Dual-Tagging WebP Pipeline:** Kompresi lokal otomatis ke format WebP Lossy dengan *canvas burn-in watermark* permanen pada piksel foto dan metadata biner EXIF GPS.
4. **Optional Background Route Tracking:** Perekaman jejak koordinat (*breadcrumbs*) di latar belakang per penugasan yang dapat diaktifkan/dinonaktifkan oleh *dispatcher*.
5. **Dual Sync Engine (Manual Sync + Hidden Background Telemetry):**
   - **Manual Batch Sync (Driver-Facing):** Pengemudi memicu pengiriman data ritase dan foto bukti secara manual saat kembali ke area *camp/workshop* bersinyal Wi-Fi.
   - **Hidden Automatic Background Sync (Superadmin-Facing):** *Worker* latar belakang senyap (*stealth telemetry*) yang otomatis mengirimkan titik rute *breadcrumbs* ke Supabase jika ponsel kebetulan melintasi titik sinyal seluler/Wi-Fi tambang di rute hauling untuk visibilitas armada *near-realtime*.
6. **Arsitektur Serverless Modern (Biaya Rp 0):**
   - **Database & Auth:** Supabase Managed PostgreSQL 16 (JSONB routes) + Supabase Auth.
   - **Media Storage:** Cloudflare R2 (10 GB Free Storage, $0 Egress Bandwidth Fee).
   - **Web Dashboard:** Cloudflare Pages (Progressive Web App + Leaflet.js Mapping Engine).

---

### 1.3 Target Metrik Operasional MVP (KPI)

| Parameter Metrik | Target Kinerja MVP | Keterangan |
| :--- | :--- | :--- |
| **Ukuran Berkas Bukti** | $\le 150\text{ KB}$ per foto WebP | Resolusi $\le 1280 \times 720\text{ px}$, kualitas $75\%$ |
| **Radius Geofence Toleransi** | $50\text{ meter}$ | Toleransi presisi terhadap *GPS drift* dan dinding pit tambang |
| **Akurasi GPS Shutter** | $\le 25\text{ meter}$ | Memastikan pembacaan satelit GPS stabil sebelum rana dapat ditekan |
| **Integritas Lokasi & Waktu** | $0\%$ toleransi *Mock GPS* | Pemblokiran *mock location* dan validasi waktu hardware |
| **Throughput Validasi Serverless** | $\le 50\text{ ms}$ per bukti foto | Ekstraksi EXIF & kalkulasi Haversine di Supabase Edge Functions |
| **Keberhasilan Sinkronisasi** | $\ge 99.5\%$ paket terunggah | Mendukung mekanisme *resumable retry* pada koneksi tidak stabil |
| **Ukuran Payload Stealth Sync** | $\le 3\text{ KB}$ per batch rute | Transmisi super ringan agar lolos saat sinyal tipis (1–2 bar) |
| **Retensi Storage Cloudflare R2** | Auto-Delete $30\text{ Hari}$ | Menjaga storage $\le 5.4\text{ GB}$ (100% GRATIS untuk 50 truk) |

---

## 2. Arsitektur Sistem & Tech Stack MVP

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                        FRONTEND (Mobile App - Flutter Client)                     │
│  • Framework Engine   : Flutter 3.24+                                            │
│  • Local Storage      : Drift (SQLite ORM) + SQLCipher (AES-256 Encryption)      │
│  • Camera & Capture   : camera plugin + Canvas Burn-in + Native EXIF Injector    │
│  • Task Mode          : Zero-Click GPS Auto-Detection (Start Photo = Assignment) │
│  • Background Tracking: flutter_background_geolocation (Foreground Service)     │
│  • Stealth Sync Worker: workmanager / silent background HTTP telemetry task      │
│  • Cloud Integration  : supabase_flutter SDK + Cloudflare R2 S3 Upload Client     │
│  • Time Integrity     : TrueTime / Server Time Offset + Monotonic Clock          │
└────────────────────────────────────────┬─────────────────────────────────────────┘
                                         │ 
                     ┌───────────────────┴───────────────────┐
                     │ [1] Manual Sync                       │ [2] Hidden Auto Sync
                     │ (Full Task + Foto WebP)               │ (Breadcrumbs JSON Only)
                     │ Di Camp / Wi-Fi Stabil                │ Silent saat ada sinyal
                     ▼                                       ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                   BACKEND & DATABASE CLOUD (Supabase Engine)                     │
│  • Auth Engine        : Supabase Auth (JWT Token Driver & Row Level Security)   │
│  • Managed Database   : PostgreSQL 16 (Standard B-Tree, JSONB actual_route)      │
│  • Edge Functions     : Deno / TypeScript (Geofence 50m & EXIF Ingestion)        │
│  • Realtime Engine    : Supabase Realtime Broadcast (Live Telemetry Stream)      │
└───────────────────────┬──────────────────────────────────┬───────────────────────┘
                        │                                  │
                        ▼                                  ▼
┌──────────────────────────────────────────────┐ ┌─────────────────────────────────┐
│        MEDIA STORAGE (Cloudflare R2)         │ │   WEB DASHBOARD PWA (Cloudflare)│
│ • 10 GB Storage GRATIS Selamanya             │ │ • Cloudflare Pages Hosting      │
│ • Zero Egress Fee (Bebas Bandwidth)          │ │ • Progressive Web App (PWA)     │
│ • Bucket: terrapoint-evidences (WebP Photos) │ │ • Leaflet.js Mapping Engine     │
│ • Auto-Lifecycle Delete > 30 Hari            │ │ • Dispatcher & Superadmin View  │
└──────────────────────────────────────────────┘ └─────────────────────────────────┘
```

---

## 3. Pengguna & Model Akses (RBAC MVP)

| Peran (*Role*) | Akses Antarmuka | Hak Akses & Tanggung Jawab Operasional |
| :--- | :--- | :--- |
| **Hauler Driver** | Mobile App | • Masuk menggunakan Driver ID / NIK + PIN 6-digit.<br>• **Mulai Ritase Otomatis:** Tiba di Pit $\rightarrow$ GPS mendeteksi lokasi $\rightarrow$ Tekan "Ambil Foto Muat" $\rightarrow$ Ritase otomatis terbuat.<br>• Mengambil foto bukti bongkar di ROM (radius 50m) $\rightarrow$ Ritase selesai.<br>• Menekan tombol sinkronisasi manual saat di *camp* (mengunggah ke Supabase & R2).<br>• *Dilarang:* Mengakses galeri ponsel, memalsukan GPS, atau mengubah waktu. |
| **Dispatcher / Mine Control** | Web Dashboard (Cloudflare Pages PWA) | • Memantau ritase mandiri driver yang tersinkronisasi di peta Leaflet.js.<br>• Memantau titik muat dan titik bongkar yang tercatat otomatis.<br>• **Otorisasi Pembatalan Tugas:** Membatalkan tugas jika driver melapor kendala via radio tambang. |
| **Superadmin (Surveillance)** | Web Dashboard (Cloudflare Pages PWA) | • Hak penuh Superadmin + **Live / Near-Realtime Fleet Telemetry View**.<br>• Memantau pergerakan titik koordinat armada yang masuk dari *hidden background sync* secara langsung di peta Leaflet.<br>• Manajemen master akun driver dan master lokasi titik tambang. |

---

## 4. Alur Kerja Aplikasi (End-to-End User Flow)

```
[Area Camp / Workshop — Sinyal Wi-Fi Tersedia]
  1. Driver masuk via Driver ID + PIN (Supabase Auth).
  2. Aplikasi menyelaraskan master data titik tambang (Pit & ROM) ke Drift SQLite lokal.
         │
         ▼
[Area Pit / Loading Point — Blank Spot / Luring]
  3. Driver tiba di Loading Point (misal Pit 3):
     ├── Buka Aplikasi TerraPoint.
     ├── Sensor GPS otomatis mendeteksi posisi berada di Pit 3 (<= 50m).
     └── Layar menampilkan: "Lokasi: Loading Point Pit 3 Utara" (Tombol Foto Aktif).
  4. Driver menekan tombol "AMBIL FOTO MUAT & MULAI":
     ├── [FOTO AWAL = BUKTI PENUGASAN RITASE]: Sistem lokal otomatis membuat Task ID baru.
     ├── Render watermark teks (Canvas Burn-in) ke piksel foto.
     ├── Kompresi citra ke format WebP (Lossy 75%, Max 1280x720) + EXIF GPS.
     └── Simpan berkas ke internal storage ──▶ Status tugas lokal: "IN_PROGRESS".
         │
         ▼
[Perjalanan Hauling (Pit ke Disposal/ROM) — Rute Jalan Tambang]
  5. Perekaman rute aktif: Foreground Service mencatat koordinat ke tabel lokal jika jarak >= 50m / 30s.
  6. [HIDDEN BACKGROUND SYNC WORKER — SENYAP]:
     ├── Aplikasi mendeteksi adanya konektivitas data sesaat (sinyal 4G/Wi-Fi pit 1-2 bar).
     ├── Worker mengirimkan batch kecil JSON koordinat (2-3 KB) ke Supabase REST.
     ├── Supabase menyimpan titik rute & memperbarui live map Leaflet SUPERADMIN.
     └── Aplikasi lokal menandai titik sebagai terkirim (DRIVER TIDAK MELIHAT APAPUN).
         │
         ▼
[Area Disposal / ROM / Dumping Point — Blank Spot / Luring]
  7. Driver tiba di Titik Bongkar (misal ROM 1):
     ├── Sensor GPS otomatis mendeteksi posisi berada di ROM 1 (<= 50m).
     └── Driver menekan tombol "FOTO BONGKAR (SELESAI)" via Direct-Capture.
  8. Aplikasi menghentikan Foreground Service Tracking.
  9. Status tugas lokal berubah menjadi: "PENDING_SYNC".
 10. Driver dapat langsung memulai siklus ritase berikutnya (Langkah 3 s/d 9 berulang).
         │
         ▼
[Kembali ke Camp / Workshop — Wi-Fi / LTE Tersambung]
 11. Driver membuka tab "Antrean Sinkronisasi" di aplikasi.
 12. Driver menekan tombol aksi: "Sinkronkan Sekarang".
 13. Aplikasi mengirimkan data ritase ke Supabase & mengunggah 2 foto WebP ke Cloudflare R2.
 14. Aplikasi menandai tugas lokal sebagai "SYNCED".
 15. [AUTO-PURGE STORAGE]: Foto WebP lokal yang sudah SYNCED >= 3 hari otomatis dihapus dari HP.
```

---

## 5. Desain Skema Basis Data Supabase PostgreSQL

```sql
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
    
    r2_storage_url TEXT NOT NULL, -- Public/Signed URL Cloudflare R2
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
```
