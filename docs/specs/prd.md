# Product Requirement Document (PRD) — TerraPoint Enterprise

---

**Nama Produk:** TerraPoint
**Deskripsi Singkat:** Sistem audit kepatuhan rute hauling pertambangan nikel, verifikasi geospasial presisi, telematika armada per-jenis roda, dan bukti visual multi-tahap (Muat, Bongkar, & Weighbridge Slip) berbasis *offline-first*.
**Sektor Industri:** Mining Logistics, Heavy Equipment Operations & Compliance
**Versi Dokumen:** 6.0 (Enterprise Architecture: Multi-Tenant Ready, Strict Sequential 4-Cards, Weighbridge Verification, Wheel-Type Rate Billing, Client-Side WebP Compression, Monthly Partitioned PostgreSQL 17 on Debian VPS)
**Status Dokumen:** Approved for Implementation & Production Active

---

## 1. Visi Produk, Model Bisnis & Arsitektur Solusi

### 1.1 Latar Belakang & Masalah Lapangan
Operasional logistik dan transportasi hauling tambang mineral/nikel (*Pit to ROM Stockpile*) menghadapi tantangan regulasi, keselamatan kerja, dan integritas finansial:
1. **Area Blank Spot Lapangan:** Koridor pit tambang dan jalur hauling sering kali tidak memiliki koneksi internet stabil (blank spot).
2. **Kecurangan & Ketidaksesuaian Pembayaran Kontraktor:** Praktik manipulasi jumlah ritase, pemalsuan jam kerja, atau perbedaan data antara material yang dimuat di pit dengan slip nota timbangan resmi yang dicatat di jembatan timbang (*Weighbridge*).
3. **Penyalahgunaan Titik Bongkar (Dumping Violation):** Pembongkaran material di luar area stockpile resmi tanpa validasi geofence yang presisi.
4. **Beban Kognitif Driver di Kabin Truk:** Pengemudi membutuhkan antarmuka yang sangat ringkas tanpa nomor kartu yang membingungkan, tanpa kartu unit truk yang memenuhi layar, dan dengan urutan aksi yang terkunci aman (tidak bisa klik bongkar sebelum muat selesai).
5. **Kebutuhan Dispatcher & Manajemen:** Dispatcher tidak memerlukan status armada statis yang rumit, melainkan identitas jenis roda kendaraan (`4 Roda`, `6 Roda`, `10 Roda`, `12 Roda`), akumulasi jumlah pengantaran harian murni, dan pembedaan warna visual setiap driver di peta live satelit.

### 1.2 Model Bisnis & Keuangan (Business Side)
1. **Model Tarif Pembayaran (Pricing Model):**
   - Pembayaran antara pemilik tambang (klien) dan kontraktor armada dihitung menggunakan **Tarif Flat Per-Trip Berdasarkan Kategori Roda Kendaraan**:
     - Kategori 1: `4 Roda (Pick-up / Engkel)` &rarr; Tarif Ritase Ringan
     - Kategori 2: `6 Roda (Dump Truck Standar)` &rarr; Tarif Ritase Sedang
     - Kategori 3: `10 Roda (Tronton Heavy)` &rarr; Tarif Ritase Berat
     - Kategori 4: `12 Roda (Trailer Heavy / Gandeng)` &rarr; Tarif Ritase Kapasitas Maksimal
   - Setiap trip yang sah diverifikasi oleh 3 dokumen foto (Muat Pit, Curah ROM, dan Nota Timbang) sebagai bukti pembayaran invoice bulanan yang sah (*proof of delivery*).
2. **Arsitektur Multi-Tenant Kontraktor:**
   - Platform mendukung banyak vendor kontraktor hauling berbeda dalam satu sistem. Setiap vendor/kontraktor memiliki isolasi data melalui `tenant_id` dan pengelompokan armada.
