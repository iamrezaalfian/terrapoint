# TerraPoint — Mining Fleet Telematics & Compliance

Platform kepatuhan dan telematika operasional hauling pertambangan nikel berbasis verifikasi geofence, kamera geotag watermark, dan jembatan timbang (*Weighbridge*).

---

## 📂 Struktur Utama Monorepo

Struktur proyek telah disederhanakan murni menjadi komponen inti di depan:

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
│   ├── specs/              --> PRD, Desain Teknis, API Spec, Guidelines, Roadmap
│   ├── server_infra/       --> Nginx config, Docker compose, SSL template
│   └── flow-assets/        --> Dokumentasi PDF & diagram alur
│
└── 📄 README.md            --> Panduan ringkas operasional & arsitektur proyek
```

---

## 1. Rincian Komponen Utama

### A. Frontend: `frontend/`
- **`frontend/web/` (Dispatcher Command Center):**
  - **Akses:** `http://terrapoint-backend:8000/` atau `http://100.89.207.92:8000/`
  - **Fitur:** Peta Leaflet dengan warna unik per driver, manajemen proyek hauling (radius muat luas & bongkar ketat), kontrol akun driver & armada roda, audit bukti 3 foto, download APK (`/terrapoint.apk`), dan galeri antarmuka (`/screenshots/`).
- **`frontend/mobile/` (Aplikasi Driver Android):**
  - **Framework:** Flutter 3 (`Dart`) dengan CameraX hardware integration.
  - **Download APK:** `http://terrapoint-backend:8000/terrapoint.apk`
  - **Fitur:** Login driver, selector armada roda fleksibel, dan sistem 4 cards berurutan tanpa nomor (Titik Muat, Titik Bongkar, Foto Nota Timbang, Riwayat Foto).

### B. Backend API & Migrations: `backend/`
- **Runtime:** Bun 1.4.3 / Node.js
- **Port:** Bind ke `0.0.0.0:8000`
- **Database:** PostgreSQL 17 di `10.10.10.2:5432/terrapoint`
- **Media Storage:** MinIO S3 di `http://10.10.10.2:9000`
- **Migrations:** `backend/migrations/`
- **Systemd Service (VPS):** `terrapoint.service`

---

## 2. Perintah Cepat Pengelolaan Server (Cheatsheet)

- **Cek Status Service:** `sudo systemctl status terrapoint`
- **Restart Backend:** `sudo systemctl restart terrapoint`
- **Lihat Log Live:** `sudo journalctl -u terrapoint -f`
- **Tes Health API:** `curl http://100.89.207.92:8000/health`
