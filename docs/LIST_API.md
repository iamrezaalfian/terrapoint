# Daftar Endpoint REST API TerraPoint (API Inventory & Reference)

Dokumen ini memuat daftar lengkap seluruh endpoint REST API backend **TerraPoint**, termasuk path, method HTTP, payload request, struktur response, serta contoh penggunaan untuk kebutuhan integrasi klien, mobile app, dan web dashboard.

---

## 1. 🌐 Base URL & Gateway Akses

| Jalur Akses | Base URL | Keterangan |
|---|---|---|
| **Publik (Testing Klien / Tanpa VPN)** | `https://affect-gary-begins-systematic.trycloudflare.com` | Cloudflare Secure Tunnel HTTPS |
| **Privat Tailscale (Tim Developer)** | `http://100.89.207.92:8000` | Jaringan Tailnet `terrapoint-backend` |
| **Internal Data Center (NOC Bridge)** | `http://10.10.10.4:8000` | Jaringan privat Debian 13 VM |

---

## 2. 📋 Ringkasan Cepat Seluruh Endpoint

| Kategori | Method | Endpoint Path | Fungsi Utama |
|---|---|---|---|
| **Sistem & Health** | `GET` | `/health` | Pemeriksaan status server & uptime |
| **Sistem & Health** | `GET` | `/api/system/logs` | Mengambil event & error log dari Log Catcher |
| **Sistem & Health** | `POST` | `/api/system/logs/clear` | Membersihkan buffer memory log catcher |
| **Autentikasi** | `POST` | `/api/auth/driver-login` | Login pengemudi via NIK/ID Driver & PIN |
| **Autentikasi** | `POST` | `/api/auth/login` | Login Dispatcher & Superadmin NOC Web |
| **Autentikasi** | `POST` | `/api/auth/admin-login` | Alias login admin web |
| **Siklus Hauling** | `POST` | `/api/sync/trip-load` | **Card 1:** Rekam muat di Pit & kunci armada roda |
| **Siklus Hauling** | `POST` | `/api/sync/trip-dump-step`| **Card 2:** Rekam foto fisik curah di ROM Stockpile |
| **Siklus Hauling** | `POST` | `/api/sync/trip-dump` | **Card 3:** Rekam foto nota timbang & selesaikan trip |
| **Siklus Hauling** | `POST` | `/api/sync/breadcrumbs` | Ingestion jejak koordinat GPS telemetri armada |
| **Dashboard & Web** | `GET` | `/api/dashboard/summary` | KPI trip harian & breakdown per jenis roda |
| **Dashboard & Web** | `GET` | `/api/dashboard/projects` | Daftar seluruh proyek penugasan hauling |
| **Dashboard & Web** | `POST` | `/api/dashboard/projects` | Buat proyek baru (radius muat luas & bongkar ketat) |
| **Dashboard & Web** | `PUT` | `/api/dashboard/projects/:id/radius` | Ubah radius toleransi proyek secara dinamis |
| **Dashboard & Web** | `GET` | `/api/dashboard/trips` | Daftar riwayat trip beserta 3 foto bukti lengkap |
| **Dashboard & Web** | `GET` | `/api/dashboard/drivers` | Daftar driver, status akun, & armada roda aktif |
| **Dashboard & Web** | `POST` | `/api/dashboard/drivers` | Daftarkan akun driver baru |
| **Dashboard & Web** | `PUT` | `/api/dashboard/drivers/:id/toggle` | Blokir / aktifkan akses login driver |
| **Dashboard & Web** | `PUT` | `/api/dashboard/drivers/:id/assign-project` | Ubah jenis roda armada atau proyek driver |
| **Dashboard & Web** | `GET` | `/api/dashboard/driver-project` | Ambil proyek aktif & status trip berjalan driver |
| **Dashboard & Web** | `GET` | `/api/dashboard/geofences` | Daftar master checkpoint & radius geofence |
| **Dashboard & Web** | `POST` | `/api/dashboard/geofences` | Tambah titik checkpoint geofence baru |
| **Dashboard & Web** | `PUT` | `/api/dashboard/geofences/:id/radius`| Ubah radius toleransi titik checkpoint |
| **Dashboard & Web** | `PUT` | `/api/dashboard/geofences/:id/toggle`| Nonaktifkan / aktifkan titik checkpoint |
| **Media & Static** | `POST` | `/api/upload/evidence` | Upload multipart file foto bukti ke VPS/S3 |
| **Media & Static** | `GET` | `/terrapoint.apk` | Download installer APK Android Driver |
| **Media & Static** | `GET` | `/screenshots/` | Halaman galeri visual dokumentasi antarmuka |

