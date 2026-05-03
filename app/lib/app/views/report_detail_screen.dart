import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../providers/report_provider.dart';
import '../widgets/custom_app_bar.dart';
import 'chat_with_report_screen.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final provider = context.read<ReportProvider>();
    final report = await provider.getReportDetail(widget.reportId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (report != null) {
          _reportData = report.toJson();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Report Details',
        onBackPressed: () => Navigator.pop(context),
      ),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _reportData == null
              ? Center(
                  child: Text('Report not found', style: GoogleFonts.poppins()),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _reportData!['title'] ?? 'Untitled',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _infoRow('Type', _reportData!['type'] ?? 'N/A'),
                            _infoRow('Date', _reportData!['documentDate'] ?? 'N/A'),
                            _infoRow('Privacy', _reportData!['privacy'] ?? 'private'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // AI Summary
                      if (_reportData!['aiSummary'] != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.infoLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: AppColors.info, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI Summary',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.info,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _reportData!['aiSummary'],
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Extracted Data section
                      _buildExtractedData(),

                      // File Viewer
                      _buildFileViewer(),
                    ],
                  ),
                ),
      floatingActionButton: _reportData?['metadata']?['aiReportId'] != null 
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatWithReportScreen(
                      reportId: _reportData!['metadata']['aiReportId'],
                      reportTitle: _reportData!['title'] ?? 'Report',
                    ),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              label: Text(
                'Chat with Report',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  Widget _buildExtractedData() {
    final metadata = _reportData?['metadata'];
    if (metadata == null || metadata['extractedData'] == null) return const SizedBox.shrink();
    
    final details = metadata['extractedData']['details'] as Map<String, dynamic>?;
    if (details == null || details.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lab Parameters',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: details.length,
            itemBuilder: (context, index) {
              final key = details.keys.elementAt(index);
              final param = details[key];
              
              final status = param['status'] ?? 'Unknown';
              Color statusColor = AppColors.textSecondary;
              if (status.toString().toUpperCase().contains('CRITICAL')) {
                statusColor = AppColors.error;
              } else if (status.toString().toUpperCase() == 'HIGH' || status.toString().toUpperCase() == 'LOW') {
                statusColor = Colors.orange;
              } else if (status.toString().toUpperCase() == 'NORMAL') {
                statusColor = AppColors.success;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        key,
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${param['value']} ${param['unit'] ?? ''}',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            status,
                            style: GoogleFonts.poppins(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getFileType(String fileUrl) {
    final uri = Uri.parse(fileUrl);
    final path = uri.path.toLowerCase();
    if (path.endsWith('.pdf')) return 'pdf';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image';
    if (path.endsWith('.png')) return 'image';
    return 'unknown';
  }

  Widget _buildFileViewer() {
    final fileUrl = _reportData!['fileUrl'] as String?;
    if (fileUrl == null || fileUrl.isEmpty) return const SizedBox.shrink();

    final fileType = _getFileType(fileUrl);

    if (fileType == 'image') {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onTap: () => _openFile(fileUrl),
              child: Image.network(
                fileUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.primary,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Failed to load image',
                        style: GoogleFonts.poppins(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    } else if (fileType == 'pdf') {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.picture_as_pdf,
                color: AppColors.primary,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'PDF Report',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _openFile(fileUrl),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.open_in_new),
                label: Text(
                  'View PDF',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _openFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Try with platformDefault mode as fallback
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No app found to open this file. Please install a PDF viewer or browser.',
                  style: GoogleFonts.poppins(),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error opening file',
              style: GoogleFonts.poppins(),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
