# TerraPoint Platform — Master Application Flow & Technical Documentation

---

**Nama Produk:** TerraPoint  
**Sektor Industri:** Mining Logistics & Heavy Equipment Fleet Compliance  
**Versi Sistem:** v2.4 (Morowali Nickel Haulage Sector — Offline-First Engine & Serverless Cloud)  
**Tanggal Rilis Dokumen:** 2026-09-21  
**Status:** Production Ready (Approved for Implementation & Deployment)  

---

## 1. Ringkasan Eksekutif & Topologi Multi-Platform

TerraPoint adalah platform audit kepatuhan rute hauling dan verifikasi visual geospasial berbasis **offline-first** yang dirancang untuk operasional tambang mineral/nikel di koridor blank spot lapangan (seperti area Morowali / Bahodopi, Sulawesi). Sistem ini terdiri dari 3 platform terintegrasi:

```text
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│ 📱 1. MOBILE CLIENT APP (Flutter 3.47+ Offline Engine)                                      │
│ • Zero-Click GPS Auto-Detection (Pit 3 / Bahodopi <= 50m)                                   │
│ • Direct-Capture Viewfinder (Tanpa Akses Galeri)                                            │
│ • Canvas Burn-In Watermark Surveyor (Peta Kontur 50m, Jam Merah Presisi WITA, Koordinat)    │
│ • K3 Silent Background Route Tracking & Stationary Filtering (v < 3 km/jam)                 │
│ • Dual-Sync Engine (Manual Wi-Fi Batch + Hidden Stealth Telemetry JSON <= 3 KB)             │
└───────────────────────────────┬─────────────────────────────────────────────────────────────┘
                                │
                 ┌──────────────┴──────────────┐
                 ▼                             ▼
┌───────────────────────────────────┐ ┌────────────────────────────────────────────────────────┐
│ ☁️ 2. SERVERLESS CLOUD BACKEND     │ │ 💻 3. WEB DASHBOARD COMMAND CENTER (Cloudflare PWA)    │
│ • Supabase PostgreSQL 16 (JSONB)  │ │ • Esri World Imagery Satellite & OpenStreetMap GIS     │
│ • Deno Edge Function (Haversine)  │ │ • Live Fleet Radar & Telemetry HUD Vehicle Inspector   │
│ • Cloudflare R2 Media Storage     │ │ • Log Ritase, Filter Grade & Ekspor CSV               │
│ • Better Auth Enterprise Identity │ │ • Master Checkpoints (Radius Slider 20m-100m) & Admin  │
└───────────────────────────────────┘ └────────────────────────────────────────────────────────┘
```

---

## 2. Matriks Alur Lintas Platform (*Cross-Platform Flow Matrix*)

| ID Alur | Platform | Nama Layar / Modul | Konektivitas | Aksi / Pemicu Pengguna | Mutasi Data & Hasil State |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **MOB-01** | Mobile | Layar 1 — Login Akun Awal | 📶 Online Wajib | Input NIK/ID Driver + Kata Sandi saat di Camp | Generate JWT token, simpan sesi driver & PIN hash di SQLite lokal. |
| **MOB-02** | Mobile | Layar 2 — Quick PIN Unlock | 📴 Offline First | Input 6-Digit PIN pada keypad angka besar ($56\text{dp}$) | Verifikasi PIN hash lokal $\rightarrow$ Buka shift kerja tanpa butuh internet. |
| **MOB-03** | Mobile | Layar 3 — Beranda Auto-Detect | 📴 Offline First | GPS mendeteksi koordinat Pit Bahodopi ($\le 50\text{m}$) | Status geofence hijau aktif $\rightarrow$ Tombol "AMBIL FOTO MUAT & MULAI" terbuka. |
| **MOB-04** | Mobile | Layar 4 — Viewfinder 50m | 📴 Offline First | Driver menekan tombol shutter kamera 68dp | Jepret foto bak truk langsung via CameraX tanpa akses galeri HP. |
| **MOB-05** | Mobile | Layar 5 — Preview + Watermark | 📴 Offline First | Tekan tombol "GUNAKAN FOTO INI" | Render *Canvas Burn-in Watermark* ke piksel $\rightarrow$ Task ID otomatis terbuat (`status: IN_PROGRESS`). |
| **MOB-06** | Mobile | Layar 6 — Status Hauling Aktif | 📴 Offline First | Driver mengemudi dari Pit ke ROM Smelter | Perekaman koordinat senyap di background service ($v \ge 3\text{ km/jam}$, $\Delta \ge 50\text{m}$). |
| **MOB-07** | Mobile | Layar 7 — Antrean Sinkronisasi| 📶 Online Wajib | Tiba di Camp $\rightarrow$ Tekan "SINKRONKAN SEKARANG" | Upload foto WebP ke Cloudflare R2 $\rightarrow$ Kirim payload ke Supabase Edge Function (`status: SYNCED`). |
| **WEB-01** | Web PWA | Halaman 1 — Peta Armada Live | 📶 Online | Klik unit truk / toggle layer satelit | Render rute polyline hauling, lingkaran toleransi 50m, dan HUD Telemetri live. |
| **WEB-02** | Web PWA | Halaman 2 — Log Ritase | 📶 Online | Cari Task ID / Filter status / Klik Ekspor | Tabel audit kepatuhan, modal foto surveyor stamp, dan download data `.csv`. |
| **WEB-03** | Web PWA | Halaman 3 — Master Geofence | 📶 Online | Geser slider radius (20m-100m) / Tambah checkpoint | Simpan koordinat checkpoint tambang dan radius toleransi baru. |
| **WEB-04** | Web PWA | Halaman 4 — Manajemen Armada | 📶 Online | Filter status armada (Hauling, Loading, Standby) | Inspeksi muatan Tonase, BBM (%), odometer, dan operator aktif. |
| **WEB-05** | Web PWA | Halaman 5 — Pengaturan Admin | 📶 Online | Ganti data source (Simulator vs Supabase Cloud) | Konfigurasi URL Supabase, R2 Bucket, batas akurasi GPS shutter lock. |

