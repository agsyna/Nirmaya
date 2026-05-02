import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/home_view_model.dart';
import 'access_screen.dart';
import 'records_screen.dart';
import 'medications_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),

            const SizedBox(height: 10),

            // Floating buttons
            Transform.translate(
              offset: const Offset(0, -40),
              child: _buildNavRow(context),
            ),

            const SizedBox(height: 10),

            // Audit Logs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildAuditLogs(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context) {
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
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          final vm = context.watch<HomeViewModel>();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT SIDE
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
                      "Welcome",
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      user?.name ?? vm.user.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        _info("Age", "${user?.age ?? vm.user.age} yrs"),
                        const SizedBox(width: 20),
                        _info("Gender", user?.gender ?? vm.user.gender),
                        const SizedBox(width: 20),
                        _info(
                          "Blood",
                          user?.bloodGroup ?? "—",
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // RIGHT SIDE
              GestureDetector(
                onTap: () {
                  // QR code scanner
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================= INFO ITEM =================
  Widget _info(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ================= NAVIGATION =================
  Widget _buildNavRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _navCircle(Icons.emergency, "Emergency", () {
          // TODO: Emergency SOS
        }),
        _navCircle(Icons.description, "Records", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecordsScreen()),
          );
        }),
        _navCircle(Icons.link, "Access", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccessScreen()),
          );
        }),
        _navCircle(Icons.medication, "Medication", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MedicationsScreen()),
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
                )
              ],
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ================= AUDIT LOGS =================
  Widget _buildAuditLogs() {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Audit Logs",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            Column(
              children: vm.logs.map((log) {
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
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.access_time,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "${log.doctorName} accessed your reports at ${_formatTime(log.timestamp)}",
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  // ================= TIME FORMAT =================
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  // ================= DRAWER MENU =================
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
            _menuItem(Icons.person_outline, 'Profile', () {
              Navigator.pop(ctx);
            }),
            _menuItem(Icons.description, 'Medical Records', () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecordsScreen()),
              );
            }),
            _menuItem(Icons.medication, 'Medications', () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedicationsScreen()),
              );
            }),
            _menuItem(Icons.settings, 'Settings', () {
              Navigator.pop(ctx);
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

  Widget _menuItem(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
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