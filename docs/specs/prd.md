# Product Requirement Document (PRD) — TerraPoint Enterprise

---

**Nama Produk:** TerraPoint
**Deskripsi Singkat:** Sistem audit kepatuhan rute hauling pertambangan nikel, verifikasi geospasial presisi, telematika armada per-jenis roda, dan bukti visual multi-tahap (Muat, Bongkar, & Weighbridge Slip) berbasis *offline-first*.
**Sektor Industri:** Mining Logistics, Heavy Equipment Operations & Compliance
**Versi Dokumen:** 5.0 (Enterprise Architecture: Project-Based Hauling, 4-Cards State Machine, Weighbridge Slip Verification, Driver Wheel-Type Management, Self-Hosted Debian VPS + Bun & PostgreSQL 17)
**Status:** Approved for Implementation & Production Active

---

## 1. Ringkasan Eksekutif & Sasaran Produk

### 1.1 Latar Belakang Masalah
Operasional transportasi hauling tambang mineral/nikel (*Pit to ROM Stockpile*) menghadapi tantangan lingkungan dan regulasi:
1. **Area Blank Spot Lapangan:** Koridor pit tambang dan jalur hauling sering kali tidak memiliki koneksi internet stabil (blank spot).
2. **Kepatuhan Muatan & Jembatan Timbang (Weighbridge):** Sering terjadi ketidaksesuaian antara material yang dimuat di pit dengan slip nota timbangan resmi yang dicatat di jembatan timbang ROM.
3. **Penyalahgunaan Titik Bongkar:** Pembongkaran material di luar area stockpile resmi tanpa validasi geofence yang presisi.
4. **Beban Kognitif Driver di Kabin Truk:** Pengemudi membutuhkan alur kerja yang sangat sederhana tanpa penomoran membingungkan, tanpa kartu unit truk yang memenuhi layar, dan dengan urutan aksi yang terkunci aman (tidak bisa klik bongkar sebelum muat selesai).
5. **Kebutuhan Dispatcher:** Dispatcher tidak memerlukan status armada statis/tonase rumit, melainkan identitas jenis roda kendaraan (`4 Roda`, `6 Roda`, `10 Roda`, `12 Roda`), akumulasi jumlah pengantaran harian, dan pembedaan warna visual setiap driver di peta live satelit.

### 1.2 Pernyataan Solusi Produk
**TerraPoint** menyediakan ekosistem terpadu yang memadukan aplikasi mobile driver yang disimplifikasi total dan web command center dispatcher:
1. **Model Penugasan Berbasis Proyek (Task per Project):**
   - 1 Proyek mendefinisikan rute jangka panjang: **1 Titik Muat (Pit)** dengan toleransi radius luas (default 250m s.d. 600m untuk kebebasan manuver) dan **1 Titik Bongkar (ROM Stockpile)** dengan radius ketat (&le; 40m).
2. **Sistem 4 Cards Tanpa Nomor dengan Strict State Lock (Mobile):**
   - **Card Titik Muat (Pit):** Ambil foto muatan bak truk ore (+ Watermark GPS).
   - **Card Titik Bongkar (Curah ROM):** Terbuka setelah muat, ambil foto fisik bak truk curah di stockpile (&le; 40m).
   - **Card Foto Nota Timbang / Invoice:** Terbuka setelah dumping, ambil foto lembar fisik slip timbangan jembatan timbang (*Weighbridge*).
   - **Card Riwayat Foto Hari Ini:** Merangkum 3 bukti foto lengkap berdampingan (Muat, Bongkar, Nota).
3. **Fleksibilitas Jenis Roda Mobil:**
   - Driver dapat memilih dan mengganti jenis armada kapan saja (`4 Roda`, `6 Roda`, `10 Roda`, `12 Roda`) di awal trip maupun via header.
4. **Warna Unik Per Driver di Peta Satelit (Web Command Center):**
   - Setiap driver memiliki warna neon khas di peta Leaflet sehingga dispatcher dapat membedakan posisi armada secara instan.
5. **Offline-First dengan Auto-Sync & Toleransi Geofence:**
   - Foto dan data trip disimpan lokal jika di blank spot dan disinkronkan otomatis begitu sinyal pulih. Jika driver berada sedikit di luar radius (karena antrean), sistem mengizinkan pengambilan foto dengan penandaan otomatis (*flagging/peringatan*) untuk diaudit dispatcher.
6. **Retensi Penyimpanan 30 Hari:**
   - Foto bukti disimpan selama 30 hari di storage MinIO S3 server sebelum diarsipkan.

---