---

## 3. Spesifikasi Detail Alur Mobile Client (7 Layar)

```text
[Alur Kerja Pengemudi di Lapangan]
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ Layar 1: LOGIN  │ ────▶ │ Layar 2: PIN    │ ────▶ │ Layar 3: HOME   │
│ (Di Camp Online)│       │ (Shift Harian)  │       │ (Auto-Detect)   │
└─────────────────┘       └─────────────────┘       └────────┬────────┘
                                                             │
                    ┌────────────────────────────────────────┘
                    ▼
┌─────────────────────────┐       ┌─────────────────────────┐       ┌─────────────────────────┐
│ Layar 4: VIEWFINDER     │ ────▶ │ Layar 5: PREVIEW STAMP  │ ────▶ │ Layar 6: HAULING AKTIF  │
│ (Interlock Radius 50m)  │       │ (Burn-in Watermark)     │       │ (K3 Silent Background)  │
└─────────────────────────┘       └─────────────────────────┘       └────────┬────────────────┘
                                                                             │ Tiba di ROM Smelter
                                                                             ▼
┌─────────────────────────┐       ┌─────────────────────────┐       ┌─────────────────────────┐
│ Layar 7: ANTREAN SYNC   │ ◀──── │ Layar 5: PREVIEW END    │ ◀──── │ Layar 4: VIEWFINDER END │
│ (Camp Wi-Fi Upload)     │       │ (Verifikasi Selesai)    │       │ (Foto Bongkar 50m)      │
└─────────────────────────┘       └─────────────────────────┘       └─────────────────────────┘
```

### 3.1 Layar 1 — Login Akun Awal (*Camp Online Required*)
- **Tujuan:** Autentikasi awal identitas driver dan penarikan master data titik tambang ke database SQLite lokal.
- **Komponen UI:** Field Driver ID/NIK (`DRV-001`), kata sandi, dan tombol amber *"MASUK AKUN (ONLINE)"*.
- **Logika Keamanan:** Menghasilkan token JWT Supabase dan menyimpan hash PIN untuk autentikasi offline shift harian.

### 3.2 Layar 2 — Quick PIN Unlock (*Offline First*)
- **Tujuan:** Membuka aplikasi secara instan setiap pergantian shift kerja tanpa memerlukan jaringan internet.
- **Komponen UI:** 6 indikator titik PIN, keypad angka besar berukuran $56 \times 56\text{ dp}$ (WCAG AAA High Contrast).
- **Logika Validasi:** Membandingkan hash PIN input dengan cache lokal di SQLite.

### 3.3 Layar 3 — Beranda Operasional Auto-Detect (*Offline First*)
- **Tujuan:** Menghilangkan beban driver memilih rute manual (*Zero-Click Routing*).
- **Komponen UI:** Kartu status auto-detect (misal: *"Lokasi: Pit Bahodopi North $\le 50\text{m}$"*), tombol amber raksasa *"📸 AMBIL FOTO MUAT & MULAI"*, dan kartu ringkasan antrean sinkronisasi.
- **Interlock Geofence:** Tombol otomatis terkunci (merah) jika driver berada $> 50\text{m}$ dari titik pit.

### 3.4 Layar 4 — Viewfinder 50m Geofence Lock (*Offline First*)
- **Tujuan:** Pengambilan foto bak truk secara langsung tanpa celah pemalsuan galeri.
- **Komponen UI:** Reticle bidik bak truk, banner deviasi jarak GPS real-time, dan tombol rana kamera $68\text{ dp}$.
- **Anti-Cheat:** Memblokir jepretan jika terdeteksi *Mock GPS* (`position.isMocked == true`) atau akurasi satelit $> 25\text{m}$.

