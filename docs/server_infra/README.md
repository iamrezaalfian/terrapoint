# Panduan Deployment TerraPoint di VM / VPS (Self-Hosted Architecture)

Panduan ini menjelaskan cara menjalankan seluruh ekosistem backend dan dashboard **TerraPoint** di server Virtual Private Server (VPS) atau Virtual Machine (VM) privat menggunakan **Docker Compose**.

---

## 🏛️ Arsitektur Sistem di VM / VPS

```
                              [ Klien Mobile (Flutter) ]
                                          │
               HTTP / HTTPS Port 80/443   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        SERVER VM / VPS UBUNTU                          │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    NGINX GATEWAY CONTAINER                       │  │
│  │  • Melayani Web Dashboard PWA (Port 80/443)                      │  │
│  │  • Reverse Proxy API `/api/` ──▶ Backend Container               │  │
│  │  • Media Static `/uploads/`  ──▶ Volume Bukti Foto WebP          │  │
│  └──────────────────┬─────────────────────────────┬─────────────────┘  │
│                     │                             │                    │
│                     ▼                             ▼                    │
│  ┌─────────────────────────────────────┐  ┌─────────────────────────┐  │
│  │      TERRAPOINT REST API BACKEND    │  │   VOLUME PENYIMPANAN    │  │
│  │  • Node.js / Express REST API       │  │      EVIDENCE DISK      │  │
│  │  • Formula Haversine Toleransi 50m  │  │  (Foto Watermark WebP   │  │
│  │  • Autentikasi Pengemudi & Admin    │  │   tersimpan lokal)      │  │
│  │  • Ingesti Breadcrumbs Telemetri    │  └─────────────────────────┘  │
│  └──────────────────┬──────────────────┘                               │
│                     │ Pool Koneksi Port 5432                           │
│                     ▼                                                  │
│  ┌─────────────────────────────────────┐                               │
│  │       POSTGRESQL 16 CONTAINER       │                               │
│  │  • Skema Relasional Mandiri         │                               │
│  │  • Auto-Init Migrations & Seeding   │                               │
│  └─────────────────────────────────────┘                               │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Langkah Cepat Deploy (1-Click Run)

### 1. Prasyarat di Server VPS
Pastikan VM / VPS (misal Ubuntu 22.04 / 24.04 LTS) telah terinstal Docker dan Docker Compose plugin:
```bash
sudo apt update && sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
```

### 2. Salin Berkas Proyek ke VPS
Clone repositori atau salin folder proyek ke VPS:
```bash
cd /opt/terrapoint/server_vps
```

### 3. Konfigurasi Environment
Salin template konfigurasi:
```bash
cp .env.example .env
nano .env
```
Sesuaikan `BASE_URL` dengan IP Publik atau Domain VPS Anda, contoh:
```env
BASE_URL=http://203.0.113.10
# Atau jika menggunakan domain:
# BASE_URL=https://terrapoint.perusahaan.com
```

### 4. Jalankan Kontainer
```bash
docker compose up -d --build
```

Verifikasi status layanan:
```bash
docker compose ps
curl http://localhost/health
```

Respon yang diharapkan:
```json
{
  "status": "healthy",
  "system": "TerraPoint Self-Hosted VM Backend"
}
```

---

## 🌐 Alamat Akses Layanan

| Komponen | URL Akses |
| :--- | :--- |
| **Web Dashboard PWA** | `http://<IP-VPS-ANDA>/` |
| **REST API Endpoint** | `http://<IP-VPS-ANDA>/api/` |
| **Health Check** | `http://<IP-VPS-ANDA>/health` |
| **Penyimpanan Foto Bukti** | `http://<IP-VPS-ANDA>/uploads/evidences/` |

---

## 🔒 Setup Domain & HTTPS / SSL (Let's Encrypt)

Jika Anda menghubungkan domain resmi ke IP VPS:
```bash
sudo apt install -y certbot
sudo certbot certonly --standalone -d terrapoint.perusahaan.com
```
Salin sertifikat yang digenerate ke folder `./ssl/`:
```bash
cp /etc/letsencrypt/live/terrapoint.perusahaan.com/fullchain.pem ./ssl/cert.pem
cp /etc/letsencrypt/live/terrapoint.perusahaan.com/privkey.pem ./ssl/key.pem
```

---

## 🔄 Pemeliharaan & Backup Database

### Backup Database:
```bash
docker exec -t terrapoint_db pg_dump -U terrapoint_user terrapoint > backup_$(date +%F).sql
```

### Restore Database:
```bash
cat backup_2026-10-12.sql | docker exec -i terrapoint_db psql -U terrapoint_user -d terrapoint
```
