import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../database/services/local_store.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onLoadPhotoPressed;
  final VoidCallback onDumpPhotoPressed;
  final VoidCallback onInvoicePhotoPressed;
  final VoidCallback onLogoutPressed;

  const HomeScreen({
    super.key,
    required this.onLoadPhotoPressed,
    required this.onDumpPhotoPressed,
    required this.onInvoicePhotoPressed,
    required this.onLogoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    final vault = LocalStorageVault.instance;
    final driver = vault.currentDriver;
    final trips = vault.todayTrips;
    final todayTripsCount = trips.length;

    // Strict sequential stage flags
    final canLoad = vault.canLoad;
    final canDump = vault.canDump;
    final canInvoice = vault.canInvoice;

    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.navyDeep,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'TP',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TerraPoint Mobile',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Hauling Compliance & Watermark',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // GPS Presisi Kanan Atas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF10B981),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.satellite_alt_rounded,
                  size: 13,
                  color: Color(0xFF34D399),
                ),
                const SizedBox(width: 5),
                Text(
                  'GPS ±3.8m',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF34D399),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.logout, size: 20, color: AppColors.textMuted),
            tooltip: 'Keluar',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  title: Text(
                    'Keluar Sesi Driver',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  content: Text(
                    'Apakah Anda ingin keluar dari sesi driver ${driver?.fullName ?? ''}?',
                    style: GoogleFonts.inter(fontSize: 13.5),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textMuted)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusError,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onLogoutPressed();
                      },
                      child: Text('Ya, Keluar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BANNER DRIVER & TOTAL TRIP HARIAN
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver?.fullName ?? 'Pengemudi Tambang',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${driver?.driverId ?? 'DRV-001'} • ${vault.currentProjectName}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Badge Jenis Roda Truk (Dapat diganti kapan saja)
                        GestureDetector(
                          onTap: () => _showWheelTypeDialog(context, vault),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFF59E0B)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  vault.currentTruckWheelType,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFBBF24),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_rounded, size: 12, color: Color(0xFFFBBF24)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL TRIP HARI INI:',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: Text(
                            '$todayTripsCount TRIP SELESAI',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF6EE7B7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==========================================
              // CARD 1: TITIK MUAT (PIT) - RADIUS LUAS (250m)
              // ==========================================
              _buildCard1Muat(
                context: context,
                canLoad: canLoad,
                isPast: !canLoad,
                startPointName: vault.currentStartPointName,
                radiusMeters: vault.currentStartRadius,
                onTap: canLoad ? onLoadPhotoPressed : null,
              ),

              const SizedBox(height: 12),

              // ==========================================
              // CARD 2: TITIK BONGKAR (ROM STOCKPILE) - FOTO DUMPING CURAH
              // ==========================================
              _buildCard2Dumping(
                context: context,
                canDump: canDump,
                isPast: canInvoice,
                isLocked: canLoad,
                endPointName: vault.currentEndPointName,
                radiusMeters: vault.currentEndRadius,
                onTap: canDump ? onDumpPhotoPressed : null,
              ),

              const SizedBox(height: 12),

              // ==========================================
              // CARD 3: FOTO NOTA TIMBANG / INVOICE (WEIGHBRIDGE)
              // ==========================================
              _buildCard3Invoice(
                context: context,
                canInvoice: canInvoice,
                isLocked: canLoad || canDump,
                onTap: canInvoice ? onInvoicePhotoPressed : null,
              ),

              const SizedBox(height: 16),

              // ==========================================
              // CARD 4: FOTO RIWAYAT (LOG PENGANTARAN HARI INI)
              // ==========================================
              _buildCard4Riwayat(
                context: context,
                trips: trips,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET CARD 1: TITIK MUAT (PIT)
  Widget _buildCard1Muat({
    required BuildContext context,
    required bool canLoad,
    required bool isPast,
    required String startPointName,
    required int radiusMeters,
    required VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canLoad ? AppColors.accentAmber : (isPast ? AppColors.statusSuccessBorder : AppColors.borderSubtle),
          width: canLoad ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: canLoad ? AppColors.accentAmber.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: canLoad ? AppColors.amberContainer : (isPast ? AppColors.statusSuccessBg : AppColors.bgScreen),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isPast ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                        color: isPast ? AppColors.statusSuccess : AppColors.accentAmberDark,
                        size: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Titik Muat (Pit)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: canLoad ? AppColors.amberContainer : AppColors.statusSuccessBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  canLoad ? 'SIAP AMBIL FOTO' : '✓ MUATAN TERCATAT',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: canLoad ? AppColors.onAmberContainer : AppColors.statusSuccessText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            startPointName,
            style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textMain),
          ),
          const SizedBox(height: 2),
          Text(
            'Radius Geofence Luas: $radiusMeters meter (Fleksibel Area Manuver)',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (canLoad) ...[
            // Selector Armada Truk
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.bgScreen,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jenis Mobil / Armada:',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSub),
                  ),
                  GestureDetector(
                    onTap: () => _showWheelTypeDialog(context, LocalStorageVault.instance),
                    child: Row(
                      children: [
                        Text(
                          LocalStorageVault.instance.currentTruckWheelType,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentAmberDark,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.arrow_drop_down_rounded, size: 17, color: AppColors.accentAmberDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyDeep,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.camera_alt_rounded, size: 17),
                label: Text(
                  'Ambil Foto Muatan di Pit',
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                onPressed: onTap,
              ),
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.statusSuccessBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.statusSuccessBorder),
              ),
              child: Text(
                '✓ Muatan selesai dicatat. Truk sedang menuju ROM Stockpile (Lanjut ke Card 2).',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.statusSuccessText, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  // WIDGET CARD 2: TITIK BONGKAR (FOTO DUMPING CURAH DI ROM)
  Widget _buildCard2Dumping({
    required BuildContext context,
    required bool canDump,
    required bool isPast,
    required bool isLocked,
    required String endPointName,
    required int radiusMeters,
    required VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: canDump ? const Color(0xFF10B981) : (isPast ? AppColors.statusSuccessBorder : AppColors.borderSubtle),
            width: canDump ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: canDump ? const Color(0xFF10B981).withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: canDump ? const Color(0xFFD1FAE5) : (isPast ? AppColors.statusSuccessBg : AppColors.bgScreen),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isPast ? Icons.check_circle_rounded : (canDump ? Icons.local_shipping_rounded : Icons.lock_outline_rounded),
                          color: isPast ? AppColors.statusSuccess : (canDump ? const Color(0xFF047857) : AppColors.textMuted),
                          size: 17,
                        ),
                      ),
                    ),
                    Text(
                      'Titik Bongkar (Curah ROM)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isLocked ? AppColors.textMuted : AppColors.textMain,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: canDump ? const Color(0xFFD1FAE5) : (isPast ? AppColors.statusSuccessBg : AppColors.bgScreen),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPast ? '✓ DUMPING SELESAI' : (canDump ? 'SIAP FOTO BONGKAR' : 'TERKUNCI'),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: isPast ? AppColors.statusSuccessText : (canDump ? const Color(0xFF047857) : AppColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              endPointName,
              style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: isLocked ? AppColors.textMuted : AppColors.textMain),
            ),
            Text(
              'Titik Bongkar Spesifik • Radius Ketat: $radiusMeters meter',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            if (canDump)
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.camera_alt_rounded, size: 17),
                  label: Text(
                    'Ambil Foto Fisik Bongkar di ROM',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  onPressed: onTap,
                ),
              )
            else if (isPast)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccessBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.statusSuccessBorder),
                ),
                child: Text(
                  '✓ Foto pembongkaran fisik curah tersimpan. Lanjut ke Card 3 untuk foto nota.',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.statusSuccessText, fontWeight: FontWeight.w500),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.bgScreen,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  'Kunci: Selesaikan foto muatan di Titik Muat terlebih dahulu.',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // WIDGET CARD 3: FOTO NOTA TIMBANG / INVOICE (WEIGHBRIDGE)
  Widget _buildCard3Invoice({
    required BuildContext context,
    required bool canInvoice,
    required bool isLocked,
    required VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: canInvoice ? const Color(0xFF3B82F6) : AppColors.borderSubtle,
            width: canInvoice ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: canInvoice ? const Color(0xFF3B82F6).withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: canInvoice ? const Color(0xFFDBEAFE) : AppColors.bgScreen,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          canInvoice ? Icons.receipt_long_rounded : Icons.lock_outline_rounded,
                          color: canInvoice ? const Color(0xFF2563EB) : AppColors.textMuted,
                          size: 17,
                        ),
                      ),
                    ),
                    Text(
                      'Foto Nota Timbang / Invoice',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isLocked ? AppColors.textMuted : AppColors.textMain,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: canInvoice ? const Color(0xFFDBEAFE) : AppColors.bgScreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    canInvoice ? 'SIAP FOTO NOTA' : 'TERKUNCI',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: canInvoice ? const Color(0xFF1D4ED8) : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Slip Timbangan Jembatan Timbang (Weighbridge)',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isLocked ? AppColors.textMuted : AppColors.textMain),
            ),
            const SizedBox(height: 2),
            Text(
              'Foto fisik surat jalan / tiket nota timbangan resmi sebelum menyelesaikan trip',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            if (canInvoice)
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.camera_alt_rounded, size: 17),
                  label: Text(
                    'Ambil Foto Nota Timbang & Selesaikan',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  onPressed: onTap,
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.bgScreen,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  'Kunci: Selesaikan foto pembongkaran curah di Card 2 terlebih dahulu.',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // WIDGET CARD 4: RIWAYAT PENGANTARAN HARI INI (MENAMPILKAN 3 FOTO)
  Widget _buildCard4Riwayat({
    required BuildContext context,
    required List<TripModel> trips,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.bgScreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.photo_library_outlined, color: AppColors.textMain, size: 17),
                    ),
                  ),
                  Text(
                    'Riwayat Foto Hari Ini',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),
              Text(
                '${trips.length} Pengantaran',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (trips.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.bgScreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Belum ada riwayat pengantaran hari ini.\nSelesaikan foto muat, bongkar, dan nota pertama Anda.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trips.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final trip = trips[idx];
                final timeStr = trip.dumpTime != null
                    ? DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(trip.dumpTime!))
                    : 'Selesai';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgScreen,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Trip #${trip.tripSequence} • $timeStr WITA',
                            style: GoogleFonts.inter(
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
                              'VERIFIED',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.statusSuccessText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 3 Foto Thumbnails: Foto Muat, Foto Bongkar, Foto Nota
                      Row(
                        children: [
                          Expanded(
                            child: _buildPhotoThumb(
                              context: ctx,
                              label: 'Muat Pit',
                              photoPath: trip.loadPhotoPath,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPhotoThumb(
                              context: ctx,
                              label: 'Bongkar ROM',
                              photoPath: trip.dumpPhotoPath,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPhotoThumb(
                              context: ctx,
                              label: 'Nota Timbang',
                              photoPath: trip.invoicePhotoPath,
                              isInvoice: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumb({
    required BuildContext context,
    required String label,
    required String? photoPath,
    bool isInvoice = false,
  }) {
    final hasFile = photoPath != null && photoPath.isNotEmpty;
    final file = hasFile ? File(photoPath) : null;
    final exists = file != null && file.existsSync();

    return GestureDetector(
      onTap: () {
        if (hasFile) {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: const Color(0xFF0F172A),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      if (exists)
                        Image.file(file, fit: BoxFit.contain)
                      else
                        Container(
                          height: 180,
                          color: Colors.white10,
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
                          ),
                        ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 62,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isInvoice ? const Color(0xFF3B82F6).withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isInvoice ? const Color(0xFF3B82F6).withValues(alpha: 0.4) : AppColors.borderSubtle,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: exists
                  ? Image.file(file, fit: BoxFit.cover)
                  : Center(
                      child: Icon(
                        isInvoice ? Icons.receipt_long_rounded : Icons.photo_camera_outlined,
                        size: 20,
                        color: isInvoice ? const Color(0xFF3B82F6) : AppColors.textMuted,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: isInvoice ? const Color(0xFF2563EB) : AppColors.textSub,
            ),
          ),
        ],
      ),
    );
  }

  void _showWheelTypeDialog(BuildContext context, LocalStorageVault vault) {
    final options = [
      '4 Roda (Pick-up / Engkel)',
      '6 Roda (Dump Truck)',
      '10 Roda (Tronton)',
      '12 Roda (Trailer Heavy)',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pilih Jenis Roda Kendaraan',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textMain),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  'Pilih jenis armada truk yang sedang Anda gunakan untuk pengantaran ini:',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                ...options.map((opt) {
                  final isSelected = opt == vault.currentTruckWheelType;
                  return InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await vault.updateTruckWheelType(opt);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.navyDeep,
                            content: Text(
                              'Armada diubah ke: $opt',
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.amberContainer : AppColors.bgScreen,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.accentAmber : AppColors.borderSubtle,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                size: 18,
                                color: isSelected ? AppColors.accentAmberDark : AppColors.textMuted,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                opt,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.onAmberContainer : AppColors.textMain,
                                ),
                              ),
                            ],
                          ),
                          if (isSelected)
                            Text(
                              'AKTIF',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accentAmberDark,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
