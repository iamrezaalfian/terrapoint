import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'database/services/local_store.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/camera/photo_capture_watermark_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider.value(
      value: LocalStorageVault.instance,
      child: const TerraPointApp(),
    ),
  );
}

enum AppFlowState {
  splash,       // Layar 0: Splash Screen Animasi
  login,        // Layar 1: Masuk Akun Pengemudi
  home,         // Layar 2: Beranda 4-Cards Utama
  photoLoad,    // Card 1: Foto Muatan di Pit (Radius Luas)
  photoDump,    // Card 2: Foto Pembongkaran Fisik di ROM (Radius Ketat)
  photoInvoice, // Card 3: Foto Nota Timbang / Surat Jalan
}

class TerraPointApp extends StatefulWidget {
  const TerraPointApp({super.key});

  @override
  State<TerraPointApp> createState() => _TerraPointAppState();
}

class _TerraPointAppState extends State<TerraPointApp> {
  AppFlowState _currentState = AppFlowState.splash;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TerraPoint Mining',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.cleanModernTheme,
      home: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    final vault = LocalStorageVault.instance;

    switch (_currentState) {
      // 0. Splash Screen
      case AppFlowState.splash:
        return SplashScreen(
          onSplashFinished: () {
            setState(() => _currentState = AppFlowState.login);
          },
        );

      // 1. Login Screen
      case AppFlowState.login:
        return LoginScreen(
          onLoginSuccess: () => setState(() => _currentState = AppFlowState.home),
        );

      // 2. Beranda 4-Cards Utama
      case AppFlowState.home:
        return HomeScreen(
          onLoadPhotoPressed: () {
            setState(() => _currentState = AppFlowState.photoLoad);
          },
          onDumpPhotoPressed: () {
            setState(() => _currentState = AppFlowState.photoDump);
          },
          onInvoicePhotoPressed: () {
            setState(() => _currentState = AppFlowState.photoInvoice);
          },
          onLogoutPressed: () {
            vault.clearDriverSession();
            setState(() => _currentState = AppFlowState.login);
          },
        );

      // Card 1: Foto Muatan di Pit (Radius Luas)
      case AppFlowState.photoLoad:
        final startLoc = MasterLocationModel(
          locationId: 'LOC-START',
          code: 'START',
          name: vault.currentStartPointName,
          locationType: 'LOADING_POINT',
          material: 'Material Tambang Utama',
          latitude: vault.currentStartLat,
          longitude: vault.currentStartLng,
          radiusMeters: vault.currentStartRadius,
        );
        return PhotoCaptureWatermarkScreen(
          checkpointType: 'LOAD',
          location: startLoc,
          onBackPressed: () => setState(() => _currentState = AppFlowState.home),
          onCaptureConfirmed: (photoPath) async {
            await vault.recordTripLoad(photoPath: photoPath);
            if (mounted) {
              setState(() => _currentState = AppFlowState.home);
            }
          },
        );

      // Card 2: Foto Pembongkaran di ROM (Radius Ketat)
      case AppFlowState.photoDump:
        final endLoc = MasterLocationModel(
          locationId: 'LOC-END',
          code: 'END',
          name: vault.currentEndPointName,
          locationType: 'DUMPING_POINT',
          material: 'Stockpile ROM',
          latitude: vault.currentEndLat,
          longitude: vault.currentEndLng,
          radiusMeters: vault.currentEndRadius,
        );
        return PhotoCaptureWatermarkScreen(
          checkpointType: 'DUMP',
          location: endLoc,
          onBackPressed: () => setState(() => _currentState = AppFlowState.home),
          onCaptureConfirmed: (photoPath) async {
            await vault.recordTripDump(dumpPhotoPath: photoPath);
            if (mounted) {
              setState(() => _currentState = AppFlowState.home);
            }
          },
        );

      // Card 3: Foto Nota Timbang / Invoice (Weighbridge)
      case AppFlowState.photoInvoice:
        final invoiceLoc = MasterLocationModel(
          locationId: 'LOC-INVOICE',
          code: 'INVOICE',
          name: '${vault.currentEndPointName} (Timbangan)',
          locationType: 'DUMPING_POINT',
          material: 'Dokumen Surat Jalan & Nota',
          latitude: vault.currentEndLat,
          longitude: vault.currentEndLng,
          radiusMeters: vault.currentEndRadius,
        );
        return PhotoCaptureWatermarkScreen(
          checkpointType: 'INVOICE',
          location: invoiceLoc,
          onBackPressed: () => setState(() => _currentState = AppFlowState.home),
          onCaptureConfirmed: (invoicePhotoPath) async {
            await vault.recordTripInvoice(invoicePhotoPath: invoicePhotoPath);
            if (mounted) {
              setState(() => _currentState = AppFlowState.home);
            }
          },
        );
    }
  }
}
