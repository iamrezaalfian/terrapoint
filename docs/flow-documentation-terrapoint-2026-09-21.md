# TerraPoint Platform — Master Application Flow & Technical Documentation

---

**Nama Produk:** TerraPoint  
**Sektor Industri:** Mining Logistics & Heavy Equipment Fleet Compliance (Sulawesi Morowali Sector)  
**Versi Sistem:** v2.5 (Clean Modern Tech Specification — Pure Slate Light, Deep Navy & Precision Amber)  
**Status:** Approved Reference Design (Master Architecture)  

---

## 1. Ringkasan Eksekutif & Identitas Visual Baru

Dokumentasi ini merangkum alur operasional lintas platform TerraPoint dengan mengadopsi standar desain master dari:  
👉 **`designs/png/terrapoint_mobile_ui2_all_in_one.png`**

### 🎨 Sistem Desain: "Clean Modern Tech"
- **Latar Layar (*Screen Surface*):** Putih bersih & sejuk (`#FFFFFF` dan `#F8FAFC`) dengan kartu komponen berbingkai halus (`border-slate-200`).
- **Elemen Kontras Kuat (*Deep Navy*):** Tombol aksi utama, header kartu hero, dan kartu ringkasan mingguan menggunakan warna navy baja pekat (`#0F172A` dan `#1E293B`) untuk memberikan kesan kokoh, modern, dan profesional.
- **Aksen Presisi (*Precision Amber*):** Aksen oranye emas tajam (`#D97706` dan `#F59E0B`) difokuskan pada titik perhatian penting (ikon navigasi aktif, status jarak, tombol play, dan penanda geofence).
- **Status Kepatuhan K3:** Indikator hijau zamrud (`#10B981`) untuk status *Siang*, *GPS Akurat*, dan *Selesai*.
- **Surveyor Geotag Watermark Permanen:** Setiap bukti foto (Foto Muatan, Foto Dumping, dan Foto Bukti Kendala) wajib menyertakan stempel watermark permanen di sudut bawah foto (jam merah presisi WITA, koordinat GPS Morowali, akurasi satelit, dan checkpoint radius 50m).

---

## 2. Matriks Alur Lintas Platform (10 Layar Mobile & Web Command Center)

