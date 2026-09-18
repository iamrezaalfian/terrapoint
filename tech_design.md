# Technical Design Document (TDD) & System Blueprint

---

**Nama Sistem:** TerraPoint (Mining Compliance & Visual Verification Platform)
**Versi Dokumen:** 2.1 (Zero-Click GPS Auto-Detection — Supabase, Cloudflare R2, Cloudflare Pages PWA, Flutter Client)
**Target Arsitektur:** 
- **Mobile Client:** Flutter 3.24+ (Drift SQLite, SQLCipher, CameraX, Supabase Flutter SDK)
- **Backend & Database:** Supabase Cloud (Managed PostgreSQL 16, Supabase Auth, Edge Functions Deno)
- **Media Storage:** Cloudflare R2 (S3-Compatible, 10 GB Free, $0 Egress Bandwidth)
- **Web Dashboard:** Cloudflare Pages (Progressive Web App / PWA + Leaflet.js Mapping Engine)
**Status:** Approved for Implementation

---

## 1. Arsitektur Sistem & Topologi Komponen

```
                                  [AREA TAMBANG (OFFLINE / BLANK SPOT)]
                                                   │
    ┌──────────────────────────────────────────────┴──────────────────────────────────────────────┐
    │                                                                                            │
    │  ┌──────────────────────────────────────────────────────────────────────────────────────┐  │
    │  │                        MOBILE APP CLIENT (Flutter Offline Engine)                    │  │
    │  │  ┌────────────────────────┐  ┌────────────────────────┐  ┌────────────────────────┐  │  │
    │  │  │   Zero-Click GPS       │  │   Adaptive Route       │  │   Local Storage Vault  │  │  │
    │  │  │   Auto-Detect & Camera │  │   Tracking Service     │  │   Drift + SQLCipher    │  │  │
    │  │  └───────────┬────────────┘  └───────────┬────────────┘  └───────────┬────────────┘  │  │
    │  │              │ (WebP + EXIF)             │ (Breadcrumbs)             │               │  │
    │  │              └───────────────────┬───────┴───────────────────────────┘               │  │
    │  │                                  │                                                   │  │
    │  │                    ┌─────────────┴─────────────┐                                     │  │
    │  │                    │   Dual Sync Engine        │                                     │  │
    │  │                    │   [A] Manual Batch Sync   │                                     │  │
    │  │                    │   [B] Stealth Telemetry   │                                     │  │
    │  │                    └─────────────┬─────────────┘                                     │  │
    │  └──────────────────────────────────┼───────────────────────────────────────────────────┘  │
    └─────────────────────────────────────┼──────────────────────────────────────────────────────┘
                                          │
                                          │ [A] Manual Wi-Fi Camp Sync (Task Payload + Foto WebP)
                                          │ [B] Fleeting 4G / Wi-Fi Signal (Stealth JSON Breadcrumbs)
                                          ▼
                               [AREA KONEKTIVITAS (CAMP / TOWER)]
                                          │
    ┌─────────────────────────────────────┴──────────────────────────────────────────────────────┐
    │                                                                                            │
    │  ┌──────────────────────────────────────────────────────────────────────────────────────┐  │
    │  │                    BACKEND & DATABASE CLOUD (Supabase Engine)                        │  │
    │  │  ┌────────────────────────────────────────────────────────────────────────────────┐  │  │
    │  │  │  Supabase Auth (JWT Driver Authentication & Row Level Security)                │  │  │
    │  │  └──────────────┬─────────────────────────────┬────────────────────────────┬──────┘  │  │
    │  │                 │                             │                            │         │  │
    │  │                 ▼                             ▼                            ▼         │  │
    │  │  ┌────────────────────────┐  ┌────────────────────────┐  ┌────────────────────────┐  │  │
    │  │  │  Supabase Edge         │  │  Managed PostgreSQL 16 │  │  Supabase Realtime     │  │  │
    │  │  │  Functions (Deno / TS) │  │  (JSONB actual_route,  │  │  Broadcast Engine      │  │  │
    │  │  │  (50m Geofence Check)  │  │   master_locations)    │  │  (Live Superadmin Map) │  │  │
    │  │  └──────────────┬─────────┘  └───────────┬────────────┘  └───────────┬────────────┘  │  │
    │  └─────────────────┼────────────────────────┼───────────────────────────┼───────────────┘  │
    │                    │                        │                           │                  │
    │                    └────────────────────────┼───────────────────────────┘                  │
    │                                             │                                              │
    │                      ┌──────────────────────┴──────────────────────┐                       │
    │                      ▼                                             ▼                       │
    │       ┌──────────────────────────────┐              ┌──────────────────────────────┐       │
    │       │   CLOUDFLARE R2 STORAGE      │              │    CLOUDFLARE PAGES (PWA)    │       │
    │       │ • 10 GB Storage GRATIS       │              │ • PWA Dispatcher Portal      │       │
    │       │ • $0 Egress Bandwidth Fee    │              │ • Leaflet.js Mapping Engine  │       │
    │       │ • Simpan Foto WebP Muat/Bongkar             │ • Unlimited Bandwidth Free   │       │
    │       └──────────────────────────────┘              └──────────────────────────────┘       │
    └────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Struktur Folder & Desain Komponen Mobile (Flutter Client)

```
frontend_mobile/
├── android/
├── ios/
├── lib/
│   ├── main.dart                   # Inisialisasi Supabase & Drift SQLite lokal
│   ├── core/                       # Infrastruktur global
│   │   ├── constants/              # App constants, Geofence radius (50m)
│   │   ├── network/                # Supabase Client & Cloudflare R2 Upload Client
│   │   ├── security/               # SQLCipher key generation & FlutterSecureStorage
│   │   └── time/                   # TrueTime NTP delta synchronization
│   ├── database/                   # Drift SQLite Layer
│   │   ├── app_database.dart       # Drift schema & migrations
│   │   ├── app_database.g.dart
│   │   ├── daos/                   # TasksDao, BreadcrumbsDao, LocationsDao
│   │   └── tables/                 # Local table definitions
│   ├── features/                   # Feature-First Modules
│   │   ├── auth/                   # Login PIN Pad, Offline PIN validation
│   │   ├── home/                   # Zero-Click Auto-Detect Screen & Summary
│   │   ├── camera/                 # Direct-Capture Viewfinder, Geofence 50m Interlock
│   │   │   ├── services/           # libwebp encoder, canvas burn-in, EXIF injector
│   │   │   └── presentation/       # Viewfinder UI dengan pesan ramah geofence
│   │   ├── tracking/               # Background Route Tracking Service (Foreground)
│   │   └── sync/                   # Dual-Sync Engine
│   │       ├── manual_sync/        # Manual Sync UI (Upload ke Supabase & R2)
│   │       ├── stealth_sync/       # Workmanager hidden background telemetry worker
│   │       └── auto_purge/         # 3-day local storage auto-purge worker
│   └── shared/                     # Reusable widgets, Dialogs, High-contrast buttons
├── pubspec.yaml
└── pubspec.lock
```

---

## 3. Logika Zero-Click GPS Auto-Detection (Mulai Ritase Otomatis)

```dart
// lib/features/home/services/location_detector.dart