---

## 3. 🔍 Rincian Payload Request & Response

### 3.1 `GET /health`
Mengecek apakah server aktif berjalan.
- **Header:** `Content-Type: application/json`
- **Response (`200 OK`):**
  ```json
  {
    "status": "healthy",
    "system": "TerraPoint Self-Hosted VM Backend",
    "uptime_sec": 1420,
    "timestamp": "2026-10-21T18:30:00.000Z"
  }
  ```

---

### 3.2 `POST /api/auth/driver-login`
Autentikasi pengemudi di aplikasi mobile.
- **Request Body:**
  ```json
  {
    "driver_id": "DRV-001",
    "pin": "123456"
  }
  ```
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "driver": {
      "driver_id": "DRV-001",
      "full_name": "Ahmad Fauzi",
      "phone_number": "081234567890"
    }
  }
  ```
- **Response Error (`401 Unauthorized` / `403 Forbidden`):**
  ```json
  { "success": false, "error": "ID Driver tidak terdaftar." }
  ```

---

### 3.3 `GET /api/dashboard/driver-project?driver_id=DRV-001`
Mengambil detail penugasan proyek, radius toleransi geofence, armada roda, dan status trip aktif untuk driver.
- **Query Parameter:** `driver_id` (wajib)
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "driver": {
      "driver_id": "DRV-001",
      "full_name": "Ahmad Fauzi",
      "truck_wheel_type": "6 Roda Jumbo",
      "is_active": true
    },
    "project": {
      "project_id": "PRJ-HAULING-01",
      "project_name": "Proyek Hauling Pit 2 ke ROM Stockpile 1",
      "start_location_id": "LOC-PIT-02",
      "start_point_name": "Loading Point Pit 2 Barat",
      "start_lat": -3.131000,
      "start_lng": 115.119000,
      "start_radius_meters": 250,
      "end_location_id": "LOC-ROM-01",
      "end_point_name": "ROM Stockpile 1",
      "end_lat": -3.145000,
      "end_lng": 115.148000,
      "end_radius_meters": 40
    },
    "active_trip": null,
    "today_completed_trips": [],
    "today_trips_count": 0
  }
  ```

---

### 3.4 `POST /api/sync/trip-load` (Card 1: Muat Pit)
Mencatat pengambilan foto muatan di Pit, menghitung deviasi jarak Haversine ke titik muat, dan mengunci jenis armada driver selama siklus pengantaran.
- **Request Body:**
  ```json
  {
    "project_id": "PRJ-HAULING-01",
    "driver_id": "DRV-001",
    "truck_wheel_type": "6 Roda Jumbo",
    "load_photo_url": "/uploads/evidences/card1_pit_muat.jpg",
    "load_lat": -3.131015,
    "load_lng": 115.119025
  }
  ```
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "trip": {
      "trip_id": "TRP-20261021-609",
      "project_id": "PRJ-HAULING-01",
      "driver_id": "DRV-001",
      "truck_wheel_type": "6 Roda Jumbo",
      "trip_sequence": 1,
      "status": "IN_TRANSIT",
      "load_photo_url": "/uploads/evidences/card1_pit_muat.jpg",
      "load_deviation_m": 3.2,
      "load_at": "2026-10-21T18:25:00.000Z"
    },
    "message": "Muatan Trip #1 berhasil dicatat! Menuju ROM Stockpile 1."
  }
  ```

---

### 3.5 `POST /api/sync/trip-dump-step` (Card 2: Curah ROM)
Mencatat pengambilan foto fisik bak dump truck selesai curah di ROM Stockpile. Membuka izin bagi pengemudi untuk mengambil foto nota timbang (Card 3).
- **Request Body:**
  ```json
  {
    "trip_id": "TRP-20261021-609",
    "dump_photo_url": "/uploads/evidences/card2_rom_curah.jpg",
    "dump_lat": -3.145018,
    "dump_lng": 115.148008
  }
  ```
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "trip": {
      "trip_id": "TRP-20261021-609",
      "dump_photo_url": "/uploads/evidences/card2_rom_curah.jpg",
      "dump_deviation_m": 2.2,
      "dump_at": "2026-10-21T18:41:00.000Z"
    },
    "message": "Foto pembongkaran berhasil dicatat. Silakan lanjutkan foto nota timbang."
  }
  ```

---

