# Technical Design Document (TDD) & System Blueprint — TerraPoint Enterprise

---

**Nama Sistem:** TerraPoint (Mining Fleet Compliance & Telematics Platform)
**Versi Dokumen:** 6.0 (Enterprise Architecture: Self-Hosted Debian VPS, Bun Runtime, PostgreSQL 17, Cloudflare Public Tunnel, Flutter Offline Client, PWA Leaflet)
**Target Arsitektur:** 
- **Mobile Client:** Flutter 3.24+ (Dart, CameraX, Real-Time Satellite GPS Sensor, Strict 4-Cards State Machine)
- **Backend Service:** Self-Hosted Node.js / Bun 1.4.3 + Express (Port 8000 on Debian 13)
- **Database Engine:** PostgreSQL 17 Relational Database with Monthly Range Partitioning
- **Media & Object Storage:** MinIO S3 Self-Hosted Data Center (`10.10.10.2:9000`)
- **Public Tunnel:** Cloudflare Tunnel HTTPS (`affect-gary-begins-systematic.trycloudflare.com`)
- **Web Dashboard:** Single-Page Application (HTML5, ES Modules, Leaflet.js Satellite & GIS Dark Engine)
**Status:** Approved for Implementation & Production Active

---

## 1. Topologi Arsitektur & Jaringan (Network Topology)

```
                       [AREA TAMBANG (OFFLINE / BLANK SPOT)]
                                         │
 ┌───────────────────────────────────────┴───────────────────────────────────────┐
 │                       MOBILE CLIENT (Flutter Offline Engine)                  │
 │  ┌───────────────────────┐  ┌───────────────────────┐  ┌───────────────────┐  │
 │  │ Hardware GPS Sensor   │  │ CameraX Downscaler    │  │ LocalStorageVault │  │
 │  │ (Real-Time Satelit)   │  │ (Max 1280px + Stamp)  │  │ (State Machine)   │  │
 │  └───────────┬───────────┘  └───────────┬───────────┘  └─────────┬─────────┘  │
 │              │                          │                        │            │
 │              └──────────────────────────┼────────────────────────┘            │
 │                                         ▼                                     │
 │                       Strict 4-Cards Sequential Workflow                      │
 │          [1. Muat Pit] ➔ [2. Curah ROM] ➔ [3. Nota Timbang] ➔ [4. Riwayat]    │
 └─────────────────────────────────────────┬─────────────────────────────────────┘
                                           │
                                           │ (Offline: Disimpan Lokal & Diproses Instan)
                                           │ (Online: Auto-Sync via HTTPS REST)
                                           ▼
 ┌───────────────────────────────────────────────────────────────────────────────┐
 │             PUBLIC GATEWAY: CLOUDFLARE SECURE TUNNEL (ZERO VPN)               │
 │  • Endpoint Publik: https://affect-gary-begins-systematic.trycloudflare.com   │
 │  • Enkripsi TLS 1.3, Proteksi DDoS, $0 Egress, Tanpa Port Forwarding / IP Pub │
 └─────────────────────────────────────────┬─────────────────────────────────────┘
                                           │ Proxy Loopback ke 127.0.0.1:8000
                                           ▼
 ┌───────────────────────────────────────────────────────────────────────────────┐
 │           BACKEND SERVER HOST (Debian 13 Trixie • 100.89.207.92:8000)         │
 │  • Service: terrapoint.service (systemd managed, auto-restart)                │
 │  • Engine: Bun 1.4.3 / Express REST API Router                                │
 │  • Static Host: Serving frontend/web/ & terrapoint.apk                         │
 │                                                                               │
 │       ┌────────────────────────┐             ┌────────────────────────┐       │
 │       │ REST Routes Controller │             │ Telemetry Cache Engine │       │
 │       │ • /api/auth            │             │ In-Memory TTL 5s       │       │
 │       │ • /api/dashboard       │             │ Fast Haversine Calc    │       │
 │       │ • /api/sync            │             │                        │       │
 │       └───────────┬────────────┘             └───────────┬────────────┘       │
 └───────────────────┼──────────────────────────────────────┼────────────────────┘
                     │                                      │
                     ▼                                      ▼
 ┌───────────────────────────────────────┐  ┌────────────────────────────────────┐
 │    POSTGRESQL 17 (10.10.10.2:5432)    │  │    MINIO S3 (10.10.10.2:9000)      │
 │ • Database: terrapoint                │  │ • Bucket: terrapoint-assets        │
 │ • Monthly Partitioned project_trips   │  │ • Bukti Muat, Bongkar, & Nota      │
 │ • Composite B-Tree Indexing           │  │ • Retensi 30 Hari Aktif            │
 └───────────────────────────────────────┘  └────────────────────────────────────┘
```

