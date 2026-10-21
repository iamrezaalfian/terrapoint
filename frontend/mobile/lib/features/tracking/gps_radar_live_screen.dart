import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class GpsRadarLiveScreen extends StatelessWidget {
  final VoidCallback onBackToHome;

  const GpsRadarLiveScreen({super.key, required this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: onBackToHome,
        ),
        title: Text(
          'Radar GPS Telemetri',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.statusErrorBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.statusErrorText),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              // Radar Screen Mockup
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.navyDeep,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.navySlate),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.radar, color: AppColors.accentAmberLight, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'PETA RADAR TELEMETRI',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentAmberLight,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pelacakan Koordinat & Elevasi Real-Time',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Live Telemetry Stats Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Unit Dump Truck', 'DT-104 (B 9234 KZ)'),
                    const Divider(color: AppColors.borderSubtle, height: 18),
                    _buildStatRow('Kecepatan Aktual', '33.8 km/jam', valueColor: AppColors.statusSuccessText),
                    const Divider(color: AppColors.borderSubtle, height: 18),
                    _buildStatRow('Elevasi Tambang', '+85m RL (Pit Ramp)', valueColor: AppColors.accentAmberDark),
                    const Divider(color: AppColors.borderSubtle, height: 18),
                    _buildStatRow('Akurasi Satelit', '±4.2 meter • 14 Satelit Aktif'),
                  ],
                ),
              ),

              const Spacer(),

              Text(
                'Sinkronisasi Otomatis Setiap 3 Detik',
                style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textMain,
          ),
        ),
      ],
    );
  }
}
