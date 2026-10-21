# TerraPoint — Mining Fleet Telematics & Compliance Platform

Platform kepatuhan, audit rute hauling, dan verifikasi bukti visual operasional pertambangan nikel berbasis verifikasi geospasial presisi, kamera geotag watermark offline-first, jembatan timbang (*Weighbridge*), dan monitoring armada berbasis jenis roda kendaraan.

---

## 🚀 Tautan Akses & Pengujian Klien (Tanpa VPN)

| Layanan / Komponen | Tautan Akses Publik (HTTPS) | Status Live |
|---|---|---|
| **🌐 Web Command Center Dispatcher** | **[Buka Web Dashboard](https://affect-gary-begins-systematic.trycloudflare.com/)** | ✅ `Online` (Port 8000) |
| **📥 Unduh APK Driver Android** | **[Download APK (55.9 MB)](https://affect-gary-begins-systematic.trycloudflare.com/terrapoint.apk)** | ✅ `Release Ready` |
| **📸 Galeri Antarmuka Mobile (8 Layar)**| **[Lihat Galeri Screenshots](https://affect-gary-begins-systematic.trycloudflare.com/screenshots/)** | ✅ `Retina 2x` |
| **⚙️ Healthcheck REST API** | **[Cek Status Server](https://affect-gary-begins-systematic.trycloudflare.com/health)** | ✅ `200 OK` |
| **📑 Daftar IP & Jaringan Lengkap** | **[docs/LIST_IP.md](./docs/LIST_IP.md)** | Topologi Tailscale & NOC |
| **📋 Daftar Seluruh REST API Endpoint**| **[docs/LIST_API.md](./docs/LIST_API.md)** | Request & Response Docs |

---

## 🔑 Akun Demo Pengujian (Login Credentials)

### 1. Aplikasi Mobile Driver (Android)
- **ID Pengemudi:** `DRV-001` (Ahmad Fauzi — *6 Roda Jumbo*)
- **ID Pengemudi:** `DRV-002` (Budi Santoso — *10 Roda Tronton*)
- **ID Pengemudi:** `DRV-003` (Hendra Saputra — *6 Roda Jumbo*)
- **PIN Shift Default:** `123456`

### 2. Web Command Center (Dispatcher Tambang)
- **Email / Username:** `ahmad.fauzi@terrapoint.id`
- **Kata Sandi:** `admin123456`
- **Peran:** Head Mine Dispatcher

### 3. Superadmin NOC (Infrastruktur Data Center)
- **Email / Username:** `nocadmin@terrapoint.noc`
- **Kata Sandi:** `P9x_NocData2026_Secure`
- **Peran:** Superadmin NOC / Server Lead

---

## 📂 Struktur Monorepo Terkonsolidasi

Struktur proyek diatur murni menjadi 3 folder inti di depan:

```
terrapoint/
├── 📱 frontend/            --> [SEMUA APLIKASI KLIEN / ANTARMUKA]
│   ├── mobile/             --> Aplikasi Android Flutter (Pengemudi Truk)
│   │   ├── lib/            --> Source code Dart (Clean Modern Architecture)
│   │   ├── android/        --> Konfigurasi Gradle & AndroidManifest Permissions
│   │   └── build/          --> Output binary APK rilis (55.9 MB)
│   │
│   └── web/                --> Web Command Center PWA Leaflet (Dispatcher & NOC Admin)
│       ├── index.html      --> Single-Page Web Dashboard
│       ├── css/styles.css  --> Mining Slate Dark / Light Theme
│       ├── js/             --> JavaScript Engine (app.js, map_service.js, icons.js)
│       ├── screenshots/    --> Galeri dokumentasi visual 8 layar mobile
│       └── terrapoint.apk  --> File installer Android siap unduh
│
├── ⚙️ backend/             --> [REST API SERVICE & DATABASE MIGRATIONS]
│   ├── src/                --> Express API Engine (Bun 1.4.3 Runtime)
│   │   ├── index.js        # Entry point server (Port 8000), security headers, static host
│   │   ├── db.js           # PostgreSQL connection pool (pg.Pool)
│   │   ├── utils/          # Haversine distance calculator & Log Catcher engine
│   │   └── routes/         # auth.js, dashboard.js, sync.js, upload.js
│   │
│   ├── migrations/         --> SQL Schema Migrations PostgreSQL 17
│   │   ├── 000001_init_schema.up.sql       # Inisialisasi skema dasar
│   │   └── 000002_project_based_trips.up.sql # Proyek hauling, armada roda, trips
│   └── package.json        --> Dependensi Bun / Node.js
│
├── 📑 docs/                --> [ARSIP & SPECS] Disimpan rapi di belakang:
│   ├── LIST_IP.md          --> Daftar lengkap IP Publik, Tailscale, & Subnet NOC
│   ├── LIST_API.md         --> Kamus lengkap seluruh endpoint REST API
│   ├── specs/              --> PRD v6.1, Technical Design v6.0, dan Roadmap
│   ├── designs/            --> Mockup artboard HTML & script renderer
│   ├── server_infra/       --> Nginx config, Docker compose, SSL template
│   └── flow-assets/        --> Dokumentasi diagram alur & PDF
│
└── 📄 README.md            --> Panduan operasional & arsitektur proyek
```

---

## 🛠️ Fitur Utama Sistem

### 1. 📱 Mobile Driver App (Flutter Android)
- **Strict Permission Gate:** Memblokir akses masuk aplikasi jika izin sensor Kamera & Satelit GPS belum diberikan supir.
- **Sensor GPS Satelit Riil 100% Offline:** Membaca koordinat lintang/bujur langsung dari antena satelit GNSS smartphone tanpa butuh koneksi internet di blank spot pit tambang.
- **Canvas Watermark & Downscaling:** Citra kamera beresolusi tinggi otomatis di-downscale ke lebar maksimal `1280 px` (~180 KB) dengan stempel waktu WITA, koordinat GPS, dan tag lokasi yang dibakar permanen ke piksel foto.
- **Konfirmasi Sesi Roda Fleksibel:** Pengemudi dapat memilih armada (`4 Roda`, `6 Roda`, `6 Roda Jumbo`, `10 Roda`) sebelum mulai muat, dan armada terkunci rapat selama hauling berjalan (*anti-fraud lock*).
- **Sistem 4 Cards Tanpa Nomor Berurutan:**
  1. `Titik Muat (Pit)`: Pengambilan foto muatan ore di pit (toleransi radius luas 250m).
  2. `Titik Bongkar (Curah ROM)`: Pengambilan foto fisik bak truk curah di ROM stockpile (toleransi ketat &le; 40m).
  3. `Foto Nota Timbang / Invoice`: Terbuka *hanya* setelah dumping selesai; pengambilan foto lembar slip timbangan jembatan timbang (*Weighbridge*).
  4. `Riwayat Foto Hari Ini`: Menampilkan riwayat seluruh trip dengan 3 foto bukti lengkap berdampingan (Muat, Bongkar, Nota).

### 2. 🌐 Web Dispatcher Command Center (PWA Leaflet)
- **Warna Neon Unik Per Driver di Peta:** Setiap pengemudi memiliki identitas warna visual khas (*glow marker* dan lintasan rute polyline) di peta satelit Leaflet.
- **Manajemen Proyek Hauling (Task per Project):** Dispatcher dapat mengonfigurasi proyek dengan 1 titik muat (radius luas) dan 1 titik bongkar (radius ketat) yang dapat diubah toleransinya secara dinamis.
- **Log Catcher Terpusat (`● System & Error Log Catcher`):** Tab pemantauan error server secara live dari browser tanpa perlu membuka terminal SSH Linux.
- **Audit Bukti 3 Foto:** Modal verifikasi menampilkan perbandingan foto muatan pit, foto fisik curah, dan foto slip timbangan untuk pengesahan pembayaran kontraktor.

### 3. ⚙️ Backend REST API (Bun & PostgreSQL 17)
- **Runtime Bun 1.4.3:** Eksekusi super cepat (< 10ms startup) dengan konsumsi RAM sangat hemat di Debian 13 VPS.
- **PostgreSQL 17 Database:** Skema relasional ACID kuat dengan partisi tabel bulanan range dan indeks komposit B-Tree pada tabel `project_trips`.
- **Security Hardening:** Kredensial `.env` dikunci `chmod 600`, port PostgreSQL/Redis terisolasi di internal bridge, dan proteksi security headers (`nosniff`, `SAMEORIGIN`, `XSS Protection`).

---

## ⚡ Panduan Operasional Server (Cheatsheet)

### 1. Remote SSH ke Server VPS (via Tailscale)
```bash
ssh terrapoint@100.89.207.92
# atau menggunakan nama host Tailnet:
ssh terrapoint@terrapoint-backend
```
- **Password:** `Terrapoint2026!Dev` *(sudo penuh)*

### 2. Perintah Manajemen Service di VPS
```bash
# Cek status service backend API
sudo systemctl status terrapoint

# Restart backend service
sudo systemctl restart terrapoint

# Memantau log service secara live (real-time stream)
sudo journalctl -u terrapoint -f

# Cek status terrapoint Cloudflare public tunnel
sudo systemctl status terrapoint-tunnel

# Tes konektivitas API lokal
curl http://127.0.0.1:8000/health
```

---

## 📑 Daftar Dokumen Referensi Lengkap

- 📄 **[docs/specs/prd.md](./docs/specs/prd.md)** — *Product Requirement Document (PRD v6.1)*
- 📄 **[docs/specs/tech_design.md](./docs/specs/tech_design.md)** — *Technical Design Document (TDD v6.0)*
- 📄 **[docs/specs/api_spec.md](./docs/specs/api_spec.md)** — *RESTful API Specification v6.0*
- 📄 **[docs/LIST_IP.md](./docs/LIST_IP.md)** — *Daftar Alamat IP & Inventaris Jaringan*
- 📄 **[docs/LIST_API.md](./docs/LIST_API.md)** — *Daftar Lengkap Endpoint REST API*
- 📄 **[docs/specs/development_roadmap.md](./docs/specs/development_roadmap.md)** — *Milestone & Roadmap Proyek*