---

## 2. Struktur Monorepo Terkonsolidasi

```
terrapoint/
├── 📱 frontend/
│   ├── mobile/                    # Flutter Android Source Code
│   │   ├── lib/
│   │   │   ├── main.dart          # Router & State Flow
│   │   │   ├── core/              # Theme, AppColors, SyncEngineService
│   │   │   ├── database/          # LocalStorageVault (State Machine)
│   │   │   └── features/
│   │   │       ├── auth/          # SplashScreen (Strict Permission Gate) & Login
│   │   │       ├── camera/        # CameraX Viewfinder & Canvas Watermark
│   │   │       └── home/          # HomeScreen (4 Cards Tanpa Nomor)
│   │   └── build/app/outputs/flutter-apk/app-release.apk # Release APK
│   │
│   └── web/                       # Dispatcher Command Center PWA
│       ├── index.html             # Single-Page Web Dashboard
│       ├── css/styles.css         # Mining Slate Dark / Light Theme
│       ├── js/
│       │   ├── app.js             # Dispatcher App Controller & State
│       │   ├── map_service.js     # Leaflet Map Engine (Warna Neon Driver)
│       │   └── icons.js           # SVG Icons Library
│       ├── screenshots/           # Galeri Visual 8 Layar Mobile
│       └── terrapoint.apk         # Downloadable APK Driver
│
├── ⚙️ backend/
│   ├── src/
│   │   ├── index.js               # Entry Point Server Bun (Port 8000)
│   │   ├── db.js                  # PostgreSQL Pool Connection
│   │   ├── utils/haversine.js     # Geofence Distance Calculation
│   │   └── routes/
│   │       ├── auth.js            # JWT Login Driver & Web
│   │       ├── dashboard.js       # Projects, Drivers, Geofences, KPI
│   │       └── sync.js            # trip-load, trip-dump-step, trip-dump
│   └── migrations/
│       ├── 000001_init_schema.up.sql
│       └── 000002_project_based_trips.up.sql # Proyek, Roda Jumbo, Trips
│
├── 📑 docs/
│   ├── specs/                     # PRD v6.1, Technical Design, API Spec
│   ├── designs/                   # Mockup Artboards & Playwright Scripts
│   ├── server_infra/              # Nginx, Docker Compose, SSL Configs
│   └── flow-assets/               # PDF Dokumen Alur & PNG Diagrams
│
└── 📄 README.md                   # Panduan Operasional & Arsitektur Monorepo
```

---

## 3. Spesifikasi Teknis Komponen

### 3.1 Mobile Engine (Flutter Client)
1. **Strict Runtime Permission Gate:**
   - Ditegakkan di `SplashScreen` via `permission_handler` dan `geolocator`.
   - Mengunci layar jika status `Permission.camera` atau `Permission.location` belum `granted`.
   - Menangani izin ditolak permanen dengan memanggil `openAppSettings()`.
2. **Real-Time Offline Satellite GPS Sensor:**
   - Menggunakan `Geolocator.getPositionStream(accuracy: LocationAccuracy.high)`.
   - Membaca koordinat satelit GPS murni (`lat`, `lng`, `accuracy`, `altitude`) langsung dari chip GNSS smartphone tanpa memerlukan data seluler.
