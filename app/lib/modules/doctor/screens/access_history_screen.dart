import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../provider/doctor_provider.dart';
import 'doctor_patient_data_screen.dart';

class AccessHistoryScreen extends StatefulWidget {
  const AccessHistoryScreen({super.key});

  @override
  State<AccessHistoryScreen> createState() => _AccessHistoryScreenState();
}

class _AccessHistoryScreenState extends State<AccessHistoryScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DoctorProvider>(context, listen: false).fetchRequests();
    });
    
    // Update UI every second for the countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimeLeft(String expiresAtStr) {
    try {
      final expiresAt = DateTime.parse(expiresAtStr).toLocal();
      final now = DateTime.now();
      final difference = expiresAt.difference(now);

      if (difference.isNegative) return 'Expired';

      final hours = difference.inHours.toString().padLeft(2, '0');
      final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');

      if (difference.inHours > 0) {
        return 'Expires in $hours:$minutes:$seconds';
      }
      return 'Expires in $minutes:$seconds';
    } catch (_) {
      return 'Unknown expiry';
    }
  }

  bool _isExpired(String expiresAtStr) {
    try {
      final expiresAt = DateTime.parse(expiresAtStr).toLocal();
      return DateTime.now().isAfter(expiresAt);
    } catch (_) {
      return true;
    }
  }

  void _openPatientData(Map<String, dynamic> request) async {
    final provider = Provider.of<DoctorProvider>(context, listen: false);
    final token = request['token'];

    // if (token == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Missing access token', style: GoogleFonts.poppins())),
    //   );
    //   return;
    // }

    // // Show loading
    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    // );

    final success = await provider.fetchPatientData(token);

    if (mounted) {
      Navigator.pop(context); // close dialog
      
      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorPatientDataScreen(
              patientName: request['patientName'] ?? 'Patient',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Access expired or invalid', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Access History', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: Consumer<DoctorProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.accessRequests.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.accessRequests.isEmpty) {
            return Center(
              child: Text(
                'No access requests found.',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchRequests,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.accessRequests.length,
              itemBuilder: (context, index) {
                final request = provider.accessRequests[index];
                return _buildRequestCard(request);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    final patientName = request['patientName'] ?? 'Unknown Patient';
    final createdAt = request['createdAt'];
    final expiresAt = request['expiresAt'];
    
    bool isApproved = status == 'approved';
    bool isExpired = isApproved && expiresAt != null && _isExpired(expiresAt);

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = isExpired ? AppColors.error : AppColors.success;
        break;
      case 'rejected':
      case 'revoked':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.warning;
    }

    String displayStatus = status.toUpperCase();
    if (isApproved && isExpired) displayStatus = 'EXPIRED';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: AppColors.surface,
      child: InkWell(
        onTap: (isApproved && !isExpired) ? () => _openPatientData(request) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      patientName,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      displayStatus,
                      style: GoogleFonts.poppins(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (createdAt != null)
                Text(
                  'Requested: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(createdAt).toLocal())}',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                ),
              if (isApproved && !isExpired && expiresAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimeLeft(expiresAt),
                        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