### 3.5 Layar 5 — Preview Foto + Watermark Surveyor (*Offline First*)
- **Tujuan:** Menanamkan bukti visual permanen ke dalam piksel foto (*Canvas Burn-in*).
- **Komponen Watermark:**
  - Kotak putih solid (opacity 98%) di sudut bawah foto.
  - Peta mini vektor kontur $80 \times 96\text{ dp}$ dengan lingkaran toleransi 50m dan pin lokasi merah.
  - Jam merah monospaced presisi (*WITA UTC+8*).
  - Koordinat GPS (Lat, Lng) dan nilai akurasi satelit ($\pm 4.2\text{m}$).
  - Identitas driver dan nomor penugasan (*Task ID*).
- **Aksi:** Tombol *"GUNAKAN FOTO INI"* (membuat task baru dan menyalakan background tracking) vs *"FOTO ULANG (RETAKE)"*.

### 3.6 Layar 6 — Status Hauling Aktif (*K3 Silent Tracking*)
- **Tujuan:** Perekaman rute 100% senyap di latar belakang tanpa animasi radar yang mengganggu fokus mengemudi di kabin truk.
- **Logika Telemetri:** *Stationary filter* mengabaikan getaran saat berhenti ($v < 3\text{ km/jam}$). Titik koordinat hanya dicatat jika armada berpindah $\ge 50\text{m}$ atau interval waktu $\ge 30\text{ detik}$.
- **Deteksi Tiba di Titik Bongkar:** Saat GPS mendeteksi posisi berada di ROM Smelter Port ($\le 50\text{m}$), tombol *"FOTO BONGKAR (SELESAI)"* otomatis aktif.

### 3.7 Layar 7 — Antrean Sinkronisasi Mandiri (*Camp Online Required*)
- **Tujuan:** Pengiriman data tugas dan foto bukti ke cloud secara batch saat driver kembali ke area camp bersinyal stabil.
- **Komponen UI:** Daftar ritase dalam bahasa manusia tanpa istilah teknis yang membingungkan (*"Ritase #1: Pit Bahodopi ➔ ROM Smelter 1 [SIAP]"*), progress bar, dan tombol *"SINKRONKAN SEKARANG"*.
- **Penyimpanan Berkas:** Foto tersimpan permanen di perangkat untuk keperluan audit historis tanpa penghapusan otomatis.

---

## 4. Spesifikasi Web Dashboard Command Center

```text
[Arsitektur Layar Web Dashboard Admin]
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ TOP NAVBAR: [Toggle Sidebar]  Judul Halaman      (• Live Telemetry) [☀️/🌙] [Admin ▾]  │
├─────────────┬──────────────────────────────────────────────────────────────────────────┤
│ SIDEBAR:    │ AREA KONTEN AKTIF (5 HALAMAN UTAMA):                                     │
│ 🗺️ Peta Live│ 1. PETA ARMADA LIVE: Leaflet Satellite/GIS + Live Radar + Telemetry HUD  │
│ 📋 Log Rit  │ 2. LOG RITASE & KEPATUHAN: Multi-Filter Search + Ekspor CSV + Modal Foto │
│ 📍 Geofence │ 3. MASTER GEOFENCE: Checkpoints List + Slider Radius 20m-100m + CRUD     │
│ 🚚 Armada   │ 4. MANAJEMEN ARMADA: Grid Kartu Unit Truk + Odo + BBM + Status Muatan    │
│ ⚙️ Settings │ 5. PENGATURAN ADMIN: Cloud Connector (Supabase/R2) + Toleransi Geofence  │
└─────────────┴──────────────────────────────────────────────────────────────────────────┘
```

### 4.1 Halaman 1 — Peta Armada Live & Telemetri HUD
- **Engine Peta:** Leaflet.js dengan dukungan dual layer:
  - **Satelit Topografi:** Esri World Imagery resolusi tinggi + label jalan & desa.
  - **Peta Vektor:** OpenStreetMap Standard dengan jaringan jalan tambang dan kawasan industri Morowali lengkap.
- **Jaringan Jalan Hauling (*Haul Roads Network*):** Garis koridor jalan resmi dari Pit Bahodopi, turunan switchback RL +180m, jembatan timbang, hingga pelabuhan smelter.
- **Inspektor Telemetri Truk (HUD Drawer):** Klik pada marker truk di peta (misal `DT-104 [45.2T]`) memunculkan drawer telemetri live (kecepatan GPS, berat muatan, grade bijih nikel, suhu mesin, tekanan ban, dan konsumsi BBM).