class LocationDetector {
  static const double geofenceRadiusMeters = 50.0;

  /// Mencocokkan posisi GPS aktual dengan master checkpoint tambang
  static Future<MasterLocation?> findNearestLocation(Position currentPos) async {
    final db = AppDatabase.instance;
    final locations = await db.locationsDao.getAllLocations();

    for (final loc in locations) {
      final distance = HaversineMath.calculate(
        currentPos.latitude,
        currentPos.longitude,
        loc.latitude,
        loc.longitude,
      );

      if (distance <= geofenceRadiusMeters) {
        return loc; // Titik muat / bongkar cocok dalam radius 50m!
      }
    }
    return null;
  }
}
```

---

## 4. Alur Pembuatan Ritase Otomatis (Foto Awal = Bukti Tugas)

```dart
// lib/features/camera/services/task_auto_starter.dart

class TaskAutoStarter {
  static Future<LocalTask> startFromPhoto({
    required MasterLocation detectedLocation,
    required Position capturedPosition,
    required String driverId,
    required String webpFilePath,
  }) async {
    final db = AppDatabase.instance;
    final taskId = "TSK-${DateTime.now().millisecondsSinceEpoch}";

    // 1. Buat record ritase baru secara otomatis
    final newTask = LocalTask(
      taskId: taskId,
      driverId: driverId,
      title: "Hauling dari ${detectedLocation.name}",
      startPointName: detectedLocation.name,
      startLat: detectedLocation.latitude,
      startLng: detectedLocation.longitude,
      startRadius: 50,
      isTrackingEnabled: 1,
      status: 'IN_PROGRESS',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await db.tasksDao.insertTask(newTask);

    // 2. Simpan bukti foto awal
    final evidence = LocalTaskEvidence(
      evidenceId: "EVD-${DateTime.now().millisecondsSinceEpoch}-START",
      taskId: taskId,
      checkpointType: 'START',
      capturedLat: capturedPosition.latitude,
      capturedLng: capturedPosition.longitude,
      accuracyMeters: capturedPosition.accuracy,
      capturedAt: DateTime.now().millisecondsSinceEpoch,
      filePath: webpFilePath,
      fileSizeBytes: await File(webpFilePath).length(),
      syncStatus: 'PENDING',
    );
    await db.evidencesDao.insertEvidence(evidence);

    // 3. Mulai servis tracking rute di latar belakang
    await BackgroundTrackingService.startTracking(taskId);

    return newTask;
  }
}
```

---

## 5. Integrasi Cloudflare R2 Storage & Web Dashboard PWA

Web Dashboard dibangun sebagai PWA statis di **Cloudflare Pages** dengan integrasi langsung ke **Supabase** dan **Leaflet.js**:

```javascript
// dashboard_pwa/src/map/route_renderer.js

export function renderTaskMap(mapContainerId, taskData) {
  const map = L.map(mapContainerId).setView([taskData.start_lat, taskData.start_lng], 14);

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 18,
    attribution: '© OpenStreetMap | TerraPoint Mining'
  }).addTo(map);

  // Titik Awal + Lingkaran 50m
  L.marker([taskData.start_lat, taskData.start_lng])
    .bindPopup(`<b>Titik Muat:</b> ${taskData.start_point_name}`)
    .addTo(map);
  L.circle([taskData.start_lat, taskData.start_lng], {
    radius: 50,
    color: '#10B981',
    fillColor: '#10B981',
    fillOpacity: 0.2
  }).addTo(map);

  // Titik Akhir (jika sudah bongkar)
  if (taskData.end_lat && taskData.end_lng) {
    L.marker([taskData.end_lat, taskData.end_lng])
      .bindPopup(`<b>Titik Bongkar:</b> ${taskData.end_point_name}`)
      .addTo(map);
    L.circle([taskData.end_lat, taskData.end_lng], {
      radius: 50,
      color: '#EF4444',
      fillColor: '#EF4444',
      fillOpacity: 0.2
    }).addTo(map);
  }

  // Polylines Rute Hauling
  if (taskData.actual_route && taskData.actual_route.length > 0) {
    const latlngs = taskData.actual_route.map(p => [p.lat, p.lng]);
    const polyline = L.polyline(latlngs, { color: '#2563EB', weight: 4 }).addTo(map);
    map.fitBounds(polyline.getBounds(), { padding: [30, 30] });
  }
}
```
