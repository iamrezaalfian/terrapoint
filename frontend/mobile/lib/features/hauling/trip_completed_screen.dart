import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../database/services/local_store.dart';

class TripCompletedScreen extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onBackToHome;

  const TripCompletedScreen({
    super.key,
    required this.task,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            children: [
              const Spacer(),

              // Success Icon Circle
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.statusSuccessBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.statusSuccessBorder, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.statusSuccess.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: AppColors.statusSuccessText, size: 36),
              ),
              const SizedBox(height: 16),

              Text(
                'Ritase Berhasil Selesai',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Data kepatuhan rute tersimpan aman di perangkat.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              // Task Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          task.taskId,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.statusSuccessBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.statusSuccessBorder),
                          ),
                          child: Text(
                            'TERVERIFIKASI',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.statusSuccessText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 20),
                    _buildSummaryRow('Rute Hauling', '${task.startPointName} → ${task.endPointName ?? "ROM Stockpile 1"}'),
                    const SizedBox(height: 10),
                    _buildSummaryRow('Total Muatan', '${task.payloadTon} Ton (${task.material})'),
                    const SizedBox(height: 10),
                    _buildSummaryRow('Jarak Tempuh', '${task.distanceKm} km', isHighlight: true),
                    const SizedBox(height: 10),
                    _buildSummaryRow('Durasi Ritase', '${task.durationMin} menit'),
                  ],
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: onBackToHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyDeep,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(
                  'Kembali ke Beranda',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.accentAmberDark : AppColors.textMain,
          ),
        ),
      ],
    );
  }
}