3. **Alur Penyelesaian Dispute & Persetujuan Manual (Dispute & Approval Workflow):**
   - Trip yang terdeteksi berada di luar batas toleransi geofence (misalnya akibat antrean truk panjang di pit atau ROM) tetap dapat diselesaikan agar operasional tidak terhenti, namun secara otomatis diberi tanda **`FLAGGED / PERLU TINJAUAN`**.
   - Trip berstatus `FLAGGED` secara otomatis **ditahan dari rekapan tagihan (*Pending Audit*)** sampai Dispatcher / Supervisor melakukan evaluasi bukti visual dan mengklik `Approve` atau `Reject` di Web Dashboard.

---

## 2. Logika Operasional & State Machine (Logic Side)

### 2.1 Alur 4 Cards Berurutan (Strict Sequential State Machine)
Aplikasi mobile dirancang menggunakan **4 Cards Mandiri Tanpa Nomor** dengan mekanisme kunci bertingkat:

```
[ Card: Titik Muat (Pit) ] 
       │ (Driver ambil foto muat di Pit 250m)
       ▼
[ Card: Titik Bongkar (Curah ROM) ] ── (Card Nota Timbang masih terkunci gembok)
       │ (Driver ambil foto fisik curah di ROM 40m)
       ▼
[ Card: Foto Nota Timbang / Invoice ] ── (Kunci Card Nota terbuka)
       │ (Driver ambil foto lembar slip timbangan)
       ▼
[ Card: Riwayat Foto Hari Ini ] ── (Trip selesai, counter +1, Card Muat siap kembali)
```

1. **Card Titik Muat (Pit):**
   - **Status Awal:** Aktif dengan status `SIAP AMBIL FOTO` dan selector jenis armada roda yang dapat diganti fleksibel.
   - **Toleransi Geofence:** Radius luas (default `250 meter` hingga `600 meter`) untuk mengakomodasi luasnya pit tambang dan manuver alat berat.
   - Setelah foto diambil, status menjadi `✓ MUATAN TERCATAT`, dan kartu terkunci agar driver tidak memuat ganda sebelum menyelesaikan pembongkaran.
2. **Card Titik Bongkar (Curah ROM):**
   - Terkunci saat truk kosong. Terbuka otomatis setelah foto muatan dicatat.
   - **Toleransi Geofence:** Radius ketat (&le; `40 meter`).
   - Driver mengambil **Foto 1: Fisik Pembongkaran Curah** membidik bak truk di ROM Stockpile.
   - **PENTING:** Card Foto Nota Timbang masih dalam kondisi **terkunci gembok** dengan instruksi: *"Kunci: Selesaikan foto pembongkaran curah di Card Titik Bongkar terlebih dahulu"*.
3. **Card Foto Nota Timbang / Invoice (Weighbridge):**
   - Kunci terbuka otomatis **HANYA setelah foto dumping curah selesai diambil**.
   - Driver mengambil **Foto 2: Lembar Fisik Slip Timbangan** dari pos jembatan timbang (*Weighbridge*) agar nomor seri dan data tonase terekam sah.
   - Begitu foto nota berhasil terkirim, trip berstatus `COMPLETED`, counter bertambah (+1 Trip Selesai), dan Card Titik Muat kembali terbuka untuk trip berikutnya.
4. **Card Riwayat Foto Hari Ini:**
   - Menampilkan daftar kronologis pengantaran hari ini.
   - Setiap trip merangkum **3 bukti foto lengkap berdampingan**:
     1. `Muat Pit` (Thumbnail & Waktu WITA)
     2. `Bongkar ROM` (Thumbnail & Waktu WITA)
     3. `Nota Timbang` (Thumbnail Slip Jembatan Timbang)
   - Tap pada thumbnail membuka dialog pratinjau foto resolusi penuh.

### 2.2 Kebijakan Operasional Khusus (Operational Policies)
1. **Durasi Perjalanan Bebas (Tanpa Batas Waktu SLA):**
   - Mengingat kondisi lapangan tambang yang dinamis (antrean panjang, *blasting* tambang, cuaca hujan lebat, atau jalan licin), trip dibiarkan aktif dalam perjalanan tanpa auto-timeout yang kaku sampai driver tiba di ROM dan menyelesaikan pembongkaran.
