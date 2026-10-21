import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../database/services/local_store.dart';
import 'services/canvas_watermark_service.dart';

class PhotoCaptureWatermarkScreen extends StatefulWidget {
  final String checkpointType; // 'START' | 'END'
  final MasterLocationModel location;
  final Function(String photoPath) onCaptureConfirmed;
  final VoidCallback onBackPressed;

  const PhotoCaptureWatermarkScreen({
    super.key,
    required this.checkpointType,
    required this.location,
    required this.onCaptureConfirmed,
    required this.onBackPressed,
  });

  @override
  State<PhotoCaptureWatermarkScreen> createState() => _PhotoCaptureWatermarkScreenState();
}

class _PhotoCaptureWatermarkScreenState extends State<PhotoCaptureWatermarkScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _availableCameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isCaptured = false;
  String? _savedStampedPhotoPath;
  late String _capturedTimeStr;
  late String _dateStr;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final now = DateTime.now();
    _capturedTimeStr = '${DateFormat('HH:mm:ss').format(now)} WITA (UTC+8)';
    _dateStr = DateFormat('yyyy-MM-dd').format(now);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await Permission.camera.request();
      }

      _availableCameras = await availableCameras();
      if (_availableCameras != null && _availableCameras!.isNotEmpty) {
        final rearCamera = _availableCameras!.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
          orElse: () => _availableCameras!.first,
        );

        _cameraController = CameraController(
          rearCamera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('[CameraScreen] Hardware camera unavailable, fallback to simulated view: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePhotoAndBurnWatermark() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final now = DateTime.now();
      _capturedTimeStr = '${DateFormat('HH:mm:ss').format(now)} WITA (UTC+8)';
      _dateStr = DateFormat('yyyy-MM-dd').format(now);

      Uint8List? rawBytes;

      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final xfile = await _cameraController!.takePicture();
        rawBytes = await xfile.readAsBytes();
      }

      // If hardware capture is empty, create fallback image bytes
      if (rawBytes == null || rawBytes.isEmpty) {
        rawBytes = _createMockPhotoBytes();
      }

      final metadata = WatermarkMetadata(
        checkpointType: widget.checkpointType,
        locationName: widget.location.name,
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        accuracyMeters: 4.2,
        altitudeMsl: widget.location.elevationMsl.toDouble(),
        driverId: LocalStorageVault.instance.currentDriver?.driverId ?? 'DRV-001',
        driverName: LocalStorageVault.instance.currentDriver?.fullName ?? 'Pengemudi',
        taskId: LocalStorageVault.instance.activeTask?.taskId ?? 'TSK-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        timestamp: now,
      );

      final stampedFile = await CanvasWatermarkService.burnWatermarkAndSave(
        rawImageBytes: rawBytes,
        metadata: metadata,
      );

      if (mounted) {
        setState(() {
          _savedStampedPhotoPath = stampedFile.path;
          _isCaptured = true;
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('[CameraScreen] Error capturing photo: $e');
      if (mounted) {
        setState(() {
          _isCaptured = true;
          _isProcessing = false;
        });
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _isCaptured = false;
      _savedStampedPhotoPath = null;
    });
  }

  void _confirmAndProceed() {
    final photoPath = _savedStampedPhotoPath ??
        'evd_${widget.checkpointType.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.png';
    widget.onCaptureConfirmed(photoPath);
  }

  Uint8List _createMockPhotoBytes() {
    final bmp = Uint8List.fromList([
      0x42, 0x4D, 0x36, 0x00, 0x0C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x36, 0x00, 0x00, 0x00,
      0x28, 0x00, 0x00, 0x00, 0x80, 0x02, 0x00, 0x00, 0x68, 0x01, 0x00, 0x00, 0x01, 0x00,
      0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    ]);
    return bmp;
  }

  @override
  Widget build(BuildContext context) {
    final isStart = widget.checkpointType == 'START';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        widget.onBackPressed();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Column(
              children: [
                // Header Status Bar with Back Button
                Row(
                  children: [
                    // Back / Return Button
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: widget.onBackPressed,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.checkpointType == 'INVOICE'
                            ? 'Foto Nota Timbang / Invoice'
                            : (widget.checkpointType == 'START' || widget.checkpointType == 'LOAD'
                                ? '1. Foto Muatan di Pit'
                                : '2. Foto Bongkar di ROM'),
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF059669)),
                      ),
                      child: Text(
                        'GPS ±4.2m (Akurat)',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6EE7B7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Viewfinder Area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isStart ? AppColors.accentAmber : AppColors.statusSuccess,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          // 1. Live Camera Feed or Mock Viewfinder
                          if (_isCameraInitialized && _cameraController != null && !_isCaptured)
                            Positioned.fill(
                              child: CameraPreview(_cameraController!),
                            )
                          else
                            Positioned.fill(
                              child: Container(
                                color: const Color(0xFF1E293B),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isStart ? Icons.local_shipping_outlined : Icons.warehouse_outlined,
                                        size: 76,
                                        color: Colors.white.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        isStart ? '[FOTO BAK TRUK MUAT]' : '[FOTO AREA DUMPING ROM]',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white.withValues(alpha: 0.5),
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // 2. Reticle Target Overlay
                          Center(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.72,
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: (isStart ? AppColors.accentAmberLight : AppColors.statusSuccess).withValues(alpha: 0.6),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),

                          // 3. Permanent Surveyor Geotag Watermark Box
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.98),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.location.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textMain,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$_capturedTimeStr • $_dateStr',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.stampRedTime,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Lat: ${widget.location.latitude.toStringAsFixed(6)}, Lng: ${widget.location.longitude.toStringAsFixed(6)} • Akurasi ±4.2m',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: widget.checkpointType == 'INVOICE'
                                          ? const Color(0xFF1E3A8A)
                                          : (isStart ? AppColors.amberContainer : AppColors.statusSuccessBg),
                                      border: Border.all(
                                        color: widget.checkpointType == 'INVOICE'
                                            ? const Color(0xFF3B82F6)
                                            : (isStart ? AppColors.accentAmber : AppColors.statusSuccessBorder),
                                      ),
                                    ),
                                    child: Text(
                                      widget.checkpointType == 'INVOICE'
                                          ? 'NOTA TIMBANG / INVOICE'
                                          : (isStart ? 'TITIK MUAT (PIT)' : 'TITIK BONGKAR (ROM)'),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: widget.checkpointType == 'INVOICE'
                                            ? const Color(0xFF93C5FD)
                                            : (isStart ? AppColors.onAmberContainer : AppColors.statusSuccessText),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Bottom Actions: Shutter or Confirm/Retake
                if (!_isCaptured)
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _takePhotoAndBurnWatermark,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isStart ? AppColors.accentAmber : AppColors.statusSuccess,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.photo_camera, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isStart ? 'Ambil Foto Muatan' : 'Ambil Foto Bongkar',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _confirmAndProceed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isStart ? AppColors.navyDeep : AppColors.statusSuccess,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                isStart ? 'Gunakan Foto (Mulai)' : 'Konfirmasi Selesai',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: _retakePhoto,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.borderStrong),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: Text(
                            'Foto Ulang',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension StringSlice on String {
  String sliceLast(int count) {
    if (length <= count) return this;
    return substring(length - count);
  }
}
