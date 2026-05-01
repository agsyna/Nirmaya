import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_view_model.dart';
import 'access_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
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
        gradient: LinearGradient(
          colors: [Color(0xFF6A2C5B), Color(0xFF4A1F40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT SIDE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.menu, color: Colors.white70),
                    const SizedBox(height: 20),

                    const Text(
                      "Welcome",
                      style: TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      vm.user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        _info("Age", "${vm.user.age} yrs"),
                        const SizedBox(width: 20),
                        _info("Gender", vm.user.gender),
                        const SizedBox(width: 20),
                        _info("User ID", vm.user.id),
                      ],
                    ),
                  ],
                ),
              ),

              // RIGHT SIDE
             const Icon(Icons.qr_code_scanner, size: 40),
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
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
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
        _navCircle(Icons.emergency, "Emergency", () {}),
        _navCircle(Icons.description, "Records", () {}),
        _navCircle(Icons.link, "Access", () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AccessScreen(),
            ),
          );
        }),
        _navCircle(Icons.medication, "Medication", () {}),
      ],
    );
  }

  Widget _navCircle(
      IconData icon, String label, VoidCallback onTap) {
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
            child: Icon(icon, color: const Color(0xFF5B2E5A)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
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
            const Text(
              "Audit Logs",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
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
                      const Icon(Icons.access_time,
                          color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "${log.doctorName} accessed your reports at ${_formatTime(log.timestamp)}",
                          style: const TextStyle(fontSize: 13),
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
}