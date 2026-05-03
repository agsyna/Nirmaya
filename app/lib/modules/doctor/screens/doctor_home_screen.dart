import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../app/views/login_screen.dart';
import 'scan_qr_screen.dart';
import 'access_history_screen.dart';
import '../provider/doctor_provider.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  static const Map<String, String> _specializationLabels = {
    'cardiology': 'Cardiology',
    'dermatology': 'Dermatology',
    'endocrinology': 'Endocrinology',
    'ent': 'ENT',
    'family_medicine': 'Family Medicine',
    'gastroenterology': 'Gastroenterology',
    'general_medicine': 'General Medicine',
    'gynecology': 'Gynecology',
    'neurology': 'Neurology',
    'oncology': 'Oncology',
    'ophthalmology': 'Ophthalmology',
    'orthopedics': 'Orthopedics',
    'pediatrics': 'Pediatrics',
    'psychiatry': 'Psychiatry',
    'radiology': 'Radiology',
    'urology': 'Urology',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().fetchRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctorProvider = context.watch<DoctorProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 10),
            Transform.translate(
              offset: const Offset(0, -40),
              child: _buildNavRow(context),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildRecentRequests(doctorProvider),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final specialization = _displaySpecialization(user?.specialization);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 80),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _showDrawerMenu(context),
                  child: const Icon(Icons.menu, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.name ?? 'Doctor',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _info('Role', 'Doctor'),
                    const SizedBox(width: 20),
                    _info('Speciality', specialization),
                  ],
                ),
              ],
            ),
          ),
          // Container(
          //   padding: const EdgeInsets.all(10),
          //   decoration: BoxDecoration(
          //     color: Colors.white.withValues(alpha: 0.15),
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: Icon(
          //     (user?.doctorVerified ?? false)
          //         ? Icons.verified
          //         : Icons.medical_services,
          //     size: 28,
          //     color: Colors.white,
          //   ),
          // ),
        ],
      ),
    );
  }

  String _displaySpecialization(String? specialization) {
    if (specialization == null || specialization.trim().isEmpty) {
      return 'General Physician';
    }

    final key = specialization.trim().toLowerCase();
    final mapped = _specializationLabels[key];
    if (mapped != null) return mapped;

    return key
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Widget _info(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 110,
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _navCircle(Icons.qr_code_scanner, 'Scan QR', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanQrScreen()),
          );
        }),
        _navCircle(Icons.history, 'History', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccessHistoryScreen()),
          );
        }),
      ],
    );
  }

  Widget _navCircle(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecentRequests(DoctorProvider provider) {
    if (provider.isLoading && provider.accessRequests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Requests',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => provider.fetchRequests(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (provider.accessRequests.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No access requests found.',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
          )
        else
          Column(
            children: provider.accessRequests.take(3).map((request) {
              final status = (request['status'] ?? 'pending').toString();
              final patientName = (request['patientName'] ?? 'Unknown Patient')
                  .toString();
              final statusColor = _statusColor(status);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      // decoration: BoxDecoration(
                      //   color: statusColor.withValues(alpha: 0.12),
                      //   borderRadius: BorderRadius.circular(10),
                      // ),
                      child: Icon(
                        Icons.person_outline,
                        color: statusColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$patientName • ${status.toUpperCase()}',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
      case 'revoked':
      case 'expired':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  void _showDrawerMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _menuItem(Icons.qr_code_scanner, 'Scan QR', () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanQrScreen()),
              );
            }),
            _menuItem(Icons.history, 'Access History', () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccessHistoryScreen()),
              );
            }),
            const Divider(),
            _menuItem(Icons.logout, 'Logout', () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            }, color: AppColors.error),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color ?? AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}
