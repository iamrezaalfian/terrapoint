import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../database/services/local_store.dart';

class IncidentReportScreen extends StatefulWidget {
  final VoidCallback onBackToHome;

  const IncidentReportScreen({super.key, required this.onBackToHome});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  int _selectedCategoryIndex = 0;
  final _categories = ['Mesin / Engine', 'Ban / Tire', 'Jalan Amblas', 'Lainnya'];
  final String _timestampStr = DateFormat('HH:mm:ss').format(DateTime.now());

  void _submitReport() {
    final vault = LocalStorageVault.instance;
    vault.addIncidentReport(
      category: _categories[_selectedCategoryIndex],
      description: 'Laporan kendala operasional hauling KM 3.8',
      photoPath: 'evd_incident_${DateTime.now().millisecondsSinceEpoch}.png',
      lat: -2.8295,
      lng: 122.1534,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.navyDeep,
        content: Text(
          'Laporan kendala berhasil dikirim ke Dispatcher!',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
    widget.onBackToHome();
  }

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
          onPressed: widget.onBackToHome,
        ),
        title: Text(
          'Lapor Kendala Lapangan',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PILIH KATEGORI KENDALA',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Category Selector 2x2 Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.8,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, idx) {
                  final isSelected = _selectedCategoryIndex == idx;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryIndex = idx),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.navyDeep : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.navyDeep : AppColors.borderSubtle,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _categories[idx],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textMain,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              Text(
                'BUKTI FOTO KENDALA (+ WATERMARK)',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Photo Container with Watermark Stamp Preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentAmber, width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_camera, size: 18, color: AppColors.accentAmberDark),
                        const SizedBox(width: 8),
                        Text(
                          'Bukti Foto Kendala Terlampir',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMain),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bgScreen,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_timestampStr WITA • KM 3.8 Haul Road',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.stampRedTime,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lat: -2.829500, Lng: 122.153400 • DRV-001 (Ahmad Fauzi)',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusError,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(
                  'Kirim Laporan ke Dispatcher',
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
}