## 2. Arsitektur Sistem & Tech Stack

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                     FRONTEND MOBILE (Flutter Android Client)                     │
│  • Framework Engine   : Flutter 3.24+ (Dart)                                     │
│  • Local Storage      : LocalStorageVault (Reactive State Machine & Cache)       │
│  • Camera Engine      : CameraX plugin + Canvas Watermark Geotag Surveyor        │
│  • State Machine Flow : Strict 4-Cards (Muat ➔ Bongkar ➔ Nota ➔ Riwayat)          │
│  • Offline Policy     : Store & Auto-Sync saat terhubung sinyal                  │
└────────────────────────────────────────┬─────────────────────────────────────────┘
                                         │ REST API / HTTP (JSON + Multipart)
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                   BACKEND API SERVER (Debian VPS Private Cloud)                  │
│  • Host & Runtime     : Debian 13 (Trixie) 64-bit • Bun 1.4.3 / Express          │
│  • Service Engine     : systemd (terrapoint.service) pada Port 8000              │
│  • Database Engine    : PostgreSQL 17 (10.10.10.2:5432/terrapoint)               │
│  • Media Storage      : MinIO S3 Bucket (10.10.10.2:9000/terrapoint-assets)      │
│  • Geofence Algorithm : Haversine Great-Circle Formula (Presisi meter)           │
└────────────────────────────────────────┬─────────────────────────────────────────┘
                                         │ Static PWA & REST API Stream
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                FRONTEND WEB (Dispatcher Operations Command Center)               │
│  • Architecture       : Single Page Application (HTML5, ES Modules, CSS Vars)    │
│  • Mapping Engine     : Leaflet.js dengan Tile Esri Satellite & GIS Dark         │
│  • Visual Identitas   : Palet Neon Unik per Driver pada Marker & Rute            │
│  • KPI Bar            : Akumulasi Trip Harian & Distribusi Jenis Roda Kendaraan │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Spesifikasi Fungsional Komponen

### 3.1 Mobile App Driver (`frontend/mobile/`)

#### A. Autentikasi Driver
- Driver memasukkan ID Pengemudi (`DRV-001`, `DRV-002`, dst.) dan PIN Shift (default `123456`).
- Mendapatkan token JWT yang berlaku selama shift kerja.

#### B. Header & Counter Akumulasi Harian
- Nama Pengemudi, ID Driver, dan Nama Proyek.
- **Badge Roda Truk:** Menampilkan jenis roda aktif (`4 Roda`, `6 Roda`, `10 Roda`, `12 Roda`) yang dapat di-tap untuk membuka pilihan armada.
- **Indikator GPS Kanan Atas:** Chip presisi satelit aktif `GPS ±3.8m` dengan pulsing dot hijau.
- **Counter Trip:** Akumulasi murni pengantaran hari ini (`X TRIP SELESAI`).

#### C. Card Titik Muat (Pit)
- Menampilkan nama loading point dan toleransi radius luas (default 250m).
- Selector armada cepat sebelum membidik kamera.
- Tombol: **Ambil Foto Muatan di Pit**.
- Hasil foto dibubuhi watermark: waktu WITA, koordinat GPS, elevasi RL, dan tag `[TITIK MUAT (PIT)]`.
- Setelah foto diambil, status menjadi `✓ MUATAN TERCATAT` dan terkunci agar tidak terjadi muat ganda.

#### D. Card Titik Bongkar (Curah ROM)
- Terkunci gembok saat awal trip. Terbuka hanya setelah Card Titik Muat selesai.
- Menampilkan nama ROM Stockpile dan radius ketat (&le; 40m).
- Tombol: **Ambil Foto Fisik Bongkar ROM**.
- Membidik bak dump truck yang selesai mencurahkan ore di stockpile.
- Watermark geotag: `[1. FOTO BONGKAR]`.

#### E. Card Foto Nota Timbang / Invoice
- Terkunci gembok sampai foto dumping di ROM selesai diambil.
- Tombol: **Ambil Foto Nota Timbang & Selesaikan**.
- Kamera mode dokumen membidik slip nota fisik dari jembatan timbang (*Weighbridge*).
- Watermark geotag: `[2. NOTA / SURAT JALAN]`.
- Begitu foto nota terkirim, trip berstatus `COMPLETED`, trip counter bertambah +1, dan Card Titik Muat kembali siap untuk trip berikutnya.

#### F. Card Riwayat Foto Hari Ini
- Menampilkan seluruh pengantaran hari ini secara kronologis.
- Setiap trip menyajikan **3 foto bukti berdampingan**:
  1. `Muat Pit` (Thumbnail & Waktu WITA)
  2. `Bongkar ROM` (Thumbnail & Waktu WITA)
  3. `Nota Timbang` (Thumbnail slip jembatan timbang)
- Tap pada foto untuk membuka preview resolusi penuh.

---

### 3.2 Web Dispatcher Command Center (`frontend/web/`)

