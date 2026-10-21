# RESTful API & Endpoint Specification — TerraPoint Enterprise

---

**Host Server:** Debian 13 VPS (`100.89.207.92:8000`)  
**Public Gateway URL:** `https://affect-gary-begins-systematic.trycloudflare.com`  
**Private Network URL:** `http://100.89.207.92:8000` (atau `http://terrapoint-backend:8000`)  
**Autentikasi:** JWT Bearer Token (`Authorization: Bearer <TOKEN>`)  
**Versi:** 6.0 (Project-Based Hauling, 4-Cards Workflow, Weighbridge Invoice Verification)

---

## 1. Header Global & Keamanan

| Nama Header | Nilai Default | Keterangan |
|---|---|---|
| `Content-Type` | `application/json` | Format payload permintaan data |
| `Authorization` | `Bearer <JWT_TOKEN>` | Token otentikasi driver / dispatcher |

---

## 2. Autentikasi Pengguna (`/api/auth`)

### 2.1 Login Pengemudi Tambang (Driver Login)
- **Method & Path:** `POST /api/auth/driver-login`
- **Request Body:**
  ```json
  {
    "driver_id": "DRV-001",
    "pin": "123456"
  }
  ```
- **Response Success (`200 OK`):**
  ```json
  {
    "success": true,
    "token": "eyJhbGciOi...",
    "driver": {
      "driver_id": "DRV-001",
      "full_name": "Ahmad Fauzi",
      "phone_number": "081234567890",
      "truck_wheel_type": "6 Roda (Dump Truck)"
    }
  }
  ```

### 2.2 Login Dispatcher / Admin Web
- **Method & Path:** `POST /api/auth/login` (atau `POST /api/auth/admin-login`)
- **Request Body:**
  ```json
  {
    "email": "ahmad.fauzi@terrapoint.id",
    "password": "admin123456"
  }
  ```
- **Response Success (`200 OK`):**
  ```json
  {
    "success": true,
    "token": "eyJhbGciOi...",
    "user": {
      "username": "ahmad.fauzi@terrapoint.id",
      "email": "ahmad.fauzi@terrapoint.id",
      "role": "Head Mine Dispatcher"
    }
  }
  ```

---

## 3. Siklus Pengantaran 4 Cards (`/api/sync`)

### 3.1 Card 1: Rekam Muat di Pit Tambang
- **Method & Path:** `POST /api/sync/trip-load`
- **Keterangan:** Memicu status trip menjadi `IN_TRANSIT`, mencatat deviasi radius muat, dan mengunci jenis armada driver selama perjalanan.
- **Request Body:**
  ```json
  {
    "project_id": "PRJ-HAULING-01",
    "driver_id": "DRV-001",
    "truck_wheel_type": "6 Roda (Dump Truck)",
    "load_photo_url": "/uploads/evidences/card1_pit_muat.jpg",
    "load_lat": -3.131010,
    "load_lng": 115.119020
  }
  ```
- **Response Success (`200 OK`):**
  ```json
  {
    "success": true,
    "trip": {
      "trip_id": "TRP-20261021-435",
      "project_id": "PRJ-HAULING-01",
      "driver_id": "DRV-001",
      "truck_wheel_type": "6 Roda (Dump Truck)",
      "trip_sequence": 1,
      "status": "IN_TRANSIT",
      "load_deviation_m": 4.2
    },
    "message": "Muatan Trip #1 berhasil dicatat! Menuju ROM Stockpile 1."
  }
  ```

### 3.2 Card 2: Rekam Foto Pembongkaran Curah di ROM
- **Method & Path:** `POST /api/sync/trip-dump-step`
- **Keterangan:** Menyimpan bukti fisik dump truck selesai curah di ROM Stockpile dan membuka kunci untuk pengambilan foto nota timbang (Card 3).
- **Request Body:**
  ```json
  {
    "trip_id": "TRP-20261021-435",
    "dump_photo_url": "/uploads/evidences/card2_rom_curah.jpg",
    "dump_lat": -3.145020,
    "dump_lng": 115.148010
  }
  ```
- **Response Success (`200 OK`):**
  ```json
  {
    "success": true,
    "trip": {
      "trip_id": "TRP-20261021-435",
      "dump_photo_url": "/uploads/evidences/card2_rom_curah.jpg",
      "dump_deviation_m": 3.8
    },
    "message": "Foto pembongkaran berhasil dicatat. Silakan lanjutkan foto nota timbang."
  }
  ```

### 3.3 Card 3: Rekam Foto Nota Timbang (Weighbridge) & Selesaikan Trip
- **Method & Path:** `POST /api/sync/trip-dump`
- **Keterangan:** Memvalidasi bukti nota timbang fisik, menandai status trip `COMPLETED`, dan memperbarui metrik live dashboard.
- **Request Body:**
  ```json
  {
    "trip_id": "TRP-20261021-435",
    "dump_photo_url": "/uploads/evidences/card2_rom_curah.jpg",
    "invoice_photo_url": "/uploads/evidences/card3_nota_invoice.jpg",
    "dump_lat": -3.145020,
    "dump_lng": 115.148010
  }
  ```
- **Response Success (`200 OK`):**
  ```json
  {
    "success": true,
    "trip": {
      "trip_id": "TRP-20261021-435",
      "status": "COMPLETED",
      "invoice_photo_url": "/uploads/evidences/card3_nota_invoice.jpg",
      "completed_at": "2026-10-21T15:53:00.000Z"
    },
    "message": "Trip #1 selesai! Pembongkaran & nota timbang terverifikasi."
  }
  ```

---

## 4. Dashboard Dispatcher & Monitoring API (`/api/dashboard`)

### 4.1 Ringkasan KPI Harian & Breakdown Roda
- **Method & Path:** `GET /api/dashboard/summary`
- **Response Success (`200 OK`):**
  ```json
  {
    "success": true,
    "data": {
      "total_trips_today": 1,
      "active_trips": 0,
      "total_projects": 1,
      "total_drivers": 3,
      "total_locations": 5,
      "wheels_summary": [
        { "wheel_type": "6 Roda (Dump Truck)", "trip_count": 0 },
        { "wheel_type": "6 Roda Jumbo", "trip_count": 1 },
        { "wheel_type": "10 Roda (Tronton)", "trip_count": 0 }
      ]
    }
  }
  ```

### 4.2 Ambil Penugasan Proyek Aktif Driver
- **Method & Path:** `GET /api/dashboard/driver-project?driver_id=DRV-001`
- **Response Success (`200 OK`):**
  ```json
  {
    "success": true,
    "driver": {
      "driver_id": "DRV-001",
      "full_name": "Ahmad Fauzi",
      "truck_wheel_type": "6 Roda (Dump Truck)",
      "is_active": true
    },
    "project": {
      "project_id": "PRJ-HAULING-01",
      "project_name": "Proyek Hauling Pit 2 ke ROM Stockpile 1",
      "start_point_name": "Loading Point Pit 2 Barat",
      "start_radius_meters": 250,
      "end_point_name": "ROM Stockpile 1",
      "end_radius_meters": 40
    },
    "active_trip": null,
    "today_completed_trips": []
  }
  ```

### 4.3 Log Pengantaran dengan Bukti 3 Foto
- **Method & Path:** `GET /api/dashboard/trips`
- **Response Success (`200 OK`):**
  Mengembalikan daftar riwayat pengantaran beserta URL `load_photo_url`, `dump_photo_url`, dan `invoice_photo_url`.