3. **Canvas Watermark & Downscaling Engine:**
   - Citra kamera beresolusi tinggi (4000x3000px) otomatis di-downscale ke lebar maksimal `1280 px` sebelum di-encode.
   - Watermark surveyor dibakar (*canvas burn-in*) permanen pada koordinat piksel: waktu WITA, koordinat GPS satelit, elevasi RL, dan tag checkpoint.
   - Ukuran berkas terkompresi menjadi $\le 180\text{ KB}$ per foto.
4. **Strict 4-Cards State Machine:**
   - Status terisolasi: `READY_TO_LOAD` &rarr; `LOADED_NEED_DUMP` &rarr; `DUMPED_NEED_INVOICE` &rarr; `READY_TO_LOAD`.
   - Selector jenis armada (`4 Roda`, `6 Roda (Dump Truck)`, `6 Roda Jumbo`, `10 Roda (Tronton)`) wajib dikonfirmasi di awal muat, dan terkunci selama siklus proyek berlangsung.
   - Driver dilarang logout saat membawa muatan (*Anti-Fraud Lock*).

---

### 3.2 Backend Service (Bun & Express API)
1. **Koneksi Database Pool:**
   - PostgreSQL connection pool (`pg.Pool`) dengan `max: 20`, `idleTimeoutMillis: 30000`.
2. **Kalkulasi Geofence Haversine:**
   ```javascript
   function calculateHaversine(lat1, lon1, lat2, lon2) {
     const R = 6371000; // radius bumi dalam meter
     const dLat = (lat2 - lat1) * Math.PI / 180;
     const dLon = (lon2 - lon1) * Math.PI / 180;
     const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
               Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
               Math.sin(dLon/2) * Math.sin(dLon/2);
     return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
   }
   ```
3. **Siklus REST Endpoints Trip:**
   - `POST /api/sync/trip-load`: Menerima foto muat, mencatat `start_deviation_m`, memperbarui tipe roda driver, dan mengembalikan `status: IN_TRANSIT`.
   - `POST /api/sync/trip-dump-step`: Menerima foto fisik curah di ROM, mencatat `dump_deviation_m`, dan membuka izin upload nota.
   - `POST /api/sync/trip-dump`: Menerima foto nota timbang, memvalidasi kelengkapan berkas, menandai `status: COMPLETED`, dan memicu rekalkulasi KPI live.

---

### 3.3 Database PostgreSQL 17 (Data Schema & Indexing)
1. **Tabel `projects`:**
   - Primary Key: `project_id`
   - Radius Toleransi: `start_radius_meters` (default 250m, range 100-600m), `end_radius_meters` (default 40m, range 20-100m).
2. **Tabel `project_trips`:**
   - Primary Key: `trip_id`
   - Foreign Keys: `project_id`, `driver_id`
   - Kolom Bukti: `load_photo_url`, `dump_photo_url`, `invoice_photo_url`
   - Kolom Audit: `load_deviation_m`, `dump_deviation_m`, `status` (`IN_TRANSIT`, `COMPLETED`, `FLAGGED`)
   - Indeks Komposit: `CREATE INDEX idx_trips_driver_created ON project_trips(driver_id, created_at DESC);`
   - Indeks Filter: `CREATE INDEX idx_trips_status_today ON project_trips(status, created_at);`

---

## 4. Keamanan, Integritas & Kinerja (Non-Functional Benchmarks)

| Parameter | Target Desain | Hasil Implementasi Nyata |
|---|---|---|
| **Ukuran Berkas Bukti** | $\le 250\text{ KB}$ | Rata-rata 140 – 180 KB per foto terkompresi |
| **Throughput REST API** | $\le 50\text{ ms}$ latency | Rata-rata 12 – 24 ms di server Bun VPS |
| **Kinerja Offline** | 100% Fungsi di Blank Spot | Sensor GPS Satelit & Local Storage aktif offline |
| **Waktu Akses Web PWA** | $\le 1.5\text{ detik}$ First Paint | 0.8 detik via Leaflet ES Modules |
| **Keamanan Kredensial** | Zero Secret Exposure | `.env` di-ignore Git; `.env.example` terstandar |
| **Akses Publik Klien** | 100% Tanpa VPN / Tailscale | Cloudflare Tunnel HTTPS aktif terverifikasi |