2. **Kunci Logout saat Membawa Muatan (Anti-Fraud Lock):**
   - Pengemudi yang sedang dalam status membawa muatan (`LOADED_NEED_DUMP` atau `DUMPED_NEED_INVOICE`) **dilarang logout dari aplikasi**. Driver awal wajib menyelesaikan pembongkaran dan foto nota sebelum sesi dapat dialihkan ke supir lain demi mencegah kecurangan dan hilangnya material di jalan hauling.
3. **Otoritas Pembatalan Trip (Void / Cancel Authority):**
   - Pengemudi di smartphone **tidak memiliki hak** untuk membatalkan trip yang sudah terlanjur difoto muat di Pit.
   - Hanya Dispatcher / Supervisor operasional di Web Command Center yang memiliki kewenangan membatalkan trip melalui tombol `Batalkan Tugas` disertai input alasan resmi (misal: truk breakdown di pit atau material salah muat).
4. **Counter Akumulasi Trip Harian Murni:**
   - Counter pada beranda mobile dan KPI dashboard menampilkan akumulasi murni (`X TRIP SELESAI`) per driver per shift tanpa kuota kaku, memberikan gambaran produktivitas riil di lapangan.

---

## 3. Arsitektur Teknologi & Infrastruktur (Tech Stack & Scaling)

### 3.1 Ringkasan Teknologi Terpadu

| Komponen | Teknologi Terpilih | Justifikasi & Keunggulan |
|---|---|---|
| **Mobile Client** | Flutter 3.24+ (`Dart`) | Kompilasi performa native AOT, rendering konsisten lintas Android, CameraX hardware integration. |
| **Penyimpanan Lokal** | `LocalStorageVault` (Reactive State Machine) | Arsitektur *offline-first*, zero dependency, instan reactive rebuild. |
| **Kompresi Gambar** | WebP Lossy Client-Side (Quality 80%, $\le 180\text{ KB}$) | Kompresi lokal sebelum upload; menghemat kuota $85\%$ dan menjamin pengunggahan lancar saat sinyal tipis (1–2 bar). |
| **Backend Runtime** | Bun 1.4.3 / Node.js + Express | Startup instan (< 10ms), hemat memori RAM pada VPS (cocok untuk spek 4 GB RAM), performa I/O tinggi. |
| **Database** | PostgreSQL 17 (Self-Hosted on Debian 13) | Skema relasional ACID kuat, dukungan partisi tabel bulanan, JSONB indexing, dan ekstensi geospasial Haversine. |
| **Telemetri Live** | REST Polling Teratur (Interval 8–15 Detik) + In-Memory Cache | Menjaga konsumsi baterai smartphone driver dan beban CPU server tetap sangat rendah dibanding koneksi WebSocket persisten yang mudah putus di area sinyal tambang. |
| **Object Storage** | MinIO S3 (Private Data Center `10.10.10.2:9000`) | Penyimpanan media mandiri berkecepatan tinggi tanpa biaya egress Cloudflare/AWS, retensi aktif 30 hari. |
| **Web Dashboard** | Single-Page Application (HTML5, ES Modules, CSS Vars, Leaflet.js) | Tanpa overhead framework berat (React/Vue build steps), beban memori browser ringan, responsif di resolusi laptop pengawas. |

### 3.2 Strategi Skala Database Skala Besar (PostgreSQL 17 Database Scaling)
Untuk menampung jutaan log trip dalam jangka panjang tanpa degradasi performa query:
1. **Partisi Tabel Bulanan (`Table Partitioning by Range`):**
   - Tabel `project_trips` dipartisi secara bulanan berdasarkan kolom `created_at` (misal: `project_trips_2026_10`, `project_trips_2026_11`).
   - Query dashboard untuk rentang tanggal tertentu hanya akan memindai partisi bulan terkait (*partition pruning*), menghasilkan waktu respon query tetap di bawah 25ms.
