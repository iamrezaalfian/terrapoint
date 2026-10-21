import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onSplashFinished;

  const SplashScreen({super.key, required this.onSplashFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isCheckingPermissions = true;
  bool _hasCameraPermission = false;
  bool _hasLocationPermission = false;
  bool _isPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();
    _checkAndEnforcePermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check jika user baru kembali dari Settings HP
      _checkAndEnforcePermissions();
    }
  }

  /// STRICT PERMISSION GATE: Tidak bisa lanjut jika belum izinkan kamera dan lokasi
  Future<void> _checkAndEnforcePermissions() async {
    if (kIsWeb) {
      widget.onSplashFinished();
      return;
    }

    setState(() => _isCheckingPermissions = true);

    try {
      // 1. Cek Status Kamera
      var camStatus = await Permission.camera.status;
      if (!camStatus.isGranted) {
        camStatus = await Permission.camera.request();
      }

      // 2. Cek Status Lokasi GPS
      var locStatus = await Permission.location.status;
      if (!locStatus.isGranted) {
        locStatus = await Permission.location.request();
      }

      var geoPerm = await Geolocator.checkPermission();
      if (geoPerm == LocationPermission.denied) {
        geoPerm = await Geolocator.requestPermission();
      }

      final cameraGranted = camStatus.isGranted;
      final locationGranted = locStatus.isGranted ||
          geoPerm == LocationPermission.always ||
          geoPerm == LocationPermission.whileInUse;

      final permDenied = camStatus.isPermanentlyDenied ||
          locStatus.isPermanentlyDenied ||
          geoPerm == LocationPermission.deniedForever;

      if (mounted) {
        setState(() {
          _isCheckingPermissions = false;
          _hasCameraPermission = cameraGranted;
          _hasLocationPermission = locationGranted;
          _isPermanentlyDenied = permDenied;
        });

        // HANYA jika KEDUA IZIN SUDAH DIBERIKAN, sistem diizinkan lanjut ke Login
        if (cameraGranted && locationGranted) {
          Timer(const Duration(milliseconds: 600), () {
            if (mounted) {
              widget.onSplashFinished();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[SplashScreen] Enforce permissions error: $e');
      if (mounted) {
        setState(() => _isCheckingPermissions = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bothGranted = _hasCameraPermission && _hasLocationPermission;

    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Animated Logo & Branding
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gradient Brand Logo
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accentAmberLight, AppColors.accentAmber],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentAmber.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'TP',
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppColors.navyDeep,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      Text(
                        'TerraPoint',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        'Sistem Telematika Hauling Tambang',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.accentAmberLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // BOTTOM PANEL: Jika Izin Ditolak, Tampilkan Gate Force Permission
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _isCheckingPermissions
                  ? Column(
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: AppColors.accentAmber,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Memverifikasi Izin Kamera & Sensor GPS...',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : (!bothGranted
                      ? _buildForcePermissionCard()
                      : Column(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.statusSuccess, size: 24),
                            const SizedBox(height: 8),
                            Text(
                              'Izin Kamera & Lokasi Terverifikasi!',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.statusSuccess,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )),
            ),
          ],
        ),
      ),
    );
  }

  /// WIDGET FORCE PERMISSION BLOCK: Tampil jika belum diizinkan
  Widget _buildForcePermissionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDC2626)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
              const SizedBox(width: 8),
              Text(
                'Izin Wajib Diperlukan',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'TerraPoint adalah sistem audit kepatuhan tambang. Anda TIDAK BISA MELANJUTKAN sebelum mengizinkan Kamera dan Lokasi GPS:',
            style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 12),

          // Status Izin Kamera
          _buildPermissionStatusRow(
            icon: Icons.camera_alt_rounded,
            label: 'Izin Kamera (Bukti Muat, Bongkar, & Nota)',
            isGranted: _hasCameraPermission,
          ),
          const SizedBox(height: 6),

          // Status Izin Lokasi
          _buildPermissionStatusRow(
            icon: Icons.location_on_rounded,
            label: 'Izin Lokasi Satelit GPS (Validasi Geofence Pit)',
            isGranted: _hasLocationPermission,
          ),
          const SizedBox(height: 14),

          // Tombol Tindakan
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(_isPermanentlyDenied ? Icons.settings : Icons.security, size: 18),
              label: Text(
                _isPermanentlyDenied ? 'Buka Pengaturan HP (App Settings)' : 'Berikan Izin Sekarang',
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
              onPressed: () async {
                if (_isPermanentlyDenied) {
                  await openAppSettings();
                } else {
                  await _checkAndEnforcePermissions();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionStatusRow({
    required IconData icon,
    required String label,
    required bool isGranted,
  }) {
    return Row(
      children: [
        Icon(
          isGranted ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isGranted ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isGranted ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
            ),
          ),
        ),
      ],
    );
  }
}
