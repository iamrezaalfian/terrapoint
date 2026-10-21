# Development Roadmap & Implementation Plan — TerraPoint MVP

---

**Nama Produk:** TerraPoint (Mining Compliance & Visual Verification Platform)  
**Target Rilis:** MVP v1.0 Production-Ready (Zero-Click GPS Auto-Detection & Self-Hosted VM/VPS Infrastructure)  
**Pendekatan Eksekusi:** **Mobile-First (Flutter 10 Layar) $\rightarrow$ Self-Hosted VM/VPS Stack (Docker Compose, PostgreSQL 16, REST API & Nginx Gateway) $\rightarrow$ Web Dashboard PWA di Nginx**  
**Tech Stack:**
- **Mobile Client:** Flutter 3.24+ (Drift SQLite, SQLCipher, CameraX, REST Sync Engine)
- **Database Engine:** PostgreSQL 16 (Containerized di VM/VPS dengan skema migrasi DDL otomatis)
- **Backend API:** Node.js Express REST API (Haversine 50m audit, autentikasi pengemudi/admin, ingesti telemetri & file upload)
- **Media & Evidence Storage:** Self-Hosted High-Performance Storage (Volume Disk VPS disajikan langsung via Nginx dengan Cache & Immutability)
- **Web Dashboard & Gateway:** Nginx Reverse Proxy (Serving PWA Web Dashboard + Reverse Proxy API `/api/` & `/uploads/` + SSL Let's Encrypt)

---

## 1. Ringkasan Peta Jalan (High-Level Milestones Overview)

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                 STATUS PETA JALAN IMPLEMENTASI MVP (UPDATE TERAKHIR)                   │
├─────────────────┬──────────────────────────────────────────┬───────────────────────────┤
│ Fase / Milestone│ Fokus Utama                              │ Status Saat Ini           │
├─────────────────┼──────────────────────────────────────────┼───────────────────────────┤
│ FASE 1: MOBILE  │                                          │                           │
│ • Milestone 1   │ Fondasi Mobile, Clean Tech UI & Storage  │ [X] SELESAI (10 Layar OK) │
│ • Milestone 2   │ CameraX Watermark & PopScope Navigasi    │ [X] SELESAI (Lolos Test)  │
│ • Milestone 3   │ Route Tracking, Radar & Build APK Release│ [X] SELESAI (APK 19.5 MB) │
├─────────────────┼──────────────────────────────────────────┼───────────────────────────┤
│ FASE 2: VPS STACK│                                         │                           │
│ • Milestone 4   │ PostgreSQL 16 & Skema DDL Auto-Migrate   │ [X] SELESAI (Docker Ready)│
│ • Milestone 5   │ REST API Backend & Formula Haversine 50m │ [X] SELESAI (Express API) │
│ • Milestone 6   │ Nginx Gateway & Evidence Volume Storage  │ [X] SELESAI (Nginx Conf)  │
├─────────────────┼──────────────────────────────────────────┼───────────────────────────┤
│ FASE 3: WEB PWA │                                          │                           │
│ • Milestone 7   │ Web Dashboard PWA di Nginx VM/VPS        │ [X] SELESAI (Siap Saji)   │
├─────────────────┼──────────────────────────────────────────┼───────────────────────────┤
│ FASE 4: TESTING │                                          │                           │
│ • Milestone 8   │ UAT Lokal, Simulasi & Deploy Live VPS    │ [ ] TAHAP BERIKUTNYA      │
└─────────────────┴──────────────────────────────────────────┴───────────────────────────┘
```

---

## 2. Rincian Fase & Langkah Kerja (Detailed Phases)

### 📱 FASE 1: MOBILE APP (FLUTTER 10-SCREEN OFFLINE CLIENT)

#### 🚀 Milestone 1: Fondasi Mobile, Arsitektur 10 Layar & Storage Terenkripsi
* [X] **1.1 Inisialisasi Project Flutter & Theme Engine:**
  * Setup Flutter 3.47+, konfigurasi `pubspec.yaml`, dan arsitektur *Clean Modern Tech* (`frontend_mobile/`).
  * Palet warna *Pure Slate Light* (`#F8FAFC`), *Deep Steel Navy* (`#0F172A`), dan *Precision Amber* (`#D97706`).
* [X] **1.2 Setup Drift SQLite & Reactive Storage Vault:**
  * Implementasi skema tabel lokal dan Reactive Storage Vault (`local_store.dart`) untuk sesi driver, penugasan ritase, master checkpoints Morowali, laporan kendala, dan breadcrumbs telemetri.
* [X] **1.3 Layar Splash Animasi & Login Pengemudi:**
  * `SplashScreen` animasi logo TP dan verifikasi sesi otomatis (`splash_screen.dart`).
  * `LoginScreen` kartu putih input ID Driver `DRV-001` dan PIN 6-digit shift (`login_screen.dart`).
* [X] **1.4 Layar Beranda Dashboard & Aksi Cepat (*Zero-Click Home*):**
  * Deteksi otomatis Pit Bahodopi North ($\le 50\text{m}$) dan tombol hero *"MULAI PERJALANAN"* (`home_screen.dart`).
  * Grid aksi cepat (*Titik Muat, Titik Bongkar, Lapor Kendala, Bantuan K3*), status GPS bar, dan tombol logout sesi.

---

#### 📸 Milestone 2: CameraX Direct-Capture & Surveyor Geotag Watermark
* [X] **2.1 Kamera Kustom Viewfinder (Direct-Capture Only):**
  * Integrasi plugin `camera` (CameraX) dengan reticle bidik bak muatan tanpa akses galeri (`photo_capture_watermark_screen.dart`).
* [X] **2.2 Navigasi Balik yang Aman (*PopScope & Back Button*):**
  * Tombol kembali di sudut kiri atas dan penanganan `PopScope` gesture Android agar tidak menutup aplikasi secara tiba-tiba.
* [X] **2.3 Geofence 50m Shutter Interlock & Anti-Cheat:**
  * Tombol terkunci otomatis jika berada di luar radius 50m atau jika terdeteksi *Mock GPS*.
* [X] **2.4 Canvas Burn-In Watermark & Geotag Permanen:**
  * Stempel permanen pada piksel foto (Nama Lokasi, Jam Merah Presisi WITA, Koordinat GPS, Akurasi Satelit) via `canvas_watermark_service.dart`.

---

#### 🔄 Milestone 3: Route Tracking, Radar Telemetri & Build Release APK
* [X] **3.1 Background Route Tracking Service:**
  * Perekaman rute jalan hauling senyap (*K3 Silent Mode*) dengan *Stationary Filter* ($v < 3\text{ km/jam}$) dan interval $\ge 50\text{m} / 30\text{s}$.
* [X] **3.2 Layar Operasional Lengkap (Alur 10 Layar):**
  * `HaulingRadarScreen` (Layar 3: Stepper alur & radar koridor Sulawesi).
  * `TripCompletedScreen` (Layar 6: Ringkasan ritase selesai 45.2T).
  * `ShiftHistoryScreen` (Layar 7: Rekapitulasi shift harian 2 Ritase • 89.8T).
  * `GpsRadarLiveScreen` (Layar 8: Radar GPS telemetri kecepatan & elevasi +85m RL).
  * `IncidentReportScreen` (Layar 9: Lapor kendala lapangan + foto berstempel).
  * `SafetyHelpScreen` (Layar 10: Radio Ch-04 & WhatsApp Control Room).
* [X] **3.3 Retensi Permanen Foto Bukti:**
  * Foto bukti tersimpan permanen di memori HP pengemudi untuk keperluan audit regulasi inspektur tambang.
* [X] **3.4 Kompilasi APK Release Ringan:**
  * Build APK release teroptimasi AOT (`--split-per-abi`) berukuran **19.5 MB** (`app-arm64-v8a-release.apk`) siap pasang ke HP fisik.

---

### 🖥️ FASE 2: SELF-HOSTED VM / VPS STACK (DOCKER COMPOSE)

#### 🗄️ Milestone 4: Setup Database PostgreSQL 16 Mandiri
* [X] **4.1 Inisialisasi Database Relasional di Kontainer VM:**
  * Kontainer `postgres:16-alpine` pada Docker Compose dengan volume persisten data (`pgdata`).
  * Auto-migrasi skema SQL dan seeding master lokasi tambang via `000001_init_schema.up.sql`.
* [X] **4.2 Healthcheck & Koneksi Pool:**
  * Konfigurasi pg_isready healthcheck dan connection pool aman pada port 5432.

---

#### ⚡ Milestone 5: REST API Backend & Audit Geofence Haversine
* [X] **5.1 Pembuatan REST API Backend Server (`server_vps/backend/`):**
  * Node.js & Express REST API (`terrapoint_api`) dengan CORS dan rate limiting.
  * Modul kalkulasi jarak garis lengkung bumi Haversine presisi dengan toleransi geofence $\le 50\text{m}$.
* [X] **5.2 Endpoint Inti Operasional:**
  * `POST /api/auth/driver-login` & `POST /api/auth/admin-login` (Otentikasi JWT 24 jam).
  * `POST /api/sync/task-complete` (Sinkronisasi ritase, audit deviasi geofence pit/ROM, mutasi status `COMPLETED` / `REJECTED_GEOFENCE`).
  * `POST /api/sync/breadcrumbs` (Ingesti data telemetri rute GPS pergerakan armada).
  * `POST /api/upload/evidence` (Penerimaan foto bukti berstempel watermark via multipart form).
  * `GET /api/dashboard/...` (Endpoint data telemetri, ritase, dan update radius geofence).

---

#### 🌐 Milestone 6: Nginx Gateway & Penyimpanan Bukti Foto Mandiri
* [X] **6.1 Nginx Reverse Proxy Container (`terrapoint_gateway`):**
  * Routing terpadu Port 80 / 443 untuk Web Dashboard PWA, Backend REST API (`/api/`), dan File Bukti (`/uploads/`).
  * Gzip compression dan caching statis untuk optimalisasi bandwidth jaringan site tambang.
* [X] **6.2 Storage Volume Dedicated Bukti Foto:**
  * Volume Docker `evidence_storage` untuk menyimpan berkas foto WebP berstempel surveyor tanpa biaya egress cloud.

---

### 🗺️ FASE 3: WEB DASHBOARD PROGRESSIVE WEB APP (PWA) DI NGINX

#### 📊 Milestone 7: Web Command Center di VM / VPS
* [X] **7.1 Penyajian PWA Statis oleh Nginx:**
  * Web Dashboard PWA (`dashboard_pwa/`) disajikan langsung melalui direktori `/usr/share/nginx/html` Nginx.
* [X] **7.2 Fitur Surveillance Command Center (7 Modul Operasional):**
  1. Peta Topografi Satelit Esri & Koridor Hauling Morowali.
  2. Telemetry HUD Vehicle Inspector (Cockpit Drawer armada DT-104).
  3. Log Ritase & Audit Kepatuhan (Ekspor format CSV).
  4. Modal Verifikasi Bukti Foto (Audit deviasi meter terhadap batas 50m).
  5. Master Geofence Checkpoints (Slider pengaturan radius 20m–100m).
  6. Manajemen Armada Truk (Scania/Volvo/Mercedes).
  7. Portal Login Mandiri Pengawas & Admin.

---

### 🛡️ FASE 4: TESTING, HARDENING & DEPLOYMENT VM/VPS

#### 🏁 Milestone 8: Pengujian End-to-End & UAT Lapangan
* [ ] **8.1 Pengujian Perangkat Fisik (Physical Device UAT):**
  * Instalasi APK release ke ponsel Android pengemudi menggunakan USB Debugging / APK direct install.
  * Validasi fungsionalitas CameraX viewfinder fisik dan akurasi sensor GPS hardware.
* [ ] **8.2 Deployment ke Server VM / VPS Live:**
  * Menjalankan `docker compose up -d --build` di server VM / VPS (Ubuntu).
  * Konfigurasi domain dan sertifikat SSL Let's Encrypt (`certbot`).
  * Uji koneksi pengemudi dari camp tambang ke IP/Domain VPS.
