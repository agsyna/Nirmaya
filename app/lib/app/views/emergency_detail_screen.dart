import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../models/emergency_model.dart';
import '../models/nominee_model.dart';
import '../providers/emergency_view_model.dart';
import '../widgets/custom_app_bar.dart';

class EmergencyDetailScreen extends StatefulWidget {
  final String sosId;

  const EmergencyDetailScreen({super.key, required this.sosId});

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
                // _buildStatusCard(emergency),
                // const SizedBox(height: 20),
                _buildEmergencyInfo(emergency),
                const SizedBox(height: 10),
  
                if (emergency.affectedPatientProfile != null) ...[
                  _buildPatientProfileCard(emergency.affectedPatientProfile!),
                  const SizedBox(height: 10),
                ],
                if (emergency.latestHealthData != null) ...[
                  _buildHealthDataCard(emergency.latestHealthData!),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
                              _buildContactsCard(emergency),
                const SizedBox(height: 10),
                                _buildLocationCard(emergency),
                const SizedBox(height: 10),
                          if (emergency.criticalInfoShared != null)...[
                
                  _buildCriticalInfoCard(emergency.criticalInfoShared!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _buildEmergencyInfo(Emergency emergency) {
    final serviceTypes = _serviceTypesFromString(emergency.serviceType);

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
            'SOS Response',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Status', emergency.status.toUpperCase()),
          const SizedBox(height: 12),
          _buildInfoRow('Service Type', emergency.serviceType.toUpperCase()),
          if (serviceTypes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: serviceTypes
                  .map(
                    (type) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          _buildInfoRow('Created', _formatDateTime(emergency.createdAt)),
          if (emergency.resolvedAt != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Resolved', _formatDateTime(emergency.resolvedAt!)),
          ],
        ],
      ),
    );
  }

  Widget _buildContactsCard(Emergency emergency) {
    final contacts = _collectContacts(emergency);
    final hasPhoneNumbers = contacts.any((contact) => contact.phone.isNotEmpty);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shared Contacts',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nominees linked to this emergency',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${contacts.length} contact${contacts.length == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (contacts.isEmpty)
            Text(
              'No nominee contacts found in this SOS response.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...contacts.map((contact) {
              final avatarSource = contact.name.trim();
              final avatarLetter = avatarSource.isNotEmpty
                  ? avatarSource[0].toUpperCase()
                  : '?';

              return GestureDetector(
                            onTap: contact.phone.isNotEmpty
                                ? () => _makePhoneCall(contact.phone)
                                : null,
                            child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primarySurface),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            child: Text(
                              avatarLetter,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.name.isNotEmpty
                                      ? contact.name
                                      : 'Unnamed contact',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (contact.email.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    contact.email,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: contact.phone.isNotEmpty
                                ? AppColors.primary
                                : AppColors.textLight,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                contact.phone.isNotEmpty
                                    ? contact.phone
                                    : 'No phone number available',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: contact.phone.isNotEmpty
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          
                        ],
                      ),
                    ],
                  ),
                ),
                ),
              );
            }),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasPhoneNumbers
                  ? () => _informContacts(emergency)
                  : null,
              icon: const Icon(Icons.sms_outlined),
              label: Text(
                'Inform Contacts',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
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
              // color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 20,
                ),
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
                IconButton(
                  icon: const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: AppColors.primary,
                  ),
                  onPressed: () => _openMaps(emergency.latitude, emergency.longitude),
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
              _buildMetricBox('Age', '${profile.age}', 'yrs', const Color.fromARGB(255, 209, 211, 212)),
              SizedBox(width: 12),
              _buildMetricBox('Blood', profile.bloodGroup, '', const Color.fromARGB(255, 209, 211, 212)),
              SizedBox(width: 12),
              _buildMetricBox(
                'Gender',
                profile.gender.isNotEmpty ? profile.gender[0].toUpperCase() : 'N/A',
                '',
                Color.fromARGB(255, 209, 211, 212)
              ),
            ],
          ),
          if (profile.height != null || profile.weight != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (profile.height != null)
                  _buildMetricBox('Height', '${profile.height}', 'cm', const Color(0xFF4CAF50))
                else
                  const SizedBox.shrink(),
                if (profile.weight != null)
                  _buildMetricBox('Weight', '${profile.weight}', 'kg', const Color(0xFFFF9800))
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
      width: double.infinity,
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
          if (info.nominees.isNotEmpty) ...[
            Text(
              'Shared Contacts in Critical Info',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...info.nominees.map(
              (contact) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${contact.name}${contact.phone.isNotEmpty ? ' · ${contact.phone}' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
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
                              color: const Color(0xFFEF5350).withValues(alpha: 0.2),
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
            }),
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
                              color: const Color(0xFF66BB6A).withValues(alpha: 0.2),
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
            }),
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
                color: Colors.black,
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
                      color: Colors.black,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: " $unit",
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.black,
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

  List<Nominee> _collectContacts(Emergency emergency) {
    final contacts = <Nominee>[...emergency.nominees];
    if (emergency.criticalInfoShared?.nominees.isNotEmpty ?? false) {
      contacts.addAll(emergency.criticalInfoShared!.nominees);
    }

    final seen = <String>{};
    return contacts.where((contact) {
      final key = contact.phone.isNotEmpty
          ? contact.phone.trim()
          : '${contact.name.trim()}|${contact.email.trim()}';
      if (seen.contains(key)) {
        return false;
      }
      seen.add(key);
      return true;
    }).toList();
  }

  List<String> _serviceTypesFromString(String serviceType) {
    return serviceType
        .split(',')
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .toList();
  }

  Future<void> _informContacts(Emergency emergency) async {
    final recipients = _collectContacts(emergency)
        .map((contact) => contact.phone.trim())
        .where((phone) => phone.isNotEmpty)
        .toList();

    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No contact numbers available to inform',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    final message =
        'Emergency SOS: ${emergency.status.toUpperCase()}\n'
        'SOS ID: ${emergency.sosId}\n'
        'Location: ${emergency.latitude}, ${emergency.longitude}\n'
        'Service Type: ${emergency.serviceType}\n'
        'Description: ${emergency.description}';

    final smsUri = Uri.parse(
      'sms:${recipients.join(',')}?body=${Uri.encodeComponent(message)}',
    );

    final launched = await launchUrl(
      smsUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open the messaging app',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

   Future<void> _openMaps(String latitude, String longitude) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // fallback
      await launchUrl(
        Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    debugPrint('Attempting to call $phoneNumber');
    final uri = Uri.parse('tel:$phoneNumber');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open the phone app',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    }
}
}