### 4.2 Halaman 2 — Log Ritase & Audit Kepatuhan
- **Pencarian & Filter Multi-Kriteria:** Filter berdasarkan Task ID, nama driver, nomor unit, status verifikasi geofence, dan grade material (*Saprolite / Limonite*).
- **Ekspor CSV:** Tombol 1-klik untuk mengunduh seluruh rekap ritase harian ke berkas `.csv`.
- **Modal Verifikasi Bukti:** Menampilkan perbandingan foto muat dan foto bongkar beserta kalkulasi deviasi radius Haversine terhadap batas toleransi 50m.

### 4.3 Halaman 3 — Master Geofence Pit & ROM
- **Manajemen Checkpoint:** Menampilkan daftar titik pit, ROM, smelter, dan disposal.
- **Modal Tambah/Edit Checkpoint:** Form penambahan titik baru dengan input koordinat Lat/Lng dan slider toleransi radius 20m hingga 100m.

### 4.4 Halaman 4 — Manajemen Armada Truk
- **Kartu Status Armada:** Menampilkan detail unit (DT-101 s/d DT-115), tipe kendaraan (*Scania P410 XT, Volvo FMX 440, Mercedes-Benz Actros*), kapasitas muatan (40–45 Ton), odometer, level bahan bakar (%), dan operator aktif.

### 4.5 Halaman 5 — Pengaturan Sistem (Admin Control)
- **Data Source Switcher:** Beralih instan antara mode *Simulator Offline Lokal* dan *Supabase PostgreSQL Cloud*.
- **Konfigurasi Kredensial:** Input URL Supabase, Anon Key, Service Role Key, dan nama bucket Cloudflare R2.
- **Parameter Kepatuhan:** Slider radius geofence default (50m) dan batas akurasi GPS shutter lock (25m).

### 4.6 Laman Login Mandiri (*Dedicated Login Page*)
- **Akses Eksklusif Admin:** Khusus untuk Head Mine Dispatcher & Superadmin.
- **Branding Better Auth:** Form login username/email admin (`admin.morowali@terrapoint.mine`) dan kata sandi dengan transisi layar mulus.

---

## 5. Kontrak Data Cloud & Protokol Sinkronisasi

### 5.1 Endpoint Sinkronisasi Ritase Selesai (`POST /functions/v1/sync-task-complete`)
Edge Function Deno/TypeScript memvalidasi radius geofence 50m menggunakan rumus Haversine sebelum data disimpan ke PostgreSQL:

```json
{
  "task_id": "TSK-MRO-20260918-001",
  "driver_id": "DRV-001",
  "title": "Hauling Pit Bahodopi ke ROM Smelter 1",
  "start_point": {
    "name": "Pit Bahodopi North (Bench +185 RL)",
    "lat": -2.812456,
    "lng": 122.143456,
    "radius": 50
  },
  "end_point": {
    "name": "ROM Smelter Stockpile 1 (Port Morowali)",
    "lat": -2.845000,
    "lng": 122.168000,
    "radius": 50
  },
  "evidences": {
    "start_photo": {
      "captured_lat": -2.812470,
      "captured_lng": 122.143460,
      "accuracy_meters": 4.2,
      "r2_url": "https://pub-r2.dev/evidences/TSK-001-START.png",
      "captured_at": "2026-09-18T08:05:22.000Z"
    },
    "end_photo": {
      "captured_lat": -2.845020,
      "captured_lng": 122.168010,
      "accuracy_meters": 4.5,
      "r2_url": "https://pub-r2.dev/evidences/TSK-001-END.png",
      "captured_at": "2026-09-18T08:27:45.000Z"
    }
  },
  "actual_route": [
    {"lat": -2.812456, "lng": 122.143456, "spd": 32.1, "t": 1790409922000},
    {"lat": -2.828200, "lng": 122.153100, "spd": 34.2, "t": 1790410500000},
    {"lat": -2.845000, "lng": 122.168000, "spd": 18.0, "t": 1790411265000}
  ]
}
```

---

## 6. Mekanisme Keamanan, Anti-Cheat & K3 Tambang

1. **Pencegahan Pemalsuan Lokasi (*Mock GPS Defense*):**
   - SDK geolokasi memeriksa status `isMocked`. Jika bernilai `true`, koordinat langsung ditolak oleh sistem.
2. **Integritas Waktu Perangkat (*Time Spoofing Defense*):**
   - Waktu pada watermark dicatat menggunakan format TrueTime UTC+8 (WITA) yang diselaraskan dengan server time offset untuk mencegah manipulasi jam HP lokal.
3. **K3 Bebas Distraksi Mengemudi (*Zero-Distraction In-Cab*):**
   - Layar ponsel pengemudi selama perjalanan dalam status tenang tanpa animasi radar atau peta bergerak yang dapat memicu insiden keselamatan di jalan hauling tambang aktif.
