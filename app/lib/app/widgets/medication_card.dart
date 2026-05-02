import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../models/medication_model.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final TimeOfDay? reminderTime;
  final String? status; // 'taken', 'missed', 'pending', 'passed'
  final VoidCallback? onTake;
  final VoidCallback? onTap;

  const MedicationCard({
    super.key,
    required this.medication,
    this.reminderTime,
    this.status,
    this.onTake,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time and status row
            if (reminderTime != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatTime(reminderTime!),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (status != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${_statusLabel(status!)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _statusColor(status!),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (status != 'taken' && onTake != null)
                    GestureDetector(
                      onTap: onTake,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          'Take',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  if (status == 'taken')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Taken',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Medicine info row
            Row(
              children: [
                // Pill icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getMedicationColor().withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getMedicationIcon(),
                    color: _getMedicationColor(),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${medication.type}, ${medication.dosage}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (reminderTime == null)
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textLight,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'am' : 'pm';
    return '${hour.toString()}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'taken':
        return 'Taken';
      case 'missed':
        return 'Missed';
      case 'skipped':
        return 'Skipped';
      case 'passed':
        return 'Passed';
      default:
        return 'Upcoming';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'taken':
        return AppColors.success;
      case 'missed':
        return AppColors.error;
      case 'skipped':
        return AppColors.warning;
      case 'passed':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getMedicationColor() {
    switch (medication.type.toLowerCase()) {
      case 'tablet':
        return AppColors.medicationPill;
      case 'capsule':
        return AppColors.medicationCapsule;
      case 'syrup':
        return AppColors.medicationSyrup;
      case 'injection':
        return AppColors.medicationInjection;
      default:
        return AppColors.primarySurface;
    }
  }

  IconData _getMedicationIcon() {
    switch (medication.type.toLowerCase()) {
      case 'tablet':
        return Icons.circle;
      case 'capsule':
        return Icons.medication;
      case 'syrup':
        return Icons.local_drink;
      case 'injection':
        return Icons.vaccines;
      case 'drops':
        return Icons.water_drop;
      case 'inhaler':
        return Icons.air;
      case 'cream':
        return Icons.spa;
      default:
        return Icons.medication;
    }
  }
}
