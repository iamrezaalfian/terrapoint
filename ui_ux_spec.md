# UI/UX Design Specification & Driver Usability Guidelines

---

**Nama Produk:** TerraPoint Mobile Client & Web Dashboard
**Target Pengguna Utama:** Pengemudi Dump Truck Tambang (*Hauler Drivers*) & Dispatcher Tambang
**Identitas Visual:** **Mining Safety Amber Industrial Design (CAT & Heavy Equipment Tough-Tech)**
**Filosofi Desain:** **Zero-Click Routing — 1 Layar, 1 Tombol Utama Amber, Silent Background Tracking, Jargon-Free Sync**

---

## 1. Analisis Lingkungan Pengguna & Prinsip Desain

### 1.1 Tantangan Lapangan Pengemudi Tambang
1. **Silau Matahari (*Direct Sunlight Glare*):** Layar ponsel di dalam kabin sering terkena pantulan sinar matahari langsung. UI wajib menggunakan **High Contrast (WCAG AAA $\ge 7:1$)** dengan teks tebal dan latar belakang tegas.
2. **K3 & Keselamatan Mengemudi (*Zero-Distraction In-Cab*):** Saat truk sedang berjalan (*hauling*), pengemudi **tidak boleh diganggu oleh visualisasi peta rute atau animasi radar**. Perekaman koordinat berjalan 100% senyap di *background service*. Layar ponsel hanya menampilkan kartu status tenang dan 1 tombol **"FOTO BONGKAR (SELESAI)"** saat tiba di titik tujuan. Visualisasi peta rute hanya ada di Web Dashboard Dispatcher.
3. **Pemeriksaan Kualitas Foto (Preview & Retake):** Setelah mengambil foto, driver melihat layar preview dengan kotak putih watermark surveyor di sudut bawah serta 2 tombol tegas: **"GUNAKAN FOTO INI"** (Amber) atau **"FOTO ULANG (RETAKE)"** (Slate).
4. **Antrean Sinkronisasi Ramah Pengemudi (*No Technical Jargon*):** Layar antrean sinkronisasi tidak menampilkan istilah teknis yang membingungkan seperti ukuran kilobyte (`~750 KB`), format berkas (`WebP`), atau jumlah titik koordinat (`142 Titik`). Cukup daftar nama ritase sederhana: *"Ritase 1: Pit 3 Utara ➔ ROM 1 [SIAP]"*.
5. **Zero-Click Routing:** Driver **tidak perlu memilih rute**. Sensor GPS otomatis mendeteksi lokasi muat (Pit) dan lokasi bongkar (ROM).

---

## 2. Palet Warna & Desain Token (Safety Amber Dual-Theme)

```
┌────────────────────────────────────────────────────────────────────────┐
│                      OFFICIAL SAFETY AMBER PALETTE                     │
├───────────────────┬───────────────────┬────────────────────────────────┤
│ Token Name        │ Dark Mode (Malam) │ Light Mode (Siang Terik)       │
├───────────────────┼───────────────────┼────────────────────────────────┤
│ bg-surface        │ #06080D (Obsidian)│ #FFFFFF (Pure White)           │
│ bg-card           │ #131824 (Charcoal)│ #F8FAFC (Slate-50)             │
│ border            │ #1C2230 (Slate-800│ #CBD5E1 (Slate-300)            │
│ text-primary      │ #F8FAFC (Slate-50)│ #0F172A (Slate-900)            │
│ text-muted        │ #7E8B9F (Slate-400│ #475569 (Slate-600)            │
│ accent-primary    │ #D97706 (Amber)   │ #D97706 (Amber)                │
│ accent-light      │ #F59E0B (Amber-500│ #B45309 (Amber-700)            │
│ accent-subtle     │ rgba(217,119,6,12)│ #FFFBEB (Amber-50)             │
│ button-retake     │ #1C2230 (Slate-800│ #E2E8F0 (Slate-200)            │
└───────────────────┴───────────────────┴────────────────────────────────┘
```

---

## 3. Spesifikasi 7 Alur Layar Mobile Lengkap

```
┌─────────────────┬─────────────────┬─────────────────┬─────────────────┬─────────────────┬─────────────────┬─────────────────┐
│ 1. LOGIN AKUN   │ 2. QUICK PIN    │ 3. BERANDA      │ 4. VIEWFINDER   │ 5. PREVIEW FOTO │ 6. STATUS       │ 7. ANTREAN      │
│    AWAL         │    UNLOCK       │    AUTO-DETECT  │    GEOFENCE 50M │    + WATERMARK  │    HAULING AKTIF│    SINKRONISASI │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ [📶 Online]     │ [📴 Offline]    │ [📴 Offline]    │ [📴 Offline]    │ [📴 Offline]    │ [📴 Offline]    │ [📶 Online]     │
│ • Input ID/NIK  │ • 6-Dots PIN    │ • GPS Auto-     │ • Banner Amber  │ • Kotak Putih   │ • Status Tenang │ • Ringkasan     │
│ • Input Sandi   │ • Keypad Besar  │   Detect Pit 3  │   "Posisi Sesuai│   Surveyor Stamp│   "Perjalanan   │   3 Ritase Siap │
│ • Tombol Amber  │   56x56dp       │ • Tombol Amber  │ • Reticle Frame │ • Jam Merah     │   Menuju ROM"   │ • Daftar Rute   │
│   "Masuk Akun"  │ • Otentikasi    │ • Kartu Cepat   │ • Shutter 68dp  │ • Peta Mini 50m │ • Tracking 100% │   Human-Friendly│
│                 │   Offline       │   Manual Sync   │   Amber Padat   │ • Retake / Use  │   di Background │ • Progress Bar  │
│                 │                 │                 │                 │                 │ • Tombol Amber  │ • Tombol Amber  │
│                 │                 │                 │                 │                 │   "Foto Bongkar"│   "Sync Sekarang│
└─────────────────┴─────────────────┴─────────────────┴─────────────────┴─────────────────┴─────────────────┴─────────────────┘
```

---

## 4. Spesifikasi Stamp Watermark Surveyor (Canvas Burn-in)

Format kotak putih permanen di sudut bawah foto:
* **Background:** Solid White (`#FFFFFF`, opacity $98\%$) dengan sudut melengkung $14\text{ dp}$ dan bayangan halus.
* **Sisi Kiri:** Peta Mini Vektor Kontur ($80 \times 96\text{ dp}$) dengan pin lokasi merah dan lingkaran toleransi 50m.
* **Sisi Kanan:**
  - Badge Header: `START CHECKPOINT` / `END CHECKPOINT` (Aksen Amber `#D97706`)
  - **Jam Utama Berwarna Merah:** `08:05:22 WITA (UTC+8)` tebal monospaced
  - Nama Titik Tambang: `Loading Point Pit 3 Utara` (Hitam `#0F172A`)
  - Koordinat GPS: `Lat: -3.123456, Lng: 115.123456`
  - Akurasi Satelit: `Akurasi: ±8.2m | Alt: 142m MSL`
  - Identitas: `DRV-001 (Ahmad Fauzi) | TSK-20260918-001`