### 3.6 `POST /api/sync/trip-dump` (Card 3: Nota Timbang & Selesai)
Merekam bukti foto dokumen nota timbangan resmi jembatan timbang (*Weighbridge*). Memvalidasi kelengkapan berkas, menyelesaikan trip menjadi `COMPLETED`, dan memperbarui metrik dashboard.
- **Request Body:**
  ```json
  {
    "trip_id": "TRP-20261021-609",
    "dump_photo_url": "/uploads/evidences/card2_rom_curah.jpg",
    "invoice_photo_url": "/uploads/evidences/card3_nota_invoice.jpg",
    "dump_lat": -3.145018,
    "dump_lng": 115.148008
  }
  ```
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "trip": {
      "trip_id": "TRP-20261021-609",
      "status": "COMPLETED",
      "dump_photo_url": "/uploads/evidences/card2_rom_curah.jpg",
      "invoice_photo_url": "/uploads/evidences/card3_nota_invoice.jpg",
      "completed_at": "2026-10-21T18:42:00.000Z"
    },
    "message": "Trip #1 selesai! Pembongkaran & nota timbang terverifikasi."
  }
  ```

---

### 3.7 `GET /api/dashboard/summary`
Mengambil data ringkasan live untuk KPI bar atas di Web Command Center.
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "data": {
      "total_trips_today": 8,
      "active_trips": 1,
      "total_projects": 1,
      "total_drivers": 3,
      "total_locations": 5,
      "wheels_summary": [
        { "wheel_type": "6 Roda (Dump Truck)", "trip_count": 4 },
        { "wheel_type": "6 Roda Jumbo", "trip_count": 3 },
        { "wheel_type": "10 Roda (Tronton)", "trip_count": 1 }
      ]
    }
  }
  ```

---

### 3.8 `GET /api/dashboard/trips`
Mengambil seluruh data riwayat perjalanan pengantaran beserta URL 3 dokumen foto bukti visual lengkap.
- **Query Parameters (Opsional):** `project_id`, `driver_id`, `status`, `date`
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "trips": [
      {
        "trip_id": "TRP-20261021-609",
        "project_id": "PRJ-HAULING-01",
        "project_name": "Proyek Hauling Pit 2 ke ROM Stockpile 1",
        "driver_id": "DRV-001",
        "driver_name": "Ahmad Fauzi",
        "truck_wheel_type": "6 Roda Jumbo",
        "trip_sequence": 1,
        "status": "COMPLETED",
        "load_point_name": "Loading Point Pit 2 Barat",
        "end_point_name": "ROM Stockpile 1",
        "load_photo_url": "/uploads/evidences/card1_pit_muat.jpg",
        "dump_photo_url": "/uploads/evidences/card2_rom_curah.jpg",
        "invoice_photo_url": "/uploads/evidences/card3_nota_invoice.jpg",
        "load_deviation_m": 3.2,
        "dump_deviation_m": 2.2,
        "load_at": "2026-10-21T18:25:00.000Z",
        "completed_at": "2026-10-21T18:42:00.000Z"
      }
    ]
  }
  ```

---

### 3.9 `PUT /api/dashboard/drivers/:id/assign-project`
Memperbarui jenis roda kendaraan atau proyek penugasan driver.
- **Path Parameter:** `id` (e.g. `DRV-001`)
- **Request Body:**
  ```json
  {
    "truck_wheel_type": "6 Roda Jumbo",
    "project_id": "PRJ-HAULING-01"
  }
  ```
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "driver": {
      "driver_id": "DRV-001",
      "truck_wheel_type": "6 Roda Jumbo",
      "assigned_project_id": "PRJ-HAULING-01"
    },
    "message": "Proyek & jenis roda driver berhasil diperbarui!"
  }
  ```

---

### 3.10 `GET /api/system/logs` (Log Catcher)
Mengambil riwayat event dan error log terkini dari buffer server VPS.
- **Query Parameters (Opsional):** `limit` (default: 50), `level` (`ALL`, `ERROR`, `WARN`, `INFO`)
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "data": {
      "stats": {
        "total": 124,
        "errors": 0,
        "warnings": 2,
        "info": 122,
        "http_4xx": 2,
        "http_5xx": 0,
        "startedAt": "2026-10-21T18:00:00.000Z"
      },
      "logs": [
        {
          "id": "LOG-1729535000000-452",
          "timestamp": "2026-10-21T18:30:15.123Z",
          "level": "INFO",
          "message": "TerraPoint Backend Server started on port 8000",
          "http": {
            "method": "GET",
            "url": "/health",
            "ip": "140.213.1.6"
          }
        }
      ]
    }
  }
  ```

---

### 3.11 `POST /api/system/logs/clear`
Mengosongkan memori buffer log catcher.
- **Response (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Memory logs catcher berhasil dibersihkan."
  }
  ```
