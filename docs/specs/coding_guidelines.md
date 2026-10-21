# Engineering Standards & Coding Guidelines

---

**Nama Proyek:** TerraPoint (Mining Logistics & Compliance System)
**Tech Stack:** Flutter 3.24+ (Mobile Client), Supabase (PostgreSQL 16 & Auth), Cloudflare R2 (S3 Storage), Cloudflare Pages (PWA Dashboard)
**Standar Arsitektur:** Feature-First BLoC/Provider (Flutter), Serverless Edge Functions (Deno/TypeScript), SQL-Standard (PostgreSQL)
**Status:** Mandatory Engineering Rules

---

## 1. Prinsip Rekayasa Umum (*Core Engineering Principles*)

1. **Correctness First, Maintainability Next:** Utamakan kebenaran logika validasi radius geofence 50m dan integritas biner WebP di atas segalanya.
2. **Refuse Needless Abstraction:** Jangan membuat *layer* wrapper yang tidak perlu. Manfaatkan SDK bawaan (`supabase_flutter`, `drift`, `minio_new`) secara bersih dan idiomatik.
3. **No Silent Error Suppression:** Dilarang mengabaikan error (`_ = err` atau `catch (e) {}` kosong). Setiap error wajib ditangani, dibungkus (*wrapped*), atau dicatat dengan konteks yang jelas.
4. **Offline-First Resource Discipline:** Kelola memori controller kamera dan sensor GPS dengan benar; pastikan setiap controller di-*dispose* saat widget dihancurkan.

---

## 2. Standar Pemrograman Mobile (Flutter 3.24+ / Dart)

### 2.1 Manajemen Siklus Hidup Sumber Daya (*Resource Lifecycle & Dispose*)
Setiap `CameraController`, `StreamSubscription`, `TextEditingController`, atau `AnimationController` wajib di-*dispose* secara eksplisit untuk mencegah *memory leaks* dan *camera lockups*:

```dart
class _CameraViewfinderState extends State<CameraViewfinder> {
  CameraController? _cameraController;
  StreamSubscription<Position>? _positionStreamSub;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startLocationListener();
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }
}
```

### 2.2 Akses Database Lokal Drift (DAO Pattern)
Semua query SQLite harus dikelompokkan ke dalam DAO (*Data Access Object*), bukan dipanggil secara acak di dalam widget:

```dart
@DriftAccessor(tables: [LocalTasks, LocalTaskEvidences, LocalTaskBreadcrumbs, LocalMasterRoutes])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(AppDatabase db) : super(db);

  Future<List<LocalTask>> getUnsyncedTasks(String driverId) {
    return (select(localTasks)
          ..where((tbl) => tbl.driverId.equals(driverId))
          ..where((tbl) => tbl.status.equals('PENDING_SYNC')))
        .get();
  }
}
```

### 2.3 Standar Integrasi Supabase & Cloudflare R2
- Gunakan `SupabaseClient` yang diinisialisasi secara global di `main.dart`.
- Upload foto WebP ke Cloudflare R2 dilakukan menggunakan `minio_new` (S3 SDK) dengan *content-type* `image/webp`.
- Selalu tangani skenario koneksi terputus (*network exception*) secara elegan tanpa menyebabkan crash pada aplikasi.

```dart
// Contoh Pola Upload & Sync yang Aman
Future<void> syncRitase(LocalTask task, List<LocalTaskEvidence> evidences) async {
  try {
    // 1. Upload Foto ke Cloudflare R2
    for (final ev in evidences) {
      final r2Url = await R2StorageClient.uploadEvidencePhoto(
        filePath: ev.filePath,
        taskId: task.taskId,
        checkpointType: ev.checkpointType,
      );
      // Update local storage URL
    }

    // 2. Kirim Metadata ke Supabase PostgreSQL
    await supabase.from('tasks').upsert({
      'task_id': task.taskId,
      'driver_id': task.driverId,
      'title': task.title,
      'status': 'COMPLETED',
      'actual_route': routeJsonArray,
    });
  } on SocketException catch (e) {
    // Tangani offline tanpa merusak data lokal
    log("Sync tertunda: jaringan belum siap");
  }
}
```

### 2.4 Background Tasks Isolation (`Workmanager`)
Fungsi callback *stealth telemetry worker* harus berdiri sendiri di tingkat *top-level* dengan anotasi `@pragma('vm:entry-point')`:

```dart
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    // Inisialisasi Drift & jalankan kirim batch titik rute ke Supabase...
    return Future.value(true);
  });
}
```

---

## 3. Standar Supabase Edge Functions (Deno / TypeScript)

1. **Strict Type Safety:** Seluruh handler Edge Functions wajib menggunakan TypeScript murni dengan interface payload yang jelas.
2. **Kalkulasi Haversine di Edge:** Validasi radius 50m dilakukan sebelum data disimpan ke database:

```typescript
// supabase/functions/sync-task-complete/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const EARTH_RADIUS_METERS = 6371000.0;

function calculateHaversine(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const dLat = (lat2 - lat1) * (Math.PI / 180.0);
  const dLon = (lon2 - lon1) * (Math.PI / 180.0);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180.0)) *
      Math.cos(lat2 * (Math.PI / 180.0)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_METERS * c;
}

serve(async (req) => {
  // Logic validation & DB Insert...
});
```

---

## 4. Standar Pengujian & Verifikasi (*Testing Standards*)

1. **Unit Testing Matematika Spasial:**
   - Uji rumus Haversine Dart dengan skenario batas (jarak 0m, 49.9m, 50.1m).
2. **Unit Testing DAO SQLite:**
   - Uji pembuatan ritase On-Demand, penambahan titik rute breadcrumbs, dan filter tugas `PENDING_SYNC`.
3. **Idempotency Verification:**
   - Uji coba pengiriman ulang data ritase yang sama ke Supabase; verifikasi bahwa data tidak terduplikasi.
