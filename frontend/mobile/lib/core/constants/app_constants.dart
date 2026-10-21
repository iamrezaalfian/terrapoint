class AppConstants {
  AppConstants._();

  static const String appName = 'TerraPoint';
  static const String appVersion = '1.0.0-PROTOTYPE';

  // Mining Geofence & Precision Rules
  static const double defaultGeofenceRadiusMeters = 50.0;
  static const double requiredGpsAccuracyMeters = 25.0;
  
  // Storage & Retention
  static const int localSyncedPhotoRetentionDays = 3;
  static const int maxPhotoUploadSizeBytes = 150 * 1024; // 150 KB target
  
  // Default Mock Coordinates (Kalimantan Selatan Coal Mine Pit 3)
  static const double defaultPit3Lat = -3.123456;
  static const double defaultPit3Lng = 115.123456;
  static const String defaultPit3Name = 'Loading Point Pit 3 Utara';

  static const double defaultRom1Lat = -3.145000;
  static const double defaultRom1Lng = 115.148000;
  static const String defaultRom1Name = 'ROM Stockpile 1';
}