#### A. Peta Operasional Satelit dengan Warna Unik Driver
- Peta Leaflet memetakan posisi seluruh armada hauling secara live.
- Setiap driver memiliki **warna neon khas** (Cobalt Blue, Emerald Green, Amber Gold, Magenta Pink, Violet, Cyan, dll.).
- Marker di peta menampilkan border neon berbayang (*glow*), label jenis roda `[6 Roda]`, dan nama driver.
- Garis rute lintasan (*polyline*) otomatis mengikuti warna driver terkait.

#### B. KPI Bar Berbasis Roda Kendaraan & Trip
- **Total Pengantaran Hari Ini** (Akumulasi seluruh proyek).
- **Truk 6 Roda (Dump Truck Standar):** X Trip selesai.
- **Truk 10 Roda (Tronton Heavy):** X Trip selesai.
- **Truk 12 Roda (Trailer Heavy):** X Trip selesai.

#### C. Manajemen Proyek Hauling (Task per Project)
- Dispatcher dapat membuat proyek baru:
  - 1 Titik Muat (Radius Luas, range 100m – 600m).
  - 1 Titik Bongkar (Radius Ketat, range 20m – 100m).
  - Menugaskan daftar driver ke proyek.
  - Mengubah radius toleransi secara dinamis kapan saja.

#### D. Kontrol Akun Driver & Penggantian Roda
- Tabel manajemen driver dengan kontrol status akun (`Aktif (Bisa Login)` / `Nonaktif (Diblokir)`).
- Tombol **Ubah Roda**: Memungkinkan dispatcher mengubah jenis roda armada driver langsung dari dashboard.

#### E. Log Pengantaran & Modal Verifikasi 3 Foto
- Tabel riwayat trip dengan status verifikasi, jam muat, jam bongkar, dan deviasi GPS.
- Modal audit menampilkan 3 kartu bukti visual: Foto Muat Pit, Foto Bongkar ROM, dan Foto Nota Timbang Weighbridge.

---

## 4. Skema Database PostgreSQL 17 (`backend/migrations/`)

### 4.1 Tabel `projects`
- `project_id` (PK, VARCHAR)
- `project_name` (VARCHAR)
- `client_name` (VARCHAR)
- `start_location_id`, `start_point_name`, `start_lat`, `start_lng`, `start_radius_meters` (INTEGER, default 250)
- `end_location_id`, `end_point_name`, `end_lat`, `end_lng`, `end_radius_meters` (INTEGER, default 40)
- `is_active` (BOOLEAN)

### 4.2 Tabel `project_trips`
- `trip_id` (PK, VARCHAR)
- `project_id` (FK to projects)
- `driver_id` (FK to drivers)
- `truck_wheel_type` (VARCHAR: `6 Roda (Dump Truck)`, dsb.)
- `trip_sequence` (INTEGER)
- `load_photo_url`, `load_lat`, `load_lng`, `load_deviation_m`, `load_at` (TIMESTAMPTZ)
- `dump_photo_url`, `dump_lat`, `dump_lng`, `dump_deviation_m`, `dump_at` (TIMESTAMPTZ)
- `invoice_photo_url` (TEXT - Foto Nota / Slip Weighbridge)
- `status` (VARCHAR: `IN_TRANSIT`, `COMPLETED`, `FLAGGED`)
- `completed_at` (TIMESTAMPTZ)

### 4.3 Tabel `drivers`
- `driver_id` (PK, VARCHAR)
- `full_name`, `phone_number`, `pin_hash`
- `truck_wheel_type` (VARCHAR)
- `assigned_project_id` (VARCHAR)
- `is_active` (BOOLEAN)

---

## 5. Keputusan Non-Fungsional & Kebijakan Operasional

1. **Kebijakan Offline (Blank Spot):**
   - Aplikasi mobile wajib mengizinkan penyimpanan foto secara lokal saat jaringan seluler hilang. Sinkronisasi dilakukan otomatis (*background retry*) saat perangkat kembali mendeteksi sinyal internet.
2. **Toleransi Geofence & Antrean Truk (Flagging):**
   - Jika pengemudi berada di luar radius toleransi (misalnya karena antrean truk panjang di pit atau ROM), foto tetap dapat diambil agar operasional tidak terhenti, namun trip otomatis diberi penandaan status **`FLAGGED / PERLU REVIEW`** pada dashboard dispatcher.
3. **Validasi Nota Timbang:**
   - Cukup mengandalkan foto fisik nota timbang jembatan timbang dengan stempel watermark permanen tanpa mewajibkan pengemudi mengetik manual nomor tiket di kabin truk.
4. **Retensi Berkas Bukti:**
   - Seluruh foto bukti dipertahankan selama **30 hari** di penyimpanan aktif MinIO S3 sebelum dipindahkan ke arsip dingin.
