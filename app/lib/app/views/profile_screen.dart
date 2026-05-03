import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../providers/patient_profile_provider.dart';
import '../widgets/primary_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PatientProfileProvider>(context, listen: false).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: Consumer<PatientProfileProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.profile == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.errorMessage != null && provider.profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!, textAlign: TextAlign.center),
                ],
              ),
            );
          }

          final profile = provider.profile;
          return RefreshIndicator(
            onRefresh: () => provider.loadAll(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileHeader(profile),
                  const SizedBox(height: 24),
                  _buildTabButtons(),
                  const SizedBox(height: 16),
                  _selectedTabIndex == 0
                      ? _buildHealthOverview(provider)
                      : _selectedTabIndex == 1
                          ? _buildAllergies(provider)
                          : _buildChronicConditions(provider),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(Icons.person, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            profile?.name ?? 'Patient',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            profile?.email ?? '',
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoBox('Age', '${profile?.age ?? 0} yrs'),
              _infoBox('Gender', _capitalize(profile?.gender ?? '—')),
              _infoBox('Blood', profile?.bloodGroup ?? '—'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoBox('Height', '${profile?.height?.toStringAsFixed(1) ?? '—'} cm'),
              _infoBox('Weight', '${profile?.weight?.toStringAsFixed(1) ?? '—'} kg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildTabButtons() {
    return Row(
      children: [
        Expanded(
          child: _tabButton(0, 'Health Data'),
        ),
        Expanded(
          child: _tabButton(1, 'Allergies'),
        ),
        Expanded(
          child: _tabButton(2, 'Conditions'),
        ),
      ],
    );
  }

  Widget _tabButton(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildHealthOverview(PatientProfileProvider provider) {
    final healthData = provider.healthData;
    if (healthData == null || healthData.healthData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.health_and_safety_outlined, size: 60, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No health data recorded yet',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Add Health Record',
              onPressed: () => _showAddHealthDataSheet(provider),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: healthData.healthData.take(5).map((data) {
              return _buildHealthDataCard(data);
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PrimaryButton(
            text: 'Add New Record',
            onPressed: () => _showAddHealthDataSheet(provider),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthDataCard(healthData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(healthData.recordedAt),
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Recorded',
                  style: GoogleFonts.poppins(fontSize: 10, color: AppColors.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              if (healthData.bloodPressure != null)
                _vitalItem('BP', healthData.bloodPressure),
              if (healthData.heartRate != null)
                _vitalItem('Heart Rate', '${healthData.heartRate} bpm'),
              if (healthData.bloodGlucose != null)
                _vitalItem('Blood Glucose', '${healthData.bloodGlucose} mg/dL'),
              if (healthData.temperature != null)
                _vitalItem('Temp', '${healthData.temperature}°C'),
              if (healthData.weight != null)
                _vitalItem('Weight', '${healthData.weight} kg'),
            ],
          ),
          if (healthData.notes != null) ...[
            const SizedBox(height: 12),
            Text(
              'Notes: ${healthData.notes}',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _vitalItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildAllergies(PatientProfileProvider provider) {
    final allergies = provider.healthData?.allergies ?? [];
    if (allergies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Text(
          'No allergies recorded',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: allergies.map((allergy) {
          final severityColor = allergy.severity == 'severe'
              ? AppColors.error
              : allergy.severity == 'moderate'
                  ? AppColors.warning
                  : AppColors.success;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allergy.name,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Severity: ${_capitalize(allergy.severity)}',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _capitalize(allergy.severity),
                    style: GoogleFonts.poppins(fontSize: 11, color: severityColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChronicConditions(PatientProfileProvider provider) {
    final conditions = provider.healthData?.chronicConditions ?? [];
    if (conditions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Text(
          'No chronic conditions recorded',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: conditions.map((condition) {
          final statusColor = condition.status == 'active' ? AppColors.warning : AppColors.success;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      condition.name,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${_capitalize(condition.status)}',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _capitalize(condition.status),
                    style: GoogleFonts.poppins(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAddHealthDataSheet(PatientProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddHealthDataSheet(
        provider: provider,
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _AddHealthDataSheet extends StatefulWidget {
  final PatientProfileProvider provider;

  const _AddHealthDataSheet({
    required this.provider,
  });

  @override
  State<_AddHealthDataSheet> createState() => _AddHealthDataSheetState();
}

class _AddHealthDataSheetState extends State<_AddHealthDataSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _bloodPressure;
  int? _bloodGlucose;
  int? _heartRate;
  double? _temperature;
  double? _weight;
  String? _notes;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Health Record',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Blood Pressure (e.g., 120/80)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onSaved: (value) => _bloodPressure = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Blood Glucose (mg/dL)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => _bloodGlucose = int.tryParse(value ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Heart Rate (bpm)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => _heartRate = int.tryParse(value ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Temperature (°C)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => _temperature = double.tryParse(value ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => _weight = double.tryParse(value ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 3,
                onSaved: (value) => _notes = value,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Record',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    final success = await widget.provider.submitHealthData(
      bloodPressure: _bloodPressure,
      bloodGlucose: _bloodGlucose,
      heartRate: _heartRate,
      temperature: _temperature,
      weight: _weight,
      notes: _notes,
    );

    if (mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Health record saved successfully', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.provider.errorMessage ?? 'Failed to save record', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
