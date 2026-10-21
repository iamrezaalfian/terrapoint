import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../database/services/local_store.dart';

class ShiftHistoryScreen extends StatelessWidget {
  final VoidCallback onBackToHome;

  const ShiftHistoryScreen({super.key, required this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    final vault = LocalStorageVault.instance;
    final tasks = vault.completedTasks;
    final totalTons = tasks.fold<double>(0.0, (acc, t) => acc + t.payloadTon);

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain, size: 20),
          onPressed: onBackToHome,
        ),
        title: Text(
          'Riwayat Ritase Shift',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shift Summary Card (Flat Slate-900)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navyDeep,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL MUATAN SHIFT HARI INI',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white60,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tasks.length} Ritase • ${totalTons.toStringAsFixed(1)} Ton Ore',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'DAFTAR RITASE TERSELESAIKAN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Task List
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada ritase selesai pada shift ini.',
                          style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            task.taskId,
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textMain,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.statusSuccessBg,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'SELESAI',
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.statusSuccessText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${task.startPointName} → ${task.endPointName ?? "ROM Smelter 1"}',
                                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${task.payloadTon} Ton • ${task.distanceKm} km (${task.durationMin} mnt)',
                                        style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
