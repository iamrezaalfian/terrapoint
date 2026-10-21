import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../database/services/local_store.dart';

class BackgroundTrackingService {
  BackgroundTrackingService._();

  static StreamSubscription<Position>? _positionStreamSub;
  static String? _currentTaskId;
  static Position? _lastRecordedPosition;
  static DateTime? _lastRecordedTime;

  static const double minDistanceDeltaMeters = 50.0;
  static const int minTimeDeltaSeconds = 30;
  static const double minMovingSpeedKmh = 3.0;

  static bool get isTracking => _positionStreamSub != null;

  /// Start recording haul road route breadcrumbs
  static Future<void> startTracking(String taskId) async {
    _currentTaskId = taskId;
    _lastRecordedPosition = null;
    _lastRecordedTime = null;

    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      debugPrint('[TrackingService] Location permission not granted');
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25, // Hardware filter
    );

    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_handleLocationUpdate);

    debugPrint('[TrackingService] Started background tracking for task $taskId');
  }

  /// Stop tracking when dump photo is taken
  static Future<void> stopTracking() async {
    await _positionStreamSub?.cancel();
    _positionStreamSub = null;
    _currentTaskId = null;
    _lastRecordedPosition = null;
    _lastRecordedTime = null;
    debugPrint('[TrackingService] Stopped background tracking');
  }

  static void _handleLocationUpdate(Position position) {
    if (_currentTaskId == null) return;

    // 1. Check Mock Location Security
    if (position.isMocked) {
      debugPrint('[TrackingService] WARNING: Mock GPS detected, ignoring coordinate.');
      return;
    }

    final now = DateTime.now();
    final speedKmh = position.speed * 3.6; // Convert m/s to km/h

    // 2. Stationary Filter & Haversine Delta Evaluation
    bool shouldRecord = false;

    if (_lastRecordedPosition == null || _lastRecordedTime == null) {
      shouldRecord = true;
    } else {
      final distance = LocalStorageVault.calculateHaversineMeters(
        _lastRecordedPosition!.latitude,
        _lastRecordedPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      final timeDiffSec = now.difference(_lastRecordedTime!).inSeconds;

      // Record if moved >= 50m OR >= 30s have passed while in motion
      if (distance >= minDistanceDeltaMeters) {
        shouldRecord = true;
      } else if (timeDiffSec >= minTimeDeltaSeconds && speedKmh >= minMovingSpeedKmh) {
        shouldRecord = true;
      }
    }

    if (shouldRecord) {
      _lastRecordedPosition = position;
      _lastRecordedTime = now;

      LocalStorageVault.instance.addActiveBreadcrumb(
        position.latitude,
        position.longitude,
        speedKmh,
        position.heading,
      );

      debugPrint(
        '[TrackingService] Recorded breadcrumb: (${position.latitude}, ${position.longitude}) speed: ${speedKmh.toStringAsFixed(1)} km/h',
      );
    }
  }

  static Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }
}