| ID Alur | Platform | Nama Layar / Modul | Konektivitas | Aksi / Pemicu Pengguna | Mutasi Data & Hasil State |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **MOB-01** | Mobile | 1 · Masuk Akun Pengemudi | 📶 Online Wajib | Input NIK/ID Driver + PIN 6 Digit di Camp | Generate JWT token & cache sesi pengemudi di SQLite lokal. |
| **MOB-02** | Mobile | 2 · Beranda / Dashboard | 📴 Offline First | GPS mendeteksi Pit Bahodopi North ($\le 50\text{m}$) | Card Pit aktif $\rightarrow$ Tombol play "MULAI PERJALANAN" aktif. |
| **MOB-03** | Mobile | 3 · Dalam Perjalanan (Hauling) | 📴 Offline First | Driver mengemudi dari Pit ke ROM Smelter | Tracking rute senyap (v $\ge 3\text{ km/jam}$) dengan radar Morowali. |
| **MOB-04** | Mobile | 4 · Foto Muatan (+ Watermark) | 📴 Offline First | Driver memotret bak muatan truk di Pit | CameraX direct-capture + Burn-in Watermark `START CHECKPOINT`. |
| **MOB-05** | Mobile | 5 · Foto Dumping (+ Watermark) | 📴 Offline First | Driver memotret area pembongkaran di ROM | CameraX direct-capture + Burn-in Watermark `END CHECKPOINT`. |
| **MOB-06** | Mobile | 6 · Selesai Perjalanan | 📴 Offline First | Verifikasi muatan (45.2T), jarak (5.24 km), durasi (22m) | Ritase ditandai `COMPLETED` dan tersimpan aman di internal HP. |
| **MOB-07** | Mobile | 7 · Riwayat Perjalanan | 📴 Offline First | Membuka tab riwayat shift harian | Rekapitulasi ritase harian (Total 2 Ritase, 89.8 Ton Ore). |
| **MOB-08** | Mobile | 8 · GPS Tracking Live Radar | 📴 Offline First | Memantau radar telemetri pergerakan truk | Menampilkan unit DT-104, kecepatan aktual (33.8 km/jam), elevasi (+85m RL). |
| **MOB-09** | Mobile | 9 · Lapor Masalah (+ Watermark) | 📴 Offline | Memilih kategori kendala (Mesin, Ban, BBM, Jalan) | Ambil foto bukti kendala + Stempel watermark koordinat KM 3.8. |
| **MOB-10** | Mobile | 10 · Bantuan & K3 Tambang | 📴 / 📶 | Panggilan radio darurat Ch-04 atau WhatsApp | Hubungi pengawas lapangan atau dispatcher tambang langsung. |
| **WEB-01** | Web PWA | Peta Satelit & Rute Hauling | 📶 Online | Klik armada DT-104 di koridor Bahodopi - Smelter | Render polyline rute berkelok (switchback RL +180m) & live radar. |
| **WEB-02** | Web PWA | Telemetry HUD Vehicle Inspector | 📶 Online | Klik marker unit truk di peta atau panel samping | Drawer cockpit: muatan 45.2T, BBM 81%, suhu 89°C, tekanan 114 PSI. |
| **WEB-03** | Web PWA | Log Ritase & Audit Geofence | 📶 Online | Filter status, cari Task ID, ekspor CSV | Rekapitulasi ritase harian + unduh data audit kepatuhan format `.csv`. |
| **WEB-04** | Web PWA | Modal Audit Bukti Foto | 📶 Online | Klik "Verifikasi Bukti" pada tabel log | Perbandingan foto muat & bongkar + audit deviasi jarak Haversine 50m. |
| **WEB-05** | Web PWA | Master Geofence Checkpoints | 📶 Online | Slider radius toleransi (20m–100m) & CRUD titik | Atur radius geofence Pit Bahodopi (+185 RL) & ROM Smelter Port. |
| **WEB-06** | Web PWA | Manajemen Armada Truk | 📶 Online | Filter armada (Hauling, Loading, Standby) | Monitoring status Scania/Volvo/Mercedes, BBM, odometer, dan muatan. |
| **WEB-07** | Web PWA | Admin Login (Better Auth) | 📶 Online | Masuk menggunakan kredensial resmi pengawas | Akses eksklusif Head Mine Dispatcher & Superadmin. |

---

## 3. Spesifikasi Detail 10 Layar Mobile Client (Desain Master Baru)

```text
[BAGIAN A: SIKLUS OPERASIONAL RITASE UTAMA]
1. MASUK AKUN ────▶ 2. BERANDA DASHBOARD ────▶ 3. DALAM PERJALANAN ────▶ 4. FOTO MUATAN ────▶ 5. FOTO DUMPING
   (ID & PIN)          (Mulai Ritase)             (Radar Hauling)          (+ Watermark)        (+ Watermark)

[BAGIAN B: MANAJEMEN RITASE, RIWAYAT & BANTUAN K3]
6. SELESAI ───────▶ 7. RIWAYAT SHIFT ────▶ 8. GPS RADAR LIVE ────▶ 9. LAPOR MASALAH ────▶ 10. BANTUAN K3
   (Rekap 45.2T)       (2 Rit • 89.8T)        (Kecepatan & RL)       (+ Watermark Foto)    (Radio Ch-04 / WA)
```

### 3.1 Layar 1 · Masuk Akun Pengemudi (*Camp Online*)
- **Fungsi:** Mengotentikasi pengemudi dan menarik data master ke SQLite lokal.
- **Visual:** Background navy pekat (`#0A0D14`), logo TP amber, form card putih bersih dengan input *Nomor ID Pengemudi* (`DRV-001`) dan *PIN 6 Digit Shift*, tombol amber *"Masuk ke Sistem"*, serta badge hijau *"Koneksi Camp Wi-Fi Terverifikasi"*.

