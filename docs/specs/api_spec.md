# RESTful API & Cloud Contract Specification — TerraPoint MVP

---

**Backend Provider:** Supabase Cloud (PostgreSQL 16 + Edge Functions) & Cloudflare R2
**Base URL API:** `https://<YOUR_SUPABASE_PROJECT_REF>.supabase.co/rest/v1`
**Base URL Edge Functions:** `https://<YOUR_SUPABASE_PROJECT_REF>.supabase.co/functions/v1`
**Storage Base URL:** `https://<YOUR_ACCOUNT_ID>.r2.cloudflarestorage.com/terrapoint-evidences`
**Autentikasi:** Supabase JWT Bearer Token

---

## 1. Header Global & Keamanan

| Nama Header | Contoh Nilai | Keterangan |
| :--- | :--- | :--- |
| `apikey` | `eyJhbGciOi...` | Supabase Anon Key (Public Key) |
| `Authorization` | `Bearer <JWT_ACCESS_TOKEN>` | Token sesi driver hasil login |
| `Content-Type` | `application/json` | Header untuk request JSON |
| `Prefer` | `return=representation` | Supabase header untuk mengembalikan data hasil insert/update |

---

## 2. Endpoint RESTful & Edge Functions

### 2.1 Autentikasi Driver

#### [POST] `/auth/v1/token?grant_type=password`
Masuk akun driver menggunakan Nomor Telepon/NIK + PIN.

* **Request Body:**
```json
{
  "phone": "081234567890",
  "password": "PIN_HASH_OR_PASSWORD"
}
```

* **Respon Sukses (`200 OK`):**
```json
{
  "access_token": "eyJhbGciOi...",
  "token_type": "bearer",
  "expires_in": 86400,
  "refresh_token": "...",
  "user": {
    "id": "DRV-001",
    "phone": "081234567890",
    "user_metadata": {
      "full_name": "Ahmad Fauzi"
    }
  }
}
```

---

### 2.2 Master Data Lokasi Tambang (Untuk GPS Auto-Detect Offline)

#### [GET] `/rest/v1/master_locations?select=*&is_active=eq.true`
Mengunduh master titik Pit & ROM ke SQLite lokal (agar ponsel dapat mencocokkan koordinat secara offline).

* **Respon Sukses (`200 OK`):**
```json
[
  {
    "location_id": "LOC-PIT-03",
    "name": "Loading Point Pit 3 Utara",
    "location_type": "LOADING_POINT",
    "latitude": -3.123456,
    "longitude": 115.123456,
    "radius_meters": 50
  },
  {
    "location_id": "LOC-ROM-01",
    "name": "ROM Stockpile 1",
    "location_type": "DUMPING_POINT",
    "latitude": -3.145000,
    "longitude": 115.148000,
    "radius_meters": 50
  }
]
```

---

### 2.3 Sinkronisasi Manual Ritase (Camp Sync)

#### [POST] `/functions/v1/sync-task-complete` (Supabase Edge Function)
Mengirimkan data ritase selesai dari antrean lokal ke database cloud setelah foto WebP berhasil diunggah ke Cloudflare R2.

* **Request Body:**
```json
{
  "task_id": "TSK-20260918-001",
  "driver_id": "DRV-001",
  "title": "Hauling Pit 3 Utara ke ROM Stockpile 1",
  "start_point": {
    "name": "Loading Point Pit 3 Utara",
    "lat": -3.123456,
    "lng": 115.123456,
    "radius": 50
  },
  "end_point": {
    "name": "ROM Stockpile 1",
    "lat": -3.145000,
    "lng": 115.148000,
    "radius": 50
  },
  "evidences": {
    "start_photo": {
      "captured_lat": -3.123470,
      "captured_lng": 115.123460,
      "accuracy_meters": 8.5,
      "r2_url": "https://pub-r2.dev/evidences/TSK-001-START.webp",
      "captured_at": "2026-09-18T08:05:22.000Z"
    },
    "end_photo": {
      "captured_lat": -3.145020,
      "captured_lng": 115.148010,
      "accuracy_meters": 9.1,
      "r2_url": "https://pub-r2.dev/evidences/TSK-001-END.webp",
      "captured_at": "2026-09-18T08:45:10.000Z"
    }
  },
  "actual_route": [
    {"lat": -3.123456, "lng": 115.123456, "spd": 28.5, "t": 1790409922000},
    {"lat": -3.124100, "lng": 115.124200, "spd": 32.1, "t": 1790409952000},
    {"lat": -3.145000, "lng": 115.148000, "spd": 15.0, "t": 1790411200000}
  ]
}
```

* **Respon Sukses (`200 OK`):**
```json
{
  "status": "SUCCESS",
  "data": {
    "task_id": "TSK-20260918-001",
    "verified_start_deviation_meters": 7.82,
    "verified_end_deviation_meters": 9.15,
    "status": "COMPLETED",
    "synced_at": "2026-09-18T18:15:30.000Z"
  }
}
```

---

### 2.4 Hidden Auto Telemetry Sync (Stealth Ingestion)

#### [POST] `/rest/v1/task_raw_breadcrumbs`
Mengirimkan potongan array titik rute secara langsung ke tabel telemetry Supabase saat mendeteksi sinyal tipis di rute hauling.

* **Request Body:**
```json
[
  {
    "task_id": "TSK-20260918-001",
    "latitude": -3.123456,
    "longitude": 115.123456,
    "speed_kmh": 28.5,
    "heading": 142.0,
    "recorded_at": "2026-09-18T08:05:22.000Z"
  },
  {
    "task_id": "TSK-20260918-001",
    "latitude": -3.124100,
    "longitude": 115.124200,
    "speed_kmh": 32.1,
    "heading": 140.5,
    "recorded_at": "2026-09-18T08:05:52.000Z"
  }
]
```

---

### 2.5 Web Dashboard PWA Queries (Leaflet Ready)

#### [GET] `/rest/v1/tasks?select=task_id,title,status,start_point_name,start_lat,start_lng,end_point_name,end_lat,end_lng,actual_route,task_evidences(checkpoint_type,r2_storage_url)&task_id=eq.{task_id}`
Mengambil data ritase dan array rute langsung untuk dirender oleh Leaflet.js (`L.polyline(task.actual_route)`).
