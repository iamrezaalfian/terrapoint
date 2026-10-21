import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '../../core/network/sync_engine_service.dart';
import '../../database/services/local_store.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _driverIdController = TextEditingController(text: 'DRV-001');
  final _pinController = TextEditingController(text: '123456');
  bool _isLoading = false;

  void _handleLogin() async {
    final driverId = _driverIdController.text.trim().toUpperCase();
    final pin = _pinController.text.trim();

    if (driverId.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Pengemudi dan PIN wajib diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final baseUrl = SyncEngineService.serverBaseUrl.replaceAll(RegExp(r'/$'), '');
      final uri = Uri.parse('$baseUrl/api/auth/driver-login');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'driver_id': driverId, 'pin': pin}),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final driverData = data['driver'] ?? {};
        final token = data['token'] ?? '';
        final name = driverData['full_name'] ?? driverId;
        final phone = driverData['phone_number'] ?? '';

        SyncEngineService.authToken = token;
        LocalStorageVault.instance.setDriverSession(
          driverId: driverId,
          fullName: name,
          phoneNumber: phone,
          token: token,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          widget.onLoginSuccess();
        }
      } else {
        final errorMsg = data['error'] ?? 'ID Driver atau PIN tidak sesuai.';
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.statusError,
            ),
          );
        }
      }
    } catch (e) {
      // Fallback for offline usage when vehicle is inside mining pit without signal
      final fallbackNames = {
        'DRV-001': 'Ahmad Fauzi',
        'DRV-002': 'Budi Santoso',
        'DRV-003': 'Hendra Saputra',
      };
      final fallbackName = fallbackNames[driverId] ?? 'Pengemudi $driverId';

      LocalStorageVault.instance.setDriverSession(
        driverId: driverId,
        fullName: fallbackName,
        phoneNumber: '081234567890',
        token: 'offline_token_$driverId',
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mode Offline: Masuk sebagai $fallbackName ($driverId)'),
            backgroundColor: AppColors.statusWarning,
          ),
        );
        widget.onLoginSuccess();
      }
    }
  }
  void _showServerConfigDialog() {
    final controller = TextEditingController(text: SyncEngineService.serverBaseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Konfigurasi Backend Server', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Server Base URL (Tailscale / VPS / NOC):', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: GoogleFonts.jetBrainsMono(fontSize: 13),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: 'https://alot-lane-blackberry-herb.trycloudflare.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              SyncEngineService.serverBaseUrl = controller.text.trim();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Server URL diatur ke: ${SyncEngineService.serverBaseUrl}')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyDeep),
            child: Text('Simpan', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _driverIdController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top System Bar Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '08:00',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: _showServerConfigDialog,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.dns_outlined, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                'SERVER',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.wifi, size: 14, color: AppColors.textSub),
                      const SizedBox(width: 4),
                      const Icon(Icons.battery_full, size: 14, color: AppColors.textSub),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // Brand Header (Clean & Minimalist)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.navyDeep,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'TP',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'TerraPoint',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Sistem Logistik & Hauling Tambang',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // Quick Driver Selection Chips for Testing
              Row(
                children: [
                  _buildDriverChip('DRV-001', 'Ahmad'),
                  const SizedBox(width: 8),
                  _buildDriverChip('DRV-002', 'Budi'),
                  const SizedBox(width: 8),
                  _buildDriverChip('DRV-003', 'Hendra'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'ID Pengemudi',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSub,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _driverIdController,
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textMain,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bgScreen,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'PIN Shift (6 Digit)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSub,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _pinController,
                obscureText: true,
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textMain,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bgScreen,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyDeep,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Masuk ke Dashboard',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
              ),

              const Spacer(),

              Center(
                child: Text(
                  'TerraPoint Mobile Driver Client',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverChip(String id, String label) {
    final isSelected = _driverIdController.text.trim().toUpperCase() == id;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _driverIdController.text = id;
            _pinController.text = '123456';
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navyDeep : AppColors.bgScreen,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.navyDeep : AppColors.borderSubtle,
            ),
          ),
          child: Column(
            children: [
              Text(
                id,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textMain,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
