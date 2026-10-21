import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/network/sync_engine_service.dart';

/// Model Sesi Driver
class DriverSessionModel {
  final String driverId;
  final String fullName;
  final String truckUnit;
  final String truckWheelType;
  final String phoneNumber;
  final String pinHash;
  final String accessToken;
  final int tokenExpiresAt;
  final int lastLoginAt;

  DriverSessionModel({
    required this.driverId,
    required this.fullName,
    required this.truckUnit,
    this.truckWheelType = '6 Roda (Dump Truck)',
    required this.phoneNumber,
    required this.pinHash,
    required this.accessToken,
    required this.tokenExpiresAt,
    required this.lastLoginAt,
  });
}

/// Model Master Checkpoint Tambang
class MasterLocationModel {
  final String locationId;
  final String code;
  final String name;
  final String locationType; // LOADING_POINT / DUMPING_POINT
  final String material;
  final int elevationMsl;
  final double latitude;
  final double longitude;
  final int radiusMeters;

  MasterLocationModel({
    required this.locationId,
    required this.code,
    required this.name,
    required this.locationType,
    required this.material,
    this.elevationMsl = 100,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 50,
  });
}

/// Model Pengantaran Per-Trip (Proyek Hauling)
class TripModel {
  final String tripId;
  final String projectId;
  final String projectName;
  final String driverId;
  final String driverName;
  final String truckWheelType;
  final int tripSequence;
  final String loadPointName;
  final String dumpPointName;
  final String? loadPhotoPath;
  final String? dumpPhotoPath;
  final String? invoicePhotoPath; // FOTO NOTA / SURAT JALAN / INVOICE
  final int? loadTime;
  final int? dumpTime;
  final String status; // 'IN_TRANSIT', 'COMPLETED'
  final double loadDeviationM;
  final double dumpDeviationM;

  TripModel({
    required this.tripId,
    required this.projectId,
    required this.projectName,
    required this.driverId,
    required this.driverName,
    required this.truckWheelType,
    required this.tripSequence,
    required this.loadPointName,
    required this.dumpPointName,
    this.loadPhotoPath,
    this.dumpPhotoPath,
    this.invoicePhotoPath,
    this.loadTime,
    this.dumpTime,
    this.status = 'COMPLETED',
    this.loadDeviationM = 5.4,
    this.dumpDeviationM = 4.2,
  });
}

/// Model Breadcrumb Telemetri
class BreadcrumbModel {
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double heading;
  final int recordedAt;
  bool isStealthSynced;

  BreadcrumbModel({
    required this.latitude,
    required this.longitude,
    this.speedKmh = 0.0,
    this.heading = 0.0,
    required this.recordedAt,
    this.isStealthSynced = false,
  });
}

/// Model Kompatibilitas Legacy Task
class TaskModel {
  final String taskId;
  final String driverId;
  final String driverName;
  final String unitId;
  final String title;
  final String material;
  final double payloadTon;
  final String startPointName;
  final double startLat;
  final double startLng;
  final int startRadius;
  String? endPointName;
  double? endLat;
  double? endLng;
  int endRadius;
  double distanceKm;
  int durationMin;
  double startDeviationM;
  double? endDeviationM;
  String status;
  final int createdAt;
  int updatedAt;
  String? startPhotoPath;
  String? endPhotoPath;
  String? invoicePhotoPath;
  List<BreadcrumbModel> breadcrumbs;

  TaskModel({
    required this.taskId,
    required this.driverId,
    required this.driverName,
    required this.unitId,
    required this.title,
    this.material = 'Material Tambang Utama',
    this.payloadTon = 45.0,
    required this.startPointName,
    required this.startLat,
    required this.startLng,
    this.startRadius = 250,
    this.endPointName,
    this.endLat,
    this.endLng,
    this.endRadius = 40,
    this.distanceKm = 5.24,
    this.durationMin = 22,
    this.startDeviationM = 6.2,
    this.endDeviationM,
    this.status = 'IN_PROGRESS',
    required this.createdAt,
    required this.updatedAt,
    this.startPhotoPath,
    this.endPhotoPath,
    this.invoicePhotoPath,
    List<BreadcrumbModel>? breadcrumbs,
  }) : breadcrumbs = breadcrumbs ?? [];
}

/// Reactive Storage Vault
class LocalStorageVault extends ChangeNotifier {
  static final LocalStorageVault instance = LocalStorageVault._internal();
  LocalStorageVault._internal() {
    _seedDefaultData();
  }