2. **Composite Indexing:**
   - Diterapkan indeks komposit B-Tree pada:
     - `(tenant_id, project_id, status)`
     - `(driver_id, created_at DESC)`
     - `(truck_wheel_type, status)`
3. **In-Memory Cache Telemetri:**
   - Endpoint summary telemetri menggunakan *in-memory cache* dengan Time-To-Live (TTL) 5 detik di server Bun untuk mencegah read-heavy query berulang ke PostgreSQL.

---

## 4. Spesifikasi Antarmuka & Visual Command Center

### 4.1 Identitas Visual Marker Peta Satelit (Warna Unik Driver)
Dispatcher dapat membedakan posisi masing-masing armada hauling secara instan tanpa perlu membaca teks detail:
- **Marker Peta Leaflet:** Setiap marker truk memiliki border neon bercahaya (*glow box-shadow*), titik status pulsing, dan label roda monospaced (misal: `[6] Ahmad Fauzi DT-01` berwarna ungu violet, `[10] Budi Santoso DT-02` berwarna hijau emerald, `[10] Hendra Saputra DT-03` berwarna magenta pink).
- **Palet Warna Aman:** Menggunakan palet distingtif (*Cobalt Blue, Amber Gold, Magenta Pink, Emerald Green, Violet, Cyan, Safety Orange, Teal*) yang di-hash dari ID driver sehingga warnanya tetap konsisten setiap kali dimuat.
- **Rute Polyline:** Garis lintasan GPS armada mengikuti warna khas driver yang bersangkutan.

### 4.2 Struktur Direktori Monorepo Terkonsolidasi
Sistem diatur dengan pemisahan direktori yang tegas:
```
terrapoint/
├── 📱 frontend/            --> [SEMUA APLIKASI KLIEN / ANTARMUKA]
│   ├── mobile/             --> Aplikasi Android Flutter (Pengemudi Truk)
│   └── web/                --> Web Command Center PWA Leaflet (Dispatcher & Admin NOC)
│
├── ⚙️ backend/             --> [REST API SERVICE & DATABASE MIGRATIONS]
│   ├── src/                --> Source code Express API (Node.js / Bun Runtime)
│   └── migrations/         --> SQL Schema Migrations PostgreSQL 17
│
├── 📑 docs/                --> [ARSIP & SPECS] Seluruh file pendukung disimpan di belakang:
│   ├── designs/            --> Artboard visual & script renderer
│   ├── specs/              --> PRD v6.0, Desain Teknis, API Spec, Guidelines, Roadmap
│   ├── server_infra/       --> Nginx config, Docker compose, SSL template
│   └── flow-assets/        --> Dokumentasi PDF & diagram alur
│
└── 📄 README.md            --> Panduan ringkas operasional & arsitektur proyek
```

---

## 5. Matriks Pengujian & Verifikasi Kepatuhan (Compliance Matrix)

| Kriteria Uji | Metode Verifikasi | Batas Toleransi Kelulusan | Status |
|---|---|---|---|
| **Urutan Kunci 4 Cards** | Automated State Machine Test | Card 2 terkunci sebelum muat; Card 3 terkunci sebelum dumping | ✅ Lulus |
| **Integritas Dual Foto** | API Multipart Verification | Trip tidak berstatus `COMPLETED` jika `invoice_photo_url` kosong | ✅ Lulus |
| **Akurasi Geofence** | Formula Haversine | Muat: toleransi luas (250m–600m); Bongkar: toleransi ketat (&le; 40m) | ✅ Lulus |
| **Audit Status FLAGGED** | Web Dashboard Approval | Trip di luar radius tertahan dari rekapan tagihan sampai di-approve | ✅ Lulus |
| **Kinerja Offline Client** | Simulated Network Disconnect | Data dan bukti tersimpan di SQLite lokal; auto-sync saat online | ✅ Lulus |
| **Kompresi Berkas Bukti** | WebP Encoding Benchmark | Ukuran file rata-rata $\le 180\text{ KB}$ per foto WebP | ✅ Lulus |
