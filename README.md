# TerraPoint — Mining Logistics & Visual Verification Platform

Sistem audit kepatuhan rute hauling dan bukti visual operasional tambang berbasis *offline-first* dengan verifikasi geospasial presisi tinggi (*50m geofence*), kamera *direct-capture* (tanpa galeri), *canvas burn-in watermark geotag*, pelacakan rute latar belakang, dan sinkronisasi awan terkelola.

---

## 🏗️ Tech Stack & Arsitektur

- **Mobile Client:** Flutter 3.24+ (Drift SQLite + SQLCipher, CameraX, Supabase SDK)
- **Cloud Backend:** Supabase (Managed PostgreSQL 16, Supabase Auth, Edge Functions Deno)
- **Media Storage:** Cloudflare R2 (10 GB Free Storage, $0 Egress Bandwidth)
- **Web Dashboard:** Cloudflare Pages (Progressive Web App / PWA + Leaflet.js Mapping Engine)
- **Visual Design:** Mining Safety Amber Industrial Design (Swiss Tough-Tech & High-Contrast)

---

## 📁 Struktur Dokumentasi & Spesifikasi

| Berkas | Deskripsi |
| :--- | :--- |
| **`prd.md`** | Product Requirement Document (v4.1 — Zero-Click Routing & Serverless Cloud) |
| **`tech_design.md`** | Technical Design Document (Blueprint Arsitektur Teknis) |
| **`ui_ux_spec.md`** | Spesifikasi UI/UX (Mining Safety Amber, K3 Silent Tracking, Jargon-Free Sync) |
| **`api_spec.md`** | Kontrak RESTful API Supabase, Edge Functions & Cloudflare R2 S3 SDK |
| **`coding_guidelines.md`** | Standar Rekayasa & Aturan Koding (Flutter & Edge Functions) |
| **`development_roadmap.md`** | Roadmap Eksekusi (Mobile-First ➔ Supabase ➔ PWA Dashboard) |
| **`designs/index.html`** | Simulator Interaktif Mobile (7 Layar Lengkap, Dark & Light Mode) |
| **`designs/terrapoint_mobile_ui.pen`** | Master File pen.dev (Pencil v2.17 Schema) |
| **`migrations/`** | DDL Skema Basis Data PostgreSQL (Supabase) & Drift SQLite Lokal |

---

## 📱 7 Alur Layar Mobile App

1. **Layar 1 — Login Akun Awal (Online Wajib):** Input ID / NIK Driver & Kata Sandi.
2. **Layar 2 — Quick PIN Unlock (Offline):** Keypad angka 6-digit cepat untuk shift harian.
3. **Layar 3 — Beranda Operasional (Offline):** Deteksi lokasi GPS otomatis (Loading Point Pit 3 &le; 50m) + Tombol Cepat Manual Sync.
4. **Layar 4 — Kamera Viewfinder 50m (Offline):** Direct-capture only tanpa galeri, reticle bidik bak truk, dan shutter button besar.
5. **Layar 5 — Preview Bukti Foto + Watermark Surveyor (Offline):** Foto bak truk dengan kotak putih stamp watermark (Peta mini 50m + Jam merah presisi) dan tombol **"Gunakan Foto"** vs **"Foto Ulang (Retake)"**.
6. **Layar 6 — Status Hauling Aktif (Offline):** Perekaman rute 100% senyap di latar belakang (bebas distraksi mengemudi), tombol **"Foto Bongkar (Selesai)"**.
7. **Layar 7 — Antrean Sinkronisasi (Online Wajib):** Daftar ritase selesai (human-friendly) dan tombol **"Sinkronkan Sekarang"**.

---

## 🚀 Membuka Desain & Simulator

Buka file **`designs/index.html`** di browser untuk mencoba simulator interaktif mobile lengkap dengan state geofence aktif/terkunci dan mode gelap/terang.