### 3.2 Layar 2 · Beranda / Dashboard (*Offline First*)
- **Fungsi:** Pusat kendali pengemudi dengan deteksi otomatis titik muat tambang.
- **Visual:** Card header armada `TRUK B 9234 KZ (Ahmad Fauzi · DT-045)` dengan chip `SIAP`. Card hero navy pekat *"MULAI PERJALANAN - Pit Bahodopi North (≤ 50 m)"* dengan tombol play amber. Dua card aksi cepat (*TITIK MUAT* & *TITIK BONGKAR*), bar status *GPS Telemetri Aktif (±4.2m)*, dan tombol *"Lacak Lokasi & Rute"*.

### 3.3 Layar 3 · Dalam Perjalanan (*Hauling Radar*)
- **Fungsi:** Memandu perjalanan tanpa mengganggu konsentrasi mengemudi.
- **Visual:** Radar mini koridor hauling Sulawesi Morowali, stepper progress 3-tahap (*1. Muat (OK) ──▶ 2. Hauling ──▶ 3. Bongkar*), card info muatan (*Nikel Saprolite 45.2 Ton, Destinasi ROM Smelter 1, Sisa 1.4 km ±5 mnt*), tombol *"Ambil Foto Bongkar"*.

### 3.4 Layar 4 · Foto Muatan Pit (*+ Geotag Watermark*)
- **Fungsi:** Mengambil bukti visual bak muatan truk di titik pit.
- **Visual:** Viewfinder CameraX direct-capture dengan garis bidik amber. Watermark box putih kontras tinggi di sudut bawah:
  - Lokasi: `Pit Bahodopi North (+185 RL)`
  - Jam Presisi: `08:05:22 WITA (UTC+8)` (Teks merah monospaced)
  - Koordinat: `Lat: -2.812456, Lng: 122.143456 • Akurasi ±4.2m`
  - Badge: `START CHECKPOINT`

### 3.5 Layar 5 · Foto Dumping ROM (*+ Geotag Watermark*)
- **Fungsi:** Mengambil bukti visual proses pembongkaran di stockpile/smelter.
- **Visual:** Viewfinder CameraX direct-capture dengan garis bidik hijau zamrud. Watermark box putih kontras tinggi di sudut bawah:
  - Lokasi: `ROM Smelter Stockpile 1 (Port Morowali)`
  - Jam Presisi: `08:27:45 WITA (UTC+8)` (Teks merah monospaced)
  - Koordinat: `Lat: -2.845000, Lng: 122.168000 • Akurasi ±4.5m`
  - Badge: `END CHECKPOINT`

### 3.6 Layar 6 · Selesai Perjalanan
- **Fungsi:** Konfirmasi penyelesaian siklus ritase dengan ringkasan lengkap.
- **Visual:** Ikon sukses hijau bulat, card ringkasan tugas: Task ID `Task #MRO-001 (TERVERIFIKASI)`, Rute `Pit Bahodopi → Smelter 1`, Total Muatan `45.2 Ton (Saprolite)`, Jarak `5.24 km`, Durasi `22 menit`, tombol *"Kembali ke Beranda"*.