  DriverSessionModel? currentDriver;
  final List<MasterLocationModel> masterLocations = [];
  final List<TaskModel> completedTasks = [];
  final List<TripModel> todayTrips = [];
  TaskModel? activeTask;

  // Strict Sequential State Machine 4 Cards:
  // Stage: 'READY_TO_LOAD' -> 'LOADED_NEED_DUMP' -> 'DUMPED_NEED_INVOICE' -> 'READY_TO_LOAD'
  String haulingStage = 'READY_TO_LOAD';

  bool get canLoad => haulingStage == 'READY_TO_LOAD';
  bool get canDump => haulingStage == 'LOADED_NEED_DUMP';
  bool get canInvoice => haulingStage == 'DUMPED_NEED_INVOICE';
  bool get isLoaded => haulingStage != 'READY_TO_LOAD';
  String? currentTripId;
  String? currentLoadPhotoPath;
  int? currentLoadTime;
  String? currentDumpPhotoPath;
  int? currentDumpTime;

  // Project Info
  String currentProjectId = 'PRJ-HAULING-01';
  String currentProjectName = 'Proyek Hauling Pit 2 ke ROM Stockpile 1';
  String currentTruckWheelType = '6 Roda (Dump Truck)';
  String currentStartPointName = 'Loading Point Pit 2 Barat';
  double currentStartLat = -3.131000;
  double currentStartLng = 115.119000;
  int currentStartRadius = 250;
  String currentEndPointName = 'ROM Stockpile 1';
  double currentEndLat = -3.145000;
  double currentEndLng = 115.148000;
  int currentEndRadius = 40;
  void setDriverSession({
    required String driverId,
    required String fullName,
    required String phoneNumber,
    required String token,
    String? truckUnit,
    String? truckWheelType,
  }) {
    final unitDigits = driverId.replaceAll(RegExp(r'[^0-9]'), '');
    final unitNumber = unitDigits.isEmpty ? '01' : unitDigits.padLeft(2, '0');
    currentDriver = DriverSessionModel(
      driverId: driverId,
      fullName: fullName,
      truckUnit: truckUnit ?? 'TRUK DT-$unitNumber',
      truckWheelType: truckWheelType ?? '6 Roda (Dump Truck)',
      phoneNumber: phoneNumber,
      pinHash: '******',
      accessToken: token,
      tokenExpiresAt: DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
      lastLoginAt: DateTime.now().millisecondsSinceEpoch,
    );
    currentTruckWheelType = currentDriver!.truckWheelType;
    notifyListeners();
    syncDriverTasksFromServer();
  }

  void clearDriverSession() {
    currentDriver = null;
    activeTask = null;
    haulingStage = 'READY_TO_LOAD';
    currentTripId = null;
    currentLoadPhotoPath = null;
    currentDumpPhotoPath = null;
    currentLoadTime = null;
    currentDumpTime = null;
    todayTrips.clear();
    completedTasks.clear();
    notifyListeners();
  }

