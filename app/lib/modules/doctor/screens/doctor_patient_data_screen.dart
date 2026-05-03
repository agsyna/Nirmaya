import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../provider/doctor_provider.dart';

class DoctorPatientDataScreen extends StatefulWidget {
  final String patientName;

  const DoctorPatientDataScreen({
    super.key,
    required this.patientName,
  });

  @override
  State<DoctorPatientDataScreen> createState() => _DoctorPatientDataScreenState();
}

class _DoctorPatientDataScreenState extends State<DoctorPatientDataScreen> {
  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DoctorProvider>(context, listen: false).clearPatientData();
    });
    super.dispose();
  }

  void _openFile(String? url) async {
    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);
    final ext = uri.path.toLowerCase();

    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png')) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(child: Image.network(url)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    } else {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open file', style: GoogleFonts.poppins())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DoctorProvider>(context);
    final data = provider.patientData;

    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.patientName)),
        body: const Center(child: Text('No data available or access expired')),
      );
    }

    // ✅ FIX: Use patientProfile instead of patientContext
    final profile = data['patientProfile'] ?? {};

    final Map<String, List<dynamic>> groupedRecords = {};

    final reports = List<dynamic>.from(data['reports'] ?? []);
    final prescriptions = List<dynamic>.from(data['prescriptions'] ?? []);
    final healthData = List<dynamic>.from(data['healthData'] ?? []);
    final chronicConditions = List<dynamic>.from(data['chronicConditions'] ?? []);
    final allergies = List<dynamic>.from(data['allergies'] ?? []);

    // ✅ ONLY list-based data
    if (reports.isNotEmpty) groupedRecords['report'] = reports;
    if (prescriptions.isNotEmpty) groupedRecords['prescription'] = prescriptions;
    if (healthData.isNotEmpty) groupedRecords['health Data'] = healthData;
    if (chronicConditions.isNotEmpty) groupedRecords['chronic Condition'] = chronicConditions;
    if (allergies.isNotEmpty) groupedRecords['allergy'] = allergies;

    final bool isEmpty = groupedRecords.isEmpty && profile.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.patientName}\'s Data',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patientName,
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (profile['age'] != null)
                        _buildBadge('Age: ${profile['age']}'),
                      if (profile['age'] != null && profile['gender'] != null)
                        const SizedBox(width: 8),
                      if (profile['gender'] != null)
                        _buildBadge(profile['gender'].toString().toUpperCase()),
                    ],
                  ),
                ],
              ),
            ),

            // ✅ Profile Card (separate)
            if (profile.isNotEmpty) _buildProfileCard(profile),

            if (isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No medical records shared.',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...groupedRecords.entries.map((entry) {
                final typeName =
                    entry.key[0].toUpperCase() + entry.key.substring(1);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        '${typeName}s',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: entry.value.length,
                      itemBuilder: (context, index) {
                        final record = entry.value[index];
                        return _buildRecordCard(record);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Patient Profile',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Age: ${profile['age'] ?? '-'}'),
          Text('Gender: ${profile['gender'] ?? '-'}'),
          Text('Blood Group: ${profile['bloodGroup'] ?? '-'}'),
          Text('Height: ${profile['height'] ?? '-'}'),
          Text('Weight: ${profile['weight'] ?? '-'}'),
        ],
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    String title;

    // ✅ FIX: type-aware title
    if (record.containsKey('condition')) {
      title = record['condition'];
    } else if (record.containsKey('allergen')) {
      title = record['allergen'];
    } else if (record.containsKey('title')) {
      title = record['title'];
    } else if (record.containsKey('name')) {
      title = record['name'];
    } else {
      title = 'Medical Record';
    }

    final createdAt =
        record['createdAt'] ?? record['documentDate'] ?? record['recordedAt'];
    final url = record['fileUrl'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: AppColors.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.description, color: AppColors.primary),
        ),
        title: Text(
          title,
          style:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: createdAt != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  DateFormat('dd MMM yyyy')
                      .format(DateTime.parse(createdAt).toLocal()),
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.visibility, color: AppColors.info),
          onPressed: () => _openFile(url),
        ),
        onTap: () => _openFile(url),
      ),
    );
  }
}