### 3.7 Layar 7 · Riwayat Perjalanan
- **Fungsi:** Melihat catatan seluruh ritase yang telah diselesaikan pada shift aktif.
- **Visual:** Daftar card ritase selesai (Task #MRO-001 dan Task #MRO-002) dengan timestamp WITA, card rekapitulasi navy pekat *"Total Muatan Shift Hari Ini: 2 Ritase • 89.8 Ton Ore"*, tab navigasi bawah (*Riwayat* & *Profil Driver*).

### 3.8 Layar 8 · GPS Tracking Live Radar
- **Fungsi:** Pemantauan kondisi telemetri unit kendaraan secara mandiri oleh pengemudi.
- **Visual:** Peta radar vektor gelap Sulawesi Morowali dengan badge `LIVE`, card status unit `DT-104 (B 9234 KZ)`, Kecepatan Aktual `33.8 km/jam`, Elevasi Tambang `+85m RL (Pit Ramp)`, sinkronisasi otomatis per detik.

### 3.9 Layar 9 · Lapor Masalah (+ Watermark Kendala)
- **Fungsi:** Melaporkan insiden teknis di jalur hauling tambang kepada tim kontrol.
- **Visual:** Grid 4 kategori kendala (*Mesin/Engine, Ban/Tire, Jalan Amblas, Lainnya*), area lampiran foto bukti kendala dengan preview watermark koordinat `08:30:12 WITA • KM 3.8 Haul Road • Lat: -2.8295, Lng: 122.1534`, tombol merah *"Kirim Laporan ke Dispatcher"*.

### 3.10 Layar 10 · Bantuan & Keselamatan K3
- **Fungsi:** Kanal darurat komunikasi pengemudi dengan pihak pengawas tambang.
- **Visual:** Card kontak cepat radio tambang `Radio Dispatcher Morowali Ch-04 / 0812 3456 7890` (tombol *Panggil*) dan `WhatsApp Control Room (Chat Pengawas Lapangan)` (tombol *Chat*), tab navigasi bawah.

---

## 4. Spesifikasi Web Dashboard Admin Command Center

```text
[Arsitektur Layar Web Dashboard Admin]
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ TOP NAVBAR: [Toggle Sidebar]  Judul Halaman      (• Live Telemetry) [☀️/🌙] [Admin ▾]  │
├─────────────┬──────────────────────────────────────────────────────────────────────────┤
│ SIDEBAR:    │ AREA KONTEN AKTIF (7 TAMPILAN OPERASIONAL):                              │
│ 🗺️ Peta Live│ 1. PETA SATELIT & HAUL ROADS: Citra Esri Satelit + Koridor Berkelok      │
│ 📋 Log Rit  │ 2. TELEMETRY HUD INSPECTOR: Cockpit Drawer (Muatan, BBM, Suhu, Tekanan)  │
│ 📍 Geofence │ 3. LOG RITASE & KEPATUHAN: Multi-Filter Search + Ekspor Data CSV         │
│ 🚚 Armada   │ 4. MODAL VERIFIKASI BUKTI: Perbandingan Foto & Audit Jarak Haversine     │
│ ⚙️ Settings │ 5. MASTER GEOFENCE: Checkpoints List + Slider Radius Toleransi 20m-100m  │
│             │ 6. MANAJEMEN ARMADA: Grid Kartu Unit Truk (Scania/Volvo/Mercedes)        │
│             │ 7. LAMAN LOGIN MANDIRI: Fullscreen Admin Auth (Better Auth Powered)      │
└─────────────┴──────────────────────────────────────────────────────────────────────────┘
```

1. **Peta Satelit Topografi (Esri World Imagery + Labels):** Menampilkan pit tambang nikel Bahodopi dan pelabuhan smelter dengan garis koridor resmi (*switchback ramp RL +180m*).
2. **Inspektor Telemetri Truk (HUD Drawer):** Klik armada (misal `DT-104 [45.2T]`) memunculkan drawer telemetri live (kecepatan GPS `33.8 km/h`, BBM `81% (19.2 L/h)`, suhu `89°C`, tekanan ban `114 PSI`).
3. **Log Ritase & Ekspor CSV:** Pencarian Task ID/Driver, filter grade bijih (*Saprolite/Limonite*), dan unduh file `.csv`.
4. **Modal Verifikasi Bukti Foto:** Menampilkan perbandingan foto muat dan foto bongkar berstempel watermark surveyor lengkap dengan deviasi jarak GPS terhadap radius toleransi 50m.
5. **Master Geofence Checkpoints:** Pengaturan radius toleransi geofence titik tambang menggunakan slider 20m hingga 100m.
6. **Manajemen Armada Truk:** Monitoring status armada (DT-101 s/d DT-115), muatan, odometer, dan level bahan bakar.
7. **Laman Login Mandiri Khusus Admin:** Autentikasi pengawas command center menggunakan kredensial Better Auth resmi.
