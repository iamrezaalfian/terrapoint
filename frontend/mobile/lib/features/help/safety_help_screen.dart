import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class SafetyHelpScreen extends StatelessWidget {
  final VoidCallback onBackToHome;

  const SafetyHelpScreen({super.key, required this.onBackToHome});

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
          'Bantuan & Keselamatan K3',
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
                'KANAL KOMUNIKASI DARURAT',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Contact 1: Radio Dispatcher
              _buildContactCard(
                icon: Icons.radio,
                iconColor: AppColors.accentAmberDark,
                iconBg: AppColors.amberContainer,
                title: 'Radio Dispatcher Pengawas Tambang',
                subtitle: 'Kanal Radio Ch-04 / 0812 3456 7890',
                actionLabel: 'Panggil',
                actionColor: AppColors.navyDeep,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.navyDeep,
                      content: Text('Menghubungkan ke Radio Kanal Ch-04...', style: GoogleFonts.inter()),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // Contact 2: WhatsApp Control Room
              _buildContactCard(
                icon: Icons.chat,
                iconColor: AppColors.statusSuccessText,
                iconBg: AppColors.statusSuccessBg,
                title: 'WhatsApp Control Room',
                subtitle: 'Chat Langsung Pengawas Lapangan',
                actionLabel: 'Chat',
                actionColor: AppColors.statusSuccess,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.statusSuccess,
                      content: Text('Membuka WhatsApp Control Room...', style: GoogleFonts.inter()),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              Text(
                'PEDOMAN KESELAMATAN K3 TAMBANG',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildRuleItem('1. Batas kecepatan maksimal di rute hauling adalah 40 km/jam.'),
                    const SizedBox(height: 8),
                    _buildRuleItem('2. Selalu hidupkan lampu rotary & radio komunikasi Ch-04.'),
                    const SizedBox(height: 8),
                    _buildRuleItem('3. Dilarang mengoperasikan HP di luar aplikasi pemantauan.'),
                  ],
                ),
              ),

              const Spacer(),

              OutlinedButton(
                onPressed: onBackToHome,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderStrong),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  'Kembali ke Beranda',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSub),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String actionLabel,
    required Color actionColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: Text(actionLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, size: 14, color: AppColors.statusSuccessText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSub, height: 1.3),
          ),
        ),
      ],
    );
  }
}
