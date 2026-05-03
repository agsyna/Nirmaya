import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../providers/report_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_app_bar.dart';

class AddReportScreen extends StatefulWidget {
  const AddReportScreen({super.key});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String _selectedType = 'report';
  String _selectedPrivacy = 'private';
  DateTime? _documentDate;
  PlatformFile? _selectedFile;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.allowedFileTypes,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _documentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => _documentDate = date);
  }

  String _getContentType(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      default: return 'application/octet-stream';
    }
  }

  void _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a file', style: GoogleFonts.poppins()), backgroundColor: AppColors.error),
      );
      return;
    }

    final provider = context.read<ReportProvider>();
    final success = await provider.uploadReport(
      title: _titleController.text.trim(),
      type: _selectedType,
      fileBytes: _selectedFile!.bytes!,
      fileName: _selectedFile!.name,
      contentType: _getContentType(_selectedFile!.name),
      documentDate: _documentDate != null ? DateFormat('yyyy-MM-dd').format(_documentDate!) : null,
      privacy: _selectedPrivacy,
    );

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage!, style: GoogleFonts.poppins()), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Add Report', onBackPressed: () => Navigator.pop(context)),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File picker
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity, height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: _selectedFile != null
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(_selectedFile!.name.endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image, size: 44, color: AppColors.primary),
                          const SizedBox(height: 8),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(_selectedFile!.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text('${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                        ])
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle), child: const Icon(Icons.cloud_upload_outlined, size: 26, color: AppColors.primary)),
                          const SizedBox(height: 10),
                          Text('Tap to upload file', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                          Text('PDF, JPG, PNG (Max 10MB)', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                        ]),
                ),
              ),
              const SizedBox(height: 20),

              CustomTextField(controller: _titleController, label: 'Report Title', hint: 'e.g., Chest X-Ray', prefixIcon: Icons.title, validator: (v) => (v == null || v.isEmpty) ? 'Enter a title' : null),
              const SizedBox(height: 18),

              // Type
              Text('Report Type', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: AppConstants.reportTypes.map((t) {
                final sel = _selectedType == t;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: sel ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? AppColors.primary : AppColors.divider)),
                    child: Text(t[0].toUpperCase() + t.substring(1), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: sel ? Colors.white : AppColors.textPrimary)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 18),

              // Date
              Text('Document Date', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text(_documentDate != null ? DateFormat('dd MMM yyyy').format(_documentDate!) : 'Select date', style: GoogleFonts.poppins(fontSize: 14, color: _documentDate != null ? AppColors.textPrimary : AppColors.textLight)),
                  ]),
                ),
              ),
              const SizedBox(height: 18),

              // Privacy
              // Text('Privacy', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
              // const SizedBox(height: 8),
              // Row(children: [
              //   _privacyChip('private', Icons.lock_outline, 'Private'),
              //   const SizedBox(width: 12),
              //   _privacyChip('shared', Icons.public, 'Shared'),
              // ]),
              const SizedBox(height: 28),

              Consumer<ReportProvider>(builder: (context, p, _) => PrimaryButton(text: 'Upload Report', icon: Icons.cloud_upload, isLoading: p.isUploading, onPressed: _upload)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _privacyChip(String value, IconData icon, String label) {
    final sel = _selectedPrivacy == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPrivacy = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: sel ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? AppColors.primary : AppColors.divider)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: sel ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: sel ? Colors.white : AppColors.textPrimary)),
          ]),
        ),
      ),
    );
  }
}
