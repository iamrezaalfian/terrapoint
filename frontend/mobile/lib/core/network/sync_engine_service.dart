import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../database/services/local_store.dart';

class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;

  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
  });
}

class SyncEngineService {
  SyncEngineService._();

  /// Public Cloudflare Tunnel URL (No VPN / Tailscale required on driver phone)
  static String serverBaseUrl = 'https://affect-gary-begins-systematic.trycloudflare.com';
  static String authToken = '';

  /// 1. Manual Batch Sync (Driver-Facing at Camp / Wi-Fi)
  static Future<SyncResult> syncAllPendingTasks({
    required List<TaskModel> pendingTasks,
  }) async {
    if (pendingTasks.isEmpty) {
      return SyncResult(success: true, message: 'Tidak ada ritase yang perlu disinkronkan.');
    }

    int successCount = 0;

    for (final task in pendingTasks) {
      try {
        task.status = 'SYNCING';

        // A. Upload foto bukti ke VM/VPS Storage via Multipart
        String? startPhotoUrl;
        String? endPhotoUrl;

        if (task.startPhotoPath != null) {
          startPhotoUrl = await _uploadToVps(
            localPath: task.startPhotoPath!,
            taskId: task.taskId,
            checkpointType: 'START',
          );
        }

        if (task.endPhotoPath != null) {
          endPhotoUrl = await _uploadToVps(
            localPath: task.endPhotoPath!,
            taskId: task.taskId,
            checkpointType: 'END',
          );
        }

        // B. Siapkan Payload Sinkronisasi REST API VM/VPS
        final payload = {
          'task_id': task.taskId,
          'driver_id': task.driverId,
          'title': task.title,
          'start_point': {
            'name': task.startPointName,
            'lat': task.startLat,
            'lng': task.startLng,
            'radius': task.startRadius,
          },
          'end_point': {
            'name': task.endPointName ?? 'ROM Stockpile 1',
            'lat': task.endLat ?? -3.145000,
            'lng': task.endLng ?? 115.148000,
            'radius': task.endRadius,
          },
          'evidences': {
            'start': {
              'captured_lat': task.startLat,
              'captured_lng': task.startLng,
              'accuracy_meters': 4.2,
              'storage_url': startPhotoUrl ?? '/uploads/evidences/${task.taskId}_START.png',
              'captured_at': DateTime.fromMillisecondsSinceEpoch(task.createdAt).toIso8601String(),
            },
            if (endPhotoUrl != null || task.endPhotoPath != null)
              'end': {
                'captured_lat': task.endLat ?? -3.145000,
                'captured_lng': task.endLng ?? 115.148000,
                'accuracy_meters': 4.5,
                'storage_url': endPhotoUrl ?? '/uploads/evidences/${task.taskId}_END.png',
                'captured_at': DateTime.fromMillisecondsSinceEpoch(task.updatedAt).toIso8601String(),
              },
          },
          'actual_route': task.breadcrumbs.map((b) => {
            'lat': b.latitude,
            'lng': b.longitude,
            'speed': b.speedKmh,
            'heading': b.heading,
            'time': DateTime.fromMillisecondsSinceEpoch(b.recordedAt).toIso8601String(),
          }).toList(),
        };

        // C. Panggil REST API VM/VPS (/api/sync/task-complete)
        debugPrint('[SyncEngine] Mengirim payload ritase ke VPS: $serverBaseUrl/api/sync/task-complete');
        
        bool apiSuccess = false;
        try {
          final uri = Uri.parse('$serverBaseUrl/api/sync/task-complete');
          final response = await http.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode(payload),
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode >= 200 && response.statusCode < 300) {
            apiSuccess = true;
          }
        } catch (_) {
          // Fallback offline bila jaringan belum terkoneksi
          apiSuccess = false;
        }

        task.status = apiSuccess ? 'SYNCED' : 'PENDING_SYNC';
        task.updatedAt = DateTime.now().millisecondsSinceEpoch;
        if (apiSuccess) successCount++;
      } catch (e) {
        task.status = 'PENDING_SYNC';
        debugPrint('[SyncEngine] Error syncing task ${task.taskId}: $e');
      }
    }

    return SyncResult(
      success: successCount > 0,
      message: 'Berhasil menyinkronkan $successCount ritase ke server VM/VPS.',
      syncedCount: successCount,
    );
  }

  /// 2. Stealth Background Telemetry Ingestion (< 3 KB JSON chunk)
  static Future<bool> sendStealthBreadcrumbsChunk({
    required String taskId,
    required List<BreadcrumbModel> unsyncedPoints,
  }) async {
    if (unsyncedPoints.isEmpty) return true;

    try {
      final breadcrumbsPayload = unsyncedPoints.map((p) => {
        'latitude': p.latitude,
        'longitude': p.longitude,
        'speed_kmh': p.speedKmh,
        'heading': p.heading,
        'recorded_at': DateTime.fromMillisecondsSinceEpoch(p.recordedAt).toIso8601String(),
      }).toList();

      final url = Uri.parse('$serverBaseUrl/api/sync/breadcrumbs');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'task_id': taskId,
          'breadcrumbs': breadcrumbsPayload,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        for (final p in unsyncedPoints) {
          p.isStealthSynced = true;
        }
        return true;
      }
    } catch (e) {
      debugPrint('[SyncEngine] Stealth sync deferred (low/no signal): $e');
    }
    return false;
  }

  /// Multipart Evidence Photo Upload to VM/VPS Storage
  static Future<String> _uploadToVps({
    required String localPath,
    required String taskId,
    required String checkpointType,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      return '/uploads/evidences/${taskId}_$checkpointType.png';
    }

    try {
      final uri = Uri.parse('$serverBaseUrl/api/upload/evidence');
      final request = http.MultipartRequest('POST', uri);
      if (authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      request.fields['task_id'] = taskId;
      request.fields['checkpoint_type'] = checkpointType;
      request.files.add(await http.MultipartFile.fromPath('image', localPath));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['storage_url'] ?? data['relative_url'] ?? '/uploads/evidences/${taskId}_$checkpointType.png';
      }
    } catch (e) {
      debugPrint('[SyncEngine] Upload foto ke VPS gagal/offline: $e');
    }

    return '/uploads/evidences/${taskId}_$checkpointType.png';
  }
}