  /// Ubah Jenis Roda Kendaraan Truk (Fleksibel kapan saja)
  Future<void> updateTruckWheelType(String newWheelType) async {
    currentTruckWheelType = newWheelType;
    notifyListeners();

    // Kirim perubahan ke backend server
    if (currentDriver != null) {
      try {
        final baseUrl = SyncEngineService.serverBaseUrl.replaceAll(RegExp(r'/$'), '');
        final uri = Uri.parse('$baseUrl/api/dashboard/drivers/${currentDriver!.driverId}/assign-project');
        await http.put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'truck_wheel_type': newWheelType,
          }),
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[LocalStorageVault] Update wheel type notice: $e');
      }
    }
  }
  /// Sinkronisasi Data Driver & Project dari Backend Server
  Future<void> syncDriverTasksFromServer() async {
    if (currentDriver == null) return;
    try {
      final baseUrl = SyncEngineService.serverBaseUrl.replaceAll(RegExp(r'/$'), '');
      final uri = Uri.parse('$baseUrl/api/dashboard/driver-project?driver_id=${currentDriver!.driverId}');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (data['driver'] != null) {
            currentTruckWheelType = data['driver']['truck_wheel_type'] ?? currentTruckWheelType;
          }
          if (data['project'] != null) {
            final p = data['project'];
            currentProjectId = p['project_id'] ?? currentProjectId;
            currentProjectName = p['project_name'] ?? currentProjectName;
            currentStartPointName = p['start_point_name'] ?? currentStartPointName;
            currentStartLat = (p['start_lat'] as num?)?.toDouble() ?? currentStartLat;
            currentStartLng = (p['start_lng'] as num?)?.toDouble() ?? currentStartLng;
            currentStartRadius = (p['start_radius_meters'] as num?)?.toInt() ?? currentStartRadius;

            currentEndPointName = p['end_point_name'] ?? currentEndPointName;
            currentEndLat = (p['end_lat'] as num?)?.toDouble() ?? currentEndLat;
            currentEndLng = (p['end_lng'] as num?)?.toDouble() ?? currentEndLng;
            currentEndRadius = (p['end_radius_meters'] as num?)?.toInt() ?? currentEndRadius;
          }

          // Active Trip (In Transit)
          if (data['active_trip'] != null) {
            final act = data['active_trip'];
            haulingStage = act['dump_photo_url'] != null ? 'DUMPED_NEED_INVOICE' : 'LOADED_NEED_DUMP';
            currentTripId = act['trip_id'];
            currentLoadPhotoPath = act['load_photo_url'];
            currentLoadTime = act['load_at'] != null ? DateTime.tryParse(act['load_at'])?.millisecondsSinceEpoch : DateTime.now().millisecondsSinceEpoch;
          } else {
            haulingStage = 'READY_TO_LOAD';
            currentTripId = null;
            currentLoadPhotoPath = null;
          }

          // Today Completed Trips
          if (data['today_completed_trips'] is List) {
            todayTrips.clear();
            for (final item in data['today_completed_trips']) {
              todayTrips.add(TripModel(
                tripId: item['trip_id'] ?? 'TRP-001',
                projectId: item['project_id'] ?? currentProjectId,
                projectName: currentProjectName,
                driverId: currentDriver!.driverId,
                driverName: currentDriver!.fullName,
                truckWheelType: item['truck_wheel_type'] ?? currentTruckWheelType,
                tripSequence: (item['trip_sequence'] as num?)?.toInt() ?? (todayTrips.length + 1),
                loadPointName: currentStartPointName,
                dumpPointName: currentEndPointName,
                loadPhotoPath: item['load_photo_url'],
                dumpPhotoPath: item['dump_photo_url'],
                invoicePhotoPath: item['invoice_photo_url'],
                loadTime: item['load_at'] != null ? DateTime.tryParse(item['load_at'])?.millisecondsSinceEpoch : null,
                dumpTime: item['dump_at'] != null ? DateTime.tryParse(item['dump_at'])?.millisecondsSinceEpoch : null,
                status: item['status'] ?? 'COMPLETED',
                loadDeviationM: (item['load_deviation_m'] as num?)?.toDouble() ?? 5.4,
                dumpDeviationM: (item['dump_deviation_m'] as num?)?.toDouble() ?? 4.2,
              ));
            }
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[LocalStorageVault] Sync project notice: $e');
    }
  }

  /// CARD 1: Rekam Muat di Pit (Membuka Kunci Card 2)
  Future<void> recordTripLoad({required String photoPath, double? lat, double? lng}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final dateStr = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');
    final tripSeq = todayTrips.length + 1;
    final generatedTripId = 'TRP-$dateStr-${(tripSeq * 100 + math.Random().nextInt(90)).toString()}';

    haulingStage = 'LOADED_NEED_DUMP';
    currentTripId = generatedTripId;
    currentLoadPhotoPath = photoPath;
    currentLoadTime = now;
    notifyListeners();

    // Kirim ke backend server
    try {
      final baseUrl = SyncEngineService.serverBaseUrl.replaceAll(RegExp(r'/$'), '');
      final uri = Uri.parse('$baseUrl/api/sync/trip-load');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'project_id': currentProjectId,
          'driver_id': currentDriver?.driverId ?? 'DRV-001',
          'truck_wheel_type': currentTruckWheelType,
          'load_photo_url': photoPath,
          'load_lat': lat ?? currentStartLat,
          'load_lng': lng ?? currentStartLng,
        }),
      ).timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('[LocalStorageVault] Record trip load notice: $e');
    }
  }

  /// CARD 2: Rekam Foto Pembongkaran di ROM (Membuka Kunci Card 3)
  Future<void> recordTripDump({
    required String dumpPhotoPath,
    double? lat,
    double? lng,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    haulingStage = 'DUMPED_NEED_INVOICE';
    currentDumpPhotoPath = dumpPhotoPath;
    currentDumpTime = now;
    notifyListeners();

    if (currentTripId != null) {
      try {
        final baseUrl = SyncEngineService.serverBaseUrl.replaceAll(RegExp(r'/$'), '');
        final uri = Uri.parse('$baseUrl/api/sync/trip-dump-step');
        await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'trip_id': currentTripId,
            'dump_photo_url': dumpPhotoPath,
            'dump_lat': lat ?? currentEndLat,
            'dump_lng': lng ?? currentEndLng,
          }),
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[LocalStorageVault] Record trip dump step notice: $e');
      }
    }
  }

  /// CARD 3: Rekam Foto Nota Timbang / Invoice (Menyelesaikan Trip & Reset ke Card 1)
  Future<void> recordTripInvoice({
    required String invoicePhotoPath,
    double? lat,
    double? lng,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final tripSeq = todayTrips.length + 1;
    final completedTripId = currentTripId ?? 'TRP-${DateTime.now().millisecondsSinceEpoch}';

    final completedTrip = TripModel(
      tripId: completedTripId,
      projectId: currentProjectId,
      projectName: currentProjectName,
      driverId: currentDriver?.driverId ?? 'DRV-001',
      driverName: currentDriver?.fullName ?? 'Pengemudi',
      truckWheelType: currentTruckWheelType,
      tripSequence: tripSeq,
      loadPointName: currentStartPointName,
      dumpPointName: currentEndPointName,
      loadPhotoPath: currentLoadPhotoPath,
      dumpPhotoPath: currentDumpPhotoPath,
      invoicePhotoPath: invoicePhotoPath, // FOTO NOTA / SURAT JALAN
      loadTime: currentLoadTime ?? (now - 1200000),
      dumpTime: currentDumpTime ?? now,
      status: 'COMPLETED',
      loadDeviationM: 6.2,
      dumpDeviationM: 4.8,
    );

    todayTrips.insert(0, completedTrip);

    // State machine reset: Siap memuat kembali di Card 1!
    haulingStage = 'READY_TO_LOAD';
    currentTripId = null;
    currentLoadPhotoPath = null;
    currentDumpPhotoPath = null;
    currentLoadTime = null;
    currentDumpTime = null;
    notifyListeners();

    // Kirim finalisasi lengkap ke backend server
    try {
      final baseUrl = SyncEngineService.serverBaseUrl.replaceAll(RegExp(r'/$'), '');
      final uri = Uri.parse('$baseUrl/api/sync/trip-dump');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'trip_id': completedTripId,
          'dump_photo_url': completedTrip.dumpPhotoPath,
          'invoice_photo_url': invoicePhotoPath,
          'dump_lat': lat ?? currentEndLat,
          'dump_lng': lng ?? currentEndLng,
        }),
      ).timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('[LocalStorageVault] Record trip invoice complete notice: $e');
    }
  }
  void _seedDefaultData() {
    currentDriver = null;
    masterLocations.addAll([
      MasterLocationModel(
        locationId: 'LOC-PIT-02',
        code: 'PIT-02',
        name: 'Loading Point Pit 2 Barat',
        locationType: 'LOADING_POINT',
        material: 'Material Tambang Utama',
        elevationMsl: 120,
        latitude: -3.131000,
        longitude: 115.119000,
        radiusMeters: 250,
      ),
      MasterLocationModel(
        locationId: 'LOC-ROM-01',
        code: 'ROM-01',
        name: 'ROM Stockpile 1',
        locationType: 'DUMPING_POINT',
        material: 'Stockpile Penampungan',
        elevationMsl: 25,
        latitude: -3.145000,
        longitude: 115.148000,
        radiusMeters: 40,
      ),
    ]);

    todayTrips.clear();
    completedTasks.clear();
    activeTask = null;
    haulingStage = 'READY_TO_LOAD';
  }

  void addIncidentReport({
    required String category,
    required String description,
    String? photoPath,
    required double lat,
    required double lng,
  }) {
    notifyListeners();
  }

  void addActiveBreadcrumb(double lat, double lng, double speedKmh, double heading) {
    if (activeTask != null) {
      activeTask!.breadcrumbs.add(BreadcrumbModel(
        latitude: lat,
        longitude: lng,
        speedKmh: speedKmh,
        heading: heading,
        recordedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      notifyListeners();
    }
  }

  static double calculateHaversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) * math.cos(_degToRad(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
}
