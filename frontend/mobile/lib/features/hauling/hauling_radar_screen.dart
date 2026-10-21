import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../database/services/local_store.dart';

class HaulingRadarScreen extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onPhotoDumpingPressed;
  final VoidCallback onCancelPressed;

  const HaulingRadarScreen({
    super.key,
    required this.task,
    required this.onPhotoDumpingPressed,
    required this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Dalam Perjalanan',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.statusSuccessBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.statusSuccessBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.statusSuccess,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'LIVE TRACKING',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusSuccessText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radar Box
              Container(
                height: 170,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.navyDeep,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.navigation_outlined, color: Colors.white70, size: 30),
                          const SizedBox(height: 6),
                          Text(
                            'PETA KORIDOR HAULING',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '${task.startPointName} ➔ ${task.endPointName ?? "ROM Stockpile 1"}',
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-3.1350, 115.1350 • 33.8 km/jam',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3-Stage Progress Stepper
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check, size: 14, color: AppColors.statusSuccess),
                        const SizedBox(width: 4),
                        Text(
                          '1. Muat Pit',
                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.statusSuccessText),
                        ),
                      ],
                    ),
                    const Text('→', style: TextStyle(color: AppColors.borderStrong)),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: AppColors.accentAmber, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '2. Hauling',
                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.accentAmber),
                        ),
                      ],
                    ),
                    const Text('→', style: TextStyle(color: AppColors.borderStrong)),
                    Text(
                      '3. Bongkar ROM',
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Haulage Details Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Muatan Truk', '${task.material} (${task.payloadTon} Ton)'),
                    const Divider(color: AppColors.borderSubtle, height: 16),
                    _buildDetailRow('Destinasi Bongkar', task.endPointName ?? 'ROM Stockpile 1'),
                    _buildDetailRow('Estimasi Sisa Rute', '1.4 km (±5 menit)', isHighlight: true),
                  ],
                ),
              ),

              const Spacer(),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: onPhotoDumpingPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyDeep,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.photo_camera_outlined, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Ambil Foto Bongkar',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: onCancelPressed,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSub,
                        side: const BorderSide(color: AppColors.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text('Batal', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
            color: isHighlight ? AppColors.accentAmber : AppColors.textMain,
          ),
        ),
      ],
    );
  }
}
