# Development Roadmap & Implementation Plan — TerraPoint MVP

---

**Nama Produk:** TerraPoint (Mining Compliance & Visual Verification Platform)
**Target Rilis:** MVP v1.0 Production-Ready (Zero-Click GPS Auto-Detection & Serverless Cloud)
**Pendekatan Eksekusi:** **Mobile-First (Flutter) $\rightarrow$ Cloud Backend (Supabase & R2) $\rightarrow$ Web Dashboard PWA (Cloudflare Pages)**
**Tech Stack:**
- **Mobile Client:** Flutter 3.24+ (Drift SQLite, SQLCipher, CameraX, Supabase SDK)
- **Cloud Backend:** Supabase (Managed PostgreSQL 16, Supabase Auth, Edge Functions)
- **Media Storage:** Cloudflare R2 (10 GB Free Storage, $0 Egress Bandwidth)
- **Web Dashboard:** Cloudflare Pages (PWA + Leaflet.js Mapping Engine)

---

## 1. Ringkasan Peta Jalan (High-Level Milestones Overview)

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        PETA JALAN IMPLEMENTASI MVP (ZERO-CLICK AUTO-DETECT)            │
├─────────────────┬─────────────────────────────────────────────────┬────────────────────┤
│ Fase / Milestone│ Fokus Utama                                     │ Deliverable Kunci  │
├─────────────────┼─────────────────────────────────────────────────┼────────────────────┤
│ FASE 1: MOBILE  │                                                 │                    │
│ • Milestone 1   │ Fondasi Mobile Flutter & Offline Storage        │ Drift + SQLCipher  │
│ • Milestone 2   │ Zero-Click Kamera Direct-Capture & WebP Engine  │ Viewfinder & WebP  │
│ • Milestone 3   │ Route Tracking, Stealth Telemetry & Sync UI     │ Tracking & Sync UI │
├─────────────────┼─────────────────────────────────────────────────┼────────────────────┤
│ FASE 2: CLOUD   │                                                 │                    │
│ • Milestone 4   │ Setup Supabase Project, Schema & Auth           │ Supabase DB & Auth │
│ • Milestone 5   │ Setup Cloudflare R2 Bucket & Edge Functions     │ R2 Bucket & Funcs  │
├─────────────────┼─────────────────────────────────────────────────┼────────────────────┤
│ FASE 3: DASHBOARD│                                                │                    │
│ • Milestone 6   │ Web Dashboard Progressive Web App (PWA)         │ Cloudflare Pages   │
├─────────────────┼─────────────────────────────────────────────────┼────────────────────┤
│ FASE 4: TESTING │                                                 │                    │
│ • Milestone 7   │ Pengujian End-to-End, Hardening & UAT           │ Production Ready   │
└─────────────────┴─────────────────────────────────────────────────┴────────────────────┘
```

---

## 2. Rincian Fase & Langkah Kerja (Detailed Phases)

### 📱 FASE 1: MOBILE APP (FLUTTER OFFLINE CLIENT)

#### 🚀 Milestone 1: Fondasi Mobile & Database Terenkripsi
* [ ] **1.1 Inisialisasi Project Flutter:**
  * Setup Flutter 3.24+, konfigurasi `pubspec.yaml`, dan struktur folder Feature-First.
* [ ] **1.2 Setup Drift SQLite & Enkripsi SQLCipher:**
  * Implementasi skema tabel lokal (`local_driver_session`, `local_master_locations`, `local_tasks`, `local_task_evidences`, `local_task_breadcrumbs`).
  * Pembuatan DAO (*Data Access Objects*) untuk operasi query lokal.
  * Enkripsi database lokal menggunakan SQLCipher (AES-256) dengan kunci aman di Android Keystore.
* [ ] **1.3 Layar Login & Keypad Angka Besar (PIN Pad):**
  * Implementasi UI Login sesuai `ui_ux_spec.md` (Keypad $56 \times 56\text{ dp}$, high contrast).
  * Dukungan autentikasi *offline* menggunakan cache PIN hash di SQLite lokal.
* [ ] **1.4 Layar Beranda Deteksi Lokasi Otomatis (*Zero-Click Home*):**
  * Kartu lokasi terdeteksi via GPS (misal Pit 3 Utara) dan tombol tunggal *"📸 AMBIL FOTO MUAT & MULAI"*.

---

#### 📸 Milestone 2: Zero-Click Kamera Direct-Capture & WebP Engine
* [ ] **2.1 Kamera Kustom Viewfinder (Direct-Capture Only):**
  * Integrasi plugin `camera` / CameraX bindings tanpa izin akses galeri.
* [ ] **2.2 Geofence 50m Shutter Interlock & UI Messaging:**
  * Tombol terkunci (merah) jika $> 50\text{m}$ (*"Anda terlalu jauh dari titik awal/akhir"*).
  * Tombol aktif (hijau besar $68 \times 68\text{ dp}$) jika $\le 50\text{m}$ dan akurasi GPS $\le 25\text{m}$ (*"Posisi sesuai, siap ambil foto"*).
  * Pemblokiran jika terdeteksi `isMockLocation == true`.
* [ ] **2.3 Auto Task Trigger (Foto Awal = Bukti Tugas):**
  * Menjepret foto awal secara otomatis men-generate record ritase baru di SQLite lokal.
* [ ] **2.4 Canvas Burn-In Watermark & WebP EXIF Injection:**
  * Menuliskan teks permanen pada piksel (ID Driver, Task ID, Koordinat, Waktu UTC).
  * Mengonversi ke WebP Lossy 75% ($\le 150\text{ KB}$) + menyisipkan tag EXIF GPS.

---

#### 🔄 Milestone 3: Route Tracking, Stealth Telemetry & Sync UI
* [ ] **3.1 Background Route Tracking Service:**
  * Menjalankan Android Foreground Service saat status tugas `IN_PROGRESS`.
  * Filter stasioner ($v < 3\text{ km/jam}$) dan pencatatan per $\ge 50\text{m} / 30\text{s}$ ke SQLite lokal.
* [ ] **3.2 Hidden Automatic Background Sync (Stealth Telemetry Worker):**
  * Background task `Workmanager` yang otomatis mengirimkan batch kecil titik rute ($\le 3\text{ KB}$ JSON) ke Supabase saat ada sinyal seluler tipis di jalan tambang.
* [ ] **3.3 Layar Antrean Sinkronisasi Manual (*Manual Sync Queue UI*):**
  * Menampilkan daftar ritase selesai dan 1 tombol hijau besar *"SINKRONKAN SEKARANG"*.
  * Integrasi upload foto langsung ke Cloudflare R2 & kirim data ritase ke Supabase.
* [ ] **3.4 Local Storage Auto-Purge Worker (3 Hari):**
  * Background cleaner harian untuk menghapus berkas fisik WebP lokal yang sudah `SYNCED` $\ge 3\text{ hari}$.

---

### ☁️ FASE 2: CLOUD BACKEND (SUPABASE & CLOUDFLARE R2)

#### 🚀 Milestone 4: Setup Supabase Project, Schema & Auth
* [ ] **4.1 Inisialisasi Project Supabase:**
  * Setup database PostgreSQL 16 di Supabase Cloud.
  * Eksekusi migrasi DDL tabel `drivers`, `master_locations`, `tasks`, `task_evidences`, dan `task_raw_breadcrumbs`.
* [ ] **4.2 Konfigurasi Supabase Auth & Row Level Security (RLS):**
  * Setup tabel profil driver dan aturan RLS untuk isolasi data antar pengemudi.

---

#### ⚙️ Milestone 5: Setup Cloudflare R2 & Supabase Edge Functions
* [ ] **5.1 Setup Cloudflare R2 Bucket:**
  * Pembuatan bucket `terrapoint-evidences` dengan kebijakan *Lifecycle Delete > 30 Hari*.
  * Konfigurasi R2 API Tokens (S3-compatible Access Key & Secret Key).
* [ ] **5.2 Supabase Edge Function (`sync-task-complete`):**
  * Edge Function berbasis Deno/TypeScript untuk validasi radius geofence 50m dan konsolidasi data ritase.

---

### 🌐 FASE 3: WEB DASHBOARD PROGRESSIVE WEB APP (PWA)

#### 🗺️ Milestone 6: Web Dashboard PWA di Cloudflare Pages
* [ ] **6.1 Setup PWA Shell & Leaflet.js:**
  * Setup Web App Manifest (`manifest.json`) dan Service Worker (`sw.js`).
  * Integrasi peta Leaflet.js untuk merender lingkaran geofence 50m (`L.circle`) dan garis rute hauling (`L.polyline`).
* [ ] **6.2 Dispatcher & Superadmin Live Surveillance View:**
  * Tabel monitoring ritase mandiri driver.
  * Peta live telemetry armada secara *near-realtime*.
* [ ] **6.3 Deployment ke Cloudflare Pages:**
  * Hosting gratis di Cloudflare Pages dengan domain kustom & SSL otomatis.

---

### 🛡️ FASE 4: TESTING, HARDENING & UAT

#### 🏁 Milestone 7: Pengujian End-to-End & UAT
* [ ] **7.1 E2E Offline Simulation:**
  * Simulasi offline penuh (Auto-detect di Pit $\rightarrow$ Foto muat $\rightarrow$ Hauling tracking $\rightarrow$ Foto bongkar di ROM $\rightarrow$ Manual sync di camp).
* [ ] **7.2 Security Verification:**
  * Pengujian mock location dan integritas EXIF GPS.
* [ ] **7.3 UAT & Production Sign-off:**
  * Build APK release terenkripsi (ProGuard/R8) dan rilis PWA.
