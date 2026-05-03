import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../models/emergency_model.dart';
import '../providers/emergency_view_model.dart';
import '../widgets/custom_app_bar.dart';

class EmergencyDetailScreen extends StatefulWidget {
  final String sosId;

  const EmergencyDetailScreen({
    super.key,
    required this.sosId,
  });

  @override
  State<EmergencyDetailScreen> createState() => _EmergencyDetailScreenState();
}

class _EmergencyDetailScreenState extends State<EmergencyDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmergencyViewModel>().getEmergencyDetail(widget.sosId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Emergency Details',
        onBackPressed: () => Navigator.pop(context),
      ),
      backgroundColor: AppColors.background,
      body: Consumer<EmergencyViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading && viewModel.currentEmergency == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (viewModel.errorMessage != null &&
              viewModel.currentEmergency == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage!,
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => viewModel.getEmergencyDetail(widget.sosId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final emergency = viewModel.currentEmergency;
          if (emergency == null) {
            return Center(
              child: Text(
                'Emergency details not found',
                style: GoogleFonts.poppins(),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                _buildStatusCard(emergency),
                const SizedBox(height: 20),

                // Emergency Info
                _buildEmergencyInfo(emergency),
                const SizedBox(height: 20),

                // Location
                _buildLocationCard(emergency),
                const SizedBox(height: 20),

                // Affected Patient Profile
                if (emergency.affectedPatientProfile != null)
                  _buildPatientProfileCard(emergency.affectedPatientProfile!),

                if (emergency.affectedPatientProfile != null)
                  const SizedBox(height: 20),

                // Latest Health Data
                if (emergency.latestHealthData != null)
                  _buildHealthDataCard(emergency.latestHealthData!),

                if (emergency.latestHealthData != null)
                  const SizedBox(height: 20),

                // Critical Info
                if (emergency.criticalInfoShared != null)
                  _buildCriticalInfoCard(emergency.criticalInfoShared!),

                if (emergency.criticalInfoShared != null)
                  const SizedBox(height: 20),

                // Action Buttons
                // if (emergency.isActive)
                //   SizedBox(
                //     width: double.infinity,
                //     child: ElevatedButton(
                //       onPressed: () => _showResolveDialog(context, viewModel),
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: const Color(0xFF66BB6A),
                //         padding: const EdgeInsets.symmetric(vertical: 14),
                //       ),
                //       child: Text(
                //         'Mark as Resolved',
                //         style: GoogleFonts.poppins(
                //           color: Colors.white,
                //           fontWeight: FontWeight.w600,
                //         ),
                //       ),
                //     ),
                //   ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(Emergency emergency) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: emergency.isActive
            ? const Color(0xFFEF5350).withValues(alpha: 0.1)
            : const Color(0xFF66BB6A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: emergency.isActive
              ? const Color(0xFFEF5350)
              : const Color(0xFF66BB6A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emergency.status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: emergency.isActive
                          ? const Color(0xFFEF5350)
                          : const Color(0xFF66BB6A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SOS ID: ${emergency.sosId}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (emergency.ambulanceEta != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ETA: ${emergency.ambulanceEta}m',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF9800),
                    ),
                  ),
                ),
            ],
          ),
          if (emergency.message != null) ...[
            const SizedBox(height: 12),
            Text(
              emergency.message!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmergencyInfo(Emergency emergency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primarySurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Service Type', emergency.serviceType.toUpperCase()),
          const SizedBox(height: 12),
          // _buildInfoRow('Ambulance Called', emergency.ambulanceCalled ? 'Yes' : 'No'),
          const SizedBox(height: 12),
          // _buildInfoRow('Voice Message', emergency.voiceMessageSent ? 'Yes' : 'No'),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emergency.description,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Created',
            _formatDateTime(emergency.createdAt),
          ),
          if (emergency.resolvedAt != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Resolved',
              _formatDateTime(emergency.resolvedAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard(Emergency emergency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primarySurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coordinates',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${emergency.latitude}, ${emergency.longitude}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientProfileCard(AffectedPatientProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primarySurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Affected Patient Profile',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricBox(
                'Age',
                '${profile.age}',
                'yrs',
                const Color.fromRGBO(33, 150, 243, 1),
              ),
              _buildMetricBox(
                'Blood',
                profile.bloodGroup,
                '',
                const Color(0xFFEF5350),
              ),
              _buildMetricBox(
                'Gender',
                profile.gender != null && profile.gender.isNotEmpty
                  ? profile.gender[0].toUpperCase()
                  : "N/A",
                '',
                const Color(0xFF9C27B0),
              ),
            ],
          ),
          if (profile.height != null || profile.weight != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (profile.height != null)
                  _buildMetricBox(
                    'Height',
                    '${profile.height}',
                    'cm',
                    const Color(0xFF4CAF50),
                  )
                else
                  const SizedBox.shrink(),
                if (profile.weight != null)
                  _buildMetricBox(
                    'Weight',
                    '${profile.weight}',
                    'kg',
                    const Color(0xFFFF9800),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthDataCard(LatestHealthData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primarySurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Health Data',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildHealthMetric('Blood Pressure', data.bloodPressure, 'mmHg'),
          const SizedBox(height: 12),
          _buildHealthMetric('Heart Rate', '${data.heartRate}', 'bpm'),
          const SizedBox(height: 12),
          _buildHealthMetric('Blood Glucose', '${data.bloodGlucose}', 'mg/dL'),
          const SizedBox(height: 12),
          _buildHealthMetric('Temperature', '${data.temperature}', '°F'),
          const SizedBox(height: 12),
          _buildHealthMetric('Weight', '${data.weight}', 'kg'),
          const SizedBox(height: 8),
          Text(
            'Recorded: ${_formatDateTime(data.recordedAt)}',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalInfoCard(CriticalInfoShared info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primarySurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Critical Information',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (info.allergies.isNotEmpty) ...[
            Text(
              'Allergies',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...info.allergies.map((allergy) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEF5350).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            allergy.name,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFC62828),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF5350)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              allergy.severity,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFC62828),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (allergy.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          allergy.description,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
          ],
          if (info.chronicConditions.isNotEmpty) ...[
            Text(
              'Chronic Conditions',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...info.chronicConditions.map((condition) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF66BB6A).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            condition.name,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF66BB6A)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              condition.status,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (condition.diagnosisDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Diagnosed: ${condition.diagnosisDate}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (condition.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          condition.notes,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthMetric(String label, String value, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: unit,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: color,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
