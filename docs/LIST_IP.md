# Daftar IP & Endpoint Jaringan TerraPoint (Network & IP Inventory)

Dokumen ini memetakan seluruh alamat IP, domain, port, dan kredensial akses untuk platform **TerraPoint**, baik melalui **Jalur Publik (Testing Klien)**, **Jalur Privat Tailscale (Developer)**, maupun **Jaringan Internal Data Center (NOC / Proxmox)**.

---

## 1. 🌐 Jalur Publik (Untuk Testing Klien — Tanpa VPN & Tanpa Tailscale)

Jalur ini dapat langsung diakses oleh siapapun (klien, pengawas, manajemen) menggunakan browser atau smartphone biasa tanpa perlu menginstal aplikasi VPN apa pun:

| Layanan / Komponen | URL Publik HTTPS | Keterangan |
|---|---|---|
| **Web Dashboard Dispatcher** | `https://affect-gary-begins-systematic.trycloudflare.com/` | Portal Command Center & Peta Live Leaflet |
| **Download APK Driver Android** | `https://affect-gary-begins-systematic.trycloudflare.com/terrapoint.apk` | File instalasi aplikasi mobile driver (55.9 MB) |
| **Galeri Screenshots (8 Layar)**| `https://affect-gary-begins-systematic.trycloudflare.com/screenshots/` | Dokumentasi visual alur operasional 4 cards |
| **Backend REST API Health** | `https://affect-gary-begins-systematic.trycloudflare.com/health` | Status kesehatan service backend server |
| **Log Catcher API** | `https://affect-gary-begins-systematic.trycloudflare.com/api/system/logs` | Pemantauan error dan event HTTP real-time |

---

## 2. 🔒 Jalur Jaringan Privat Tailscale (Tim Developer & Internal)

Digunakan untuk akses manajemen, remote SSH, dan pemantauan internal developer:

| Nama Host Tailscale | Alamat IPv4 Tailscale | Port | Protokol / Layanan | Keterangan |
|---|---|---|---|---|
| **`terrapoint-backend`** | `100.89.207.92` | `8000` | HTTP | Backend REST API & Static Web Host |
| **`terrapoint-backend`** | `100.89.207.92` | `22` | SSH | Remote terminal Linux (`user: terrapoint`) |
| **`proxmox-pve`** | `100.93.187.4` | `8006` | HTTPS | Web GUI Hypervisor Proxmox VE |
| **`pc-home`** | `100.101.210.14` | - | Windows | Perangkat workstation lokal developer |
| **`pc-noc`** | `100.69.162.43` | - | Windows | Workstation tim NOC |

### Cara Remote SSH via Tailscale:
```bash
ssh terrapoint@100.89.207.92
# atau menggunakan hostname:
ssh terrapoint@terrapoint-backend
```
- **User:** `terrapoint`
- **Password:** `Terrapoint2026!Dev` *(sudo penuh)*

---

## 3. 🏢 Jaringan Internal Kantor / Data Center (NOC Subnet)

Digunakan saat terhubung ke VPN Kantor atau berada di jaringan kabel LAN Data Center:

| Layanan | IP Internal | Port | Kredensial / URI | Keterangan |
|---|---|---|---|---|
| **Backend CT (ct-terrapoint)** | `10.10.10.4` | `8000` | Bind `0.0.0.0:8000` | Container Debian 13 backend mobile |
| **SSH via VPN Kantor** | `10.1.4.241` | `2204` | `ssh -p 2204 terrapoint@10.1.4.241` | Port forward SSH gateway kantor |
| **Database PostgreSQL 17** | `10.10.10.2` | `5432` | `postgresql://nocadmin:P9x_NocData2026_Secure@10.10.10.2:5432/terrapoint` | Database utama (CT 102) |
| **MinIO S3 Media Storage** | `10.10.10.2` | `9000` | `http://10.10.10.2:9000` (User: `nocadmin` / Pass: `P9x_NocData2026_Secure`) | Object storage foto muat, bongkar, nota |
| **Proxmox Hypervisor Host** | `10.1.4.240` | `8006` | `https://10.1.4.240:8006` | Host fisik server datacenter |

---

## 4. 🔑 Akun Demo Pengujian (Login Credentials)

### A. Pengemudi (Mobile App Driver)
- **ID Pengemudi:** `DRV-001` (Ahmad Fauzi — *6 Roda Jumbo*)
- **ID Pengemudi:** `DRV-002` (Budi Santoso — *10 Roda Tronton*)
- **ID Pengemudi:** `DRV-003` (Hendra Saputra — *6 Roda Jumbo*)
- **PIN Shift Default:** `123456`

### B. Dispatcher / Supervisor (Web Dashboard)
- **Email:** `ahmad.fauzi@terrapoint.id`
- **Kata Sandi:** `admin123456`
- **Peran:** Head Mine Dispatcher

### C. Superadmin NOC (Infrastruktur Data Center)
- **Email:** `nocadmin@terrapoint.noc`
- **Kata Sandi:** `P9x_NocData2026_Secure`
- **Peran:** Superadmin NOC
